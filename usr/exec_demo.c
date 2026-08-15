#include "syscall.h"

static void write_text(const char* text, unsigned long length) {
    (void)sys_write(1, text, length);
}

void _start(void) {
    static const char started[] =
        "[Ring 3] exec demo: replacing image through FS service.\n";
    static const char failed[] = "[Ring 3] exec demo FAILED.\n";
    static const char target[] = "hello.elf";

    write_text(started, sizeof(started) - 1);
    if (sys_exec(target) < 0) {
        write_text(failed, sizeof(failed) - 1);
        (void)sys_exit(1);
    }

    /* 成功的 exec 不会返回到这里。 */
    (void)sys_exit(2);
}
