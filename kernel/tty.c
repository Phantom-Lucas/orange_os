#include "tty.h"

#include "io.h"
#include "memory.h"
#include "string.h"
#include "sync.h"
#include "ipc.h"
#include "thread.h"
#include "process.h"

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_CELLS (VGA_WIDTH * VGA_HEIGHT)
#define TTY_HISTORY_LINES 256
#define TTY_HISTORY_CELLS (VGA_WIDTH * TTY_HISTORY_LINES)
#define TTY_HISTORY_BYTES ((uint64_t)TTY_CONSOLE_COUNT * TTY_HISTORY_CELLS * sizeof(uint16_t))
#define TTY_HISTORY_PAGES ((TTY_HISTORY_BYTES + PAGE_SIZE - 1) / PAGE_SIZE)
#define VGA_DEFAULT_COLOR 0x0F
#define TTY_INPUT_QUEUE_SIZE 4096
#define TTY_MESSAGE_READ_REQUEST 0x54545901U
#define TTY_MESSAGE_READ_REPLY   0x54545902U
#define TTY_MESSAGE_WRITE_REQUEST 0x54545903U
#define TTY_MESSAGE_WRITE_REPLY   0x54545904U
#define TTY_SERVICE_BUFFER_SIZE   4096U

/*
 * TTY IPC 不传递调用者栈指针或堆指针。旧实现把 request.value 指向
 * syscall 栈上的结构，服务线程再异步解引用；在连续 read/write、线程
 * 切换和进程退出交错时，这会形成悬空请求并最终破坏内核堆。
 *
 * 现在每个服务使用一个内核拥有的固定缓冲区，并用请求锁串行化交接：
 * 调用者先复制到/从固定缓冲区，IPC 消息只传长度，服务线程永远不会
 * 访问已经返回的调用者栈或已经释放的 kmalloc block。
 */
static char tty_input_reply_buffer[TTY_SERVICE_BUFFER_SIZE];
static char tty_output_request_buffer[TTY_SERVICE_BUFFER_SIZE];
static mutex_t tty_input_request_lock;
static mutex_t tty_output_request_lock;

struct tty_console {
    uint16_t* cells;
    uint32_t cursor;
    uint32_t line_count;
    uint32_t view_top;
};

static struct tty_console consoles[TTY_CONSOLE_COUNT];
static uint32_t active_console;
static int initialized;
static spinlock_t tty_lock;
static char input_queue[TTY_INPUT_QUEUE_SIZE];
static uint32_t input_head;
static uint32_t input_tail;
static struct thread* tty_input_service_task;
static struct thread* tty_output_service_task;
static uint32_t foreground_pid;

static uint16_t hw_cursor_get(void) {
    uint16_t pos;
    outb(0x3D4, 0x0E);
    pos = (uint16_t)inb(0x3D5) << 8;
    outb(0x3D4, 0x0F);
    pos |= inb(0x3D5);
    return pos;
}

static void hw_cursor_set(uint16_t pos) {
    outb(0x3D4, 0x0E);
    outb(0x3D5, (uint8_t)(pos >> 8));
    outb(0x3D4, 0x0F);
    outb(0x3D5, (uint8_t)pos);
}

static void console_clear(struct tty_console* console) {
    for (uint32_t i = 0; i < TTY_HISTORY_CELLS; i++) {
        console->cells[i] = ((uint16_t)VGA_DEFAULT_COLOR << 8) | ' ';
    }
    console->cursor = 0;
    console->line_count = 1;
    console->view_top = 0;
}

static void console_scroll_history(struct tty_console* console, uint8_t color) {
    /* 源区域位于目标之后，内核 memcpy 的正向复制可安全完成下移。 */
    memcpy(console->cells, console->cells + VGA_WIDTH,
           (TTY_HISTORY_CELLS - VGA_WIDTH) * sizeof(uint16_t));
    for (uint32_t i = TTY_HISTORY_CELLS - VGA_WIDTH;
         i < TTY_HISTORY_CELLS; i++) {
        console->cells[i] = ((uint16_t)color << 8) | ' ';
    }
    console->cursor -= VGA_WIDTH;
    if (console->line_count > 1) console->line_count--;
}

static void console_make_cursor_room(struct tty_console* console, uint8_t color) {
    while (console->cursor >= TTY_HISTORY_CELLS) {
        console_scroll_history(console, color);
    }
}

