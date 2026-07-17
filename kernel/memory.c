// kernel/memory.c

#include "memory.h"

// 全局位图实例，用于管理物理内存
Bitmap phy_mem_map;

// 初始化物理内存位图
void init_phy_mem_map(uint64_t total_memory_bytes)
{
    // 实现初始化逻辑
    uint32_t ards_count = *((uint32_t*)0x8000);
    struct ARDS* ards_array = (struct ARDS*)0x8004;
    
    uint64_t max_phy_addr = 0; // 用来记录内存的最高天花板
    
    // 遍历获取最高地址
    for (uint32_t i = 0; i < ards_count; i++) {
        // 只要是可用内存，我们就看看它是不是伸得最远的
        if (ards_array[i].type == 1) {
            uint64_t current_end = ards_array[i].base_addr + ards_array[i].length;
            if (current_end > max_phy_addr) {
                max_phy_addr = current_end;
            }
        }
    }
    phy_mem_map.bits = (uint8_t*)0x200000; // 位图从 0x200000 开始存放
    uint64_t total_bits = max_phy_addr / 4096; // 计算总共需要多少页
    phy_mem_map.bmap_bytes = (total_bits + 7) / 8; // 向上取整到字节
    memset(phy_mem_map.bits, 0xFF, phy_mem_map.bmap_bytes); // 先全部标记为已占用

    // 遍历 ARDS，标记可用内存页
    for(uint32_t i=0;i<ards_count;i++) 
    {
        struct ARDS* entry = &ards_array[i];
        if(entry->type == 1) 
        {
            uint64_t start_page = entry->base_addr / 4096;
            uint64_t end_page = (entry->base_addr + entry->length) / 4096;
            for(uint64_t page=start_page;page<end_page;page++) 
            {
                set_bit(&phy_mem_map, page, 0); // 标记为可用
            }
        }
    }

    // 保护位图本身占用的内存页
    uint64_t bitmap_end_addr = (uint64_t)phy_mem_map.bits + phy_mem_map.bmap_bytes;
    uint64_t protect_end_page = (bitmap_end_addr + 4095) / 4096;
    for (uint64_t page = 0; page < protect_end_page; page++) {
        set_bit(&phy_mem_map, page, 1);
    }

}

// 设置位图中某一位的值
void set_bit(Bitmap* bitmap, uint64_t index, uint8_t value)
{
    if (index >= bitmap->bmap_bytes * 8) {
        return; // 越界检查
    }
    uint64_t byte_index = index / 8;
    uint8_t bit_index = index % 8;

    if (value) {
        bitmap->bits[byte_index] |= (1 << bit_index);
    } else {
        bitmap->bits[byte_index] &= ~(1 << bit_index);
    }
}

// 获取位图中某一位的值
uint8_t get_bit(Bitmap* bitmap, uint64_t index)
{
    if (index >= bitmap->bmap_bytes * 8) {
        return 0; // 越界检查
    }
    uint64_t byte_index = index / 8;
    uint8_t bit_index = index % 8;

    return (bitmap->bits[byte_index] >> bit_index) & 1;
}

// 分配物理页，返回其物理地址
// kernel/memory.c 新增代码

// 核心算法：在物理内存中寻找连续的 N 个空闲页
void* alloc_pages(uint32_t page_count) {
    if (page_count == 0) return NULL;
    
    uint32_t consecutive_free = 0; // 记录连续找到了几个空闲页
    uint32_t start_page = 0;       // 记录这片连续区域的起始页号
    uint32_t total_pages = phy_mem_map.bmap_bytes * 8; // 位图里的总页数

    // 遍历整个位图，寻找连续的 0
    for (uint32_t i = 0; i < total_pages; i++) {
        if (get_bit(&phy_mem_map, i) == 0) { // 发现一个空闲页
            if (consecutive_free == 0) {
                start_page = i; // 记录连续区域的起点
            }
            consecutive_free++;
            
            // 如果连续空闲的数量已经达到了要求
            if (consecutive_free == page_count) {
                // 找到了！把这连续的 N 页全部标记为占用 (1)
                for (uint32_t j = 0; j < page_count; j++) {
                    set_bit(&phy_mem_map, start_page + j, 1);
                }
                // 返回这片连续物理内存的首地址
                return (void*)((uint64_t)start_page * 4096);
            }
        } else {
            // 中间遇到了被占用的页（暗礁），连续被打断，重新计数
            consecutive_free = 0; 
        }
    }
    
    return NULL; // 如果找遍了全地图都没有这么大的连续空间，返回 NULL (OOM)
}

// 为了兼容你之前的代码，我们保留 alloc_page，让它直接调用 alloc_pages(1)
void* alloc_page(void) {
    return alloc_pages(1);
}

// 释放一个物理页
void free_page(void* ptr) {
    uint64_t page_index = (uint64_t)ptr / 4096;
    memset(ptr, 0, 4096); // 清空页内容
    set_bit(&phy_mem_map, page_index, 0); // 标记为可
} 

