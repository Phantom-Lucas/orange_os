// kernel/print.h

#ifndef PRINT_H
#define PRINT_H


unsigned short get_cursor(void); // 获取光标位置

void set_cursor(unsigned short pos); // 设置光标位置

void clear_screen(void); // 清屏

void put_char(char c); // 输出一个字符

void print_string(const char *str); // 输出字符串

void print_hex(unsigned long val); // 输出十六进制数

void print_int(long val); // 输出整数

#endif