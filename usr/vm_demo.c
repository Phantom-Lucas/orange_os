#include "syscall.h"

#ifndef VM_TEST_ROUNDS
#define VM_TEST_ROUNDS 32
#endif

static int wait_status(long pid, int expected);

static int run_cow_round(unsigned long round)
{
    volatile unsigned long* page;
    void* mapping = sys_mmap(0, 4096, 0x3, 0x22);
    long pid;

    if (mapping == 0) return -1;
    page = (volatile unsigned long*)mapping;
    page[0] = round;
    pid = sys_fork();
    if (pid < 0) return -1;
    if (pid == 0) {
        if (page[0] != round) sys_exit(220);
        page[0] = round ^ 0xC0DEULL;
        sys_exit(0);
    }
    page[0] = round ^ 0xA5A5ULL;
    if (wait_status(pid, 0) != 0 || page[0] != (round ^ 0xA5A5ULL)) {
        return -1;
    }
    return sys_munmap(mapping, 4096) == 0 ? 0 : -1;
}

static int wait_status(long pid, int expected)
{
    int status = -1;
    if (sys_wait((unsigned long)pid, &status) != pid) return -1;
    return status == expected ? 0 : -1;
}

int main(void)
{
    volatile unsigned long* shared;
    long pid;
    int status;
    void* mapping;
    volatile unsigned char stack_probe[8192];

    sys_write(1, "[VM] COW/mmap demo start\n", 25);
    mapping = sys_mmap(0, 3 * 4096, 0x3, 0x22);
    if (mapping == 0) sys_exit(201);
    shared = (volatile unsigned long*)mapping;
    shared[0] = 0x11111111UL;

    pid = sys_fork();
    if (pid < 0) sys_exit(202);
    if (pid == 0) {
        /* 子进程先读到父值，再写自己的 COW 副本。 */
        if (shared[0] != 0x11111111UL) sys_exit(203);
        shared[0] = 0x22222222UL;

        /* 多代 fork：孙进程再次触发同一页的 COW。 */
        long grandchild = sys_fork();
        if (grandchild < 0) sys_exit(204);
        if (grandchild == 0) {
            if (shared[0] != 0x22222222UL) sys_exit(205);
            shared[0] = 0x33333333UL;
            sys_exit(33);
        }
        if (wait_status(grandchild, 33) != 0) sys_exit(206);
        if (shared[0] != 0x22222222UL) sys_exit(207);
        sys_exit(22);
    }

    shared[0] = 0xAAAAAAAAUL;
    if (wait_status(pid, 22) != 0 || shared[0] != 0xAAAAAAAAUL) {
        sys_exit(208);
    }

    /* 代码段是 ELF PF_W=0 的真正只读页，写入应只终止子进程。 */
    pid = sys_fork();
    if (pid < 0) sys_exit(212);
    if (pid == 0) {
        volatile unsigned char* code =
            (volatile unsigned char*)(unsigned long)main;
        *code = (unsigned char)(*code ^ 0x1U);
        sys_exit(213);
    }
    status = -1;
    if (sys_wait((unsigned long)pid, &status) != pid || status != 142) {
        sys_exit(214);
    }

    /* 匿名私有映射的部分解除、剩余解除和重复解除。 */
    if (sys_munmap((unsigned char*)mapping + 4096, 4096) != 0) {
        sys_exit(209);
    }
    if (sys_munmap(mapping, 4096) != 0 ||
        sys_munmap((unsigned char*)mapping + 8192, 4096) != 0 ||
        sys_munmap(mapping, 4096) == 0) {
        sys_exit(210);
    }

    for (unsigned long round = 1; round <= VM_TEST_ROUNDS; round++) {
        if (run_cow_round(round) != 0) sys_exit(215);
    }

    /* 触碰当前栈页下方，验证 VM_GROWSDOWN 页故障路径。 */
    stack_probe[0] = 0x5A;
    stack_probe[8191] = 0xA5;
    if (stack_probe[0] != 0x5A || stack_probe[8191] != 0xA5) {
        sys_exit(211);
    }

    sys_write(1, "[VM] COW/mmap demo PASSED\n", 28);
    sys_exit(0);
}

void _start(void)
{
    main();
    sys_exit(0);
}
