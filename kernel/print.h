// kernel/print.h

#ifndef PRINT_H
#define PRINT_H

#ifndef BOOT_DIAGNOSTIC
#define BOOT_DIAGNOSTIC 0
#endif

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

void clear_screen(void);

void put_char(char c);

void print_string(const char *str);

void print_buffer(const char* buffer, unsigned long length);

void print_hex(unsigned long val);

void print_int(long val);

void set_print_color(unsigned char fg, unsigned char bg);

void reset_print_color(void);

void print_error(const char* str);

void print_success(const char* str);

void print_info(const char* str);

void print_warning(const char* str);
/* 仅在 BOOT_DIAGNOSTIC=1 时输出；正常启动保持安静。 */
void print_debug(const char* str);

void panic_print(const char* str);

void panic_print_hex(unsigned long val);

void panic_print_int(long val);

#endif
