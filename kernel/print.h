// kernel/print.h

#ifndef PRINT_H
#define PRINT_H

#define VGA_BLACK         0
#define VGA_BLUE          1
#define VGA_GREEN         2
#define VGA_CYAN          3
#define VGA_RED           4
#define VGA_MAGENTA       5
#define VGA_BROWN         6
#define VGA_LIGHT_GRAY    7
#define VGA_DARK_GRAY     8
#define VGA_LIGHT_BLUE    9
#define VGA_LIGHT_GREEN   10
#define VGA_LIGHT_CYAN    11
#define VGA_LIGHT_RED     12
#define VGA_LIGHT_MAGENTA 13
#define VGA_YELLOW        14
#define VGA_WHITE         15

void print_init(void);

void clear_screen(void); // 清屏

void put_char(char c); // 输出一个字符

void print_string(const char *str); // 输出字符串

void print_hex(unsigned long val); // 输出十六进制数

void print_int(long val); // 输出整数

void set_print_color(unsigned char fg, unsigned char bg); // 设置打印颜色

void reset_print_color(void); // 重置打印颜色为默认值

void print_error(const char* str);    // 亮红色

void print_success(const char* str);  // 亮绿色

void print_info(const char* str);     // 亮青色

void print_warning(const char* str);  // 黄色

void panic_print(const char* str);

void panic_print_hex(unsigned long val);

void panic_print_int(long val);

#endif