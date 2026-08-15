#ifndef USER_THREAD_RUNTIME_H
#define USER_THREAD_RUNTIME_H

#include <stdint.h>
#include "syscall.h"

/*
 * 用户态同步对象不包含内核指针：正常路径只修改用户内存，只有
 * contention 才通过 futex 让出 CPU。state=2 表示至少有一个 waiter。
 */
typedef struct {
    volatile uint32_t state;
    volatile uint32_t owner_tid;
} user_mutex_t;

typedef struct {
    volatile uint32_t sequence;
} user_cond_t;

struct user_tls {
    uint64_t self;
    int errno_value;
    uint32_t reserved;
    uint64_t custom_value;
};

static inline void user_mutex_init(user_mutex_t* mutex)
{
    mutex->state = 0;
    mutex->owner_tid = 0;
}

static inline int user_mutex_lock(user_mutex_t* mutex)
{
    uint32_t expected = 0;
    uint32_t tid = (uint32_t)sys_gettid();

    if (__atomic_compare_exchange_n(&mutex->state, &expected, 1, 0,
                                    __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        __atomic_store_n(&mutex->owner_tid, tid, __ATOMIC_RELAXED);
        return 0;
    }
    for (;;) {
        /*
         * State 1 means locked without a known waiter; state 2 means
         * locked with contention.  A waiter may promote 1 to 2, but it
         * must not treat that promotion as acquiring the mutex: the
         * current owner may still be running.  Only a 0 -> 1 transition
         * transfers ownership.
         */
        expected = 1;
        (void)__atomic_compare_exchange_n(&mutex->state, &expected, 2, 0,
                                          __ATOMIC_ACQ_REL,
                                          __ATOMIC_RELAXED);
        if (expected == 0) continue;
        (void)sys_futex_wait(&mutex->state, 2);
    }
}

static inline int user_mutex_unlock(user_mutex_t* mutex)
{
    uint32_t tid = (uint32_t)sys_gettid();
    if (__atomic_load_n(&mutex->owner_tid, __ATOMIC_RELAXED) != tid) return -1;
    uint32_t state;
    state = __atomic_load_n(&mutex->state, __ATOMIC_RELAXED);
    if (state == 0) return -1;
    __atomic_store_n(&mutex->owner_tid, 0, __ATOMIC_RELAXED);
    state = __atomic_exchange_n(&mutex->state, 0, __ATOMIC_RELEASE);
    if (state == 2) (void)sys_futex_wake(&mutex->state, 1);
    return 0;
}

static inline void user_cond_init(user_cond_t* condition)
{
    condition->sequence = 0;
}

/* 返回前一定重新取得 mutex；调用者必须重新检查自己的条件谓词。 */
static inline int user_cond_wait(user_cond_t* condition,
                                 user_mutex_t* mutex)
{
    uint32_t sequence = __atomic_load_n(&condition->sequence,
                                        __ATOMIC_ACQUIRE);
    if (user_mutex_unlock(mutex) != 0) return -1;
    (void)sys_futex_wait(&condition->sequence, sequence);
    return user_mutex_lock(mutex);
}

static inline int user_cond_signal(user_cond_t* condition)
{
    __atomic_fetch_add(&condition->sequence, 1, __ATOMIC_RELEASE);
    return (int)sys_futex_wake(&condition->sequence, 1);
}

static inline int user_cond_broadcast(user_cond_t* condition)
{
    __atomic_fetch_add(&condition->sequence, 1, __ATOMIC_RELEASE);
    return (int)sys_futex_wake(&condition->sequence, 0xFFFFFFFFU);
}

static inline int* user_errno_location(void)
{
    uint64_t base;
    __asm__ volatile("movq %%fs:0, %0" : "=r"(base));
    return (int*)(base + 8);
}

static inline uint64_t* user_custom_tls_location(void)
{
    uint64_t base;
    __asm__ volatile("movq %%fs:0, %0" : "=r"(base));
    return (uint64_t*)(base + 16);
}

static inline void user_tls_set_custom(uint64_t value)
{
    *user_custom_tls_location() = value;
}

static inline uint64_t user_tls_get_custom(void)
{
    return *user_custom_tls_location();
}

#endif
