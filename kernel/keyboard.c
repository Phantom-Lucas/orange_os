#include "keyboard.h"

#include "sync.h"

#define KEYBOARD_QUEUE_SIZE 4096

static struct keyboard_event queue[KEYBOARD_QUEUE_SIZE];
static uint32_t queue_head;
static uint32_t queue_tail;
static int shift_down;
static int caps_lock;
static int ctrl_down;
static int extended_scancode;
static spinlock_t keyboard_lock;

static const char keymap_normal[128] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
  '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0,  'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
    0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',   0,
  '*',  0,  ' ',  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0, '-',   0,   0,   0, '+',   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0
};

static const char keymap_shift[128] = {
    0,  27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
  '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
    0,  'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',
    0,  '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?',   0,
  '*',  0,  ' ',  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0,   0,   0,   0,   0,   0, '-',   0,   0,   0, '+',   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0
};

static void enqueue_event(struct keyboard_event event) {
    uint32_t next = (queue_head + 1) % KEYBOARD_QUEUE_SIZE;
    if (next == queue_tail) {
        /* 压力输入时优先保留回车和控制键，避免 Shell 永远等不到命令结束。 */
        if (event.type != KEYBOARD_EVENT_CHAR ||
            (event.ch != '\n' && event.ch != '\r' &&
             event.ch != 0x03 && event.ch != 0x04 &&
             event.ch != 0x0C && event.ch != 0x15 &&
             event.ch != 0x17 && event.ch != 0x1A && event.ch != 0x1C)) {
            return;
        }
        queue_tail = (queue_tail + 1) % KEYBOARD_QUEUE_SIZE;
        next = (queue_head + 1) % KEYBOARD_QUEUE_SIZE;
    }
    queue[queue_head] = event;
    queue_head = next;
}

void keyboard_init(void) {
    spinlock_init(&keyboard_lock);
    queue_head = 0;
    queue_tail = 0;
    shift_down = 0;
    caps_lock = 0;
    ctrl_down = 0;
    extended_scancode = 0;
}

void keyboard_handle_scancode(uint8_t scancode) {
    spinlock_acquire(&keyboard_lock);

    if (scancode == 0xE0) {
        extended_scancode = 1;
    } else if (extended_scancode) {
        extended_scancode = 0;
        if (!(scancode & 0x80)) {
            struct keyboard_event event = {0};
            if (scancode == 0x49) {
                event.type = KEYBOARD_EVENT_SCROLL_UP;
                enqueue_event(event);
            } else if (scancode == 0x51) {
                event.type = KEYBOARD_EVENT_SCROLL_DOWN;
                enqueue_event(event);
            }
        }
    } else if (scancode == 0x1D) {
        ctrl_down = 1;
    } else if (scancode == 0x9D) {
        ctrl_down = 0;
    } else if (scancode == 0x2A || scancode == 0x36) {
        shift_down = 1;
    } else if (scancode == 0xAA || scancode == 0xB6) {
        shift_down = 0;
    } else if (scancode == 0x3A) {
        caps_lock = !caps_lock;
    } else if (!(scancode & 0x80)) {
        struct keyboard_event event = {0};
        if (scancode >= 0x3B && scancode <= 0x3D) {
            event.type = KEYBOARD_EVENT_SWITCH_CONSOLE;
            event.console_index = scancode - 0x3B;
            enqueue_event(event);
        } else {
            char normal = keymap_normal[scancode];
            char shifted = keymap_shift[scancode];
            if (normal != 0) {
                event.type = KEYBOARD_EVENT_CHAR;
                if (normal >= 'a' && normal <= 'z') {
                    if (ctrl_down) {
                        event.ch = (char)(normal - 'a' + 1);
                    } else {
                        event.ch = (shift_down ^ caps_lock) ? shifted : normal;
                    }
                } else if (ctrl_down && normal == '\\') {
                    event.ch = 0x1C; /* Ctrl+\\ / SIGQUIT */
                } else {
                    event.ch = shift_down ? shifted : normal;
                }
                enqueue_event(event);
            }
        }
    }

    spinlock_release(&keyboard_lock);
}

int keyboard_pop_event(struct keyboard_event* event) {
    int has_event = 0;
    spinlock_acquire(&keyboard_lock);
    if (queue_tail != queue_head) {
        *event = queue[queue_tail];
        queue_tail = (queue_tail + 1) % KEYBOARD_QUEUE_SIZE;
        has_event = 1;
    }
    spinlock_release(&keyboard_lock);
    return has_event;
}
