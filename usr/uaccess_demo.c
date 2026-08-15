#include "syscall.h"

/*
 * Ring 3 用户指针回归测试。
 *
 * 用户 ELF 只在 0x7fffffff e000 这一页建立栈映射；从该页最后一个
 * 字节开始访问两个字节，会强制跨入未映射页。测试的目标不是触发页错，
 * 而是确认系统调用在阻塞、访问文件或 IPC 之前就返回 -1。
 */
static const unsigned long CROSS_PAGE = 0x00007FFFFFFFEFFFULL;

static int rejected(long result) {
    return result < 0;
}

static unsigned long text_length(const char* text) {
    unsigned long length = 0;
    while (text[length] != '\0') length++;
    return length;
}

static int expect_rejected(const char* label, long result) {
    if (rejected(result)) return 0;
    (void)sys_write(1, label, text_length(label));
    return 1;
}

void _start(void) {
    static const char passed[] = "[Ring 3] uaccess demo PASSED.\n";
    static const char failed[] = "[Ring 3] uaccess demo FAILED.\n";
    static const char valid_name[] = "missing-uaccess-file.elf";
    int failures = 0;

    /* 让跨页字符串的第一页末字节非零，确保 copy_string 真的走到下一页。 */
    *(volatile char*)CROSS_PAGE = 'x';

    /* NULL/低地址、跨页和超长字符串都必须在内核中被拒绝。 */
    failures += expect_rejected("uaccess unexpected: write-null\n",
                                sys_write(1, (const char*)1, 1));
    failures += expect_rejected("uaccess unexpected: write-cross-page\n",
                                sys_write(1, (const char*)CROSS_PAGE, 2));
    failures += expect_rejected("uaccess unexpected: open-null\n",
                                sys_open((const char*)1, 0));
    failures += expect_rejected("uaccess unexpected: open-cross-page\n",
                                sys_open((const char*)CROSS_PAGE, 2));
    failures += expect_rejected("uaccess unexpected: unlink-null\n",
                                sys_unlink((const char*)1));
    failures += expect_rejected("uaccess unexpected: spawn-null\n",
                                sys_spawn((const char*)1));
    failures += expect_rejected("uaccess unexpected: exec-null\n",
                                sys_exec((const char*)1));

    /* 输出缓冲区必须在可能阻塞的 TTY/FS/IPC 操作之前完成验证。 */
    failures += expect_rejected("uaccess unexpected: read-cross-page\n",
                                sys_read(0, (void*)CROSS_PAGE, 2));
    failures += expect_rejected("uaccess unexpected: list-cross-page\n",
                                sys_list((void*)CROSS_PAGE, 2));
    failures += expect_rejected("uaccess unexpected: wait-null\n",
                                sys_wait(0xFFFFFFFFUL, (int*)1));
    failures += expect_rejected("uaccess unexpected: send-null\n",
                                sys_send(1, (const struct ipc_message*)1));
    failures += expect_rejected("uaccess unexpected: receive-null\n",
                                sys_receive(IPC_ANY, (struct ipc_message*)1));

    /* 合法参数仍应保留原有语义，避免测试只覆盖“全部拒绝”。 */
    if (sys_open(valid_name, 0) >= 0) {
        (void)sys_write(1, "uaccess unexpected: open-missing\n", 33);
        failures++;
    }

    if (failures == 0) {
        (void)sys_write(1, passed, sizeof(passed) - 1);
        (void)sys_exit(0);
    }

    (void)sys_write(1, failed, sizeof(failed) - 1);
    (void)sys_exit(1);
    while (1) { }
}
