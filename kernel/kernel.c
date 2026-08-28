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
#include "tty.h"
#include "keyboard.h"
#include "ipc.h"
#include "futex.h"
#include "qemu_fb.h"

extern uint8_t __bss_start[];
extern uint8_t __bss_end[];

static void clear_kernel_bss(void) {
    volatile uint8_t* cursor = __bss_start;
    while (cursor < __bss_end) {
        *cursor++ = 0;
    }
}

__attribute__((section(".entry_point")))
void kernel_main(void) {
    /* A raw-binary loader does not materialize ELF NOBITS sections.  QEMU
       normally supplies zeroed RAM, but the kernel ABI must not depend on it. */
    clear_kernel_bss();
    print_init();
    clear_screen();
#if BOOT_DIAGNOSTIC
    print_success("[BOOT] Orange'S x86_64 kernel\n");
#else
    print_success("[BOOT] kernel ready\n");
#endif

    idt_init(); 
    pic_init();
    timer_init(); 
    gdt_init();
    if (init_phy_mem_map() != 0) {
        print_error("[MEM] Physical memory initialization failed.\n");
        while (1) __asm__ volatile ("hlt");
    }
    kmalloc_init();
    tty_init();
    keyboard_init();
    thread_init();
    futex_init();
    ipc_init();
    tty_service_init();
    
    // =======================================================
    // 【核心新增】：初始化系统调用机制！配置硬件 MSR 寄存器
    // 必须在跳入 Ring 3 之前完成，为 syscall 指令铺好轨道
    // =======================================================
    syscall_init();
    
    __asm__ volatile ("sti"); 
    
    /* 诊断启动才显示完整内核/IPC 自测；正常启动只保留启动摘要。 */
#if BOOT_DIAGNOSTIC
    run_all_kernel_tests();
    ipc_run_self_test();
#endif

    disk_init();
    uint8_t sector_buffer[512] = {0};
    if (disk_read_sector_checked(0, sector_buffer, 1) != 0) {
        print_error("[FAIL] Disk: unable to read MBR after retries.\n");
        print_error("[HALT] Storage is unavailable; startup stopped.\n");
        while (1) __asm__ volatile ("hlt");
    }
    if (sector_buffer[510] != 0x55 || sector_buffer[511] != 0xAA) {
        print_error("[FAIL] Disk: invalid MBR signature.\n");
        print_error("[HALT] Startup stopped before mounting the file system.\n");
        while (1) __asm__ volatile ("hlt");
    }
#if BOOT_DIAGNOSTIC
    print_success("[BOOT] Disk: ATA ready\n");
#endif

    if (fs_init() != 0) {
        print_error("[FAIL] File system: MyFS mount failed.\n");
        print_error("[HALT] Startup stopped because storage is unavailable.\n");
        while (1) __asm__ volatile ("hlt");
    }
#if BOOT_DIAGNOSTIC
    print_success("[BOOT] File system: MyFS mounted\n");
#else
    print_success("[BOOT] storage ready\n");
#endif

#if BOOT_DIAGNOSTIC
    fs_run_self_test();
#endif
    fs_service_init();

    /* The font is a MyFS asset, so framebuffer activation intentionally happens
       only after a successful mount.  A failed probe leaves the established VGA
       TTY untouched and therefore diagnosable. */
    if (qemu_fb_initialize() == 0) {
        if (tty_use_framebuffer_geometry(qemu_fb_geometry()) == 0) {
            print_success("[FB] QEMU framebuffer active\n");
        }
    }

#if BOOT_DIAGNOSTIC
    int init_pid = execute_elf("hello.elf");
    int init_ok = 0;
    if (init_pid >= 0) {
        int init_status = -1;
        int waited = process_wait((uint32_t)init_pid, &init_status, 0);
        if (waited == init_pid && init_status == 42) {
            print_success("[PROC] init exit/wait lifecycle PASSED.\n");
            init_ok = 1;
        } else {
            print_error("[PROC] init exit/wait lifecycle FAILED.\n");
        }
    }
    /* 用户态文件系统验收：避免只验证内核直调路径。程序结束后目录和
       文件都自行清理，因此重启测试不会污染基线。 */
    int fs_pid = execute_elf("fs-demo.elf");
    if (fs_pid >= 0) {
        int fs_status = -1;
        if (process_wait((uint32_t)fs_pid, &fs_status, 0) == fs_pid && fs_status == 0)
            print_success("[FS] User syscall filesystem self-test PASSED.\n");
        else
            print_error("[FS] User syscall filesystem self-test FAILED.\n");
    } else {
        print_error("[FS] User syscall filesystem self-test could not start.\n");
    }
    if (fs_persistence_verified())
        print_success("[FS] Reboot persistence state verified.\n");
#else
    int init_ok = 1;
#endif

    // init 综合自检失败时不启动交互入口，以免把失败伪装成可用系统。
    if (!init_ok) {
        print_error("[SYSTEM] init self-test failed; kernel halted.\n");
        while (1) __asm__ volatile ("hlt");
    }

    /*
     * 用户 Shell 一旦进入就会通过 TTY 输出欢迎页。启动它之后再由内核
     * 打印会与用户输出竞争 TTY 光标，造成启动标记和标题粘连。把“准备
     * 启动”标记放在 execute_elf() 前，并在成功后把终端完全交给 Shell。
     */
    print_success("[BOOT] launching shell\n");

    // 正常交互入口改为 Ring 3 shell；内核 shell 仅保留为加载失败时的调试后备。
    if (execute_elf("shell.elf") >= 0) {
        thread_yield();
        while (1) __asm__ volatile ("hlt");
    }

    print_error("[SYSTEM] User shell failed; falling back to kernel shell.\n");
    shell_init();
    while(1) {
        __asm__ volatile ("hlt"); 
    }
}
