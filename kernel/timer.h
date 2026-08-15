// kernel/timer.h

#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>
struct thread;
extern volatile uint64_t system_ticks; // 系统时钟滴答数

// 初始化 8253 PIT 时钟
void timer_init(void);

// 时钟中断处理函数
void timer_interrupt_handler(void);

/* 让当前线程阻塞到指定 tick；不在忙等循环中消耗时间片。 */
void thread_sleep_ticks(uint64_t ticks);
void timer_cancel_thread_sleep(struct thread* thread);
void timer_wake_sleepers(void);

#endif