static void console_update_line_count(struct tty_console* console) {
    uint32_t rows = console->cursor / VGA_WIDTH + 1;
    if (rows > TTY_HISTORY_LINES) rows = TTY_HISTORY_LINES;
    if (rows > console->line_count) console->line_count = rows;
}

static void flush_active_console(void);

static void console_follow_bottom(struct tty_console* console) {
    console->view_top = console->line_count > VGA_HEIGHT
                            ? console->line_count - VGA_HEIGHT : 0;
}

static void console_resume_live_view(struct tty_console* console) {
    uint32_t bottom = console->line_count > VGA_HEIGHT
                          ? console->line_count - VGA_HEIGHT : 0;
    if (console->view_top != bottom) {
        console->view_top = bottom;
        /* PageUp/PageDown 只改变显示窗口；第一次输入时恢复到活动行，
           防止字符被写入屏幕外而看起来像 Shell 卡住。 */
        flush_active_console();
    }
}

static void console_put_char(struct tty_console* console, char c, uint8_t color) {
    console_make_cursor_room(console, color);
    if (c == '\r') {
        console->cursor = (console->cursor / VGA_WIDTH) * VGA_WIDTH;
    } else if (c == '\n') {
        console->cursor = (console->cursor / VGA_WIDTH + 1) * VGA_WIDTH;
    } else if (c == '\b') {
        if (console->cursor > 0) {
            console->cursor--;
            console->cells[console->cursor] = ((uint16_t)color << 8) | ' ';
        }
    } else {
        console->cells[console->cursor] = ((uint16_t)color << 8) | (uint8_t)c;
        console->cursor++;
    }
    console_make_cursor_room(console, color);
    console_update_line_count(console);
}

static void flush_active_console(void) {
    volatile uint16_t* vga = (volatile uint16_t*)P2V(0xB8000UL);
    struct tty_console* console = &consoles[active_console];
    uint32_t max_top = console->line_count > VGA_HEIGHT
                           ? console->line_count - VGA_HEIGHT : 0;
    if (console->view_top > max_top) console->view_top = max_top;
    for (uint32_t row = 0; row < VGA_HEIGHT; row++) {
        uint32_t source_row = console->view_top + row;
        for (uint32_t col = 0; col < VGA_WIDTH; col++) {
            uint32_t screen = row * VGA_WIDTH + col;
            vga[screen] = source_row < console->line_count
                              ? console->cells[source_row * VGA_WIDTH + col]
                              : ((uint16_t)VGA_DEFAULT_COLOR << 8) | ' ';
        }
    }
    uint32_t cursor_row = console->cursor / VGA_WIDTH;
    uint32_t cursor_col = console->cursor % VGA_WIDTH;
    uint16_t screen_cursor = VGA_CELLS - 1;
    if (cursor_row >= console->view_top &&
        cursor_row < console->view_top + VGA_HEIGHT) {
        screen_cursor = (uint16_t)((cursor_row - console->view_top) * VGA_WIDTH +
                                   cursor_col);
    }
    hw_cursor_set(screen_cursor);
}

void tty_init(void) {
    spinlock_init(&tty_lock);
    mutex_init(&tty_input_request_lock);
    mutex_init(&tty_output_request_lock);

    paddr_t pages = alloc_pages_owned(TTY_HISTORY_PAGES, PAGE_OWNER_TTY);
    if (pages == 0) return;

    uint16_t* backing = (uint16_t*)P2V(pages);
    volatile uint16_t* vga = (volatile uint16_t*)P2V(0xB8000UL);
    for (uint32_t i = 0; i < TTY_CONSOLE_COUNT; i++) {
        consoles[i].cells = backing + i * TTY_HISTORY_CELLS;
        console_clear(&consoles[i]);
    }

    for (uint32_t i = 0; i < VGA_CELLS; i++) {
        consoles[0].cells[i] = vga[i];
    }
    consoles[0].cursor = hw_cursor_get();
    consoles[0].line_count = VGA_HEIGHT;
    consoles[0].view_top = 0;
    active_console = 0;
    input_head = 0;
    input_tail = 0;
    foreground_pid = 0;
    initialized = 1;
}

int tty_is_initialized(void) {
    return initialized;
}

void tty_write_colored(const char* buffer, unsigned long length, uint8_t color) {
    if (!initialized || buffer == 0) return;

    spinlock_acquire(&tty_lock);
    struct tty_console* console = &consoles[active_console];
    console_follow_bottom(console);
    for (unsigned long i = 0; i < length; i++) {
        console_put_char(console, buffer[i], color);
    }
    console_follow_bottom(console);
    flush_active_console();
    spinlock_release(&tty_lock);
}

