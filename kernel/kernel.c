// kernel/kernel.c

#include "print.h"

__attribute__((section(".text.kernel_main")))
void kernel_main() {
	// 1. 先在第一行打印 OS
	put_char('O');
	put_char('S');

	// 2. 打印换行符（测试换行 \n）
	put_char('\n');

	// 3. 在第二行打印 A B
	put_char('A');
	put_char('B');

	// 4. 打印退格符（测试退格 \b，此时 'B' 应该被删掉，光标退回到 'A' 的右边）
	put_char('\b');

	// 5. 打印 C（测试字符覆盖，此时 'C' 应该写在原本 'B' 的位置上）
	put_char('C');
	put_char('\r');
	while (1) {
		__asm__ volatile("hlt");
		// 内核悬停
	}
}