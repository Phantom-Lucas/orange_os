// kernel/idt.h

#ifndef IDT_H
#define IDT_H

// 中断门描述符 (64位模式下固定 16 字节)
struct idt_entry 
{
    unsigned short offset_low;    // 目标函数地址的 第 0~15 位
    unsigned short selector;      // 代码段选择子，填 0x08
    unsigned char  ist;           // 中断栈表偏移，暂时不用，填 0
    unsigned char  type_attr;     // 属性字节，64位中断门固定填 0x8E
    unsigned short offset_mid;    // 目标函数地址的 第 16~31 位
    unsigned int   offset_high;   // 目标函数地址的 第 32~63 位
    unsigned int   reserved;      // 保留位，必须填 0
} __attribute__((packed));


// IDTR 寄存器结构 (固定 10 字节)
struct idtr 
{
    unsigned short limit;         // IDT 表的总字节数减 1
    unsigned long  base;          // IDT 表的物理内存首地址
} __attribute__((packed));

// CPU 压入栈的上下文信息
struct interrupt_frame 
{
    unsigned long rip;     // 发生异常的那条指令的地址 (非常重要，可以用来排查 bug！)
    unsigned long cs;      // 代码段选择子
    unsigned long rflags;  // 状态标志寄存器
    unsigned long rsp;     // 栈顶指针
    unsigned long ss;      // 堆栈段选择子
};


// 设置中断门描述符
void set_idt_gate(int interrupt_number, unsigned long handler_address);

// 除零异常处理函数
__attribute__((interrupt))
void isr0_divide_by_zero(struct interrupt_frame* frame);

// 13 号异常：通用保护异常 (General Protection Fault)
__attribute__((interrupt))
void isr13_gpf(struct interrupt_frame* frame, unsigned long error_code);

// 14 号异常：页错误 (Page Fault)
__attribute__((interrupt))
void isr14_page_fault(struct interrupt_frame* frame, unsigned long error_code);

// 硬件时钟中断处理函数
__attribute__((interrupt))
void isr32_timer(struct interrupt_frame* frame); 

// 键盘中断处理函数
__attribute__((interrupt))
void isr33_keyboard(struct interrupt_frame* frame);

// 初始化中断描述符表
void idt_init(void);

#endif