// kernel/print.c

#include "print.h"
#include "io.h"
#include "string.h"
#include "sync.h"
#include "memory.h"
#include "tty.h"

static unsigned char current_color = 0x0F;

mutex_t print_lock;

// 获取光标位置
unsigned short _get_cursor(void) {
    unsigned short pos = 0;
    outb(0x3D4, 0x0E);
    pos |= ((unsigned short)inb(0x3D5)) << 8;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    return pos;
}

// 设置光标位置
void _set_cursor(unsigned short pos) {
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)(pos >> 8));
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(pos & 0xFF));
}

// 内部打印字符函数，直接操作显存，不加锁
static void _put_char(char c) {
    unsigned short pos = _get_cursor();
    char* video_memory = (char*)P2V(0xb8000UL);

    if (c == '\r') {
        pos = (pos / 80) * 80;
    } else if (c == '\n') {
        pos = (pos / 80 + 1) * 80;
    } else if (c == '\b') {
        if (pos > 0) {
            pos--;
            video_memory[pos * 2] = ' ';
            video_memory[pos * 2 + 1] = current_color;
        }
    } else {
        video_memory[pos * 2] = c;
        video_memory[pos * 2 + 1] = current_color;
        pos++;
    }

    if (pos >= 80 * 25) {
        memcpy(video_memory, video_memory + 80 * 2, 80 * 24 * 2);
        for (int i = 80 * 24; i < 80 * 25; i++) {
            video_memory[i * 2] = ' ';
            video_memory[i * 2 + 1] = 0x0F;
        }
        pos = 80 * 24;
    }
    _set_cursor(pos);
}

// 内部打印字符函数，带颜色支持
static void output_char(char c) {
    if (tty_is_initialized()) {
        tty_put_char_colored(c, current_color);
    } else {
        _put_char(c);
    }
}

// 内部打印字符串
static void _print_string(const char* str) {
    while (*str != '\0') {
        output_char(*str);
        str++;
    }
}

// 内部打印十六进制数
static void _print_hex(unsigned long val) {
    if (val == 0) { output_char('0'); return; }
    char buffer[16];
    int idx = 0;
    const char* hex_chars = "0123456789ABCDEF";
    while (val > 0) { buffer[idx++] = hex_chars[val & 0x0F]; val >>= 4; }
    while (idx > 0) { idx--; output_char(buffer[idx]); }
}

// 内部打印整数
static void _print_int(long val) {
    if (val == 0) { output_char('0'); return; }
    if (val < 0) { output_char('-'); val = -val; }
    char buffer[20];
    int idx = 0;
    while (val > 0) { buffer[idx++] = '0' + (val % 10); val /= 10; }
    while (idx > 0) { idx--; output_char(buffer[idx]); }
}

// ==========================================
// 外部安全 API (自带加锁与解锁，确保线程安全)
// ==========================================

// 清屏函数
void clear_screen(void) {
    mutex_acquire(&print_lock);
    if (tty_is_initialized()) {
        tty_clear_active();
        mutex_release(&print_lock);
        return;
    }
    char* video_memory = (char*)P2V(0xb8000UL);
    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2] = ' ';
        video_memory[i * 2 + 1] = 0x0F;
    }
    _set_cursor(0);
    mutex_release(&print_lock);
}

// 打印单个字符
void put_char(char c) {
    mutex_acquire(&print_lock);
    output_char(c);
    mutex_release(&print_lock);
}

// 打印字符串
void print_string(const char* str) {
    mutex_acquire(&print_lock);
    _print_string(str);
    mutex_release(&print_lock);
}

// 打印缓冲区
void print_buffer(const char* buffer, unsigned long length) {
    mutex_acquire(&print_lock);
    if (tty_is_initialized()) {
        tty_write_colored(buffer, length, current_color);
    } else {
        for (unsigned long i = 0; i < length; i++) {
            _put_char(buffer[i]);
        }
    }
    mutex_release(&print_lock);
}

// 打印十六进制数
void print_hex(unsigned long val) {
    mutex_acquire(&print_lock);
    _print_string("0x");
    _print_hex(val);
    mutex_release(&print_lock);
}

// 打印整数
void print_int(long val) {
    mutex_acquire(&print_lock);
    _print_int(val);
    mutex_release(&print_lock);
}

// 颜色设置保留为公开接口，但建议在多任务环境下尽量使用下面的语义化函数
void set_print_color(unsigned char fg, unsigned char bg) {

    mutex_acquire(&print_lock);
    current_color = (bg << 4) | (fg & 0x0F);
    mutex_release(&print_lock);
}

void reset_print_color(void) {
    mutex_acquire(&print_lock);
    current_color = 0x0F;
    mutex_release(&print_lock);
}

// ==========================================
// 语义化安全打印 (把变色、打印、恢复颜色打包成一个绝对不被打断的原子操作！)
// ==========================================


void print_error(const char* str) {
    mutex_acquire(&print_lock);
    current_color = (0x00 << 4) | (0x0C & 0x0F); // 假设 0x00 黑底，0x0C 亮红
    _print_string(str);
    current_color = 0x0F;
    mutex_release(&print_lock);
}

void print_success(const char* str) {
    mutex_acquire(&print_lock);
    current_color = (0x00 << 4) | (0x0A & 0x0F); // 0x0A 亮绿
    _print_string(str);
    current_color = 0x0F;
    mutex_release(&print_lock);
}

void print_info(const char* str) {
    mutex_acquire(&print_lock);
    current_color = (0x00 << 4) | (0x0B & 0x0F); // 0x0B 亮青
    _print_string(str);
    current_color = 0x0F;
    mutex_release(&print_lock);
}

void print_warning(const char* str) {
    mutex_acquire(&print_lock);
    current_color = (0x00 << 4) | (0x0E & 0x0F); // 0x0E 黄色
    _print_string(str);
    current_color = 0x0F;
    mutex_release(&print_lock);
}

void print_debug(const char* str) {
#if BOOT_DIAGNOSTIC
    print_info(str);
#else
    (void)str;
#endif
}

void panic_print(const char* str) {
    current_color = 0x4F; // 强制变更为：红底白字
    while (*str != '\0') {
        _put_char(*str++);
    }
}

void panic_print_hex(unsigned long val) {
    current_color = 0x4F;
    _put_char('0');
    _put_char('x');
    if (val == 0) { _put_char('0'); return; }
    char buffer[16];
    int idx = 0;
    const char* hex_chars = "0123456789ABCDEF";
    while (val > 0) { buffer[idx++] = hex_chars[val & 0x0F]; val >>= 4; }
    while (idx > 0) { _put_char(buffer[--idx]); }
}

void panic_print_int(long val) {
    current_color = 0x4F;
    if (val == 0) { _put_char('0'); return; }
    if (val < 0) { _put_char('-'); val = -val; }
    char buffer[20];
    int idx = 0;
    while (val > 0) { buffer[idx++] = '0' + (val % 10); val /= 10; }
    while (idx > 0) { _put_char(buffer[--idx]); }
}

// 【新增】初始化打印机锁 (需要在 kernel_main 最早调用)
void print_init(void) {
    mutex_init(&print_lock);
}
