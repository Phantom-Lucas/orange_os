// kernel/memory.h

#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>
#include "string.h"
#include <stddef.h>

#define PAGE_OFFSET 0xFFFF800000000000

// 物理地址转虚拟地址 (Physical to Virtual)
#define P2V(paddr) ((void*)((uint64_t)(paddr) + PAGE_OFFSET))

// 虚拟地址转物理地址 (Virtual to Physical)
#define V2P(vaddr) ((uint64_t)(vaddr) - PAGE_OFFSET)

// kernel/memory.h

// 页表属性标志位
#define PTE_P    0x01    // Present: 存在位 (1表示在物理内存中)
#define PTE_RW   0x02    // Read/Write: 读写位 (1表示可读写)
#define PTE_US   0x04    // User/Supervisor: 用户态位 (1表示Ring 3平民可访问)

// 四级页表的索引提取宏
// 64位虚拟地址的 39~47 位是 PML4 的索引 (共 9 位，最大 511)
#define PML4_INDEX(vaddr) (((vaddr) >> 39) & 0x1FF)
// 30~38 位是 PDPT 的索引
#define PDPT_INDEX(vaddr) (((vaddr) >> 30) & 0x1FF)
// 21~29 位是 PD 的索引
#define PD_INDEX(vaddr)   (((vaddr) >> 21) & 0x1FF)
// 12~20 位是 PT 的索引
#define PT_INDEX(vaddr)   (((vaddr) >> 12) & 0x1FF)

// 地址掩码，用于抹除低 12 位的属性标志，提取纯净的物理基址
#define PTE_ADDR_MASK     (~0xFFFULL)
;
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

//  分配指定数量的连续物理页，返回其物理地址
void* alloc_pages(uint32_t page_count);

// 分配一个物理页，返回其物理地址
void* alloc_page();

// 释放一个物理页
void free_page(void* ptr);

// 创建一个新的页目录 (PML4)，并复制内核的高半区映射
void* create_page_dir(void);

// 函数声明
void map_page(uint64_t pml4_paddr, uint64_t vaddr, uint64_t paddr, uint64_t flags);

// 统计当前系统中还有多少个空闲物理页
uint32_t get_free_page_count(void);
#endif