void tty_write(const char* buffer, unsigned long length) {
    tty_write_colored(buffer, length, VGA_DEFAULT_COLOR);
}

void tty_put_char_colored(char c, uint8_t color) {
    tty_write_colored(&c, 1, color);
}

void tty_input_char(char c) {
    if (!initialized) return;
    spinlock_acquire(&tty_lock);
    console_resume_live_view(&consoles[active_console]);
    uint32_t next = (input_head + 1) % TTY_INPUT_QUEUE_SIZE;
    if (next != input_tail) {
        input_queue[input_head] = c;
        input_head = next;
        /* 键盘 IRQ 是输入事件源；若服务线程正阻塞，立即唤醒它。 */
        if (tty_input_service_task != 0 &&
            tty_input_service_task->status == TASK_BLOCKED) {
            thread_unblock(tty_input_service_task);
        }
    } else if (c == '\n' || c == '\r' || c == 0x03 || c == 0x04 ||
               c == 0x0C || c == 0x15 || c == 0x17 || c == 0x1A ||
               c == 0x1C) {
        /* 队列满时丢弃最旧普通字符，但不丢命令结束或中断事件。 */
        input_tail = (input_tail + 1) % TTY_INPUT_QUEUE_SIZE;
        input_queue[input_head] = c;
        input_head = (input_head + 1) % TTY_INPUT_QUEUE_SIZE;
        if (tty_input_service_task != 0 &&
            tty_input_service_task->status == TASK_BLOCKED) {
            thread_unblock(tty_input_service_task);
        }
    }
    spinlock_release(&tty_lock);
}

void tty_handle_input_char(char c) {
    uint32_t pid;
    int status;

    /* Ctrl+C/Ctrl+\\/Ctrl+Z 由终端交给前台进程。当前内核没有 stopped
       进程状态，所以 Ctrl+Z 采用“终止前台任务”的明确降级语义。 */
    if (c == 0x03 || c == 0x1C || c == 0x1A) {
        pid = tty_get_foreground_pid();
        status = c == 0x03 ? 130 : (c == 0x1C ? 131 : 148);
        if (pid != 0 && process_request_terminal_signal(pid, status) == 0) {
            return;
        }
    }
    /* 没有前台任务时，控制键交给 Shell 做行编辑；普通字符直接入队。 */
    tty_input_char(c);
}

void tty_set_foreground_pid(uint32_t pid) {
    if (!initialized) return;
    spinlock_acquire(&tty_lock);
    foreground_pid = pid;
    spinlock_release(&tty_lock);
}

uint32_t tty_get_foreground_pid(void) {
    uint32_t pid;
    if (!initialized) return 0;
    spinlock_acquire(&tty_lock);
    pid = foreground_pid;
    spinlock_release(&tty_lock);
    return pid;
}

static int tty_take_input_char(char* output) {
    int available = 0;
    spinlock_acquire(&tty_lock);
    if (input_tail != input_head) {
        *output = input_queue[input_tail];
        input_tail = (input_tail + 1) % TTY_INPUT_QUEUE_SIZE;
        available = 1;
    }
    spinlock_release(&tty_lock);
    return available;
}

static void tty_input_service_main(void) {
    while (1) {
        struct message request;
        if (ipc_receive(IPC_ANY, &request) != 0 ||
            request.type != TTY_MESSAGE_READ_REQUEST) {
            continue;
        }

        unsigned long length = request.value;
        unsigned long count = 0;
        if (length == 0 || length > TTY_SERVICE_BUFFER_SIZE) length = 1;

        for (;;) {
            char ch;
            /* 关闭本地中断覆盖“检查队列→进入 BLOCKED”，避免丢失键盘事件。 */
            __asm__ volatile("cli" ::: "memory");
            if (tty_take_input_char(&ch)) {
                __asm__ volatile("sti" ::: "memory");
                tty_input_reply_buffer[count++] = ch;
                break;
            }
            thread_block();
            __asm__ volatile("sti" ::: "memory");
        }

        /* 第一个字符已经满足阻塞读；其余字符只取当前队列中的部分。 */
        while (count < length) {
            if (!tty_take_input_char(&tty_input_reply_buffer[count])) break;
            count++;
        }

        struct thread* client = thread_find_by_pid(request.source_pid);
        struct message reply = {0, TTY_MESSAGE_READ_REPLY, count};
        if (client != 0 && client->status != TASK_ZOMBIE &&
            client->status != TASK_DEAD) {
            (void)ipc_send(client, &reply);
        }
    }
}

