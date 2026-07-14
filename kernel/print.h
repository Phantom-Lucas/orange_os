// kernel/print.h
#ifndef PRINT_H
#define PRINT_H


unsigned short get_cursor(void); // 获取光标位置

void set_cursor(unsigned short pos); // 设置光标位置

void put_char(char c); // 输出一个字符

#endif