// kernel/elf.c
#include "elf.h"
#include "fs.h"
#include "disk.h"
#include "kalloc.h"
#include "memory.h"
#include "print.h"
#include "string.h"
#include "gdt.h"

// ==========================================
// 全局数据与外部依赖声明
// ==========================================

// 必须与 syscall.c 中的定义保持 100% 内存布局一致
struct cpu_local_data {
    uint64_t kernel_rsp;
    uint64_t user_rsp;
};

// 引用在 syscall.c 中初始化的当前 CPU 数据结构
extern struct cpu_local_data current_cpu;

// 引用在 gdt.c 中定义的 TSS 栈刷新函数
extern void set_tss_rsp0(uint64_t rsp0);

// 给即将运行的 Ring 3 进程准备的 4KB 专属内核栈
static uint8_t ring3_kernel_stack[4096]; 

// ==========================================
// ELF 文件加载与内存映射核心逻辑
// ==========================================
static int load_elf_process(const char* filename, uint64_t* out_entry, uint64_t* out_cr3, uint64_t* out_stack) {
    struct inode target_file;
    if (!fs_find_file(filename, &target_file)) {
        return 0;
    }
    
    // 1. 将文件读入内核堆缓存中
    uint8_t* file_buf = (uint8_t*)kmalloc(target_file.size + 512); 
    uint32_t total_sectors = (target_file.size + 511) / 512;
    uint32_t first_lba = FS_START_LBA + target_file.direct_blocks[0] * 8;
    disk_read_sector(first_lba, file_buf, total_sectors);

    // 2. 校验 ELF 魔数
    Elf64_Ehdr* ehdr = (Elf64_Ehdr*)file_buf;
    if (ehdr->e_ident[0] != 0x7F || ehdr->e_ident[1] != 'E' ||
        ehdr->e_ident[2] != 'L'  || ehdr->e_ident[3] != 'F') {
        kfree(file_buf);
        return 0;
    }

    *out_entry = ehdr->e_entry;
    
    // 3. 创建全新的 Ring 3 页表目录
    uint64_t user_cr3 = (uint64_t)create_page_dir();
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

            // 为该段分配物理页并建立映射
            for (uint64_t p = 0; p < pages; p++) {
                void* phys = alloc_page();
                memset((void*)P2V(phys), 0, 4096);
                map_page(user_cr3, start_page + p * 4096, (uint64_t)phys, 0x07);
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
    void* stack_phys = alloc_page();
    memset((void*)P2V(stack_phys), 0, 4096);
    map_page(user_cr3, user_stack_top - 4096, (uint64_t)stack_phys, 0x07);
    *out_stack = user_stack_top;

    kfree(file_buf);
    return 1;
}

// ==========================================
// 跃迁指令控制中心
// ==========================================
void execute_elf(const char* filename) {
    print_info("[ELF] Attempting to execute: ");
    print_string(filename);
    print_string("\n");

    uint64_t ring3_rip, ring3_cr3, ring3_rsp;
    
    if (load_elf_process(filename, &ring3_rip, &ring3_cr3, &ring3_rsp)) {
        
        // 修正非规范地址错误
        if (ring3_rip > 0x00007FFFFFFFFFFF) {
            ring3_rip = 0x400000; 
        } 
        
        print_success("[SYSTEM] Executing Unbreakable Ring 3 Jump...\n");
        
        // 计算当前进程的专属内核栈顶安全地址
        uint64_t safe_kernel_stack_top = (uint64_t)ring3_kernel_stack + 4096;
        
        // ========================================================
        // 核心装甲配置：为 Ring 3 构建双重降落伞
        // ========================================================
        
        // 降落伞 1：TSS 栈（应对时钟、异常等硬件中断强制回站）
        set_tss_rsp0(safe_kernel_stack_top);
        
        // 降落伞 2：Per-CPU GS 栈（应对 SwapGS 与 Syscall 软件系统调用）
        current_cpu.kernel_rsp = safe_kernel_stack_top;
        
        // ========================================================
        
        // 锁死中断门，准备强行切换时空
        __asm__ volatile ("cli");
        
        // iretq 信仰之跃：切页表 -> 载入伪造的栈帧 -> 跃迁
        __asm__ volatile (
            "mov %0, %%cr3 \n"
            
            "mov $0x1B, %%ax \n"
            "mov %%ax, %%ds \n"
            "mov %%ax, %%es \n"
            "mov %%ax, %%fs \n"
            "mov %%ax, %%gs \n"
            
            "pushq $0x1B \n"     // 5. SS (User Data 0x1B)
            "pushq %1 \n"        // 4. RSP
            "pushq $0x202 \n"    // 3. RFLAGS (IF=1 开启中断，准备接受调度)
            "pushq $0x23 \n"     // 2. CS (User Code 0x23)
            "pushq %2 \n"        // 1. RIP
            
            "iretq \n"
            : 
            : "r"(ring3_cr3), "r"(ring3_rsp), "r"(ring3_rip)
            : "memory", "rax"
        );
        
        // 永远不会执行到这里，除非跃迁失败
        while(1); 
        
    } else {
        print_error("[ELF] Failed to load.\n");
    }
}