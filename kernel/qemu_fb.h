#ifndef QEMU_FB_H
#define QEMU_FB_H

#include <stdint.h>
#include "tty.h"

/* QEMU stdvga / Bochs DISPI only.  The backend stays kernel-private. */
int qemu_fb_initialize(void);
int qemu_fb_is_active(void);
const struct tty_geometry* qemu_fb_geometry(void);
void qemu_fb_render_cells(const uint16_t* cells, uint32_t line_count,
                          uint32_t view_top, uint32_t cursor,
                          int cursor_visible);
void qemu_fb_clear(uint32_t rgb);
uint64_t qemu_fb_bar0(void);
uint64_t qemu_fb_size(void);

#endif
