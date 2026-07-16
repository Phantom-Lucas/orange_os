// kernel/memory.h

#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>
#include "string.h"
#include <stddef.h>

// 强制编译器按 1 字节对齐，绝不允许私自加空白填充！
struct ARDS {
    uint64_t base_addr;  // 这块内存的起始物理地址 (8字节)
    uint64_t length;     // 这块内存的大小 (8字节)
    uint32_t type;       // 这块内存的类型 (4字节)
} __attribute__((packed));

// 提示性质的代码架构：
typedef struct {
    uint8_t* bits;      // 指向位图实际存放的内存起始地址 (一维字节数组)
    uint64_t bmap_bytes;// 位图占用的总字节数
} Bitmap;


// 物理内存位图结构体
extern Bitmap phy_mem_map;

// 初始化物理内存位图
void init_phy_mem_map(uint64_t total_memory_bytes);

// 设置位图中某一位的值
void set_bit(Bitmap* bitmap, uint64_t index, uint8_t value);

// 获取位图中某一位的值
uint8_t get_bit(Bitmap* bitmap, uint64_t index);

// 分配一个物理页，返回其物理地址
void* alloc_page();

// 释放一个物理页
void free_page(void* ptr);

#endif
