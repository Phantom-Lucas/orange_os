#include "libc.h"

#define SHOWCASE_PAGE_SIZE 4096U
#define SHOWCASE_IPC_TYPE  0x53484F57U
#define SHOWCASE_IPC_VALUE 0xC0DEU
#define SHOWCASE_THREADS   4U

static int showcase_passed;
static int showcase_failed;

static volatile unsigned thread_counter;
static volatile unsigned observed_tids[SHOWCASE_THREADS];
static user_mutex_t thread_mutex;

static int same_bytes(const char* left, const char* right, unsigned length)
{
    for (unsigned i = 0; i < length; i++) {
        if (left[i] != right[i]) return 0;
    }
    return 1;
}

static int report_step(const char* name, int ok)
{
    if (ok) {
        showcase_passed++;
        printf("PASS %s\n", name);
    } else {
        showcase_failed++;
        printf("FAIL %s\n", name);
    }
    return ok;
}

static int step_system(void)
{
    struct sys_process_info entries[32];
    unsigned pid = (unsigned)sys_getpid();
    unsigned ticks = (unsigned)sys_get_ticks();
    unsigned processes = 0;
    unsigned threads = 0;
    unsigned user_pages = 0;
    long count = sys_ps(entries, 32);

    if (count >= 0) {
        processes = (unsigned)count;
        for (long i = 0; i < count; i++) {
            threads += entries[i].threads;
            if (entries[i].pid == pid) user_pages = entries[i].user_pages;
        }
    }
    printf("[1/6] SYSTEM\n");
    printf("input getpid/get_ticks/ps capacity=32\n");
    printf("actual pid=%u ticks=%u processes=%u threads=%u user_pages=%u\n",
           pid, ticks, processes, threads, user_pages);
    printf("expect pid>0 processes>0 threads>=processes self_pages>0\n");
    return report_step("SYSTEM", count >= 0 && pid != 0 && processes != 0 &&
                       threads >= processes && user_pages != 0);
}

static int step_cow(void)
{
    volatile unsigned short* value = (volatile unsigned short*)
        sys_mmap(0, SHOWCASE_PAGE_SIZE, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS);
    unsigned short before = 0;
    unsigned short child_value = 0;
    unsigned short parent_after = 0;
    long child = -1;
    int child_status = -1;
    long waited = -1;

    if (value != 0) {
        *value = 0x1111;
        before = *value;
        child = sys_fork();
        if (child == 0) {
            *value = 0x2222;
            sys_exit((int)*value);
            while (1) { }
        }
        if (child > 0) waited = sys_wait((unsigned long)child, &child_status);
        parent_after = *value;
        child_value = (unsigned short)child_status;
        (void)sys_munmap((void*)value, SHOWCASE_PAGE_SIZE);
    }

    printf("[2/6] PROCESS + COW\n");
    printf("input mmap page; parent=0x1111 child=0x2222\n");
    printf("actual before=0x%x child=0x%x parent-after=0x%x wait=%d\n",
           (unsigned)before, (unsigned)child_value, (unsigned)parent_after,
           (int)child_status);
    printf("expect before=0x1111 child=0x2222 parent-after=0x1111\n");
    return report_step("PROCESS + COW", value != 0 && child > 0 &&
                       waited == child && child_status == 0x2222 &&
                       before == 0x1111 && child_value == 0x2222 &&
                       parent_after == 0x1111);
}

static int step_ipc(void)
{
    unsigned parent_pid = (unsigned)sys_getpid();
    struct ipc_message message = {0, SHOWCASE_IPC_TYPE, SHOWCASE_IPC_VALUE};
    struct ipc_message received = {0, 0, 0};
    long child = sys_fork();
    long sent = -1;
    long waited = -1;
    int child_status = -1;

    if (child == 0) {
        int result = sys_receive((long)parent_pid, &received);
        int ok = result == 0 && received.source_pid == parent_pid &&
                 received.type == SHOWCASE_IPC_TYPE &&
                 received.value == SHOWCASE_IPC_VALUE;
        struct ipc_message reply = {0, received.source_pid, received.value};
        if (ok && sys_send((unsigned long)parent_pid, &reply) != 0) ok = 0;
        sys_exit(ok ? 0 : 1);
        while (1) { }
    }
    if (child > 0) {
        sent = sys_send((unsigned long)child, &message);
        if (sent != 0) (void)sys_kill((unsigned long)child, 9);
        if (sent == 0 && sys_receive((long)child, &received) != 0) {
            received.source_pid = 0;
            received.value = 0;
        }
        waited = sys_wait((unsigned long)child, &child_status);
    }

    printf("[3/6] IPC\n");
    printf("input send source=%u value=0xC0DE\n", parent_pid);
    printf("actual sent=%d received-source=%u value=0x%x exit=%d\n",
           (int)sent, received.source_pid, (unsigned)received.value,
           child_status);
    printf("expect sent=0 source=%u value=0xC0DE exit=0\n", parent_pid);
    return report_step("IPC", child > 0 && sent == 0 && waited == child &&
                       child_status == 0);
}

