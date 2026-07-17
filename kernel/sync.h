#ifndef SYNC_H
#define SYNC_H

#include <stdint.h>

typedef struct {
    uint32_t lock_flag;
    uint64_t saved_rflags; // 【新增】用来记住上锁前的 CPU 状态
} spinlock_t;

void spinlock_init(spinlock_t* lock);
void spinlock_acquire(spinlock_t* lock);
void spinlock_release(spinlock_t* lock);

typedef struct {
    spinlock_t guard;   // 用于保护 Mutex 自身状态的极短自旋锁
    uint32_t is_locked; // 0 表示可用，1 表示被占用
} mutex_t;

void mutex_init(mutex_t* lock);
void mutex_acquire(mutex_t* lock);
void mutex_release(mutex_t* lock);



#endif