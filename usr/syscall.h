#ifndef USER_SYSCALL_H
#define USER_SYSCALL_H

#define SYS_WRITE      1
#define SYS_GET_TICKS  2
#define SYS_OPEN       3
#define SYS_READ       4
#define SYS_CLOSE      5
#define SYS_UNLINK     6
#define SYS_EXIT       7
#define SYS_WAIT       8
#define SYS_SPAWN      9
#define SYS_LIST       10
#define SYS_EXEC       11
#define SYS_FORK       12
#define SYS_SEND       13
#define SYS_RECEIVE    14
#define SYS_THREAD_CREATE 15
#define SYS_THREAD_JOIN   16
#define SYS_THREAD_EXIT   17
#define SYS_GETTID        18
#define SYS_FUTEX_WAIT    19
#define SYS_FUTEX_WAKE    20
#define SYS_THREAD_DETACH 21
#define SYS_THREAD_YIELD  22
#define SYS_MMAP          23
#define SYS_MUNMAP        24
#define SYS_MKDIR         25
#define SYS_STAT          26
#define SYS_CHDIR         27
#define SYS_GETCWD        28
#define SYS_DUP           29
#define SYS_DUP2          30
#define SYS_PIPE          31
#define SYS_GETPID        32
#define SYS_SLEEP         33
#define SYS_KILL          34
#define SYS_PS            35
#define SYS_CLEAR         36

#define O_CREATE       0x01
#define O_TRUNC        0x02
#define O_APPEND       0x04

#define PROT_READ      0x1
#define PROT_WRITE     0x2
#define PROT_EXEC      0x4
#define MAP_PRIVATE    0x02
#define MAP_ANONYMOUS  0x20

#define FS_TYPE_DIRECTORY 1
#define FS_TYPE_FILE      2

struct sys_stat {
    unsigned int inode;
    unsigned int type;
    unsigned long long size;
    unsigned int links;
};

#define IPC_ANY (-1)

struct ipc_message {
    unsigned int source_pid;
    unsigned int type;
    unsigned long value;
};

static inline long syscall3(long number, long arg1, long arg2, long arg3) {
    long result;
    __asm__ volatile (
        "syscall"
        : "=a"(result)
        : "a"(number), "D"(arg1), "S"(arg2), "d"(arg3)
        : "rcx", "r11", "memory"
    );
    return result;
}

static inline long sys_write(int fd, const char* buffer, unsigned long length) {
    return syscall3(SYS_WRITE, fd, (long)buffer, (long)length);
}

static inline unsigned long sys_get_ticks(void) {
    return (unsigned long)syscall3(SYS_GET_TICKS, 0, 0, 0);
}

static inline long sys_open(const char* path, unsigned long flags) {
    return syscall3(SYS_OPEN, (long)path, flags, 0);
}

static inline long sys_read(int fd, void* buffer, unsigned long length) {
    return syscall3(SYS_READ, fd, (long)buffer, (long)length);
}

static inline long sys_close(int fd) {
    return syscall3(SYS_CLOSE, fd, 0, 0);
}

static inline long sys_unlink(const char* path) {
    return syscall3(SYS_UNLINK, (long)path, 0, 0);
}

static inline long sys_exit(int status) {
    return syscall3(SYS_EXIT, status, 0, 0);
}

static inline long sys_wait(unsigned long pid, int* status) {
    return syscall3(SYS_WAIT, pid, (long)status, 0);
}
static inline long sys_wait_nohang(unsigned long pid, int* status) {
    return syscall3(SYS_WAIT, pid, (long)status, 1);
}

static inline long sys_spawn(const char* path) {
    return syscall3(SYS_SPAWN, (long)path, 0, 0);
}
static inline long sys_spawnv(const char* path, const char* const argv[]) {
    return syscall3(SYS_SPAWN, (long)path, (long)argv, 0);
}

static inline long sys_list(void* buffer, unsigned long length) {
    return syscall3(SYS_LIST, (long)buffer, length, 0);
}

