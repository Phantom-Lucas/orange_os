// kernel/timer.c

#include "timer.h"
#include "io.h"      // 你之前写的用于 outb/inb 的汇编封装头文件
#include "print.h"
#include <stdint.h>

#define PIT_CTRL_PORT 0x43
#define PIT_DATA_PORT 0x40

void timer_init(void) {
    // 设置频率为 100Hz (也就是每秒触发 100 次时钟中断，每 10ms 触发一次)
    uint32_t frequency = 100;
    // 1193180 是主板硬件晶振的固有频率
    uint32_t divisor = 1193180 / frequency; 

    // 发送控制字 0x36：通道 0，工作模式 3 (方波)，先写低字节再写高字节
    outb(PIT_CTRL_PORT, 0x36);

    // 拆分出低 8 位并写入
    outb(PIT_DATA_PORT, (uint8_t)(divisor & 0xFF));
    // 拆分出高 8 位并写入
    outb(PIT_DATA_PORT, (uint8_t)((divisor >> 8) & 0xFF));

    print_string("[INFO] PIT 8253 Timer initialized at 100Hz.\n");
}