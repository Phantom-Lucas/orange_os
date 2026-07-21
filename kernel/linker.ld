/* kernel/linker.ld */
ENTRY(kernel_main)

/* 定义高半区虚拟基址常量 */
KERNEL_VMA = 0xFFFF800000000000;
/* 内核实际存放在内存中的物理地址 */
KERNEL_LMA = 0x1900;

SECTIONS
{
    /* 设置当前虚拟地址计数器 */
    . = KERNEL_VMA + KERNEL_LMA;

    /* AT() 关键字告诉加载器这部分代码实际的物理存放地址 */
    .text : AT(ADDR(.text) - KERNEL_VMA)
    {
        /* 【绝对核心修复】：强制提取入口函数，钉在二进制的第 1 个字节！ */
        *(.entry_point)
        
        /* 其他普通代码紧随其后 */
        *(.text*)
    }

    .rodata : AT(ADDR(.rodata) - KERNEL_VMA)
    {
        *(.rodata*)
    }

    .data : AT(ADDR(.data) - KERNEL_VMA)
    {
        *(.data*)
    }

    .bss : AT(ADDR(.bss) - KERNEL_VMA)
    {
        *(COMMON)
        *(.bss*)
    }
}