// kernel/idt.c

#include "idt.h"
#include "print.h"
#include "io.h"

// 中断描述符表 (IDT) 的数组
#define IDT_SIZE 256
struct idt_entry idt[IDT_SIZE];
struct idtr idtr_reg;

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

// 除零异常处理函数
__attribute__((interrupt))
void isr0_divide_by_zero(struct interrupt_frame* frame) {
    // 1. (可选) 清个屏，让红底白字或者显眼的报错信息霸占屏幕
    // clear_screen(); 

    // 2. 打印报错信息
    print_string("\n================================================\n");
    print_string("[KERNEL PANIC] Exception 0: Divide by Zero!\n");
    
    // 3. 提取法医现场的证据：打印崩溃时的 RIP 地址
    print_string("Crash Instruction Address (RIP): ");
    print_hex(frame->rip);
    print_string("\n");
    print_string("================================================\n");
    print_string("System Halted.\n");

    // 4. 彻底锁死 CPU，防止它继续乱跑执行错误代码
    while (1) {
        __asm__ volatile("hlt");
    }
}

// 硬件时钟中断处理函数
__attribute__((interrupt))
void isr32_timer(struct interrupt_frame* frame) 
{
    // 极其重要：发送 EOI (End Of Interrupt)
    // 每次处理完外设中断，必须告诉 PIC 秘书：“处理完了！”
    // 时钟连在主片上，所以向主片的命令端口 (0x20) 发送 0x20
    outb(0x20, 0x20);
}

// 极其简易的键盘扫描码 -> ASCII 码映射表 (只映射了按下时的码，忽略了 Shift/大写)
const char kbd_us[128] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
  '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0,  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
    0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',   0,
  '*',  0,  ' ',  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0, '-',   0,   0,   0, '+',   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0
};

// 33 号中断：键盘处理函数
__attribute__((interrupt))
void isr33_keyboard(struct interrupt_frame* frame) {
    // 1. 从 0x60 端口读取键盘发来的扫描码
    unsigned char scan_code = inb(0x60);

    // 2. 判断是“按下”还是“松开” (最高位为 0 是按下，为 1 是松开)
    // 我们目前只处理“按下”事件
    if (!(scan_code & 0x80)) {
        // 去字典里查这个按键对应的字符
        char c = kbd_us[scan_code];
        
        // 如果不是空字符，就打印到屏幕上！
        if (c != 0) {
            put_char(c);
        }
    }

    // 3. 极其重要：告诉 PIC 秘书，键盘中断处理完毕！
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

    
    // 注册 0 号：除零异常
    set_idt_gate(0, (unsigned long)isr0_divide_by_zero);

    // 注册 32 号：硬件时钟中断
    set_idt_gate(32, (unsigned long)isr32_timer); 

    // 注册 33 号：键盘中断
    set_idt_gate(33, (unsigned long)isr33_keyboard); 


    // 设置 IDTR 寄存器
    idtr_reg.limit = sizeof(idt) - 1;
    idtr_reg.base = (unsigned long)&idt;

    // 加载 IDTR 寄存器
    __asm__ volatile("lidt %0" : : "m"(idtr_reg));

}