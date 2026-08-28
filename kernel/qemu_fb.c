#include "qemu_fb.h"

#include "fs.h"
#include "io.h"
#include "memory.h"
#include "string.h"

#ifndef CONSOLE_BACKEND_QEMU_FB
#define CONSOLE_BACKEND_QEMU_FB 0
#endif
#ifndef FB_WIDTH
#define FB_WIDTH 1280U
#endif
#ifndef FB_HEIGHT
#define FB_HEIGHT 720U
#endif

/* Diagnostic kernels retain the small VGA backend so all verbose bootstrap
 * self-tests remain inside the immutable loader window. */
#if CONSOLE_BACKEND_QEMU_FB && !BOOT_DIAGNOSTIC

#define PCI_CONFIG_ADDRESS 0xCF8
#define PCI_CONFIG_DATA    0xCFC
#define BOCHS_INDEX        0x01CE
#define BOCHS_DATA         0x01CF
#define BOCHS_XRES         1
#define BOCHS_YRES         2
#define BOCHS_BPP          3
#define BOCHS_ENABLE       4
#define BOCHS_VIRT_WIDTH   6
#define BOCHS_ENABLE_ON    0x01
#define BOCHS_ENABLE_LFB   0x40
#define QEMU_FB_VADDR      0xFFFF900000000000ULL
#define PSF2_MAGIC          0x864AB572U
#define PSF2_HEADER_BYTES   32U
#define FB_MARGIN_X         24U
#define FB_MARGIN_Y         24U
#define QEMU_FB_MAX_VISIBLE_CELLS (200U * 60U)

struct psf2_header {
    uint32_t magic, version, headersize, flags, glyphs, bytes_per_glyph;
    uint32_t height, width;
};

static uint8_t* font_data;
static uint32_t font_headersize;
static uint32_t font_bytes_per_glyph;
static uint32_t font_height;
static uint32_t font_width;
static volatile uint32_t* framebuffer;
static uint64_t framebuffer_bar;
static uint64_t framebuffer_size;
static int framebuffer_active;
static struct tty_geometry geometry;
/* Retaining the previous visual grid lets normal shell edits touch only the
 * changed glyph and the old/new cursor cells instead of rewriting the whole
 * uncached MMIO framebuffer. */
static uint16_t rendered_cells[QEMU_FB_MAX_VISIBLE_CELLS];
static uint32_t rendered_count;
static int32_t rendered_cursor = -1;
static int rendered_valid;

static uint32_t pci_read(uint8_t device, uint8_t offset) {
    outl(PCI_CONFIG_ADDRESS, 0x80000000U | ((uint32_t)device << 11) |
         ((uint32_t)offset & 0xFCU));
    return inl(PCI_CONFIG_DATA);
}

static void pci_write(uint8_t device, uint8_t offset, uint32_t value) {
    outl(PCI_CONFIG_ADDRESS, 0x80000000U | ((uint32_t)device << 11) |
         ((uint32_t)offset & 0xFCU));
    outl(PCI_CONFIG_DATA, value);
}

static void bochs_write(uint16_t index, uint16_t value) {
    outw(BOCHS_INDEX, index); outw(BOCHS_DATA, value);
}

static uint16_t bochs_read(uint16_t index) {
    outw(BOCHS_INDEX, index); return inw(BOCHS_DATA);
}

static uint32_t rgb[16] = {
    0x300824, 0x2A0810, 0x123012, 0x30300A,
    0x2A0810, 0x281028, 0x0A2A2A, 0xC8C8C8,
    0x707070, 0x5F87FF, 0x5FD75F, 0x5FD7D7,
    0xFF5F5F, 0xD75FD7, 0xFFD75F, 0xF2F2F2
};

