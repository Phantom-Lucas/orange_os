// kernel/kernel.c
#include "print.h"
#include "idt.h"
#include "pic.h"  
#include "io.h"   
#include "shell.h" 
#include "timer.h"
#include "memory.h"
#include "kalloc.h"
#include "thread.h" 
#include "gdt.h"
#include "syscall.h"

struct task_struct main_thread; // 全局主线程占位
// 暴露我们在汇编里写的变量，用来告诉汇编：“当前的内核栈在哪”
extern uint64_t kernel_rsp_scratch; 

// ==========================================
// 这是平民自己写的标准库函数 (libc)
// ==========================================
void user_print(const char* str) {
    // 触发系统调用！(功能号 1 放进 rax，参数 str 放进 rdi)
    asm volatile(
        "syscall"
        : 
        : "a"(1), "D"(str) 
        : "rcx", "r11", "memory" // 告诉编译器这些会被破坏
    );
}

void user_app_a() {
    while(1) {
        user_print("A"); 
        // 增加一点人为延时，防止打印太快看不清
        for(volatile int i=0; i<10000000; i++); 
    }
}

// 平民程序 B
void user_app_b() {
    while(1) {
        user_print("B"); 
        for(volatile int i=0; i<10000000; i++); 
    }
}

__attribute__((section(".text.kernel_main")))
void kernel_main() {
    print_init(); clear_screen(); print_string("Welcome to My 64-bit OS!\n");

    gdt_init(); idt_init(); pic_init(); timer_init();        
    init_phy_mem_map(128*1024*1024); kmalloc_init();
    syscall_init();

    // 1. 初始化内核主线程，负责接管后续的闲置/Shell
    main_thread.ticks = 10;
    main_thread.priority = 10;
    main_thread.status = TASK_READY;
    main_thread.kernel_stack_top = 0; // 内核主线程不需要降落伞
    thread_append(&main_thread);

    // 2. 利用刚刚写的调度器，创建两个 Ring 3 用户进程！
    struct task_struct* proc_a = process_create(user_app_a, 10);
    thread_append(proc_a);

    struct task_struct* proc_b = process_create(user_app_b, 10);
    thread_append(proc_b);

    // 3. 解除硬件屏蔽，开启上帝之手 (时钟)！
    outb(0x21, 0xFC); 
    __asm__ volatile("sti"); 

    // 内核主线程悬停
    while (1) { 
        __asm__ volatile("hlt"); 
    }
}