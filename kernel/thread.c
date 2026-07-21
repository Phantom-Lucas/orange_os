// kernel/thread.c
#include "thread.h"
#include "memory.h"  
#include "kalloc.h"  

// ==========================================
// 【新增核心定义】：引入 CPU 局部数据结构 (应对 SwapGS Syscall)
// 结构体布局必须和 syscall.c 保持 100% 一致
// ==========================================
struct cpu_local_data {
    uint64_t kernel_rsp;
    uint64_t user_rsp;
};
extern struct cpu_local_data current_cpu;

struct task_struct* current_thread = 0; // 当前正在运行的线程

// 之前的 switch_to 汇编
extern void switch_to(struct task_struct* current, struct task_struct* next);
// 引入必需的外部变量和函数
extern void return_to_user(void);
extern void set_tss_rsp0(uint64_t rsp0);
extern void* create_page_dir(void);
extern void map_page(uint64_t pml4_paddr, uint64_t vaddr, uint64_t paddr, uint64_t flags); // 引入挂载函数

// 初始化多线程系统，为主线程颁发合法身份
void thread_init(void) {
    // 1. 为当前正在运行的主线程 (Boot Thread) 申请一块内存作为 PCB
    void* main_pcb_paddr = alloc_page();
    struct task_struct* main_thread = (struct task_struct*)P2V(main_pcb_paddr);
    
    // 2. 初始化基本属性
    main_thread->status = TASK_READY;
    main_thread->priority = 5;
    main_thread->ticks = 5;
    
    // 主线程就运行在内核空间，直接使用默认的内核页表物理基址
    main_thread->cr3_paddr = 0x70000; 
    
    // 3. 将它设为全局当前线程，并且闭环成单向循环链表
    main_thread->next = main_thread;
    current_thread = main_thread;
}

// 1. 创建线程时，初始化时间片
struct task_struct* thread_create(void (*function)(void), uint32_t priority) {
    void* paddr = alloc_page(); 
    // 必须全部转换为高半区虚拟地址操作！
    struct task_struct* thread = (struct task_struct*)P2V(paddr);
    thread->stack_base = (uint64_t*)P2V(paddr);
    
    thread->ticks = priority;
    thread->priority = priority;
    thread->next = 0;
    thread->status = TASK_READY;
    thread->cr3_paddr = 0x70000; 
    
    // 栈顶必须是虚拟地址！
    uint64_t stack_top = (uint64_t)thread->stack_base + 4096;
    stack_top -= sizeof(struct thread_context);
    struct thread_context* ctx = (struct thread_context*)stack_top;
    
    ctx->rip = (uint64_t)function; 
    ctx->rbp = 0; ctx->rbx = 0; ctx->r12 = 0; 
    ctx->r13 = 0; ctx->r14 = 0; ctx->r15 = 0;
    
    thread->rsp = stack_top;
    return thread;
}

// 2. 将线程加入循环链表
void thread_append(struct task_struct* new_thread) {
    if (current_thread == 0) {
        // 如果是第一个线程，自己指向自己，形成环
        current_thread = new_thread;
        new_thread->next = new_thread;
    } else {
        // 找到链表尾部并插入
        struct task_struct* temp = current_thread;
        while (temp->next != current_thread) {
            temp = temp->next;
        }
        temp->next = new_thread;
        new_thread->next = current_thread; // 闭环
    }
}

// 3. 核心：调度函数
void schedule() {
    if (current_thread == 0 || current_thread->next == current_thread) return; 
    
    struct task_struct* prev = current_thread;
    struct task_struct* next = current_thread->next; 
    
    while (next->status == TASK_BLOCKED || next->status == TASK_DEAD) {
        next = next->next;
        if (next == current_thread) return;
    }
    
    if (next != current_thread) {
        // ==========================================
        // 【核心修改】在灵魂出窍之前，把系统的双重降落伞都换成新进程的！
        // ==========================================
        if (next->kernel_stack_top != 0) {
            // 降落伞 1：给硬件中断用 (Timer, Keyboard 等)
            set_tss_rsp0(next->kernel_stack_top);
            
            // 降落伞 2：【修复点】给软件 syscall 换栈用 (彻底告别旧变量)
            current_cpu.kernel_rsp = next->kernel_stack_top;
        }
        
        if (next->cr3_paddr != prev->cr3_paddr) {
            __asm__ volatile (
                "mov %0, %%cr3" 
                : 
                : "r"(next->cr3_paddr) 
                : "memory"
            );
        }

        current_thread = next; 
        switch_to(prev, next);
    }
}

void thread_yield(void) {
    __asm__ volatile("cli");  // 关中断保护现场
    schedule();               // 主动呼叫调度器切走自己
    __asm__ volatile("sti");  // 等再次轮到自己时，恢复中断
}


// ==========================================
// 创建 Ring 3 用户进程！
// ==========================================
struct task_struct* process_create(void (*app_func)(void), uint32_t priority) {
    // 1. 分配内核栈 (必须用 P2V)
    void* kstack_paddr = alloc_page(); 
    struct task_struct* thread = (struct task_struct*)P2V(kstack_paddr);
    thread->stack_base = (uint64_t*)P2V(kstack_paddr);
    thread->ticks = priority;
    thread->priority = priority;
    thread->status = TASK_READY;
    thread->waiting_lock = 0;
    thread->next = 0;
    
    // 分配并初始化独立的页表
    thread->cr3_paddr = (uint64_t)create_page_dir();

    // 记录虚拟内核栈顶 (用于 TSS 和 Syscall)
    uint64_t k_stack_top = (uint64_t)thread->stack_base + 4096;
    thread->kernel_stack_top = k_stack_top;

    // 2. 分配用户栈 
    void* user_stack_paddr = alloc_page();
    // 为用户栈指定一个合法的虚拟地址 (比如 0xC0000000)
    uint64_t user_stack_vaddr = 0xC0000000;
    // 将物理页挂载到这个虚拟地址上 (权限 0x07，用户态可读写)
    map_page(thread->cr3_paddr, user_stack_vaddr, (uint64_t)user_stack_paddr, 0x07);
    // 用户态的栈顶指针
    uint64_t user_rsp = user_stack_vaddr + 4096;

    // 3. 在内核虚拟栈顶，向下伪造 5 层 iretq 结构
    uint64_t* stack = (uint64_t*)k_stack_top;
    *(--stack) = 0x1B;               // 第 5 层：SS (用户数据段)
    *(--stack) = user_rsp;           // 第 4 层：RSP (合法的用户虚拟栈)
    *(--stack) = 0x202;              // 第 3 层：RFLAGS (开启中断)
    *(--stack) = 0x23;               // 第 2 层：CS (用户代码段)
    *(--stack) = (uint64_t)app_func; // 第 1 层：RIP (用户态入口)

    // 4. 伪造 switch_to 需要的线程上下文
    stack = (uint64_t*)((uint64_t)stack - sizeof(struct thread_context));
    struct thread_context* ctx = (struct thread_context*)stack;
    
    ctx->rip = (uint64_t)return_to_user; 
    ctx->rbp = 0; ctx->rbx = 0; ctx->r12 = 0; 
    ctx->r13 = 0; ctx->r14 = 0; ctx->r15 = 0;
    
    // 5. 最终交给 switch_to 的必定是一个高半区虚拟栈指针！
    thread->rsp = (uint64_t)stack;
    
    return thread;
}

void thread_exit(void) {
    current_thread->status = TASK_DEAD; // 标记自己死亡
    while(1) { thread_yield(); }        // 永远交出 CPU
}