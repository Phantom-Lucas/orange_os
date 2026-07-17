// kernel/gdt.c
#include "gdt.h"

// GDT 有 7 个条目：
// 0: Null
// 1: 内核代码段 (Ring 0)  - 偏移 0x08
// 2: 内核数据段 (Ring 0)  - 偏移 0x10
// 3: 用户数据段 (Ring 3)  - 偏移 0x18
// 4: 用户代码段 (Ring 3)  - 偏移 0x20
// 5 & 6: TSS 段 (占用两个位置) - 偏移 0x28
uint64_t gdt_entries[7];

// GDTR 指针结构 (给 lgdt 指令用)
struct {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed)) gdt_ptr;

tss_entry_t tss;

// 外部汇编函数，用于刷新 GDT 和加载 TSS
extern void gdt_flush(uint64_t ptr);
extern void tss_flush(void);

// 设置一个普通的 8 字节 GDT 表项
void set_gdt_entry(int index, uint64_t flags) {
    gdt_entries[index] = flags;
}

// 设置 16 字节的 TSS 表项
void write_tss(int index) {
    // 1. 初始化 TSS 结构内存
    uint32_t base = (uint32_t)(uint64_t)&tss;
    uint32_t limit = sizeof(tss) - 1;

    // 清零 TSS
    uint8_t* tss_ptr = (uint8_t*)&tss;
    for(int i=0; i<sizeof(tss); i++) tss_ptr[i] = 0;
    
    tss.iopb_offset = sizeof(tss); // 禁用 IO 权限位图

    // 2. 填充 GDT 中的 TSS 描述符 (x86_64 坑点：这玩意分两截)
    // 低 8 字节 (包含 Base 的低 32 位，Limit，和标志位 0x89)
    gdt_entries[index] = (limit & 0xFFFF) | 
                         (((uint64_t)(base & 0xFFFFFF)) << 16) | 
                         (0x89ULL << 40) | 
                         (((uint64_t)((limit >> 16) & 0xF)) << 48) | 
                         (((uint64_t)((base >> 24) & 0xFF)) << 56);
                         
    // 高 8 字节 (包含 Base 的高 32 位)
    gdt_entries[index + 1] = ((uint64_t)&tss) >> 32;
}

void gdt_init() {
    gdt_ptr.limit = sizeof(gdt_entries) - 1;
    gdt_ptr.base = (uint64_t)&gdt_entries;

    // 0x00: Null 描述符
    set_gdt_entry(0, 0x0000000000000000); 

    // 0x08: 内核代码段 (Ring 0, 64-bit, Exec/Read) -> Flag: 0x00AF98000000FFFF
    set_gdt_entry(1, 0x00AF98000000FFFF); 

    // 0x10: 内核数据段 (Ring 0, Read/Write)      -> Flag: 0x00AF92000000FFFF
    set_gdt_entry(2, 0x00AF92000000FFFF); 

    // 0x18: 用户数据段 (Ring 3, Read/Write, DPL=3) -> Flag: 0x00AFF2000000FFFF
    set_gdt_entry(3, 0x00AFF2000000FFFF); 

    // 0x20: 用户代码段 (Ring 3, 64-bit, Exec/Read, DPL=3) -> Flag: 0x00AFF8000000FFFF
    set_gdt_entry(4, 0x00AFF8000000FFFF); 

    // 0x28 & 0x30: TSS 段
    write_tss(5);

    // 刷新硬件，启用新 GDT 和 TSS！
    gdt_flush((uint64_t)&gdt_ptr);
    tss_flush();
}

// 当线程切换时，我们要告诉 TSS："如果你在 Ring 3 遇到中断，请回到这个新的内核栈！"
void set_tss_rsp0(uint64_t rsp0) {
    tss.rsp0 = rsp0;
}