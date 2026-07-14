// kernel/print.c
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

// 清屏并将光标归零
void clear_screen(void) {
    char* video_memory = (char*)0xb8000UL;
    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2] = ' ';       // 字符为空格
        video_memory[i * 2 + 1] = 0x0F;  // 属性为黑底白字
    }
    set_cursor(0);
}

// 打印单个字符（内置自动滚屏）
void put_char(char c) {
    unsigned short pos = get_cursor();
    char* video_memory = (char*)0xb8000UL;

    if (c == '\r') {
        pos = (pos / 80) * 80; // 回车：回到行首
    } else if (c == '\n') {
        pos = (pos / 80 + 1) * 80; // 换行：下一行行首
    } else if (c == '\b') {
        if (pos > 0) {
            pos--; // 退格：回退一格，并清空显存
            video_memory[pos * 2] = ' ';
            video_memory[pos * 2 + 1] = 0x0F;
        }
    } else {
        // 普通字符写入
        video_memory[pos * 2] = c;
        video_memory[pos * 2 + 1] = 0x0F;
        pos++;
    }

    // ==========================================
    // 【新增】屏幕滚动逻辑 (Scroll)
    // ==========================================
    if (pos >= 80 * 25) {
        // 1. 将第 2~25 行的数据（共 24 行），强制搬运到第 1~24 行
        for (int i = 0; i < 80 * 24 * 2; i++) {
            video_memory[i] = video_memory[i + 80 * 2];
        }
        // 2. 将最后一行的内容用空格清空
        for (int i = 80 * 24; i < 80 * 25; i++) {
            video_memory[i * 2] = ' ';
            video_memory[i * 2 + 1] = 0x0F;
        }
        // 3. 把光标强行拉回最后一行的行首
        pos = 80 * 24;
    }

    set_cursor(pos);
}

// 打印字符串
void print_string(const char* str) {
    while (*str != '\0') {
        put_char(*str);
        str++;
    }
}

// 打印 64 位十六进制数 (会自动去除前导 0)
void print_hex(unsigned long val) {
    print_string("0x");
    if (val == 0) {
        put_char('0');
        return;
    }
    
    char buffer[16];
    int idx = 0;
    const char* hex_chars = "0123456789ABCDEF";
    
    // 提取每一位十六进制数字
    while (val > 0) {
        buffer[idx++] = hex_chars[val & 0x0F];
        val >>= 4;
    }
    
    // 因为提取出来是反的，所以倒序打印
    while (idx > 0) {
        idx--;
        put_char(buffer[idx]);
    }
}

// 打印十进制有符号整数
void print_int(long val) {
    if (val == 0) {
        put_char('0');
        return;
    }
    if (val < 0) {
        put_char('-');
        val = -val;
    }
    
    char buffer[20];
    int idx = 0;
    
    // 提取每一位十进制数字
    while (val > 0) {
        buffer[idx++] = '0' + (val % 10);
        val /= 10;
    }
    
    // 倒序打印
    while (idx > 0) {
        idx--;
        put_char(buffer[idx]);
    }
}