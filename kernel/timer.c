// kernel/timer.c

#include "timer.h"
#include "io.h"      
#include "print.h"
#include <stdint.h>
#include "thread.h"
#include "sync.h"

#define PIT_CTRL_PORT 0x43
#define PIT_DATA_PORT 0x40

volatile uint64_t system_ticks = 0;
static spinlock_t sleep_lock;
static struct thread* sleep_head;

static void sleep_unlink_locked(struct thread* victim)
{
    struct thread** link = &sleep_head;
    while (*link != 0 && *link != victim) link = &(*link)->sleep_next;
    if (*link == victim) *link = victim->sleep_next;
    victim->sleep_next = 0;
    victim->sleeping = 0;
}

void timer_cancel_thread_sleep(struct thread* thread)
{
    if (thread == 0 || !thread->sleeping) return;
    spinlock_acquire(&sleep_lock);
    if (thread->sleeping) sleep_unlink_locked(thread);
    spinlock_release(&sleep_lock);
}

void timer_wake_sleepers(void)
{
    spinlock_acquire(&sleep_lock);
    while (sleep_head != 0 && sleep_head->wake_tick <= system_ticks) {
        struct thread* thread = sleep_head;
        sleep_head = thread->sleep_next;
        thread->sleep_next = 0;
        thread->sleeping = 0;
        if (thread->status == TASK_BLOCKED) thread_unblock(thread);
    }
    spinlock_release(&sleep_lock);
}

void timer_init(void) {
    spinlock_init(&sleep_lock);
    sleep_head = 0;
    uint32_t frequency = 100;
    uint32_t divisor = 1193180 / frequency; 

    outb(PIT_CTRL_PORT, 0x36);
    outb(PIT_DATA_PORT, (uint8_t)(divisor & 0xFF));
    outb(PIT_DATA_PORT, (uint8_t)((divisor >> 8) & 0xFF));

    print_debug("[INFO] PIT 8253 Timer initialized at 100Hz.\n");
}

void thread_sleep_ticks(uint64_t ticks)
{
    uint64_t flags;
    int user_gs = current_thread != 0 && current_thread->process != kernel_process;
    if (current_thread == 0 || ticks == 0) {
        if (current_thread != 0) thread_yield();
        return;
    }
    __asm__ volatile("pushfq; popq %0" : "=r"(flags));
    __asm__ volatile("cli");
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    spinlock_acquire(&sleep_lock);
    if (!current_thread->sleeping) {
        struct thread** link;
        current_thread->wake_tick = system_ticks + ticks;
        current_thread->sleeping = 1;
        link = &sleep_head;
        while (*link != 0 && (*link)->wake_tick <= current_thread->wake_tick) {
            link = &(*link)->sleep_next;
        }
        current_thread->sleep_next = *link;
        *link = current_thread;
    }
    spinlock_release(&sleep_lock);
    current_thread->status = TASK_BLOCKED;
    schedule();
    while (current_thread->status == TASK_BLOCKED) {
        __asm__ volatile("sti; hlt; cli" ::: "memory");
        schedule();
    }
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    __asm__ volatile("pushq %0; popfq" :: "r"(flags) : "memory", "cc");
}

// 这个函数需要每 10ms (100Hz) 被你的硬件中断 IRQ0 调用一次
void timer_interrupt_handler(void) {
    
    // 因为等一下 schedule() 可能会切换到别的线程，导致当前函数暂时无法 return 返回。
    // 如果不提前向 PIC（可编程中断控制器）发送 EOI (End of Interrupt) 信号，
    // PIC 会以为本次中断还没处理完，从而死锁，再也不会发出下一次时钟中断！
    // 向主 PIC (端口 0x20) 发送 EOI 信号 (命令 0x20)
    outb(0x20, 0x20); 
    system_ticks++; // 系统滴答数 +1
    timer_wake_sleepers();
    // 如果还没有创建任何线程（或者 current_thread 未初始化），直接退出，什么都不做
    if (current_thread == 0) {
        return;
    }

    // 走到这里，说明多任务系统已经启动
    // 1. 扣除当前正在运行线程的时间片
    current_thread->ticks--;

    // 2. 如果时间片耗尽 (归零)，只请求抢占，不在任意中间位置切换。
    if (current_thread->ticks == 0) {
        // 重置该线程的时间片，等下次轮到它时可以继续跑
        current_thread->ticks = current_thread->priority;
        
        thread_request_reschedule();
    }

    /* 定时器处理函数的末尾是本架构的抢占安全点：此时已经 EOI，且
       PMM/堆自旋锁会关闭 IF，不会在持有自旋锁时进入这里。 */
    thread_preempt_point();
}
