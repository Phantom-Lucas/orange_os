#ifndef KALLOC_H
#define KALLOC_H

#include <stddef.h>
#include <stdint.h>

/* 返回内核高半区虚拟地址；调用者必须使用 kfree() 释放。 */
void kmalloc_init(void);
void* kmalloc(size_t size);

/* 0 表示成功；非法指针、重复释放或堆损坏返回负值。 */
int kfree(void* ptr);

struct kalloc_stats {
    uint64_t arenas;
    uint64_t arena_pages;
    uint64_t active_blocks;
    uint64_t allocated_bytes;
    uint64_t free_bytes;
};

void kalloc_get_stats(struct kalloc_stats* stats);
void kalloc_dump_stats(const char* tag);

#endif
