#include "sync.h"
#include "thread.h"

void spinlock_init(spinlock_t* lock) {
    lock->lock_flag = 0;
    lock->saved_rflags = 0;
}

void spinlock_acquire(spinlock_t* lock) {
    uint64_t rflags;
    
    // 1. 读取当前的 CPU 状态寄存器 (RFLAGS) 并存入变量 rflags
    asm volatile("pushfq; popq %0" : "=r"(rflags));
    
    // 2. 关中断，防止在临界区被时钟抢占
    asm volatile("cli");
    thread_preempt_disable();

    // 3. 自旋等待别人释放锁。
    //
    // 这里不能为了让时钟中断运行而重新打开 IF：如果中断处理程序
    // 重入同一把锁，它会在当前 CPU 上永远等自己释放锁。所有持锁者
    // 都在关中断状态下运行，因此持锁者不会被本地时钟中断抢走。
    while (__sync_lock_test_and_set(&lock->lock_flag, 1) == 1) {
        asm volatile("pause");
    }
    
    // 4. 抢到锁后，把最初的状态保存在锁里
    lock->saved_rflags = rflags;
}

void spinlock_release(spinlock_t* lock) {
    // 1. 提取出这把锁原本始保存的状态
    uint64_t rflags = lock->saved_rflags;
    
    // 2. 原子操作：释放锁
    __sync_lock_release(&lock->lock_flag);
    thread_preempt_enable();
    
    // 3. 完美还原状态：如果上锁前是开中断的（IF位为1），现在才开中断；
    // 如果上锁前是关中断的（比如正在 kernel_main 初始化），就继续保持关中断！
    if (rflags & (1 << 9)) {
        asm volatile("sti");
    }
}

void mutex_init(mutex_t* m) {
    spinlock_init(&m->guard);
    m->is_locked = 0;
}

void mutex_acquire(mutex_t* m) {
    while (1) {
        // 先用自旋锁保护一下状态检查
        spinlock_acquire(&m->guard);
        
        if (m->is_locked == 0) {
            // 没人用！我占用了！
            m->is_locked = 1;
            spinlock_release(&m->guard);
            return; // 成功拿到锁，退出函数
        }
        
        // 走到这里，说明锁被别人拿着。
        // 我们不自旋死等，我们要主动休眠！
        current_thread->waiting_lock = m;
        
        // 【关键】：休眠前，必须把自旋锁还回去，否则别人连释放锁的机会都没了！
        spinlock_release(&m->guard);
        
        // 接下来，线程进入休眠循环。
        // 因为状态已经变成了 BLOCKED，时钟中断触发的 schedule() 会彻底无视本线程。
        // 我们只需用 hlt 挂起 CPU 节省算力，直到有人把我们的状态改回 READY。
        thread_block();

        // 被唤醒后重新检查锁状态。
    }
}
void mutex_release(mutex_t* m) {
    spinlock_acquire(&m->guard);
    m->is_locked = 0; // 释放锁
    
    int woke_someone = 0; // 【新增】记录是否唤醒了别人
    
    if (current_thread != 0) {
        struct thread* temp = current_thread->next;
        while (temp != current_thread) {
            if (temp->status == TASK_BLOCKED && temp->waiting_lock == m) {
                thread_unblock(temp);
                woke_someone = 1; // 【标记】我叫醒了一个兄弟！
                break; 
            }
            temp = temp->next;
        }
    }
    spinlock_release(&m->guard);
    
    // ==========================================
    // 【核心机制：唤醒抢占】
    // 如果我刚才唤醒了别人，那我就好人做到底，主动放弃剩下的时间片！
    // ==========================================
    if (woke_someone) thread_request_reschedule();
}
