// kernel/kernel.c
#include "print.h"
#include "idt.h"
#include "pic.h"  // 引入你新建的 pic.h
#include "io.h"   // 引入 outb
#include "shell.h" // 引入 shell.h

__attribute__((section(".text.kernel_main")))
void kernel_main() {
    clear_screen();
    print_string("Welcome to My 64-bit OS!\n");

    // 1. 提交通讯录给 CPU
    idt_init();
    
    // 2. 初始化并重映射秘书芯片 PIC
    pic_init(); 

    // 3. 解除对时钟的屏蔽
    // 主片的数据端口是 0x21。0xFE 的二进制是 1111 1110。
    // 最低位(0位)对应 IRQ0(时钟)。设为 0 表示放行，其余为 1 表示继续屏蔽。
    outb(0x21, 0xFC); 
    
    print_string("Timer unmasked. Enabling CPU interrupts...\n");

    // 4. STI (Set Interrupt Flag)：让 CPU 允许接收外设中断！
    __asm__ volatile("sti"); 

    print_string("Keyboard enabled. Start typing!\n");

    // 5. 初始化 shell，打印提示符
    shell_init();
    
    // 6. 内核悬停：什么都不干，就静静看着屏幕
    while (1) {
        __asm__ volatile("hlt"); 
    }
}