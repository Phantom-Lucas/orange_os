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

#define ELF_MAX_LOAD_VMAS 32
#define ELF_MAX_ARGS 16
struct elf_load_vma {
    uint64_t start;
    uint64_t end;
    uint64_t flags;
    uint64_t file_offset;
};


// 加载 ELF 到新的用户地址空间，供 spawn/exec 共用。
int elf_load_image(const char* filename, uint64_t* out_entry, uint64_t* out_cr3,
                   uint64_t* out_stack, struct elf_load_vma* vmas,
                   uint32_t* vma_count);
int elf_load_image_args(const char* filename, const char* const* argv,
                        uint32_t argc, uint64_t* out_entry,
                        uint64_t* out_cr3, uint64_t* out_stack,
                        struct elf_load_vma* vmas, uint32_t* vma_count);

// 创建一个新的用户进程并加入调度队列。
int execute_elf(const char* filename);
int execute_elf_args(const char* filename, const char* const* argv,
                     uint32_t argc);

#define PT_LOAD 1

#endif
