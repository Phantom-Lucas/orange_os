// kernel/print.c

#include "print.h"
#include "io.h"
#include "string.h"
#include "sync.h" // 【新增】引入锁机制
#include "memory.h"

static unsigned char current_color = 0x0F;

// 【新增】定义全局打印机锁
mutex_t print_lock;



// ==========================================
// 内部无锁基础函数 (以下函数调用前必须已获得锁)
// ==========================================

unsigned short _get_cursor(void) {
    unsigned short pos = 0;
    outb(0x3D4, 0x0E);
    pos |= ((unsigned short)inb(0x3D5)) << 8;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    return pos;
}

void _set_cursor(unsigned short pos) {
    outb(0x3D4, 0x0E);
    outb(0x3D5, (unsigned char)(pos >> 8));
    outb(0x3D4, 0x0F);
    outb(0x3D5, (unsigned char)(pos & 0xFF));
}

// 内部的真正 put_char
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

// 内部的真正 print_string
static void _print_string(const char* str) {
    while (*str != '\0') {
        _put_char(*str);
        str++;
    }
}

// 
static void _print_hex(unsigned long val) {
    if (val == 0) { _put_char('0'); return; }
    char buffer[16];
    int idx = 0;
    const char* hex_chars = "0123456789ABCDEF";
    while (val > 0) { buffer[idx++] = hex_chars[val & 0x0F]; val >>= 4; }
    while (idx > 0) { idx--; _put_char(buffer[idx]); }
}

// 
static void _print_int(long val) {
    if (val == 0) { _put_char('0'); return; }
    if (val < 0) { _put_char('-'); val = -val; }
    char buffer[20];
    int idx = 0;
    while (val > 0) { buffer[idx++] = '0' + (val % 10); val /= 10; }
    while (idx > 0) { idx--; _put_char(buffer[idx]); }
}

// ==========================================
// 外部安全 API (自带加锁与解锁，确保线程安全)
// ==========================================

void clear_screen(void) {
    mutex_acquire(&print_lock);
    char* video_memory = (char*)P2V(0xb8000UL);
    for (int i = 0; i < 80 * 25; i++) {
        video_memory[i * 2] = ' ';
        video_memory[i * 2 + 1] = 0x0F;
    }
    _set_cursor(0);
    mutex_release(&print_lock);
}

void put_char(char c) {
    mutex_acquire(&print_lock);
    _put_char(c);
    mutex_release(&print_lock);
}

void print_string(const char* str) {
    mutex_acquire(&print_lock);
    _print_string(str);
    mutex_release(&print_lock);
}

void print_hex(unsigned long val) {
    mutex_acquire(&print_lock);
    _print_string("0x");
    _print_hex(val);
    mutex_release(&print_lock);
}

void print_int(long val) {
    mutex_acquire(&print_lock);
    _print_int(val);
    mutex_release(&print_lock);
}


// 颜色设置保留为公开接口，但建议在多任务环境下尽量使用下面的语义化函数
void set_print_color(unsigned char fg, unsigned char bg) {
    current_color = (bg << 4) | (fg & 0x0F);
}

void reset_print_color(void) {
    current_color = 0x0F;
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

void panic_print(const char* str) {
    current_color = 0x4F; // 强制变更为：红底白字
    _print_string(str);   // 直接呼叫底层驱动，无视 print_lock！
}

void panic_print_hex(unsigned long val) {
    current_color = 0x4F;
    _print_string("0x");
    _print_hex(val);
}

void panic_print_int(long val) {
    current_color = 0x4F;
    _print_int(val);
}

// 【新增】初始化打印机锁 (需要在 kernel_main 最早调用)
void print_init(void) {
    mutex_init(&print_lock);
}