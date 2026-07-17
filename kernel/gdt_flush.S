.global gdt_flush
.global tss_flush

/* void gdt_flush(uint64_t ptr); */
/* 此时 rdi = gdt_ptr 的地址 */
gdt_flush:
    lgdt (%rdi)          /* 加载新 GDT */
    
    /* 刷新数据段寄存器为内核数据段 (0x10) */
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss

    /* 刷新 CS (代码段) 寄存器为内核代码段 (0x08)。*/
    /* x86 强制要求必须通过远跳转 (Far Return/Jump) 来刷新 CS */
    pushq $0x08
    lea .flush_cs(%rip), %rax
    pushq %rax
    lretq                /* 从栈上弹出 RIP 和 CS，实现远跳转 */

.flush_cs:
    ret

/* void tss_flush(void); */
tss_flush:
    /* 在 GDT 中，TSS 段的偏移量是 0x28 (第五个 8 字节条目) */
    mov $0x28, %ax
    ltr %ax              /* Load Task Register */
    ret