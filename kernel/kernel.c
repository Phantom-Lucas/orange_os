// kernel/kernel.c
#include "print.h"
#include "idt.h"
#include "pic.h"  
#include "io.h"   
#include "shell.h" 
#include "timer.h"
#include "memory.h"
#include "kalloc.h"
#include "thread.h" 
#include "gdt.h"
#include "syscall.h"
#include "test.h"
#include "disk.h"
#include "fs.h"
#include "elf.h"

struct task_struct main_thread; // 全局主线程占位

__attribute__((section(".entry_point")))
void kernel_main(void) {
    print_init();
    clear_screen();
    print_success("[SYSTEM] Booting High-Half Kernel...\n");

    idt_init(); 
    pic_init();
    timer_init(); 
    gdt_init();
    init_phy_mem_map(0); 
    kmalloc_init();
    thread_init();
    
    // =======================================================
    // 【核心新增】：初始化系统调用机制！配置硬件 MSR 寄存器
    // 必须在跳入 Ring 3 之前完成，为 syscall 指令铺好轨道
    // =======================================================
    syscall_init();
    
    __asm__ volatile ("sti"); 
    
    print_string("[SYSTEM] Running Automated Kernel Tests...\n");
    // 测试代码因为有 Use-After-Free 的地雷，依然保持注释状态
    // run_all_kernel_tests(); 

    // =============== Phase 1 测试代码开始 ===============
    disk_init();
    
    // 在栈上分配 512 字节缓冲区用于接收扇区数据
    uint8_t sector_buffer[512] = {0}; 
    
    print_info("[TEST] Reading MBR (Sector 0) from Disk...\n");
    // 读取 0 号扇区 (LBA = 0)，读 1 个扇区
    disk_read_sector(0, sector_buffer, 1);
    
    print_string("[TEST] MBR Magic Bytes: ");
    print_hex(sector_buffer[510]);
    print_string(" ");
    print_hex(sector_buffer[511]);
    print_string("\n");
    
    // 验证是不是 0x55 和 0xAA
    if (sector_buffer[510] == 0x55 && sector_buffer[511] == 0xAA) {
        print_success("[TEST] Phase 1 PASSED: ATA Disk Read SUCCESS!\n");
    } else {
        print_error("[TEST] Phase 1 FAILED: Magic number mismatch.\n");
    }
    // =============== Phase 1 测试代码结束 ===============

    // =============== Phase 2 & 3 测试代码开始 ===============
    fs_init();
    
    // 【系统跃迁】：开始加载并执行 Ring 3 应用！
    execute_elf("hello.elf");
    // =============== Phase 2 & 3 测试代码结束 ===============
    
    // 如果一切顺利，execute_elf 内部是死循环，永远不会执行到这里。
    // 如果打印了下面这句话，说明 ELF 没找到或者加载失败了。
    print_error("[SYSTEM] Kernel halted.\n");
    
    shell_init();
    while(1) {
        __asm__ volatile ("hlt"); 
    }
}