// kernel/idt.c

#include "idt.h"
#include "print.h"
#include "io.h"
#include "timer.h"
#include "tty.h"
#include "keyboard.h"
#include "thread.h"
#include "process.h"


// 中断描述符表 (IDT) 的数组
#define IDT_SIZE 256
struct idt_entry idt[IDT_SIZE];
struct idtr idtr_reg;

/*
 * Ring 3 异常不应当毁掉整个系统：把出错进程按普通退出处理，让正在
 * wait() 的父进程得到一个可辨认的退出码。内核态异常仍然保留 panic，
 * 因为那意味着内核自身的数据或控制流已经不可信。
 */

 // 检查异常是否来自用户态 (Ring 3)
static int exception_from_user(const struct interrupt_frame* frame) {
    return (frame->cs & 0x3) == 0x3;
}

// 终止出错的用户态进程，并打印错误信息
static __attribute__((noreturn))
void terminate_faulting_user(struct interrupt_frame* frame, int status, const char* description) {
    print_error("[PROCESS] Ring 3 exception: ");
    print_error(description);
    print_error(" pid=");
    print_int(current_thread && current_thread->process ?
              (long)current_thread->process->pid : -1);
    print_error(" rip=");
    print_hex(frame->rip);
    print_error("; terminating process.\n");
    process_exit(status);
    while (1) { __asm__ volatile("hlt"); }
}

// 设置中断门描述符
void set_idt_gate(int interrupt_number, unsigned long handler_address) 
{
    idt[interrupt_number].offset_low = handler_address & 0xFFFF;
    idt[interrupt_number].selector = 0x08; // 代码段选择子
    idt[interrupt_number].ist = 0;
    idt[interrupt_number].type_attr = 0x8E; // 中断门属性  
    idt[interrupt_number].offset_mid = (handler_address >> 16) & 0xFFFF;
    idt[interrupt_number].offset_high = (handler_address >> 32) & 0xFFFFFFFF;
    idt[interrupt_number].reserved = 0;
}

// 0 号异常：除零异常处理函数
__attribute__((interrupt))
void isr0_divide_by_zero(struct interrupt_frame* frame) {
    if (exception_from_user(frame)) {
        terminate_faulting_user(frame, 128, "divide by zero");
    }
    panic_print("\n================================================\n");
    panic_print("[KERNEL PANIC] Exception 0: Divide by Zero!\n");
    panic_print("Crash Instruction Address (RIP): ");
    panic_print_hex(frame->rip);
    panic_print("\n================================================\n");
    panic_print("System Halted.\n");
    while (1) { __asm__ volatile("hlt"); }
}

// 13 号异常：通用保护异常 (General Protection Fault)
__attribute__((interrupt))
void isr13_gpf(struct interrupt_frame* frame, unsigned long error_code)
{
    if (exception_from_user(frame)) {
        (void)error_code;
        terminate_faulting_user(frame, 141, "general protection fault");
    }
    panic_print("\n================================================\n");
    panic_print("[KERNEL PANIC] Exception 13: General Protection Fault!\n");
    panic_print("Error Code: "); panic_print_hex(error_code); panic_print("\n");
    panic_print("RIP (Crash Instruction): "); panic_print_hex(frame->rip); panic_print("\n");
    panic_print("================================================\n");
    panic_print("System Halted.\n");
    while (1) { __asm__ volatile("hlt"); }
}

