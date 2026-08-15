#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <stdint.h>

enum keyboard_event_type {
    KEYBOARD_EVENT_CHAR,
    KEYBOARD_EVENT_SWITCH_CONSOLE,
    KEYBOARD_EVENT_SCROLL_UP,
    KEYBOARD_EVENT_SCROLL_DOWN,
};

struct keyboard_event {
    uint8_t type;
    char ch;
    uint8_t console_index;
};

void keyboard_init(void);
void keyboard_handle_scancode(uint8_t scancode);
int keyboard_pop_event(struct keyboard_event* event);

#endif
