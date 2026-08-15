// kernel/gdt.h
#ifndef GDT_H
#define GDT_H

#include <stdint.h>

// 64 位下的 TSS 结构 (必须是 104 字节，严格对齐)
struct tss_entry_struct {
    uint32_t reserved1;
    uint64_t rsp0;
    uint64_t rsp1;
    uint64_t rsp2;
    uint64_t reserved2;
    uint64_t ist1;
    uint64_t ist2;
    uint64_t ist3;
    uint64_t ist4;
    uint64_t ist5;
    uint64_t ist6;
    uint64_t ist7;
    uint64_t reserved3;
    uint16_t reserved4;
    uint16_t iopb_offset;
} __attribute__((packed));

typedef struct tss_entry_struct tss_entry_t;


// 设置一个普通的 8 字节 GDT 表项
void set_gdt_entry(int index, uint64_t flags) ;

// 设置 16 字节的 TSS 表项
void write_tss(int index);

// 暴露初始化的函数
void gdt_init(void);

// 暴露更新 TSS 的函数（未来每次切换进程都要更新它）
void set_tss_rsp0(uint64_t rsp0);

#endif