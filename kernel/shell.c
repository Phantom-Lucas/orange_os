// kernel/shell.c

#include "shell.h"
#include "string.h"
#include "print.h"
#include "idt.h" 
#include <stdint.h>
#include "memory.h" 
#include "kalloc.h"
#include "timer.h"
#include "thread.h"

#define CMD_BUF_SIZE 256

static char cmd_buffer[CMD_BUF_SIZE]; 
static int cmd_index = 0;             

// 写一段死循环的极简汇编机器码，代表我们的“第三方APP”
// 机器码 eb fe 对应汇编： jmp $ (无尽的死循环)
static uint8_t app_machine_code[] = { 0xeb, 0xfe }; 
// 初始化 shell，打印提示符
void shell_init(void)
{
    print_string("MyOS > ");
}

// 供多线程测试使用的虚拟线程函数
static void dummy_thread_task(void) {
    print_info("\n[Thread Task] Hello from dynamically created kernel thread!\n");
    print_info("[Thread Task] Yielding CPU to prove scheduler works...\n");
    thread_yield();
    print_info("[Thread Task] Thread resumed and finishing execution.\n");
    // 注意：当前没有线程回收机制，这里用死循环挂起，防止乱跑
    while(1) { thread_yield(); }
}

// 执行命令的核心逻辑
void execute_command(char* cmd) {
    if (cmd_index == 0) return;
    cmd[cmd_index] = '\0'; // 封口

    // ==========================================
    // 1. 基础系统与交互模块
    // ==========================================
    if (strcmp(cmd, "help") == 0) 
    {
        print_info("================ AVAILABLE COMMANDS ================\n");
        print_string("  [Basic]   help, clear, hello, echo <msg>\n");
        print_string("  [System]  uptime, cpuinfo\n");
        print_string("  [Memory]  meminfo, testpage, testmalloc\n");
        print_string("  [Thread]  yield, testthread\n");
        print_string("  [Panic]   panic (Div 0), testpf (Page Fault)\n");
        print_string("  [Library] testlib, testprint\n");
        print_info("====================================================\n");
    } 
    else if (strcmp(cmd, "clear") == 0) { clear_screen(); } 
    else if (strcmp(cmd, "hello") == 0) { print_success("Hello! You are inside a 64-bit High-Half Kernel!\n"); }
    else if (strncmp(cmd, "echo ", 5) == 0) { print_string(cmd + 5); print_string("\n"); }
    
    // ==========================================
    // 2. 硬件状态与系统信息模块
    // ==========================================
    else if (strcmp(cmd, "uptime") == 0) 
    {
        unsigned long seconds = system_ticks / 100; 
        print_string("System Uptime: "); print_int(seconds); print_string(" seconds.\n");
    }
    else if (strcmp(cmd, "cpuinfo") == 0)
    {
        unsigned int eax, ebx, ecx, edx;
        __asm__ volatile ("cpuid" : "=a"(eax), "=b"(ebx), "=c"(ecx), "=d"(edx) : "a"(0));
        char vendor[13];
        vendor[0] = (ebx >> 0) & 0xFF; vendor[1] = (ebx >> 8) & 0xFF;
        vendor[2] = (ebx >> 16) & 0xFF; vendor[3] = (ebx >> 24) & 0xFF;
        vendor[4] = (edx >> 0) & 0xFF; vendor[5] = (edx >> 8) & 0xFF;
        vendor[6] = (edx >> 16) & 0xFF; vendor[7] = (edx >> 24) & 0xFF;
        vendor[8] = (ecx >> 0) & 0xFF; vendor[9] = (ecx >> 8) & 0xFF;
        vendor[10] = (ecx >> 16) & 0xFF; vendor[11] = (ecx >> 24) & 0xFF;
        vendor[12] = '\0';
        print_string("CPU Vendor: "); print_info(vendor); print_string("\n");
    }

    // ==========================================
    // 3. 内存管理测试模块 (Memory Management)
    // ==========================================
    else if (strcmp(cmd, "meminfo") == 0) 
    {
        // 【修正地址】：必须使用搬家后的 0x500 和 0x504 !
        uint32_t ards_count = *((uint32_t*)P2V(0x500));
        struct ARDS* ards_array = (struct ARDS*)P2V(0x504);
        uint64_t total_usable_bytes = 0;
        
        print_info("System Physical Memory Map:\n");
        for(int i = 0; i < ards_count; i++) {
            struct ARDS* entry = &ards_array[i];
            print_string("  Base: "); print_hex(entry->base_addr);
            print_string(", Len: "); print_hex(entry->length);
            print_string(", Type: "); print_int(entry->type); print_string("\n");
            if(entry->type == 1) total_usable_bytes += entry->length;
        }
        print_success("Total Usable Physical Memory: ");
        print_int(total_usable_bytes / 1024 / 1024); print_success(" MB\n");
    }
    else if (strcmp(cmd, "testpage") == 0) 
    {
        print_string("Testing Physical Page Allocation (alloc_page)...\n");
            paddr_t paddr = alloc_page_owned(PAGE_OWNER_TEST);
        if (paddr) {
            print_string("  -> Allocated Physical Addr: "); print_hex((uint64_t)paddr); print_string("\n");
            void* vaddr = P2V(paddr);
            print_string("  -> Mapped Virtual Addr:   "); print_hex((uint64_t)vaddr); print_string("\n");
            
            // 写入测试
            *(uint64_t*)vaddr = 0xDEADBEEFCAFEBABE;
            if (*(uint64_t*)vaddr == 0xDEADBEEFCAFEBABE) {
                print_success("  -> Read/Write Test: PASSED\n");
            }
            free_page_owned(paddr, PAGE_OWNER_TEST);
            print_success("  -> Page freed successfully.\n");
        } else {
            print_error("  -> Allocation FAILED!\n");
        }
    }
    else if (strcmp(cmd, "testmalloc") == 0) 
    {
        print_string("Testing Kernel Heap (kmalloc & kfree)...\n");
        char* str1 = (char*)kmalloc(100);
        char* str2 = (char*)kmalloc(4096); // 触发扩容测试
        
        if (str1 && str2) {
            strcpy(str1, "  -> KMalloc Data Write PASSED!");
            print_success(str1); print_string("\n");
            print_string("  -> Pointers: ptr1="); print_hex((uint64_t)str1); 
            print_string(", ptr2="); print_hex((uint64_t)str2); print_string("\n");
            kfree(str1);
            kfree(str2);
            print_success("  -> Memory blocks freed.\n");
        } else {
            print_error("  -> KMalloc FAILED!\n");
        }
    }

    // ==========================================
    // 4. 多任务与调度器测试模块 (Multitasking)
    // ==========================================
    else if(strcmp(cmd, "yield") == 0)
    {
        print_warning("Yielding CPU to next thread...\n");
        thread_yield();
    }
    else if(strcmp(cmd, "testthread") == 0)
    {
        print_string("Spawning a new kernel thread...\n");
        struct thread* new_thread = thread_create(dummy_thread_task, 5);
        if (new_thread) {
            thread_append(new_thread);
            print_success("Thread created and appended to Ready Queue!\n");
        } else {
            print_error("Thread creation failed (Out of memory).\n");
        }
    }

    // ==========================================
    // 5. C 标准库函数测试模块
    // ==========================================
    else if(strcmp(cmd, "testprint") == 0)
    {
        print_info("Testing Color and Format Outputs:\n");
        print_success("  Success Message\n");
        print_error("  Error Message\n");
        print_warning("  Warning Message\n");
        print_string("  Integer Test: "); print_int(-123456); print_string("\n");
        print_string("  Hex Test:     "); print_hex(0x1A2B3C4D); print_string("\n");
    }
    else if (strcmp(cmd, "testlib") == 0) 
    {
        char buf1[20]; char buf2[20];
        memset(buf1, 'A', 10); buf1[10] = '\0';
        print_string("memset: "); print_info(buf1); print_string("\n");
        strcpy(buf2, "MyOS libc");
        print_string("strcpy: "); print_info(buf2); print_string("\n");
        print_string("strlen: "); print_int(strlen(buf2)); print_string(" (Expected 9)\n");
    }

    // ==========================================
    // 6. 异常与中断防御测试模块 (Panic Tests)
    // ==========================================
    else if (strcmp(cmd, "panic") == 0)
    {
        print_error("Initiating Kernel Panic (Divide by Zero)...\n");
        uint32_t divisor = 0;
        /* Trigger #DE at runtime without relying on C undefined behaviour or
           leaving a permanent -Wdiv-by-zero warning in release builds. */
        __asm__ volatile("xorl %%edx, %%edx\n\t"
                         "movl $1, %%eax\n\t"
                         "divl %0"
                         : : "r"(divisor) : "rax", "rdx", "memory");
    }
    else if (strcmp(cmd, "testpf") == 0) 
    {
        print_error("Initiating Page Fault (Unmapped Address)...\n");
        volatile int* bad_ptr = (int*)0x00000000BAADF00D; // 低半区绝对未映射的地址
        int a = *bad_ptr; 
    }
    // ==========================================
    // 7. 用户态进程测试模块 (User Process)
    // ==========================================
    else if(strcmp(cmd, "testprocess") == 0)
    {
        print_string("Spawning a Ring 3 isolated User Process...\n");

        // 1. 创建进程 PCB，它会拿到一个独立的、低半区纯净的 CR3 页表
        struct process* new_process = process_create((void (*)(void))0x400000, 5);
        
        if (new_process) {
            // 2. 为这个进程申请一页真实的物理内存存放代码
            paddr_t code_paddr = alloc_page_owned(PAGE_OWNER_USER);
            if (code_paddr == 0) {
                process_discard(new_process);
                cmd_index = 0;
                return;
            }
            
            // 3. 将机器码拷贝到这块物理页中 (必须用 P2V 操作)
            memcpy(P2V(code_paddr), app_machine_code, sizeof(app_machine_code));
            
            // 4. 【见证奇迹的时刻】：将这块物理页，挂载到新进程的虚拟地址 0x400000 处！
            // 权限设置为 PTE_P | PTE_RW | PTE_US (值为 0x07，代表用户态可读写)
            if (map_page(new_process->cr3_paddr, 0x400000, code_paddr,
                         PTE_RW | PTE_US) != 0)
            {
                print_error("  -> Code page mapping FAILED!\n");
                free_page_owned(code_paddr, PAGE_OWNER_USER);
                process_discard(new_process);
                cmd_index = 0;
                return;   // 注意：这里在 execute_command 里，用 return 即可
            }
            
            // 5. 加入就绪队列
            thread_append(new_process->main_thread);
            print_success("User Process created! Address 0x400000 mapped and ready.\n");
            print_warning("Run 'yield' to jump into it (System will hang in the user app as intended).\n");
        } else {
            print_error("Process creation failed.\n");
        }
    }
    else if (strcmp(cmd, "testvm") == 0) 
    {
        print_info("[VM Proof] Creating two independent Universes (CR3)...\n");

        // 1. 创造两个完全独立的进程页表
        paddr_t cr3_A = create_page_dir();
        paddr_t cr3_B = create_page_dir();

        // 2. 申请两个不同的真实物理页
        paddr_t phys_A = alloc_page_owned(PAGE_OWNER_USER);
        paddr_t phys_B = alloc_page_owned(PAGE_OWNER_USER);

        if (cr3_A == 0 || cr3_B == 0 || phys_A == 0 || phys_B == 0) {
            if (phys_A != 0) free_page(phys_A);
            if (phys_B != 0) free_page(phys_B);
            if (cr3_A != 0) destroy_user_address_space(cr3_A);
            if (cr3_B != 0) destroy_user_address_space(cr3_B);
            print_error("  -> VM test setup allocation FAILED!\n");
            cmd_index = 0;
            return;
        }

        // 3. 在物理页里写下不同的印记 (利用内核的 P2V 后门)
        strcpy((char*)P2V(phys_A), "I am Data from Universe A!");
        strcpy((char*)P2V(phys_B), "I am Data from Universe B!");

        // 4. 【核心】：将它们挂载到 两个页表 的 ！！！同一个虚拟地址！！！
        uint64_t target_vaddr = 0x40000000; // 选定虚拟地址 1GB 处
        if (map_page(cr3_A, target_vaddr, phys_A, PTE_RW | PTE_US) != 0) {
            print_error("  -> Mapping Universe A FAILED!\n");
            free_page(phys_A);      // ← 补上
            free_page(phys_B);      // ← 补上（B 也白分配了）
            destroy_user_address_space(cr3_A);
            destroy_user_address_space(cr3_B);
            cmd_index = 0;          // ← 补上（见下方说明）
            return;
        }
        if (map_page(cr3_B, target_vaddr, phys_B, PTE_RW | PTE_US) != 0) {
            print_error("  -> Mapping Universe B FAILED!\n");
            free_page(phys_B);      // B 尚未挂入 B 的地址空间
            destroy_user_address_space(cr3_A);
            destroy_user_address_space(cr3_B);
            cmd_index = 0;          // ← 补上
            return;
        }

        // 5. 保存内核当前的 CR3
        uint64_t old_cr3;
        __asm__ volatile("mov %%cr3, %0" : "=r"(old_cr3));

        print_string("Mapping done. Now performing direct memory read at 0x40000000...\n");

        // 6. 切换到 宇宙 A，读取虚拟地址 0x40000000
        __asm__ volatile("mov %0, %%cr3" :: "r"(cr3_A) : "memory");
        print_string("  -> [CR3 = A] Value = ");
        print_success((char*)target_vaddr); // C 语言直接读取该虚拟地址！
        print_string("\n");

        // 7. 切换到 宇宙 B，读取一模一样的虚拟地址 0x40000000
        __asm__ volatile("mov %0, %%cr3" :: "r"(cr3_B) : "memory");
        print_string("  -> [CR3 = B] Value = ");
        print_success((char*)target_vaddr);
        print_string("\n");

        // 8. 恢复内核环境
        __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");

        /* A/B 的用户页和四级页表由地址空间销毁流程统一回收。 */
        destroy_user_address_space(cr3_A);
        destroy_user_address_space(cr3_B);
        
        print_info("[VM Proof] Same Virtual Address, Different Data. Isolation is REAL!\n");
    }
    else if (strcmp(cmd, "testring3") == 0)
    {
        print_info("[Ring 3 Proof] Spawning a user process to attempt illegal operations...\n");

        // 1. 创建进程，指定它去执行 0x800000 的代码
        struct process* rogue_process = process_create((void (*)(void))0x800000, 5);
        
        if (rogue_process) {
            paddr_t code_paddr = alloc_page_owned(PAGE_OWNER_USER);
            if (code_paddr == 0) {
                process_discard(rogue_process);
                cmd_index = 0;
                return;
            }
            
            // 2. 植入恶意机器码
            // 0xFA 是 cli 指令 (关闭中断)，这是典型的 Ring 0 特权指令！
            // 0xEB 0xFE 是死循环
            static uint8_t malicious_code[] = { 0xFA, 0xEB, 0xFE }; 
            memcpy(P2V(code_paddr), malicious_code, sizeof(malicious_code));
            
            // 3. 挂载物理页
            if (map_page(rogue_process->cr3_paddr, 0x800000, code_paddr,
                         PTE_RW | PTE_US) != 0) {
                print_error("  -> Malicious code mapping FAILED!\n");
                free_page_owned(code_paddr, PAGE_OWNER_USER);
                process_discard(rogue_process);
                cmd_index = 0;
                return;
            }
            
            thread_append(rogue_process->main_thread);
            print_success("Rogue User Process mapped at 0x800000.\n");
            print_warning("Run 'yield'. If Ring 3 works, you MUST get a General Protection Fault (Exception 13)!\n");
        }
    }
    // ==========================================
    // 7. 错误指令兜底
    // ==========================================
    else 
    {
        print_error("[-] Unknown command: ");
        print_error(cmd);
        print_error(". Type 'help' for available commands.\n");
    }

    // 执行完毕，缓冲区清零，等待下一次输入
    cmd_index = 0;
}

// 接收键盘中断传来的字符
void shell_take_char(char c) {
    if (c == '\n') {
        put_char('\n');
        cmd_buffer[cmd_index] = '\0';
        execute_command(cmd_buffer);
        print_string("MyOS > ");
    } 
    else if (c == '\b') {
        if (cmd_index > 0) {
            cmd_index--;
            put_char('\b');
        }
    } 
    else if (c == 27) { // 处理 ESC 键，快速清空当前行
        while (cmd_index > 0) {
            put_char('\b');
            cmd_index--;
        }
        cmd_buffer[0] = '\0'; 
    } 
    else {
        if (cmd_index < CMD_BUF_SIZE - 1) {
            cmd_buffer[cmd_index] = c;
            cmd_index++;
            put_char(c);
        }
    }
}