static int load_font(void) {
    struct inode inode;
    struct psf2_header header;
    uint64_t required;
    paddr_t pages;
    uint32_t page_count;

    if (!fs_find_file("terminal.psf", &inode) || inode.size < sizeof(header) ||
        fs_read_file("terminal.psf", 0, &header, sizeof(header)) != (int)sizeof(header))
        return -1;
    if (header.magic != PSF2_MAGIC || header.headersize < PSF2_HEADER_BYTES ||
        header.glyphs < 256 || header.width != 12 || header.height != 24 ||
        header.bytes_per_glyph != 48)
        return -1;
    required = (uint64_t)header.headersize +
               (uint64_t)header.glyphs * header.bytes_per_glyph;
    if (required > inode.size || required > 65536U) return -1;
    page_count = (uint32_t)((required + PAGE_SIZE - 1) / PAGE_SIZE);
    pages = alloc_pages_owned(page_count, PAGE_OWNER_TTY);
    if (pages == 0) return -1;
    font_data = (uint8_t*)P2V(pages);
    if (fs_read_file("terminal.psf", 0, font_data, (uint32_t)required) != (int)required)
        return -1;
    font_headersize = header.headersize;
    font_bytes_per_glyph = header.bytes_per_glyph;
    font_height = header.height;
    font_width = header.width;
    return 0;
}

static int locate_bar(uint64_t bytes) {
    for (uint8_t device = 0; device < 32; device++) {
        uint32_t id = pci_read(device, 0);
        uint32_t class = pci_read(device, 8);
        uint32_t bar, mask;
        if ((id & 0xFFFFU) != 0x1234U || (id >> 16) != 0x1111U ||
            ((class >> 24) & 0xFFU) != 0x03U) continue;
        bar = pci_read(device, 0x10);
        if ((bar & 1U) || (bar & 6U) == 4U) return -1;
        pci_write(device, 0x10, 0xFFFFFFFFU);
        mask = pci_read(device, 0x10);
        pci_write(device, 0x10, bar);
        framebuffer_bar = (uint64_t)(bar & ~0xFU);
        framebuffer_size = (uint64_t)(~(mask & ~0xFU)) + 1U;
        if (framebuffer_bar == 0 || framebuffer_bar == 0xFFFFFFF0U ||
            framebuffer_size < bytes || framebuffer_bar + bytes < framebuffer_bar)
            return -1;
        uint32_t command = pci_read(device, 4);
        if (!(command & 2U)) pci_write(device, 4, command | 2U);
        return 0;
    }
    return -1;
}