static inline long sys_exec(const char* path) {
    return syscall3(SYS_EXEC, (long)path, 0, 0);
}
static inline long sys_execv(const char* path, const char* const argv[]) {
    return syscall3(SYS_EXEC, (long)path, (long)argv, 0);
}

static inline long sys_fork(void) {
    return syscall3(SYS_FORK, 0, 0, 0);
}

static inline long sys_send(unsigned long pid, const struct ipc_message* message) {
    return syscall3(SYS_SEND, (long)pid, (long)message, 0);
}

static inline long sys_receive(long source_pid, struct ipc_message* message) {
    return syscall3(SYS_RECEIVE, source_pid, (long)message, 0);
}

static inline long sys_thread_create(void (*entry)(void*), void* arg) {
    return syscall3(SYS_THREAD_CREATE, (long)entry, (long)arg, 0);
}

static inline long sys_thread_join(unsigned long tid, int* status) {
    return syscall3(SYS_THREAD_JOIN, (long)tid, (long)status, 0);
}

static inline long sys_thread_exit(int status) {
    return syscall3(SYS_THREAD_EXIT, status, 0, 0);
}

static inline long sys_gettid(void) {
    return syscall3(SYS_GETTID, 0, 0, 0);
}

static inline long sys_futex_wait(volatile unsigned int* address,
                                  unsigned int expected) {
    return syscall3(SYS_FUTEX_WAIT, (long)address, expected, 0);
}

static inline long sys_futex_wake(volatile unsigned int* address,
                                  unsigned int count) {
    return syscall3(SYS_FUTEX_WAKE, (long)address, count, 0);
}

static inline long sys_thread_detach(unsigned long tid) {
    return syscall3(SYS_THREAD_DETACH, (long)tid, 0, 0);
}

static inline long sys_thread_yield(void) {
    return syscall3(SYS_THREAD_YIELD, 0, 0, 0);
}

/* 当前阶段只实现匿名 MAP_PRIVATE；flags 由内核按 ABI 的高 8 位解析。 */
static inline void* sys_mmap(void* hint, unsigned long length,
                             unsigned long prot, unsigned long flags) {
    long result = syscall3(SYS_MMAP, (long)hint, (long)length,
                           (long)(prot | (flags << 8)));
    return result < 0 ? (void*)0 : (void*)result;
}

static inline long sys_munmap(void* address, unsigned long length) {
    return syscall3(SYS_MUNMAP, (long)address, (long)length, 0);
}

static inline long sys_mkdir(const char* path) { return syscall3(SYS_MKDIR, (long)path, 0, 0); }
static inline long sys_stat(const char* path, struct sys_stat* out) {
    return syscall3(SYS_STAT, (long)path, (long)out, 0);
}
static inline long sys_chdir(const char* path) { return syscall3(SYS_CHDIR, (long)path, 0, 0); }
static inline long sys_getcwd(char* buffer, unsigned long length) {
    return syscall3(SYS_GETCWD, (long)buffer, length, 0);
}
static inline long sys_dup(int fd) { return syscall3(SYS_DUP, fd, 0, 0); }
static inline long sys_dup2(int oldfd, int newfd) { return syscall3(SYS_DUP2, oldfd, newfd, 0); }
static inline long sys_pipe(int fds[2]) { return syscall3(SYS_PIPE, (long)fds, 0, 0); }
static inline long sys_getpid(void) { return syscall3(SYS_GETPID, 0, 0, 0); }
static inline long sys_clear(void) { return syscall3(SYS_CLEAR, 0, 0, 0); }
static inline long sys_sleep(unsigned long ticks) {
    return syscall3(SYS_SLEEP, (long)ticks, 0, 0);
}
static inline long sys_kill(unsigned long pid, int signal) {
    return syscall3(SYS_KILL, (long)pid, signal, 0);
}

struct sys_process_info {
    unsigned int pid;
    unsigned int ppid;
    unsigned int state;
    unsigned int threads;
    unsigned int user_pages;
    unsigned int name_length;
    char name[32];
};

static inline long sys_ps(struct sys_process_info* buffer,
                           unsigned long count) {
    return syscall3(SYS_PS, (long)buffer, count, 0);
}

#endif
