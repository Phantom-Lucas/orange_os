#ifndef VGA_H
#define VGA_H

#include <stdint.h>

void vga_palette_set(uint8_t index,
                     uint8_t red,
                     uint8_t green,
                     uint8_t blue);
void vga_apply_terminal_theme(void);
void vga_set_block_cursor(void);
void vga_set_underline_cursor(void);

#endif
