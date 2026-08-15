#ifndef THREAD_H
#define THREAD_H

#include <stdint.h>
#include "ipc.h"
#include "process.h"

typedef enum {
    TASK_READY = 0,
    TASK_RUNNING,
    TASK_BLOCKED,
    TASK_ZOMBIE,
    TASK_DEAD
} thread_state_t;

/* 调度状态和生命周期状态是两个正交维度：BLOCKED 线程仍可 join，
 * DETACHED 线程退出后由调度器自动回收。 */
typedef enum {
    THREAD_JOINABLE_RUNNING = 0,
    THREAD_JOINABLE_ZOMBIE,
    THREAD_DETACHED_RUNNING,
    THREAD_DETACHED_ZOMBIE,
    THREAD_REAPED
} thread_lifecycle_t;

struct thread_context {
    uint64_t r15;
    uint64_t r14;
    uint64_t r13;
    uint64_t r12;
    uint64_t rbx;
    uint64_t rbp;
    uint64_t rip;
} __attribute__((packed));

/*
 * 调度实体。进程页表、文件表、PID 和父子关系均通过 process 访问，
 * 不再混入线程对象。rsp 必须保持第一个字段，switch.S 依赖该偏移。
 */
struct thread {
    uint64_t rsp;
    /* syscall/中断切换时保存的用户栈指针，不能放在全局 CPU 临时槽。 */
    uint64_t user_rsp;
    paddr_t object_paddr;
    uint64_t* stack_base;

    uint32_t tid;
    uint32_t ticks;
    uint32_t priority;
    struct thread* next;

    thread_state_t status;
    void* waiting_lock;
    uint64_t kernel_stack_top;

    /* 用户线程私有的一页栈；地址空间本身仍由 process 共享。 */
    vaddr_t user_stack_base;
    vaddr_t user_stack_top;
    paddr_t user_stack_paddr;
    vaddr_t tls_base;
    paddr_t tls_paddr;
    int32_t exit_status;

    struct process* process;
    struct thread* process_next;
    struct thread* join_waiter;
    thread_lifecycle_t lifecycle;
    uint32_t lifecycle_claimed;

    /* futex waiter 嵌入线程对象，禁止在桶锁内分配内存。 */
    uint32_t futex_waiting;
    uint32_t futex_bucket;
    int32_t futex_result;
    struct process* futex_process;
    vaddr_t futex_uaddr;
    struct thread* futex_prev;
    struct thread* futex_next;

    /* IPC 是线程级阻塞状态；用户可见的 source_pid 仍来自 process->pid。 */
    uint32_t ipc_sending;
    uint32_t ipc_receiving;
    int32_t ipc_receive_from;
    int32_t ipc_status;
    struct message ipc_message;
    struct thread* ipc_waiting_for;
    struct thread* ipc_sender_head;
    struct thread* ipc_sender_tail;
    struct thread* ipc_next_sender;

    /* 定时器睡眠队列节点；sleeping 防止同一线程重复入队。 */
    uint64_t wake_tick;
    uint32_t sleeping;
    struct thread* sleep_next;
};

extern struct thread* current_thread;

extern volatile uint32_t preempt_disable_count;
extern volatile uint32_t need_resched;

extern void thread_init(void);
void schedule(void);

struct thread* thread_create(void (*function)(void), uint32_t priority);
void thread_append(struct thread* thread);
int thread_in_scheduler_ring(const struct thread* thread);
void thread_block(void);
void thread_block_with_lock(spinlock_t* guard);
void thread_unblock(struct thread* thread);
void thread_yield(void);
void thread_request_reschedule(void);
void thread_preempt_point(void);
void thread_sleep_ticks(uint64_t ticks);
void thread_preempt_disable(void);
void thread_preempt_enable(void);
uint64_t thread_current_user_rsp(void);
void thread_set_current_user_rsp(uint64_t user_rsp);
void thread_note_user_interrupt_rsp(uint64_t user_rsp);

void thread_exit(void);
void thread_exit_with_status(int status) __attribute__((noreturn));
struct thread* thread_find_by_pid(uint32_t pid);
struct thread* thread_find_by_tid(struct process* process, uint32_t tid);
int thread_join(struct thread* target, int* status);
int thread_detach(struct thread* target);
void thread_reap_detached(void);

#endif
