// kernel/elf.c
#include "elf.h"
#include "fs.h"
#include "kalloc.h"
#include "memory.h"
#include "print.h"
#include "string.h"
#include "thread.h"

// ==========================================
// ELF 文件加载与内存映射核心逻辑
// ==========================================
int elf_load_image_args(const char* filename, const char* const* argv,
                        uint32_t argc, uint64_t* out_entry,
                        uint64_t* out_cr3, uint64_t* out_stack,
                        struct elf_load_vma* vmas, uint32_t* vma_count) {
    struct fs_request stat_request = {0};
    stat_request.operation = FS_REQUEST_STAT;
    strcpy(stat_request.name, filename);
    if (fs_service_call(&stat_request) != 0 ||
        stat_request.stat_size == 0 ||
        stat_request.stat_size > UINT32_MAX ||
        stat_request.stat_size > FS_MAX_FILE_SIZE) {
        return 0;
    }
    uint32_t file_size = (uint32_t)stat_request.stat_size;
    
    // 1. 通过 FS 服务将文件读入内核堆缓存。
    uint8_t* file_buf = (uint8_t*)kmalloc((uint32_t)file_size + 512);
    if (!file_buf) return 0;
    struct fs_request read_request = {0};
    read_request.operation = FS_REQUEST_READ;
    read_request.length = (uint32_t)file_size;
    read_request.buffer = file_buf;
    strcpy(read_request.name, filename);
    if (fs_service_call(&read_request) != file_size) {
        kfree(file_buf);
        return 0;
    }

    // 2. 校验 ELF 魔数
    Elf64_Ehdr* ehdr = (Elf64_Ehdr*)file_buf;
    if (ehdr->e_ident[0] != 0x7F || ehdr->e_ident[1] != 'E' ||
        ehdr->e_ident[2] != 'L'  || ehdr->e_ident[3] != 'F') {
        kfree(file_buf);
        return 0;
    }

    *out_entry = ehdr->e_entry;
    *out_cr3 = 0;
    *out_stack = 0;
    if (vma_count != 0) *vma_count = 0;
    
    // 3. 创建全新的 Ring 3 页表目录
    paddr_t user_cr3 = create_page_dir();
    if (user_cr3 == 0) {
        kfree(file_buf);
        return 0;
    }
    *out_cr3 = user_cr3;

    // 4. 遍历程序头，映射内存段
    Elf64_Phdr* phdr = (Elf64_Phdr*)(file_buf + ehdr->e_phoff);
    for (int i = 0; i < ehdr->e_phnum; i++) {
        if (phdr[i].p_type == PT_LOAD) { 
            uint64_t vaddr = phdr[i].p_vaddr;
            uint64_t memsz = phdr[i].p_memsz;
            uint64_t filesz = phdr[i].p_filesz;
            uint64_t offset = phdr[i].p_offset;

            uint64_t start_page = vaddr & ~0xFFFULL;
            uint64_t end_page = (vaddr + memsz + 0xFFF) & ~0xFFFULL;
            uint64_t pages = (end_page - start_page) / 4096;

            if (vmas != 0 && vma_count != 0 &&
                *vma_count < ELF_MAX_LOAD_VMAS) {
                vmas[*vma_count].start = start_page;
                vmas[*vma_count].end = end_page;
                vmas[*vma_count].flags = phdr[i].p_flags;
                vmas[*vma_count].file_offset = offset;
                (*vma_count)++;
            }

            // 为该段分配物理页并建立映射
            for (uint64_t p = 0; p < pages; p++) {
                paddr_t phys = alloc_page_owned(PAGE_OWNER_USER);
                if (phys == 0) {
                    goto load_fail;
                }
                memset(P2V(phys), 0, PAGE_SIZE);
                /* 只把 ELF 的 PF_W 段映射为可写；代码和 .rodata 必须
                   允许读取但不能被用户伪造为 futex writable 地址。 */
                uint64_t page_flags = PTE_US;
                if ((phdr[i].p_flags & 0x2U) != 0) page_flags |= PTE_RW;
                if(map_page(user_cr3, start_page + p * PAGE_SIZE,
                            phys, page_flags)!=0){
                    free_page_owned(phys, PAGE_OWNER_USER);
                    goto load_fail;
                }

            }

            // 【严谨修复】：借用 CR3 拷贝数据时，必须强行屏蔽中断！
            // 防止时钟中断在此期间触发进程调度，导致使用不完整的页表引发 Page Fault
            uint64_t old_cr3;
            uint64_t rflags;
            
            __asm__ volatile (
                "pushfq \n"
                "popq %0 \n"
                "cli \n"             // 强行关中断
                : "=r"(rflags) 
                :: "memory"
            );

            __asm__ volatile("mov %%cr3, %0" : "=r"(old_cr3));
            __asm__ volatile("mov %0, %%cr3" :: "r"(user_cr3) : "memory");
            
            // 数据拷贝
            memcpy((void*)vaddr, file_buf + offset, filesz);
            
            __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");

            // 恢复中断状态
            __asm__ volatile (
                "pushq %0 \n"
                "popfq \n"           // 恢复进入此代码段之前的中断标志
                :: "r"(rflags)
                : "memory", "cc"
            );
        }
    }

    // 5. 分配并映射用户栈空间
    uint64_t user_stack_top = 0x00007FFFFFFFF000; 
    paddr_t stack_phys = alloc_page_owned(PAGE_OWNER_USER);
    if (stack_phys == 0) {
        goto load_fail;
    }
    memset(P2V(stack_phys), 0, PAGE_SIZE);
    if(map_page(user_cr3, user_stack_top - PAGE_SIZE, stack_phys, 0x07)!=0){
        free_page_owned(stack_phys, PAGE_OWNER_USER);
        goto load_fail;
    }
    if (argv != 0 && argc > ELF_MAX_ARGS) goto load_fail;
    {
        uint64_t user_argv[ELF_MAX_ARGS];
        uint64_t cursor = user_stack_top;
        uint64_t bottom = user_stack_top - PAGE_SIZE;
        uint64_t old_cr3;
        uint64_t rflags;
        uint32_t i;

        __asm__ volatile("pushfq; popq %0; cli" : "=r"(rflags) :: "memory");
        __asm__ volatile("mov %%cr3, %0" : "=r"(old_cr3));
        __asm__ volatile("mov %0, %%cr3" :: "r"(user_cr3) : "memory");
        for (i = argc; i != 0; i--) {
            size_t length = strlen(argv[i - 1]) + 1;
            if (length > cursor - bottom) {
                __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");
                __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
                goto load_fail;
            }
            cursor -= length;
            memcpy((void*)cursor, argv[i - 1], length);
            user_argv[i - 1] = cursor;
        }
        cursor &= ~7ULL;
        if (cursor < bottom + (uint64_t)(argc + 2) * sizeof(uint64_t)) {
            __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");
            __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
            goto load_fail;
        }
        cursor -= sizeof(uint64_t);
        *(uint64_t*)cursor = 0;
        for (i = argc; i != 0; i--) {
            cursor -= sizeof(uint64_t);
            *(uint64_t*)cursor = user_argv[i - 1];
        }
        cursor -= sizeof(uint64_t);
        *(uint64_t*)cursor = argc;
        __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");
        __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
        *out_stack = cursor;
    }

    kfree(file_buf);
    return 1;

load_fail:
    /* destroy_user_address_space 会回收已成功映射的用户页和页表页。 */
    destroy_user_address_space(user_cr3);
    kfree(file_buf);
    *out_cr3 = 0;
    *out_stack = 0;
    return 0;
}

