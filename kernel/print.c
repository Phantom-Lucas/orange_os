#include "print.h"
#include "io.h"

// 获取当前硬件光标的位置
unsigned short get_cursor(void) {
    unsigned short pos = 0;
    outb(0x3D4, 0x0E);
    pos |= ((unsigned short)inb(0x3D5)) << 8;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    return pos;
}

// 设置硬件光标的位置
void set_cursor(unsigned short pos) {
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)(pos >> 8));
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(pos & 0xFF));
}

// 打印单个字符状态机
void put_char(char c) {
    unsigned short pos = get_cursor();

    if (c == '\r') {
        pos = (pos / 80) * 80; // 回车：回到当前行行首
    } else if (c == '\n') {
        pos = (pos / 80 + 1) * 80; // 换行：去往下一行行首
    } else if (c == '\b') {
        if (pos > 0) pos--; // 退格：回退一格，并清空显存
        char* video_memory = (char*)(0xb8000UL + pos * 2);
        video_memory[0] = ' ';
        video_memory[1] = 0x0F;
    } else {
        // 普通字符写入
        char* video_memory = (char*)(0xb8000UL + pos * 2);
        video_memory[0] = c;
        video_memory[1] = 0x0F;
        pos++;
    }

    // 临时边界处理（超过屏幕则回绕到开头）
    if (pos >= 80 * 25) {
        pos = 0;
    }
    set_cursor(pos);
}