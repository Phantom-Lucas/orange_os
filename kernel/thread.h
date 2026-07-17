// kernel/thread.h
#ifndef THREAD_H
#define THREAD_H

#include <stdint.h>

// ===================================
// 【新增】定义线程的两种基本状态
// ===================================
#define TASK_READY   0   // 就绪态：可以被分配 CPU
#define TASK_BLOCKED 1   // 阻塞态：正在睡觉，不能被分配 CPU

struct thread_context {
    uint64_t r15;
    uint64_t r14;
    uint64_t r13;
    uint64_t r12;
    uint64_t rbx;
    uint64_t rbp;
    uint64_t rip;
} __attribute__((packed));

struct task_struct {
    uint64_t rsp;              // 偏移 0：栈指针
    uint64_t *stack_base;      // 记录申请的 4KB 地址
    
    // --- 战役二新增 ---
    uint32_t ticks;            // 当前剩余时间片(比如 10 个 tick)
    uint32_t priority;         // 默认时间片大小(用于 ticks 归零后重置)
    struct task_struct* next;  // 形成简单的单向循环链表
    
    // ===================================
    // 【新增】为了 Mutex 设计的状态字段
    // ===================================
    uint32_t status;           // 当前状态 (READY 或 BLOCKED)
    void* waiting_lock;        // 记录本线程正在等哪把锁

     uint64_t kernel_stack_top; // 内核栈顶地址，用于中断处理
};

struct task_struct* process_create(void (*app_func)(void), uint32_t priority);
// 暴露全局变量和函数
extern struct task_struct* current_thread;
void schedule(void);
struct task_struct* thread_create(void (*function)(void), uint32_t priority);
void thread_append(struct task_struct* thread);

void thread_yield(void); // 【新增】主动让出 CPU，呼叫调度器
#endif