static int map_framebuffer(uint64_t bytes) {
    uint64_t page_bytes = (bytes + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
    for (uint64_t offset = 0; offset < page_bytes; offset += PAGE_SIZE) {
        if (map_page(BOOT_KERNEL_PML4_PADDR, QEMU_FB_VADDR + offset,
                     framebuffer_bar + offset, PTE_P | PTE_RW | PTE_PWT | PTE_PCD) != 0)
            return -1;
    }
    framebuffer = (volatile uint32_t*)QEMU_FB_VADDR;
    return 0;
}

int qemu_fb_initialize(void) {
    uint64_t bytes = (uint64_t)FB_WIDTH * FB_HEIGHT * 4U;
    if (framebuffer_active || FB_WIDTH < 640 || FB_HEIGHT < 400 ||
        bytes / 4U != (uint64_t)FB_WIDTH * FB_HEIGHT || load_font() != 0 ||
        locate_bar(bytes) != 0) return -1;
    bochs_write(BOCHS_ENABLE, 0);
    bochs_write(BOCHS_XRES, FB_WIDTH);
    bochs_write(BOCHS_YRES, FB_HEIGHT);
    bochs_write(BOCHS_BPP, 32);
    bochs_write(BOCHS_VIRT_WIDTH, FB_WIDTH);
    bochs_write(BOCHS_ENABLE, BOCHS_ENABLE_ON | BOCHS_ENABLE_LFB);
    if (bochs_read(BOCHS_XRES) != FB_WIDTH || bochs_read(BOCHS_YRES) != FB_HEIGHT ||
        bochs_read(BOCHS_BPP) != 32 || map_framebuffer(bytes) != 0) return -1;
    geometry.columns = (FB_WIDTH - 2 * FB_MARGIN_X) / font_width;
    geometry.visible_rows = (FB_HEIGHT - 2 * FB_MARGIN_Y) / font_height;
    geometry.history_rows = 256;
    geometry.glyph_width = font_width;
    geometry.glyph_height = font_height;
    geometry.origin_x = (FB_WIDTH - geometry.columns * font_width) / 2;
    geometry.origin_y = (FB_HEIGHT - geometry.visible_rows * font_height) / 2;
    if (geometry.columns < 40 || geometry.columns > 200 || geometry.visible_rows < 15 ||
        geometry.visible_rows > 60) return -1;
    framebuffer_active = 1;
    qemu_fb_clear(rgb[0]);
    return 0;
}

int qemu_fb_is_active(void) { return framebuffer_active; }
const struct tty_geometry* qemu_fb_geometry(void) { return framebuffer_active ? &geometry : 0; }
uint64_t qemu_fb_bar0(void) { return framebuffer_bar; }
uint64_t qemu_fb_size(void) { return framebuffer_size; }

void qemu_fb_clear(uint32_t color) {
    if (!framebuffer_active) return;
    for (uint64_t i = 0; i < (uint64_t)FB_WIDTH * FB_HEIGHT; i++) framebuffer[i] = color;
    rendered_valid = 0;
    rendered_cursor = -1;
}

static void render_cell(uint32_t cell_x, uint32_t cell_y, uint16_t cell, int cursor) {
    uint8_t ch = (uint8_t)cell;
    uint8_t attr = (uint8_t)(cell >> 8);
    const uint8_t* glyph = font_data + font_headersize + (uint32_t)ch * font_bytes_per_glyph;
    uint32_t fg = rgb[attr & 15U], bg = rgb[attr >> 4];
    for (uint32_t y = 0; y < font_height; y++) {
        volatile uint32_t* row = framebuffer +
                                 (geometry.origin_y + cell_y * font_height + y) * FB_WIDTH +
                                 geometry.origin_x + cell_x * font_width;
        for (uint32_t x = 0; x < font_width; x++) {
            uint8_t bit = glyph[y * 2 + x / 8] & (0x80U >> (x & 7));
            row[x] = cursor ? (bit ? bg : fg) : (bit ? fg : bg);
        }
    }
}

void qemu_fb_render_cells(const uint16_t* cells, uint32_t line_count,
                          uint32_t view_top, uint32_t cursor, int cursor_visible) {
    if (!framebuffer_active || !cells) return;
    uint32_t visible_cells = geometry.columns * geometry.visible_rows;
    uint32_t cursor_screen = visible_cells;
    if (visible_cells == 0 || visible_cells > QEMU_FB_MAX_VISIBLE_CELLS) return;
    if (cursor_visible) {
        uint32_t cursor_row = cursor / geometry.columns;
        if (cursor_row >= view_top && cursor_row < view_top + geometry.visible_rows)
            cursor_screen = (cursor_row - view_top) * geometry.columns +
                            cursor % geometry.columns;
    }
    for (uint32_t row = 0; row < geometry.visible_rows; row++) {
        uint32_t source = view_top + row;
        for (uint32_t col = 0; col < geometry.columns; col++) {
            uint32_t screen = row * geometry.columns + col;
            uint16_t cell = source < line_count
                                ? cells[source * geometry.columns + col] : 0x0F20U;
            if (!rendered_valid || rendered_count != visible_cells ||
                rendered_cells[screen] != cell || (int32_t)screen == rendered_cursor ||
                screen == cursor_screen) {
                render_cell(col, row, cell, screen == cursor_screen);
            }
            rendered_cells[screen] = cell;
        }
    }
    rendered_count = visible_cells;
    rendered_cursor = cursor_screen < visible_cells ? (int32_t)cursor_screen : -1;
    rendered_valid = 1;
}

#else
int qemu_fb_initialize(void) { return -1; }
int qemu_fb_is_active(void) { return 0; }
const struct tty_geometry* qemu_fb_geometry(void) { return 0; }
void qemu_fb_render_cells(const uint16_t* c, uint32_t a, uint32_t b, uint32_t d, int e)
{ (void)c; (void)a; (void)b; (void)d; (void)e; }
void qemu_fb_clear(uint32_t c) { (void)c; }
uint64_t qemu_fb_bar0(void) { return 0; }
uint64_t qemu_fb_size(void) { return 0; }
#endif