static void tty_output_service_main(void) {
    while (1) {
        struct message message;
        if (ipc_receive(IPC_ANY, &message) != 0 ||
            message.type != TTY_MESSAGE_WRITE_REQUEST || message.value == 0) {
            continue;
        }

        unsigned long length = message.value;
        int valid = length != 0 && length <= TTY_SERVICE_BUFFER_SIZE;
        if (valid) tty_write(tty_output_request_buffer, length);

        struct thread* client = thread_find_by_pid(message.source_pid);
        struct message reply = {0, TTY_MESSAGE_WRITE_REPLY,
                                valid ? 0 : UINT64_MAX};
        if (client != 0 && client->status != TASK_ZOMBIE &&
            client->status != TASK_DEAD) {
            (void)ipc_send(client, &reply);
        }
    }
}

void tty_service_init(void) {
    if (!initialized) return;
    if (tty_input_service_task == 0) {
        tty_input_service_task = thread_create(tty_input_service_main, 5);
        if (tty_input_service_task != 0) thread_append(tty_input_service_task);
    }
    if (tty_output_service_task == 0) {
        tty_output_service_task = thread_create(tty_output_service_main, 5);
        if (tty_output_service_task != 0) thread_append(tty_output_service_task);
    }
}

int tty_service_read(char* buffer, unsigned long length) {
    if (!initialized || !buffer || length == 0 || !tty_input_service_task ||
        (tty_input_service_task->status == TASK_ZOMBIE ||
         tty_input_service_task->status == TASK_DEAD)) return -1;

    if (length > TTY_SERVICE_BUFFER_SIZE) return -1;
    mutex_acquire(&tty_input_request_lock);
    struct message request = {0, TTY_MESSAGE_READ_REQUEST, length};
    struct message reply;
    if (ipc_send(tty_input_service_task, &request) != 0 ||
        ipc_receive((int32_t)tty_input_service_task->process->pid, &reply) != 0 ||
        reply.type != TTY_MESSAGE_READ_REPLY || reply.value > length) {
        mutex_release(&tty_input_request_lock);
        return -1;
    }
    memcpy(buffer, tty_input_reply_buffer, (unsigned long)reply.value);
    mutex_release(&tty_input_request_lock);
    return (int)reply.value;
}

int tty_service_write(const char* buffer, unsigned long length) {
    if (!initialized || !buffer || length == 0) return -1;

    if (length > TTY_SERVICE_BUFFER_SIZE) return -1;
    /* syscall 层已经把用户缓冲复制到内核；直接进入受 tty_lock
       保护的输出路径，避免交互回显为每个批次再付出一次 IPC 往返。 */
    tty_write(buffer, length);
    return 0;
}

int tty_read(char* buffer, unsigned long length) {
    if (!initialized || buffer == 0 || length == 0) return 0;

    unsigned long done = 0;
    while (done < length) {
        if (tty_take_input_char(&buffer[done])) {
            done++;
            continue;
        }

        /* syscall 入口屏蔽了 IF；空队列时安全地打开中断并等待下一事件。 */
        if (done != 0) break;
        __asm__ volatile("sti; hlt; cli" ::: "memory");
    }
    return (int)done;
}

void tty_clear_active(void) {
    if (!initialized) return;

    spinlock_acquire(&tty_lock);
    console_clear(&consoles[active_console]);
    flush_active_console();
    spinlock_release(&tty_lock);
}

void tty_scroll_active(int32_t lines) {
    if (!initialized || lines == 0) return;

    spinlock_acquire(&tty_lock);
    struct tty_console* console = &consoles[active_console];
    int64_t top = (int64_t)console->view_top + lines;
    uint32_t max_top = console->line_count > VGA_HEIGHT
                           ? console->line_count - VGA_HEIGHT : 0;
    if (top < 0) top = 0;
    if ((uint64_t)top > max_top) top = max_top;
    console->view_top = (uint32_t)top;
    flush_active_console();
    spinlock_release(&tty_lock);
}

void tty_switch(uint32_t index) {
    if (!initialized || index >= TTY_CONSOLE_COUNT) return;

    spinlock_acquire(&tty_lock);
    active_console = index;
    flush_active_console();
    spinlock_release(&tty_lock);
}

uint32_t tty_active_index(void) {
    return active_console;
}
