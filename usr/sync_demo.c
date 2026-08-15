#include "thread_runtime.h"

#ifndef SYNC_TEST_ROUNDS
#define SYNC_TEST_ROUNDS 100
#endif
#ifndef SYNC_WORKER_ROUNDS
#define SYNC_WORKER_ROUNDS 20000
#endif

static user_mutex_t counter_mutex;
static user_mutex_t second_mutex;
static user_mutex_t queue_mutex;
static user_cond_t queue_ready;
static user_cond_t broadcast_ready;
static volatile uint32_t counter;
static volatile uint32_t queue_value;
static volatile uint32_t producer_done;
static volatile uint32_t broadcast_release;
static volatile uint32_t broadcast_waiters;
static volatile uint32_t broadcast_finished;
static volatile uint32_t failures;
static volatile uint32_t blocked_word;
static volatile uint32_t blocked_started;

static void write_text(const char* text)
{
    const char* end = text;
    while (*end != 0) end++;
    sys_write(1, text, (unsigned long)(end - text));
}

static void write_hex_u32(uint32_t value)
{
    char buffer[11];
    const char* digits = "0123456789ABCDEF";
    uint32_t shift;
    buffer[0] = '0';
    buffer[1] = 'x';
    for (shift = 0; shift < 8; shift++) {
        buffer[2 + shift] = digits[(value >> (28 - shift * 4)) & 0xF];
    }
    buffer[10] = '\n';
    sys_write(1, buffer, sizeof(buffer));
}

static void worker(void* argument)
{
    uint32_t rounds = (uint32_t)(unsigned long)argument;
    uint32_t i;
    uint32_t local = sys_gettid();
    *user_errno_location() = (int)local;
    user_tls_set_custom(((uint64_t)local << 32) | rounds);
    for (i = 0; i < rounds; i++) {
        if ((i & 31U) == 0) user_mutex_lock(&second_mutex);
        if (user_mutex_lock(&counter_mutex) != 0) failures++;
        counter++;
        if (user_mutex_unlock(&counter_mutex) != 0) failures++;
        if ((i & 31U) == 0 && user_mutex_unlock(&second_mutex) != 0) failures++;
    }
    if (*user_errno_location() != (int)local ||
        user_tls_get_custom() != (((uint64_t)local << 32) | rounds)) failures++;
    sys_thread_exit(0);
}

static void producer(void* unused)
{
    (void)unused;
    user_mutex_lock(&queue_mutex);
    queue_value = 0x55AA;
    producer_done = 1;
    user_cond_signal(&queue_ready);
    user_mutex_unlock(&queue_mutex);
    sys_thread_exit(0);
}

static int run_round(uint32_t thread_count, uint32_t rounds)
{
    unsigned long tids[16];
    int status;
    uint32_t i;

    counter = 0;
    failures = 0;
    user_mutex_init(&counter_mutex);
    user_mutex_init(&second_mutex);
    for (i = 0; i < thread_count; i++) {
        tids[i] = (unsigned long)sys_thread_create(worker,
                                                   (void*)(unsigned long)rounds);
        if ((long)tids[i] <= 0) return -10;
    }
    for (i = 0; i < thread_count; i++) {
        if (sys_thread_join(tids[i], &status) != 0 || status != 0) return -20;
    }
    if (failures != 0) return -30;
    if (counter != thread_count * rounds) return -40;
    return 0;
}

static void blocked_futex_thread(void* unused)
{
    (void)unused;
    blocked_started = 1;
    (void)sys_futex_wait(&blocked_word, 0);
    sys_thread_exit(0);
}

static int run_process_exit_futex_test(void)
{
    long pid = sys_fork();
    unsigned long tid;
    int status;

    if (pid < 0) return -1;
    if (pid == 0) {
        blocked_word = 0;
        blocked_started = 0;
        tid = (unsigned long)sys_thread_create(blocked_futex_thread, 0);
        if ((long)tid <= 0) sys_exit(94);
        while (!blocked_started) sys_thread_yield();
        /* process_exit 必须取消 waiter、回收线程对象和用户栈。 */
        sys_exit(0);
    }
    if (sys_wait((unsigned long)pid, &status) != pid || status != 0) return -1;
    return 0;
}

