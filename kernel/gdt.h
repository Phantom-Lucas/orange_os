// kernel/gdt.h
#ifndef GDT_H
#define GDT_H

#include <stdint.h>

// 64 位下的 TSS 结构 (必须是 104 字节，严格对齐)
struct tss_entry_struct {
    uint32_t reserved1;
    uint64_t rsp0;      // 【极其关键！】Ring 3 发生中断时，CPU 会自动把栈顶切到这里！
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
    uint16_t iopb_offset; // IO 权限位图偏移
} __attribute__((packed));

typedef struct tss_entry_struct tss_entry_t;

// 暴露初始化的函数
void gdt_init(void);
// 暴露更新 TSS 的函数（未来每次切换进程都要更新它）
void set_tss_rsp0(uint64_t rsp0);

#endif