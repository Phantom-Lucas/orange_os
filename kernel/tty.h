#ifndef TTY_H
#define TTY_H

#include <stdint.h>

#define TTY_CONSOLE_COUNT 3

struct tty_geometry {
    uint32_t columns;
    uint32_t visible_rows;
    uint32_t history_rows;
    uint32_t glyph_width;
    uint32_t glyph_height;
    uint32_t origin_x;
    uint32_t origin_y;
};

void tty_init(void);
int tty_is_initialized(void);
int tty_use_framebuffer_geometry(const struct tty_geometry* geometry);

void tty_write(const char* buffer, unsigned long length);
void tty_write_colored(const char* buffer, unsigned long length, uint8_t color);
/* 用户 TTY 路径解析有限 ANSI SGR；内核 print 路径仍使用 raw colored API。 */
void tty_write_user(const char* buffer, unsigned long length);
void tty_put_char_colored(char c, uint8_t color);

/* 键盘 IRQ 写入，read(0, ...) 从此队列阻塞读取。 */
void tty_input_char(char c);
void tty_input_sequence(const char* sequence, unsigned long length);
/* 处理键盘产生的控制字符；普通字符仍进入输入队列。 */
void tty_handle_input_char(char c);
int tty_read(char* buffer, unsigned long length);

/* TTY 服务任务：用户读写均通过同步 IPC；IRQ 仅负责向输入队列入队。 */
void tty_service_init(void);
/* 阻塞等待至少一个字符，然后尽量批量返回当前已经到达的字符。 */
int tty_service_read(char* buffer, unsigned long length);
int tty_service_write(const char* buffer, unsigned long length);

void tty_clear_active(void);
/* lines < 0 向历史顶部翻，lines > 0 向最新输出翻。 */
void tty_scroll_active(int32_t lines);
void tty_set_foreground_pid(uint32_t pid);
uint32_t tty_get_foreground_pid(void);
void tty_switch(uint32_t index);
uint32_t tty_active_index(void);
const struct tty_geometry* tty_get_geometry(void);

#endif