// 14 号异常：页错误 (Page Fault)
__attribute__((interrupt))
void isr14_page_fault(struct interrupt_frame* frame, unsigned long error_code)
{
    unsigned long cr2_address;
    __asm__ volatile("mov %%cr2, %0" : "=r"(cr2_address));

    if (exception_from_user(frame)) {
        /* Present + write + user fault on a COW PTE is recoverable. */
        if ((error_code & 0x7UL) == 0x7UL && current_thread != NULL &&
            current_thread->process != NULL) {
            struct process* process = current_thread->process;
            int handled;
            spinlock_acquire(&process->address_space_lock);
            handled = handle_cow_page_fault(process->cr3_paddr,
                                            (vaddr_t)cr2_address);
            spinlock_release(&process->address_space_lock);
            if (handled == 0) return;
        }
        /* 非 present 的用户栈页可以按 VMA 的 VM_GROWSDOWN 规则补入。 */
        if (current_thread != NULL && current_thread->process != NULL &&
            (error_code & 0x1UL) == 0 &&
            process_handle_page_fault(current_thread->process,
                                       (vaddr_t)cr2_address,
                                       error_code) == 0) {
            return;
        }
        terminate_faulting_user(frame, 142, "page fault");
    }

    panic_print("\n================================================\n");
    panic_print("[KERNEL PANIC] Exception 14: Page Fault!\n");
    panic_print("Faulting Memory Address (CR2): "); panic_print_hex(cr2_address); panic_print("\n");
    panic_print("Error Code: "); panic_print_hex(error_code); panic_print("\n");
    panic_print("RIP (Crash Instruction): "); panic_print_hex(frame->rip); panic_print("\n");
    panic_print("================================================\n");
    panic_print("System Halted.\n");
    while (1) { __asm__ volatile("hlt"); }
}

// 硬件时钟中断处理函数
__attribute__((interrupt))
void isr32_timer(struct interrupt_frame* frame) 
{
    struct thread* interrupted = current_thread;
    int from_user = (frame->cs & 0x3) == 0x3;
    if (from_user) thread_note_user_interrupt_rsp(frame->rsp);
    if (from_user) __asm__ volatile("swapgs" ::: "memory");
    timer_interrupt_handler(); // 调用 timer.c 中的处理函数
    /* 若切换没有离开当前中断上下文，恢复用户 GS 后再 iret；如果已经
       切到另一个线程，返回路径会由其 kernel/user 入口负责。 */
    if (from_user && current_thread == interrupted) {
        if (interrupted->process != 0 && interrupted->process->exit_requested) {
            process_exit(interrupted->process->kill_status);
        }
        __asm__ volatile("swapgs" ::: "memory");
    }
}

// 33 号中断：键盘处理函数
__attribute__((interrupt))
void isr33_keyboard(struct interrupt_frame* frame) {
    unsigned char scan_code = inb(0x60);
    keyboard_handle_scancode(scan_code);

    struct keyboard_event event;
    while (keyboard_pop_event(&event)) {
        if (event.type == KEYBOARD_EVENT_SWITCH_CONSOLE) {
            tty_switch(event.console_index);
        } else if (event.type == KEYBOARD_EVENT_SCROLL_UP) {
            tty_scroll_active(-24);
        } else if (event.type == KEYBOARD_EVENT_SCROLL_DOWN) {
            tty_scroll_active(24);
        } else {
            tty_handle_input_char(event.ch);
        }
    }

    outb(0x20, 0x20);
}

// 初始化 IDT
void idt_init(void) 
{
    // 初始化 IDT 表
    for(int i = 0; i < IDT_SIZE; i++) {
        idt[i].offset_low = 0;
        idt[i].selector = 0x08; // 代码段选择子
        idt[i].ist = 0;
        idt[i].type_attr = 0x8E; // 中断门属性  
        idt[i].offset_mid = 0;
        idt[i].offset_high = 0;
        idt[i].reserved = 0;
    }


    set_idt_gate(0, (unsigned long)isr0_divide_by_zero);
    set_idt_gate(13, (unsigned long)isr13_gpf);
    set_idt_gate(14, (unsigned long)isr14_page_fault);
    set_idt_gate(32, (unsigned long)isr32_timer); 
    set_idt_gate(33, (unsigned long)isr33_keyboard); 


    // 设置 IDTR 寄存器
    idtr_reg.limit = sizeof(idt) - 1;
    idtr_reg.base = (unsigned long)&idt;

    // 加载 IDTR 寄存器
    __asm__ volatile("lidt %0" : : "m"(idtr_reg));

}