static int run_condvar_test(void)
{
    unsigned long tid;
    int status;

    queue_value = 0;
    producer_done = 0;
    user_mutex_init(&queue_mutex);
    user_cond_init(&queue_ready);
    tid = (unsigned long)sys_thread_create(producer, 0);
    if ((long)tid <= 0) return -1;
    user_mutex_lock(&queue_mutex);
    while (!producer_done) {
        if (user_cond_wait(&queue_ready, &queue_mutex) != 0) return -1;
    }
    if (queue_value != 0x55AA) failures++;
    user_mutex_unlock(&queue_mutex);
    return sys_thread_join(tid, &status) == 0 && status == 0 ? 0 : -1;
}

static void broadcast_waiter(void* unused)
{
    (void)unused;
    user_mutex_lock(&queue_mutex);
    broadcast_waiters++;
    while (!broadcast_release) {
        if (user_cond_wait(&broadcast_ready, &queue_mutex) != 0) {
            write_text("sync: waiter cond error\n");
            sys_thread_exit(93);
        }
    }
    broadcast_finished++;
    user_mutex_unlock(&queue_mutex);
    sys_thread_exit(0);
}

static int run_broadcast_test(void)
{
    unsigned long tids[4];
    int status;
    uint32_t i;

    broadcast_release = 0;
    broadcast_waiters = 0;
    broadcast_finished = 0;
    user_cond_init(&broadcast_ready);
    user_mutex_init(&queue_mutex);
    for (i = 0; i < 4; i++) {
        tids[i] = (unsigned long)sys_thread_create(broadcast_waiter, 0);
        if ((long)tids[i] <= 0) {
            write_text("sync: broadcast create failed\n");
            return -1;
        }
    }
    for (i = 0; i < 10000 && broadcast_waiters != 4; i++) sys_thread_yield();
    if (broadcast_waiters != 4) {
        write_text("sync: broadcast waiters not ready\n");
        return -1;
    }
    user_mutex_lock(&queue_mutex);
    broadcast_release = 1;
    user_cond_broadcast(&broadcast_ready);
    user_mutex_unlock(&queue_mutex);
    for (i = 0; i < 4; i++) {
        if (sys_thread_join(tids[i], &status) != 0 || status != 0) {
            write_text("sync: broadcast join failed\n");
            return -1;
        }
    }
    if (broadcast_finished != 4) write_text("sync: broadcast finish count bad\n");
    return broadcast_finished == 4 ? 0 : -1;
}

static volatile unsigned long lifecycle_target;
static volatile int lifecycle_join_result;
static volatile int lifecycle_detach_result;

static void lifecycle_target_thread(void* unused)
{
    (void)unused;
    for (uint32_t i = 0; i < 100; i++) sys_thread_yield();
    sys_thread_exit(33);
}

static void lifecycle_join_attempt(void* unused)
{
    int status;
    (void)unused;
    lifecycle_join_result = (int)sys_thread_join(lifecycle_target, &status);
    sys_thread_exit(0);
}

static void lifecycle_detach_attempt(void* unused)
{
    (void)unused;
    lifecycle_detach_result = (int)sys_thread_detach(lifecycle_target);
    sys_thread_exit(0);
}

static void detached_worker(void* unused)
{
    (void)unused;
    for (uint32_t i = 0; i < 1000; i++) sys_thread_yield();
    sys_thread_exit(0);
}

static int run_lifecycle_race_test(void)
{
    unsigned long joiner;
    unsigned long detacher;
    int status;

    lifecycle_join_result = -99;
    lifecycle_detach_result = -99;
    lifecycle_target = (unsigned long)sys_thread_create(lifecycle_target_thread, 0);
    if ((long)lifecycle_target <= 0) return -1;
    joiner = (unsigned long)sys_thread_create(lifecycle_join_attempt, 0);
    detacher = (unsigned long)sys_thread_create(lifecycle_detach_attempt, 0);
    if ((long)joiner <= 0 || (long)detacher <= 0) return -1;
    if (sys_thread_join(joiner, &status) != 0 || status != 0) return -1;
    if (sys_thread_join(detacher, &status) != 0 || status != 0) return -1;
    /* join/detach 对同一目标必须恰好一个成功。 */
    return ((lifecycle_join_result == 0) ^
            (lifecycle_detach_result == 0)) ? 0 : -1;
}

static int run_detach_test(void)
{
    unsigned long tid;
    uint32_t spins = 0;

    /* detached 线程不能复用会修改 mutex 测试 counter 的 worker，避免
       它跨测试轮次运行时污染下一轮的计数结果。 */
    tid = (unsigned long)sys_thread_create(detached_worker, 0);
    if ((long)tid <= 0 || sys_thread_detach(tid) != 0) return -1;
    /* detached 线程退出后不能再被 join；短暂让出 CPU 等待自动回收。 */
    while (spins++ < 2000) sys_get_ticks();
    return sys_thread_join(tid, 0) == 0 ? -1 : 0;
}

