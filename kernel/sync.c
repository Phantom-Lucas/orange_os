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

    // 3. 自旋等待别人释放锁
    while (__sync_lock_test_and_set(&lock->lock_flag, 1) == 1) {
        // 如果系统已经处于开中断阶段，别人占着锁，我们需要短暂开一下中断
        // 让时钟可以滴答，否则会死锁
        if (rflags & (1 << 9)) { // 第 9 位是 IF (Interrupt Flag)
            asm volatile("sti");
            asm volatile("nop");
            asm volatile("cli");
        }
    }
    
    // 4. 抢到锁后，把最初的状态保存在锁里
    lock->saved_rflags = rflags;
}

void spinlock_release(spinlock_t* lock) {
    // 1. 提取出这把锁原本始保存的状态
    uint64_t rflags = lock->saved_rflags;
    
    // 2. 原子操作：释放锁
    __sync_lock_release(&lock->lock_flag);
    
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
        current_thread->status = TASK_BLOCKED;
        current_thread->waiting_lock = m;
        
        // 【关键】：休眠前，必须把自旋锁还回去，否则别人连释放锁的机会都没了！
        spinlock_release(&m->guard);
        
        // 接下来，线程进入休眠循环。
        // 因为状态已经变成了 BLOCKED，时钟中断触发的 schedule() 会彻底无视本线程。
        // 我们只需用 hlt 挂起 CPU 节省算力，直到有人把我们的状态改回 READY。
        while (current_thread->status == TASK_BLOCKED) {
            asm volatile("sti; hlt"); 
        }
        
        // 如果代码执行到了这里，说明有人调用 mutex_release 唤醒了我们！
        // 循环会回到最外层的 while(1)，我们再次尝试去抢锁。
    }
}
void mutex_release(mutex_t* m) {
    spinlock_acquire(&m->guard);
    m->is_locked = 0; // 释放锁
    
    int woke_someone = 0; // 【新增】记录是否唤醒了别人
    
    if (current_thread != 0) {
        struct task_struct* temp = current_thread->next;
        while (temp != current_thread) {
            if (temp->status == TASK_BLOCKED && temp->waiting_lock == m) {
                temp->status = TASK_READY;
                temp->waiting_lock = 0;
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
    if (woke_someone) {
        // 关中断，保护 schedule 函数不被时钟打断
        asm volatile("cli");
        
        // 强行呼叫上帝之手，把 CPU 立刻切给刚才被唤醒的人！
        schedule();          
        
        // 当未来某一天 CPU 再次切回我这里时，再恢复开中断
        asm volatile("sti"); 
    }
}