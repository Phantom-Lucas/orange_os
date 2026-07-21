// kernel/elf.h
#ifndef ELF_H
#define ELF_H
#include <stdint.h>

typedef uint64_t Elf64_Addr;
typedef uint16_t Elf64_Half;
typedef uint64_t Elf64_Off;
typedef uint32_t Elf64_Word;
typedef uint64_t Elf64_Xword;

// ELF 文件头 (位于文件开头的 64 字节)
typedef struct {
    unsigned char e_ident[16]; // 魔数和标识
    Elf64_Half    e_type;      // 文件类型
    Elf64_Half    e_machine;   // 架构 (应为 0x3E，即 x86-64)
    Elf64_Word    e_version;
    Elf64_Addr    e_entry;     // 程序入口点虚拟地址 !!! 核心 !!!
    Elf64_Off     e_phoff;     // 程序头表偏移量
    Elf64_Off     e_shoff;     // 节头表偏移量
    Elf64_Word    e_flags;
    Elf64_Half    e_ehsize;
    Elf64_Half    e_phentsize; // 程序头表单个条目大小
    Elf64_Half    e_phnum;     // 程序头表条目数量
    Elf64_Half    e_shentsize;
    Elf64_Half    e_shnum;
    Elf64_Half    e_shstrndx;
} Elf64_Ehdr;

// 程序头 (Program Header) - 描述了应该如何把文件加载到内存
typedef struct {
    Elf64_Word  p_type;        // 段类型 (1 表示 PT_LOAD，即可加载段)
    Elf64_Word  p_flags;       // 读/写/执行权限
    Elf64_Off   p_offset;      // 该段在文件中的偏移量
    Elf64_Addr  p_vaddr;       // 期望被映射到的虚拟地址
    Elf64_Addr  p_paddr;       // 物理地址 (通常忽略)
    Elf64_Xword p_filesz;      // 在文件中占据的大小
    Elf64_Xword p_memsz;       // 在内存中占据的大小 (可能大于 filesz，比如 .bss 段)
    Elf64_Xword p_align;       // 对齐要求
} Elf64_Phdr;


// 解析、加载并直接执行一个 ELF 文件
void execute_elf(const char* filename);

#define PT_LOAD 1

#endif