static int run_futex_validation_test(void)
{
    static const uint32_t read_only_word = 0;
    volatile uint32_t word = 0;
    volatile uint32_t* cross_page = (volatile uint32_t*)0x7FFFFFFFFFFCUL;

    write_text("sync: futex invalid-null\n");
    if (sys_futex_wait(0, 0) >= 0 || sys_futex_wake(0, 1) >= 0) return -1;
    write_text("sync: futex invalid-unaligned\n");
    if (sys_futex_wait((volatile uint32_t*)((unsigned long)&word + 1), 0) >= 0) {
        return -1;
    }
    write_text("sync: futex invalid-cross-page\n");
    if (sys_futex_wait(cross_page, 0) >= 0 ||
        sys_futex_wake(cross_page, 1) >= 0) return -1;
    write_text("sync: futex invalid-readonly\n");
    if (sys_futex_wait((volatile uint32_t*)&read_only_word, 0) >= 0 ||
        sys_futex_wake((volatile uint32_t*)&read_only_word, 1) >= 0) return -1;
    write_text("sync: futex value-mismatch\n");
    word = 1;
    int result = (int)sys_futex_wait(&word, 0);
    write_text("sync: futex validation done\n");
    return result == -2 ? 0 : -1;
}

void _start(void)
{
    uint32_t count;
    uint32_t round;
    int mutex_result;

    for (round = 0; round < SYNC_TEST_ROUNDS; round++) {
        if (round == 0) write_text("sync: mutex rounds\n");
        if (round != 0 && (round % 10U) == 0) {
            write_text("sync: stress progress\n");
        }
        for (count = 1; count <= 16; count *= 2) {
            if (round == 0) write_text("sync: mutex batch\n");
            mutex_result = run_round(count, SYNC_WORKER_ROUNDS);
            if (mutex_result != 0) {
                write_text("sync demo FAILED: mutex\n");
                if (count == 1) write_text("sync mutex batch=1\n");
                if (count == 2) write_text("sync mutex batch=2\n");
                if (count == 4) write_text("sync mutex batch=4\n");
                if (count == 8) write_text("sync mutex batch=8\n");
                if (count == 16) write_text("sync mutex batch=16\n");
                if (mutex_result == -10) write_text("sync mutex create failed\n");
                if (mutex_result == -20) write_text("sync mutex join failed\n");
                if (mutex_result == -30) write_text("sync mutex operation failed\n");
                if (mutex_result == -40) write_text("sync mutex counter failed\n");
                if (mutex_result == -40) {
                    write_text("sync counter=");
                    write_hex_u32(counter);
                    write_text("sync expected=");
                    write_hex_u32(count * SYNC_WORKER_ROUNDS);
                }
                if (round == 0) write_text("sync mutex round=0\n");
                if (round == 1) write_text("sync mutex round=1\n");
                if (round == 2) write_text("sync mutex round=2\n");
                sys_exit(91);
            }
        }
        if (round == 0) write_text("sync: condvar\n");
        if (round == 0 && run_process_exit_futex_test() != 0) {
            write_text("sync: process-exit futex failed\n");
            sys_exit(92);
        }
        if (run_condvar_test() != 0) {
            write_text("sync: condvar failed\n");
            sys_exit(92);
        }
        if (round == 0) write_text("sync: condvar done\n");
        if (run_broadcast_test() != 0) {
            write_text("sync: broadcast failed\n");
            sys_exit(92);
        }
        if (round == 0) write_text("sync: broadcast done\n");
        if (round == 0) write_text("sync: lifecycle begin\n");
        if (run_lifecycle_race_test() != 0) {
            write_text("sync: lifecycle failed\n");
            sys_exit(92);
        }
        if (round == 0) write_text("sync: lifecycle done\n");
        if (run_detach_test() != 0) {
            write_text("sync: detach failed\n");
            sys_exit(92);
        }
        if (round == 0) write_text("sync: detach done\n");
        if ((round == 0 && run_futex_validation_test() != 0)) {
            write_text("sync demo FAILED: condvar/lifecycle\n");
            sys_exit(92);
        }
    }
    write_text("sync demo PASSED\n");
    sys_exit(0);
}
