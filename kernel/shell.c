// kernel/shell.c

#include "shell.h"
#include "string.h"
#include "print.h"
#include "idt.h" 

#define CMD_BUF_SIZE 256
static char cmd_buffer[CMD_BUF_SIZE]; // 存放当前输入的命令字符
static int cmd_index = 0;             // 记录当前输入了多少个字符

// 初始化 shell，打印提示符
void shell_init(void)
{
    print_string("\nMyOS > ");
}

// 执行命令的核心逻辑
void execute_command(char* cmd) {
    // 1. 如果什么都没输入直接回车，就直接返回
    if (cmd_index == 0) 
    {
        return;
    }

    // 2. 封口：给字符数组末尾加上 '\0'，让它变成一个合法的 C 语言字符串
    cmd[cmd_index] = '\0';

    // 3. 开始字符串匹配，执行命令！
    if (strcmp(cmd, "help") == 0) 
    {
        print_string("Available commands:\n");
        print_string("  help  - Show this message\n");
        print_string("  clear - Clear the screen\n");
        print_string("  hello - Say hello to the OS\n");
    } 
    else if (strcmp(cmd, "clear") == 0) 
    {
        clear_screen(); // 调用你之前写好的清屏函数
    } 
    else if (strcmp(cmd, "hello") == 0) 
    {

        print_success("Hello! You are typing inside a 64-bit OS written from scratch!\n");
    }
    else if (strcmp(cmd, "uptime") == 0) 
    {
        // 默认 PIT 频率约 18.2 Hz，所以 ticks / 18 约等于秒数
        unsigned long seconds = system_ticks / 18; 
        print_string("System Uptime: ");
        print_int(seconds);
        print_string(" seconds.\n");
    }
    else if (strcmp(cmd, "cpuinfo") == 0)
    {
        unsigned int eax, ebx, ecx, edx;
        // 使用内联汇编调用 cpuid 指令
        __asm__ volatile (
            "cpuid"
            : "=a"(eax), "=b"(ebx), "=c"(ecx), "=d"(edx)
            : "a"(0)
        );

        // CPU 厂商名字固定为 12 个字符，拼接 ebx, edx, ecx
        char vendor[13];
        vendor[0] = (ebx >> 0) & 0xFF; vendor[1] = (ebx >> 8) & 0xFF;
        vendor[2] = (ebx >> 16) & 0xFF; vendor[3] = (ebx >> 24) & 0xFF;
        vendor[4] = (edx >> 0) & 0xFF; vendor[5] = (edx >> 8) & 0xFF;
        vendor[6] = (edx >> 16) & 0xFF; vendor[7] = (edx >> 24) & 0xFF;
        vendor[8] = (ecx >> 0) & 0xFF; vendor[9] = (ecx >> 8) & 0xFF;
        vendor[10] = (ecx >> 16) & 0xFF; vendor[11] = (ecx >> 24) & 0xFF;
        vendor[12] = '\0';

        print_string("CPU Vendor: ");
        print_string(vendor);
        print_string("\n");
    }
    else if (strncmp(cmd, "echo ", 5) == 0) 
    {
        // cmd + 5 就是跳过 "echo " 这 5 个字符，直接打印后面的内容
        print_string(cmd + 5); 
        print_string("\n");
    }
    else if (strcmp(cmd, "panic") == 0)
     {
        print_string("Initiating Kernel Panic...\n");
        volatile int a = 1 / 0; // 瞬间引爆除零异常！
    }
    else if (strcmp(cmd, "testlib") == 0) 
    {
        char buf1[50];
        char buf2[50];
        
        // 测试 memset
        memset(buf1, 'A', 10);
        buf1[10] = '\0';
        print_string("memset test (should be AAAAAAAAAA): ");
        print_string(buf1);
        print_string("\n");

        // 测试 strcpy
        strcpy(buf2, "Hello System!");
        print_string("strcpy test: ");
        print_string(buf2);
        print_string("\n");

        // 测试 strlen
        print_string("strlen test ('Hello System!'): ");
        print_int(strlen(buf2));
        print_string(" (Expected 13)\n");
    }
    else if (strcmp(cmd, "testpf") == 0) {
        print_string("Attempting to read unmapped memory...\n");
        // 故意造一个极其离谱的虚拟内存地址（我们根本没有映射它）
        volatile int* bad_ptr = (int*)0xFFFFFFFFFFFFFFFF;
        
        // 读它！瞬间爆炸！
        int a = *bad_ptr; 
        
        print_string("You will never see this line.\n");
    }
    else 
    {
        print_error("[-] Unknown command: ");
        print_error(cmd);
        print_error("\n");
    }

    // 4. 命令执行完后，把缓冲区清空，准备接收下一条命令
    cmd_index = 0;
}

// 这个函数专门用来吃掉键盘传来的字符，并处理回车退格逻辑
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
    // ==========================================
    // 【新增】处理 ESC 键 (ASCII 27)
    // 逻辑：把屏幕上的字一个个退格吃掉，然后缓冲区清零
    // ==========================================
    else if (c == 27) {
        // 只要缓冲区还有字，就模拟退格键把屏幕上的字删掉
        while (cmd_index > 0) {
            put_char('\b');
            cmd_index--;
        }
        // 缓冲区首字符设为结束符，彻底清空
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