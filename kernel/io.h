// kernel/io.h
#ifndef IO_H
#define IO_H

// 往指定端口写入一个字节
static inline void outb(unsigned short port, unsigned char val) {
    // 使用 %b0 和 %w1 强行对齐寄存器尺寸，防止编译器生成 eax/rax 导致 #GP 异常崩溃
    __asm__ volatile ( "outb %b0, %w1" : : "a"(val), "Nd"(port) );
}

// 从指定端口读出一个字节
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    // 使用 %w1 和 %b0 确保使用 dx 和 al
    __asm__ volatile ( "inb %w1, %b0" : "=a"(ret) : "Nd"(port) );
    return ret;
}

#endif