int elf_load_image(const char* filename, uint64_t* out_entry, uint64_t* out_cr3,
                   uint64_t* out_stack, struct elf_load_vma* vmas,
                   uint32_t* vma_count)
{
    return elf_load_image_args(filename, 0, 0, out_entry, out_cr3, out_stack,
                               vmas, vma_count);
}

// ==========================================
// 跃迁指令控制中心
// ==========================================
int execute_elf_args(const char* filename, const char* const* argv,
                     uint32_t argc) {
    print_debug("[ELF] Attempting to execute: ");
    print_debug(filename);
    print_debug("\n");

    uint64_t ring3_rip, ring3_cr3, ring3_rsp;
    
    struct elf_load_vma vmas[ELF_MAX_LOAD_VMAS];
    uint32_t vma_count = 0;
    if (!elf_load_image_args(filename, argv, argc, &ring3_rip, &ring3_cr3,
                             &ring3_rsp, vmas, &vma_count)) {
        print_error("[ELF] Failed to load.\n");
        return -1;
    }

    if (ring3_rip > 0x00007FFFFFFFFFFF) {
        destroy_user_address_space(ring3_cr3);
        return -1;
    }
    struct process* process = process_create_loaded(ring3_rip, ring3_cr3,
                                                    ring3_rsp, 5,
                                                    vmas, vma_count);
    if (!process) {
        print_error("[ELF] Failed to create process.\n");
        return -1;
    }
    {
        const char* base = filename;
        uint32_t length = 0;
        while (*base != '\0') {
            if (*base == '/') filename = base + 1;
            base++;
        }
        while (filename[length] != '\0' && length + 1 < sizeof(process->name)) {
            process->name[length] = filename[length];
            length++;
        }
        process->name[length] = '\0';
        /* Shell 是当前唯一的终端会话控制者。普通用户程序即使执行
           自己的 fork/wait，也不能把全局终端前台 PID 清零。 */
        process->terminal_controller = 0;
        if (filename[0] == 's' && filename[1] == 'h' &&
            filename[2] == 'e' && filename[3] == 'l' &&
            filename[4] == 'l' && filename[5] == '.' &&
            filename[6] == 'e' && filename[7] == 'l' &&
            filename[8] == 'f' && filename[9] == '\0') {
            process->terminal_controller = 1;
        }
    }
    thread_append(process->main_thread);
    print_debug("[SYSTEM] User process queued.\n");
    return (int)process->pid;
}

int execute_elf(const char* filename)
{
    return execute_elf_args(filename, 0, 0);
}
