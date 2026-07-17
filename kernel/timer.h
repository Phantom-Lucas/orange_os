// kernel/timer.h

#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>
extern volatile uint64_t system_ticks; // 系统时钟滴答数
// 初始化 8253 PIT 时钟
void timer_init(void);

void timer_interrupt_handler(void);

#endif