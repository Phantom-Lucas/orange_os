// kernel/kalloc.h

#ifndef KALLOC_H
#define KALLOC_H

#include <stddef.h>
#include <stdbool.h>

struct MemBlock {
    struct MemBlock* next; // 指向下一个内存块的指针
    bool is_free;
    size_t size;           // 内存块的大小
};

// 初始化内核内存分配器
void kmalloc_init(void);

// 分配指定大小的内存块
void* kmalloc(size_t size);

// 释放指定的内存块
void kfree(void* ptr);

#endif
