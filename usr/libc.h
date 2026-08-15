#ifndef ORANGES_LIBC_H
#define ORANGES_LIBC_H

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include "syscall.h"
#include "thread_runtime.h"

typedef int32_t pid_t;
typedef int64_t ssize_t;

#define LIBC_EINVAL 22
#define LIBC_ENOMEM 12
#define LIBC_ECHILD 10
#define LIBC_EINTR  4

int* __errno_location(void);
#define errno (*__errno_location())

void* malloc(size_t size);
void* calloc(size_t count, size_t size);
void* realloc(void* pointer, size_t size);
void free(void* pointer);

size_t strlen(const char* string);
int strcmp(const char* left, const char* right);
int strncmp(const char* left, const char* right, size_t length);
char* strcpy(char* destination, const char* source);
char* strncpy(char* destination, const char* source, size_t length);
void* memcpy(void* destination, const void* source, size_t length);
void* memmove(void* destination, const void* source, size_t length);
void* memset(void* destination, int value, size_t length);
int memcmp(const void* left, const void* right, size_t length);

int vsnprintf(char* buffer, size_t length, const char* format, va_list arguments);
int snprintf(char* buffer, size_t length, const char* format, ...);
int printf(const char* format, ...);
int puts(const char* string);

int open(const char* path, int flags);
ssize_t read(int fd, void* buffer, size_t length);
ssize_t write(int fd, const void* buffer, size_t length);
int close(int fd);
int unlink(const char* path);
int mkdir(const char* path);
int stat(const char* path, struct sys_stat* result);
int chdir(const char* path);
char* getcwd(char* buffer, size_t length);
int dup(int fd);
int dup2(int oldfd, int newfd);
int pipe(int fds[2]);

pid_t getpid(void);
pid_t fork(void);
pid_t waitpid(pid_t pid, int* status);
int execv(const char* path, char* const argv[]);
void exit(int status) __attribute__((noreturn));
void _exit(int status) __attribute__((noreturn));
unsigned long sleep(unsigned long ticks);
int kill(pid_t pid, int signal);
long ps(struct sys_process_info* buffer, size_t count);

typedef user_mutex_t mutex_t;
typedef user_cond_t cond_t;
static inline void mutex_init(mutex_t* mutex) { user_mutex_init(mutex); }
static inline int mutex_lock(mutex_t* mutex) { return user_mutex_lock(mutex); }
static inline int mutex_unlock(mutex_t* mutex) { return user_mutex_unlock(mutex); }
static inline void cond_init(cond_t* condition) { user_cond_init(condition); }
static inline int cond_wait(cond_t* condition, mutex_t* mutex) {
    return user_cond_wait(condition, mutex);
}
static inline int cond_signal(cond_t* condition) { return user_cond_signal(condition); }
static inline int cond_broadcast(cond_t* condition) {
    return user_cond_broadcast(condition);
}

static inline long thread_create(void (*entry)(void*), void* argument) {
    return sys_thread_create(entry, argument);
}
static inline int thread_join(unsigned long tid, int* status) {
    return (int)sys_thread_join(tid, status);
}
static inline int thread_detach(unsigned long tid) {
    return (int)sys_thread_detach(tid);
}
static inline void thread_exit(int status) __attribute__((noreturn));
static inline void thread_exit(int status) {
    (void)sys_thread_exit(status);
    for (;;) { }
}

#endif
