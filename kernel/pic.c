// kernel/pic.c

#include "pic.h"
#include "io.h"   
#include "print.h"

// 初始化 8259A 可编程中断控制器 (PIC)
#define PIC1_COMMAND 0x20
#define PIC1_DATA    0x21
#define PIC2_COMMAND 0xA0
#define PIC2_DATA    0xA1

void pic_init(void) {
    //  发送 ICW1：告诉主从片，准备初始化
    outb(PIC1_COMMAND, 0x11);
    outb(PIC2_COMMAND, 0x11);

    //  发送 ICW2：最核心的重映射！
    outb(PIC1_DATA, 0x20); // 主片 IRQ0~7 映射到中断号 0x20~0x27 (十进制 32~39)
    outb(PIC2_DATA, 0x28); // 从片 IRQ8~15 映射到中断号 0x28~0x2F (十进制 40~47)

    //  发送 ICW3：设置级联
    outb(PIC1_DATA, 0x04); // 告诉主片，从片接在你的 IRQ2 引脚上 (二进制 0000 0100)
    outb(PIC2_DATA, 0x02); // 告诉从片，你自己的身份标识是 2

    //  发送 ICW4：设置工作模式为 8086 模式
    outb(PIC1_DATA, 0x01);
    outb(PIC2_DATA, 0x01);

    //  发送 OCW1 (屏蔽字)：先把所有硬件都屏蔽掉 (写入 0xFF 即 11111111)
    outb(PIC1_DATA, 0xFF); 
    outb(PIC2_DATA, 0xFF); 

    print_string("[INFO] 8259A PIC Initialized and Remapped.\n");
}

