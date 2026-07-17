#include "thread.h"
#include "memory.h"  
#include "kalloc.h"  
// 假设有 alloc_page, printf 等函数

struct task_struct* current_thread = 0; // 当前正在运行的线程

// 之前的 switch_to 汇编
extern void switch_to(struct task_struct* current, struct task_struct* next);
// 引入必需的外部变量和函数
extern void return_to_user(void);
extern void set_tss_rsp0(uint64_t rsp0);
extern uint64_t kernel_rsp_scratch;

// 1. 创建线程时，初始化时间片
struct task_struct* thread_create(void (*function)(void), uint32_t priority) {
    void* stack_page = alloc_page(); 
    struct task_struct* thread = (struct task_struct*)stack_page;
    thread->stack_base = (uint64_t*)stack_page;
    
    // 初始化时间片
    thread->ticks = priority;
    thread->priority = priority;
    thread->next = 0;
    
    uint64_t stack_top = (uint64_t)stack_page + 4096;
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
    
    while (next->status == TASK_BLOCKED) {
        next = next->next;
        if (next == current_thread) return;
    }
    
    if (next != current_thread) {
        // ==========================================
        // 【核心修改】在灵魂出窍之前，把系统的降落伞换成新进程的！
        // 这样即使新进程发生中断或 syscall，也不会污染别人的栈！
        // ==========================================
        if (next->kernel_stack_top != 0) {
            set_tss_rsp0(next->kernel_stack_top);
            kernel_rsp_scratch = next->kernel_stack_top;
        }

        current_thread = next; 
        switch_to(prev, next);
    }
}

void thread_yield(void) {
    asm volatile("cli");  // 关中断保护现场
    schedule();           // 主动呼叫调度器切走自己
    asm volatile("sti");  // 等再次轮到自己时，恢复中断
}



// ==========================================
// 创建 Ring 3 用户进程！
// ==========================================
struct task_struct* process_create(void (*app_func)(void), uint32_t priority) {
    // 1. 分配内核栈 (Ring 0)，PCB 放底部
    void* kernel_stack = alloc_page(); 
    struct task_struct* thread = (struct task_struct*)kernel_stack;
    thread->stack_base = (uint64_t*)kernel_stack;
    thread->ticks = priority;
    thread->priority = priority;
    thread->status = TASK_READY;
    thread->waiting_lock = 0;
    thread->next = 0;
    
    // 记录内核栈的最高点 (用于 TSS 和 Syscall)
    uint64_t k_stack_top = (uint64_t)kernel_stack + 4096;
    thread->kernel_stack_top = k_stack_top;

    // 2. 分配用户栈 (Ring 3)
    void* user_stack = alloc_page();
    uint64_t user_rsp = (uint64_t)user_stack + 4096;

    // 3. 核心黑魔法：在内核栈顶，向下伪造 5 层 iretq 结构！
    uint64_t* stack = (uint64_t*)k_stack_top;
    *(--stack) = 0x1B;               // 第 5 层：SS (用户数据段)
    *(--stack) = user_rsp;           // 第 4 层：RSP (用户栈指针)
    *(--stack) = 0x202;              // 第 3 层：RFLAGS (开启中断)
    *(--stack) = 0x23;               // 第 2 层：CS (用户代码段)
    *(--stack) = (uint64_t)app_func; // 第 1 层：RIP (用户态函数入口)

    // 4. 在 iretq 结构之下，继续伪造 switch_to 需要的线程上下文
    stack = (uint64_t*)((uint64_t)stack - sizeof(struct thread_context));
    struct thread_context* ctx = (struct thread_context*)stack;
    
    // 让 switch_to 切过来时，跳到刚才写的 return_to_user 汇编去执行 iretq！
    ctx->rip = (uint64_t)return_to_user; 
    ctx->rbp = 0; ctx->rbx = 0; ctx->r12 = 0; 
    ctx->r13 = 0; ctx->r14 = 0; ctx->r15 = 0;
    
    // 5. 保存最后的栈顶
    thread->rsp = (uint64_t)stack;
    
    return thread;
}