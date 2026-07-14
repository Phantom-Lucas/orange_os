// kernel/kernel.c
#include "print.h"

__attribute__((section(".text.kernel_main")))
void kernel_main() {
    // 1. 清理掉屏幕上 Loader 留下的 MSLP6K，让我们有一个干净的画板
    clear_screen();

    // 2. 测试完美的字符串打印与换行
    print_string("=================================================\n");
    print_string("  Welcome to My 64-bit OS! \n");
    print_string("  Memory Pagination is ACTIVE.\n");
    print_string("=================================================\n\n");

    // 3. 测试数字转换体系（十六进制 与 十进制）
    unsigned long my_magic_ptr = 0x1234567890ABCDEF; // 一个 64 位的虚拟地址
    long money = -99998888;
    
    print_string("[TEST] Address of my_magic_ptr: ");
    print_hex(my_magic_ptr);
    print_string("\n");

    print_string("[TEST] Negative Decimal Number: ");
    print_int(money);
    print_string("\n\n");

    // 4. 测试滚屏大冲刺（打印 30 行内容，观察前几行是否被顶上去，而且不乱码）
    print_string("Starting scroll test...\n");
    for (int i = 1; i <= 30; i++) {
        print_string("This is line number ");
        print_int(i);
        print_string(" being printed to test screen scrolling.\n");
    }

    print_string("\n[SUCCESS] If you can read this at the bottom, your printing system is PERFECT!\n");

    // 5. 内核悬停停机
    while (1) {
        __asm__ volatile("hlt");
    }
}