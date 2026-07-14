ENTRY(kernel_main)
OUTPUT_FORMAT("elf64-x86-64")

SECTIONS
{
    /* 强制内核起始物理地址为 0x1900 */
    . = 0x1900;

    .text : {
        /* 1. 强制将入口函数的专属段排在 0x1900 最前端 */
        *(.text.kernel_main)
        
        /* 2. 随后才是其他所有普通的 text 段 */
        *(.text)
        *(.text.*)
    }

    .rodata : {
        *(.rodata)
        *(.rodata.*)
    }

    .data : {
        *(.data)
        *(.data.*)
    }

    .bss : {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }

    /* === 核心修复：丢弃所有妨碍裸机运行的无用 note、comment 和 eh_frame 段 === */
    /DISCARD/ : {
        *(.note.gnu.property)
        *(.note.GNU-stack)
        *(.note.*)
        *(.eh_frame)
        *(.eh_frame_hdr)
        *(.comment)
    }
}