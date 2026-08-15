#ifndef SYSCALL_H
#define SYSCALL_H

#include <stdint.h>

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

#define WAIT_NOHANG       0x1U
#define SIGNAL_TERM      15
#define SIGNAL_KILL      9

#define O_CREATE       0x01

#define SYSCALL_ERR_INVAL ((uint64_t)-1)

void syscall_init(void);
uint64_t syscall_handler(uint64_t sys_num, uint64_t arg1, uint64_t arg2, uint64_t arg3,
                         uint64_t syscall_frame_rsp);
void resume_user_image(uint64_t rip, uint64_t rsp, uint64_t cr3) __attribute__((noreturn));

#endif
