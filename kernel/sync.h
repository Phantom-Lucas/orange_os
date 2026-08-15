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

/*
 * 分配器锁约束：本地中断处理程序不得在持有同一把锁的上下文中重入
 * PMM/kmalloc；spinlock_acquire 会关闭本地中断，避免这种重入死锁。
 * 当前全局锁顺序为 address-space(调用方序列化) -> heap -> PMM；PMM
 * 临界区内不得调用 kmalloc、页表创建或任何可能再次分配的代码。
 */

typedef struct {
    spinlock_t guard;   // 用于保护 Mutex 自身状态的极短自旋锁
    uint32_t is_locked; // 0 表示可用，1 表示被占用
} mutex_t;

void mutex_init(mutex_t* lock);
void mutex_acquire(mutex_t* lock);
void mutex_release(mutex_t* lock);



#endif
