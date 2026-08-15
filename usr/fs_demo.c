#include "syscall.h"

static unsigned long slen(const char* s) { unsigned long n = 0; while (s[n]) n++; return n; }
static int same(const char* a, const char* b) {
    unsigned long i = 0; while (a[i] && b[i] && a[i] == b[i]) i++;
    return a[i] == b[i];
}
static void out(const char* s) { (void)sys_write(1, s, slen(s)); }

void _start(void) {
    static const char dir[] = "fs-test";
    static const char file[] = "note";
    static const char payload[] = "abcdef";
    static const char pipe_data[] = "pipe-data";
    static const char shared_parent[] = "parent";
    static const char shared_child[] = "-child";
    static const char pass[] = "fs demo PASSED\n";
    static const char fail[] = "fs demo FAILED\n";
    char cwd[64] = {0}, data[sizeof(payload) + 1] = {0};
    char pipe_readback[sizeof(pipe_data)] = {0};
    struct sys_stat st;
    int ok = 1;
    (void)sys_unlink(file);
    (void)sys_chdir("/");
    if (sys_mkdir(dir) != 0 || sys_chdir(dir) != 0) ok = 0;
    if (sys_getcwd(cwd, sizeof(cwd)) < 0 || !same(cwd, "/fs-test")) ok = 0;
    long fd = sys_open(file, O_CREATE);
    if (fd < 0 || sys_write((int)fd, payload, sizeof(payload) - 1) != sizeof(payload) - 1) ok = 0;
    long duplicate = fd >= 0 ? sys_dup((int)fd) : -1;
    if (duplicate < 0 || sys_write((int)duplicate, "X", 1) != 1) ok = 0;
    if (duplicate >= 0) (void)sys_close((int)duplicate);
    if (fd >= 0) (void)sys_close((int)fd);
    fd = sys_open(file, 0);
    if (fd < 0 || sys_read((int)fd, data, sizeof(payload)) != sizeof(payload)) ok = 0;
    if (!same(data, "abcdefX")) ok = 0;
    if (fd >= 0) (void)sys_close((int)fd);
    if (sys_stat(file, &st) != 0 || st.type != FS_TYPE_FILE || st.size != sizeof(payload)) ok = 0;
    int fds[2] = {-1, -1};
    if (sys_pipe(fds) != 0 || sys_write(fds[1], pipe_data, sizeof(pipe_data) - 1) != sizeof(pipe_data) - 1 ||
        sys_read(fds[0], pipe_readback, sizeof(pipe_readback) - 1) != sizeof(pipe_data) - 1 ||
        !same(pipe_readback, pipe_data)) ok = 0;
    if (fds[0] >= 0) (void)sys_close(fds[0]);
    if (fds[1] >= 0) (void)sys_close(fds[1]);

    /* 标准输出重定向回归：dup2 将普通文件安装到 fd 1，关闭后恢复
       TTY 回退路径；O_TRUNC 还要保证旧内容不会残留。 */
    (void)sys_unlink("redirect");
    fd = sys_open("redirect", O_CREATE);
    if (fd < 0 || sys_write((int)fd, "stale-data", 10) != 10) ok = 0;
    if (fd >= 0) (void)sys_close((int)fd);
    fd = sys_open("redirect", O_CREATE | O_TRUNC);
    if (fd < 0 || sys_dup2((int)fd, 1) != 1) {
        ok = 0;
    } else {
        (void)sys_close((int)fd);
        if (sys_write(1, "redirect-ok", 11) != 11) ok = 0;
        if (sys_close(1) != 0) ok = 0;
    }
    fd = sys_open("redirect", 0);
    char redirect_readback[12] = {0};
    if (fd < 0 || sys_read((int)fd, redirect_readback, 11) != 11 ||
        !same(redirect_readback, "redirect-ok")) ok = 0;
    if (fd >= 0) (void)sys_close((int)fd);
    if (sys_unlink("redirect") != 0) ok = 0;

    /* 跨进程文件表回归：fork 继承同一个 open file description，父子
       顺序写入共享 offset，子进程退出后父进程仍能 close/read。 */
    (void)sys_unlink("shared");
    fd = sys_open("shared", O_CREATE);
    if (fd < 0 || sys_write((int)fd, shared_parent,
                            sizeof(shared_parent) - 1) !=
                   (long)(sizeof(shared_parent) - 1)) {
        ok = 0;
    } else {
        long child = sys_fork();
        if (child == 0) {
            int child_ok = sys_write((int)fd, shared_child,
                                     sizeof(shared_child) - 1) ==
                           (long)(sizeof(shared_child) - 1);
            (void)sys_close((int)fd);
            (void)sys_exit(child_ok ? 0 : 1);
        } else if (child < 0) {
            ok = 0;
        } else {
            int child_status = -1;
            if (sys_wait((unsigned long)child, &child_status) != child ||
                child_status != 0) ok = 0;
        }
    }
    if (fd >= 0) (void)sys_close((int)fd);
    fd = sys_open("shared", 0);
    char shared_readback[sizeof(shared_parent) + sizeof(shared_child) - 1] = {0};
    if (fd < 0 || sys_read((int)fd, shared_readback,
                           sizeof(shared_readback) - 1) !=
                   (long)(sizeof(shared_readback) - 1) ||
        !same(shared_readback, "parent-child")) ok = 0;
    if (fd >= 0) (void)sys_close((int)fd);
    if (sys_unlink("shared") != 0) ok = 0;

    if (sys_chdir("..") != 0 || sys_getcwd(cwd, sizeof(cwd)) < 0 || !same(cwd, "/")) ok = 0;
    if (sys_unlink("/fs-test/note") != 0) ok = 0;
    if (sys_unlink("/fs-test") != 0) ok = 0;
    out(ok ? pass : fail);
    (void)sys_exit(ok ? 0 : 1);
    while (1) __asm__ volatile("pause");
}
