#include "vga.h"

#include "io.h"

#define VGA_DAC_INDEX 0x3C8
#define VGA_DAC_DATA  0x3C9
#define VGA_CRTC_INDEX 0x3D4
#define VGA_CRTC_DATA  0x3D5
#define VGA_CURSOR_START 0x0A
#define VGA_CURSOR_END   0x0B

struct vga_rgb {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
};

/* RGB values are public 8-bit values; the DAC receives six-bit components. */
static const struct vga_rgb terminal_palette[16] = {
    { 48,  8, 36 }, /* 0: #300824, deep purple background */
    { 42,  8, 16 }, /* 1: dark red */
    { 18, 48, 18 }, /* 2: dark green */
    { 48, 48, 10 }, /* 3: dark yellow */
    { 42,  8, 16 }, /* 4: panic red background */
    { 40, 16, 40 }, /* 5: dark magenta */
    { 10, 42, 42 }, /* 6: dark cyan */
    { 200, 200, 200 }, /* 7: #C8C8C8 */
    { 112, 112, 112 }, /* 8: #707070 */
    {  95, 135, 255 }, /* 9: #5F87FF */
    {  95, 215,  95 }, /* 10: #5FD75F */
    {  95, 215, 215 }, /* 11: #5FD7D7 */
    { 255,  95,  95 }, /* 12: #FF5F5F */
    { 215,  95, 215 }, /* 13: #D75FD7 */
    { 255, 215,  95 }, /* 14: #FFD75F */
    { 242, 242, 242 }  /* 15: #F2F2F2 */
};

void vga_palette_set(uint8_t index,
                     uint8_t red,
                     uint8_t green,
                     uint8_t blue) {
    if (index > 15) return;
    outb(VGA_DAC_INDEX, index);
    outb(VGA_DAC_DATA, (uint8_t)(red >> 2));
    outb(VGA_DAC_DATA, (uint8_t)(green >> 2));
    outb(VGA_DAC_DATA, (uint8_t)(blue >> 2));
}

void vga_apply_terminal_theme(void) {
#if VGA_TERMINAL_THEME
    for (uint8_t index = 0; index < 16; index++) {
        vga_palette_set(index,
                        terminal_palette[index].red,
                        terminal_palette[index].green,
                        terminal_palette[index].blue);
    }
#endif
}

static void vga_set_cursor_shape(uint8_t start, uint8_t end) {
    outb(VGA_CRTC_INDEX, VGA_CURSOR_START);
    outb(VGA_CRTC_DATA, start);
    outb(VGA_CRTC_INDEX, VGA_CURSOR_END);
    outb(VGA_CRTC_DATA, end);
}

void vga_set_block_cursor(void) {
    vga_set_cursor_shape(0, 15);
}

void vga_set_underline_cursor(void) {
    vga_set_cursor_shape(13, 15);
}
