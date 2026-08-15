// usr/hello.c
#include "syscall.h"

static void write_text(const char* text, unsigned long length) {
    (void)sys_write(1, text, length);
}

void _start() {
    static const char hello[] = "[Ring 3] SYS_WRITE is working.\n";
    static const char ticks_ok[] = "[Ring 3] SYS_GET_TICKS is working.\n";
    static const char fs_ok[] = "[Ring 3] open/read/write/close/unlink are working.\n";
    static const char fs_fail[] = "[Ring 3] file syscall self-test FAILED.\n";
    static const char fork_ok[] = "[Ring 3] fork/exit/wait are working.\n";
    static const char fork_fail[] = "[Ring 3] fork/exit/wait self-test FAILED.\n";
    static const char filename[] = "user-selftest";
    static const char payload[] = "user file payload";
    char readback[sizeof(payload)];

    write_text(hello, sizeof(hello) - 1);

    unsigned long ticks = sys_get_ticks();
    while (sys_get_ticks() == ticks) {
        __asm__ volatile ("pause");
    }
    write_text(ticks_ok, sizeof(ticks_ok) - 1);

    (void)sys_unlink(filename);
    long fd = sys_open(filename, O_CREATE);
    long written = fd >= 0 ? sys_write((int)fd, payload, sizeof(payload) - 1) : -1;
    long closed = fd >= 0 ? sys_close((int)fd) : -1;
    fd = sys_open(filename, 0);
    long read = fd >= 0 ? sys_read((int)fd, readback, sizeof(payload) - 1) : -1;
    if (fd >= 0) (void)sys_close((int)fd);

    int matches = 1;
    for (unsigned long i = 0; i < sizeof(payload) - 1; i++) {
        if (readback[i] != payload[i]) matches = 0;
    }
    if (written == (long)(sizeof(payload) - 1) && closed == 0 &&
        read == written && matches && sys_unlink(filename) == 0) {
        write_text(fs_ok, sizeof(fs_ok) - 1);
    } else {
        write_text(fs_fail, sizeof(fs_fail) - 1);
    }

    long child_pid = sys_fork();
    int final_status = 42;
    if (child_pid == 0) {
        (void)sys_exit(7);
    } else if (child_pid > 0) {
        int child_status = -1;
        if (sys_wait((unsigned long)child_pid, &child_status) == child_pid && child_status == 7) {
            write_text(fork_ok, sizeof(fork_ok) - 1);
        } else {
            write_text(fork_fail, sizeof(fork_fail) - 1);
            final_status = 1;
        }
    } else {
        write_text(fork_fail, sizeof(fork_fail) - 1);
        final_status = 1;
    }

    (void)sys_exit(final_status);
    while (1) __asm__ volatile ("pause");
}
