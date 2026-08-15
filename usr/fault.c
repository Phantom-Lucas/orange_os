#include "syscall.h"

/* 用于回归测试 Ring 3 异常隔离：内核必须杀掉本进程并继续运行 Shell。 */
void _start(void) {
    static const char notice[] = "[Ring 3] deliberate page fault\n";
    volatile unsigned long* invalid_address =
        (volatile unsigned long*)0x00000000BAADF00DULL;

    sys_write(1, notice, sizeof(notice) - 1);
    *invalid_address = 1;
    while (1) { }
}
