// kernel/timer.c

// kernel/timer.c

#include "timer.h"
#include "io.h"      
#include "print.h"
#include <stdint.h>
#include "thread.h"  // 【新增】引入线程控制结构和 schedule()

#define PIT_CTRL_PORT 0x43
#define PIT_DATA_PORT 0x40

volatile uint64_t system_ticks = 0;

void timer_init(void) {
    uint32_t frequency = 100;
    uint32_t divisor = 1193180 / frequency; 

    outb(PIT_CTRL_PORT, 0x36);
    outb(PIT_DATA_PORT, (uint8_t)(divisor & 0xFF));
    outb(PIT_DATA_PORT, (uint8_t)((divisor >> 8) & 0xFF));

    print_string("[INFO] PIT 8253 Timer initialized at 100Hz.\n");
}

// 【新增】时钟中断的真正处理函数
// 这个函数需要每 10ms (100Hz) 被你的硬件中断 IRQ0 调用一次
void timer_interrupt_handler(void) {
    
    // 【避坑警告：极其重要！】
    // 因为等一下 schedule() 可能会切换到别的线程，导致当前函数暂时无法 return 返回。
    // 如果不提前向 PIC（可编程中断控制器）发送 EOI (End of Interrupt) 信号，
    // PIC 会以为本次中断还没处理完，从而死锁，再也不会发出下一次时钟中断！
    // 向主 PIC (端口 0x20) 发送 EOI 信号 (命令 0x20)
    outb(0x20, 0x20); 
    system_ticks++; // 系统滴答数 +1
    // 如果还没有创建任何线程（或者 current_thread 未初始化），直接退出，什么都不做
    if (current_thread == 0) {
        return;
    }

    // 走到这里，说明多任务系统已经启动
    // 1. 扣除当前正在运行线程的时间片
    current_thread->ticks--;

    // 2. 如果时间片耗尽 (归零)
    if (current_thread->ticks == 0) {
        // 重置该线程的时间片，等下次轮到它时可以继续跑
        current_thread->ticks = current_thread->priority;
        
        // 呼叫调度器，切换到下一个线程！
        schedule(); 
    }
}