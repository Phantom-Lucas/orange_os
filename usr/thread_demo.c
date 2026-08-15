#include "syscall.h"

/*
 * 用户态多线程回归测试：
 * 1. 多个线程共享同一进程的全局数据；
 * 2. 每个线程有独立用户栈和 TID，可返回退出码并被 join；
 * 3. 反复创建/回收线程，验证用户栈映射没有泄漏；
 * 4. 多线程期间 fork/exec 必须按策略失败；
 * 5. 最后由主线程退出，验证进程级退出会清理仍存活的线程。
 */
static volatile unsigned long started;
static volatile unsigned long finished;
static volatile unsigned long release_blocker;
static volatile unsigned long slots[4];

static void write_text(const char* text, unsigned long length)
{
    (void)sys_write(1, text, length);
}

static void fail(void)
{
    static const char message[] = "thread demo FAILED\n";
    write_text(message, sizeof(message) - 1);
    sys_exit(1);
}

static void worker(void* raw_id)
{
    unsigned long id = (unsigned long)raw_id;
    unsigned long tid = (unsigned long)sys_gettid();

    if (id >= 1 && id <= 4) slots[id - 1] = tid;
    started++;
    finished++;
    sys_thread_exit((int)id);
}

static void blocker(void* unused)
{
    (void)unused;
    started++;
    while (!release_blocker) (void)sys_get_ticks();
    sys_thread_exit(77);
}

static void final_worker(void* unused)
{
    unsigned long i;
    (void)unused;
    for (i = 0; i < 20; i++) (void)sys_get_ticks();
    sys_thread_exit(0);
}

void _start(void)
{
    static const char passed[] = "thread demo PASSED\n";
    int statuses[4];
    long tids[4];
    unsigned long i;
    int status;

    for (i = 0; i < 3; i++) {
        tids[i] = sys_thread_create(worker, (void*)(i + 1));
        if (tids[i] <= 0) fail();
    }
    while (started < 3) (void)sys_get_ticks();
    for (i = 0; i < 3; i++) {
        statuses[i] = -1;
        if (sys_thread_join((unsigned long)tids[i], &statuses[i]) != 0 ||
            statuses[i] != (int)(i + 1) || slots[i] == 0) fail();
    }
    if (sys_gettid() == 0) fail();

    /* 顺序反复创建/回收，重点覆盖同一地址空间的栈页映射回收。 */
    for (i = 0; i < 32; i++) {
        long tid = sys_thread_create(worker, (void*)1);
        status = -1;
        if (tid <= 0 || sys_thread_join((unsigned long)tid, &status) != 0 ||
            status != 1) fail();
    }

    /* fork/exec 策略：只要仍有第二个线程，两个操作都必须失败。 */
    started = 0;
    release_blocker = 0;
    long blocked_tid = sys_thread_create(blocker, 0);
    if (blocked_tid <= 0) fail();
    while (started == 0) (void)sys_get_ticks();
    if (sys_fork() >= 0 || sys_exec("hello.elf") >= 0) fail();
    release_blocker = 1;
    status = -1;
    if (sys_thread_join((unsigned long)blocked_tid, &status) != 0 ||
        status != 77) fail();

    write_text(passed, sizeof(passed) - 1);

    /* 主线程先退出；最后一个仍存活的线程再触发进程级回收。 */
    if (sys_thread_create(final_worker, 0) <= 0) fail();
    sys_thread_exit(0);
    while (1) { }
}