static void showcase_worker(void* raw_id)
{
    unsigned id = (unsigned)(uintptr_t)raw_id;
    if (id == 0 || id > SHOWCASE_THREADS || user_mutex_lock(&thread_mutex) != 0) {
        sys_thread_exit(100 + (int)id);
        while (1) { }
    }
    observed_tids[id - 1] = (unsigned)sys_gettid();
    thread_counter++;
    (void)user_mutex_unlock(&thread_mutex);
    sys_thread_exit(10 + (int)id);
    while (1) { }
}

static int step_threads(void)
{
    long tids[SHOWCASE_THREADS] = {0, 0, 0, 0};
    int statuses[SHOWCASE_THREADS] = {-1, -1, -1, -1};
    unsigned created = 0;
    int joins_ok = 1;

    thread_counter = 0;
    for (unsigned i = 0; i < SHOWCASE_THREADS; i++) {
        observed_tids[i] = 0;
        tids[i] = sys_thread_create(showcase_worker,
                                    (void*)(uintptr_t)(i + 1));
        if (tids[i] > 0) created++;
    }
    for (unsigned i = 0; i < SHOWCASE_THREADS; i++) {
        if (tids[i] <= 0 || sys_thread_join((unsigned long)tids[i],
                                            &statuses[i]) != 0) {
            joins_ok = 0;
        }
    }

    int values_ok = 1;
    for (unsigned i = 0; i < SHOWCASE_THREADS; i++) {
        if (tids[i] <= 0 || observed_tids[i] != (unsigned)tids[i] ||
            statuses[i] != (int)(11 + i)) values_ok = 0;
    }
    printf("[4/6] THREADS\n");
    printf("input create 4 threads; mutex increments shared counter\n");
    printf("actual created=%u tids=%u,%u,%u,%u counter=%u\n", created,
           (unsigned)tids[0], (unsigned)tids[1], (unsigned)tids[2],
           (unsigned)tids[3], (unsigned)thread_counter);
    printf("expect tids>0 observed_tids match exit=11,12,13,14 counter=4\n");
    return report_step("THREADS", created == SHOWCASE_THREADS && joins_ok &&
                       values_ok && thread_counter == SHOWCASE_THREADS);
}

static int step_filesystem(void)
{
    static const char proof[] = "ORANGE/64 showcase proof v1\n";
    char readback[sizeof(proof)] = {0};
    struct sys_stat stat_result = {0, 0, 0, 0};
    unsigned expected = (unsigned)(sizeof(proof) - 1);
    long fd = sys_open("demo-proof.txt", O_CREATE | O_TRUNC);
    long written = -1;
    long read_count = -1;
    int close_ok = 0;
    int reopen_close_ok = 0;

    if (fd >= 0) {
        written = sys_write((int)fd, proof, expected);
        close_ok = sys_close((int)fd) == 0;
    }
    fd = sys_open("demo-proof.txt", 0);
    if (fd >= 0) {
        read_count = sys_read((int)fd, readback, expected);
        reopen_close_ok = sys_close((int)fd) == 0;
    }
    int text_ok = read_count == (long)expected &&
                  same_bytes(readback, proof, expected);
    int stat_ok = sys_stat("demo-proof.txt", &stat_result) == 0 &&
                  stat_result.type == FS_TYPE_FILE &&
                  stat_result.size == expected;

    printf("[5/6] FILESYSTEM\n");
    printf("input create/truncate demo-proof.txt bytes=%u\n", expected);
    printf("actual write=%d read=%d type=%u size=%u text=%s\n",
           (int)written, (int)read_count, stat_result.type,
           (unsigned)stat_result.size, text_ok ? "match" : "mismatch");
    printf("expect write/read=%u type=2 size=%u text=match keep-file=1\n",
           expected, expected);
    return report_step("FILESYSTEM", written == (long)expected && close_ok &&
                       reopen_close_ok && text_ok && stat_ok);
}

static int step_fault_isolation(void)
{
    int status = -1;
    long fault_pid = sys_spawn("fault.elf");
    long waited = fault_pid > 0
                    ? sys_wait((unsigned long)fault_pid, &status) : -1;

    printf("[6/6] FAULT ISOLATION\n");
    printf("input spawn fault.elf and wait\n");
    printf("actual pid=%d status=%d\n", (int)fault_pid, status);
    printf("expect pid>0 status>=128 and showcase continues\n");
    return report_step("FAULT ISOLATION", fault_pid > 0 && waited == fault_pid &&
                       status >= 128);
}

int main(void)
{
    printf("ORANGE/64 GUIDED TOUR\n");
    (void)step_system();
    (void)step_cow();
    (void)step_ipc();
    user_mutex_init(&thread_mutex);
    (void)step_threads();
    (void)step_filesystem();
    (void)step_fault_isolation();
    printf("RESULT %d passed %d failed\n", showcase_passed, showcase_failed);
    return showcase_failed == 0 ? 0 : 1;
}
