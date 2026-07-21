// kernel/memory.c

#include "memory.h"

// 全局位图实例，用于管理物理内存
Bitmap phy_mem_map;

// 初始化物理内存位图
void init_phy_mem_map(uint64_t total_memory_bytes)
{
    // 实现初始化逻辑
    uint32_t ards_count = *((uint32_t*)P2V(0x500));
    struct ARDS* ards_array = (struct ARDS*)P2V(0x504);

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
    phy_mem_map.bits = (uint8_t*)P2V(0x200000); // 位图从 0x200000 开始存放
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
    uint64_t bitmap_end_addr = 0x200000 + phy_mem_map.bmap_bytes;
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

void* create_page_dir(void) {
    // 1. 申请一页物理内存作为新进程的 PML4
    void* pml4_paddr = alloc_page();
    if (!pml4_paddr) return NULL;
    
    // 2. 转换为高半区虚拟地址以便 C 语言操作
    uint64_t* new_pml4_vaddr = (uint64_t*)P2V(pml4_paddr);
    
    // 3. 彻底清零！这等同于【清空了新进程的低半区映射】
    memset(new_pml4_vaddr, 0, 4096);
    
    // 4. 复制内核的高半区映射
    // 我们在 loader.S 中把内核初始 PML4 建立在了物理地址 0x70000 处
    uint64_t* kernel_pml4_vaddr = (uint64_t*)P2V(0x70000);
    
    // PML4 有 512 个项，0~255 是低半区，256~511 是高半区
    // 我们只把 256 到 511 项（内核空间）复制过来，保证内核在新页表下不死机
    for (int i = 256; i < 512; i++) {
        new_pml4_vaddr[i] = kernel_pml4_vaddr[i];
    }
    
    // 5. CR3 寄存器只认物理地址，所以返回物理地址
    return pml4_paddr;
}


// 终极页表映射函数：将物理地址 paddr 挂载到指定的 cr3(pml4_paddr) 的虚拟地址 vaddr 处
void map_page(uint64_t pml4_paddr, uint64_t vaddr, uint64_t paddr, uint64_t flags) {
    
    // 1. 获取 PML4 表的高半区虚拟指针，以便 C 语言操作
    uint64_t* pml4 = (uint64_t*)P2V(pml4_paddr);
    uint32_t pml4_idx = PML4_INDEX(vaddr);

    // 2. 检查 PML4[idx] 指向的 PDPT 是否存在
    if (!(pml4[pml4_idx] & PTE_P)) {
        // 不存在，则申请一页纯物理内存作为 PDPT
        void* new_pdpt_paddr = alloc_page();
        // 用虚拟地址清零这块内存
        memset(P2V(new_pdpt_paddr), 0, 4096);
        // 将纯物理地址加上属性，挂进 PML4 (注意：给用户态开放的页表节点必须带 PTE_US)
        pml4[pml4_idx] = (uint64_t)new_pdpt_paddr | PTE_P | PTE_RW | PTE_US;
    }

    // 3. 提取 PDPT 的地址，并检查 PD 是否存在
    uint64_t pdpt_paddr = pml4[pml4_idx] & PTE_ADDR_MASK;
    uint64_t* pdpt = (uint64_t*)P2V(pdpt_paddr);
    uint32_t pdpt_idx = PDPT_INDEX(vaddr);

    if (!(pdpt[pdpt_idx] & PTE_P)) {
        void* new_pd_paddr = alloc_page();
        memset(P2V(new_pd_paddr), 0, 4096);
        pdpt[pdpt_idx] = (uint64_t)new_pd_paddr | PTE_P | PTE_RW | PTE_US;
    }

    // 4. 提取 PD 的地址，并检查 PT 是否存在
    uint64_t pd_paddr = pdpt[pdpt_idx] & PTE_ADDR_MASK;
    uint64_t* pd = (uint64_t*)P2V(pd_paddr);
    uint32_t pd_idx = PD_INDEX(vaddr);

    if (!(pd[pd_idx] & PTE_P)) {
        void* new_pt_paddr = alloc_page();
        memset(P2V(new_pt_paddr), 0, 4096);
        pd[pd_idx] = (uint64_t)new_pt_paddr | PTE_P | PTE_RW | PTE_US;
    }

    // 5. 提取 PT 的地址，进行最后一击：将真正的目标物理地址挂入 PT 中！
    uint64_t pt_paddr = pd[pd_idx] & PTE_ADDR_MASK;
    uint64_t* pt = (uint64_t*)P2V(pt_paddr);
    uint32_t pt_idx = PT_INDEX(vaddr);

    // 将用户传入的物理地址 paddr 加上最终的 flags 属性写入
    pt[pt_idx] = (paddr & PTE_ADDR_MASK) | flags;
}

// 统计当前系统中还有多少个空闲物理页
uint32_t get_free_page_count(void) {
    uint32_t count = 0;
    uint32_t total_pages = phy_mem_map.bmap_bytes * 8;
    for (uint32_t i = 0; i < total_pages; i++) {
        if (get_bit(&phy_mem_map, i) == 0) {
            count++;
        }
    }
    return count;
}