// kernel/thread.c
#include "thread.h"
#include "thread_internal.h"
#include "memory.h"
#include "kalloc.h"
#include "debug.h"
#include "print.h"
#include "string.h"
#include "futex.h"
#include "timer.h"

struct cpu_local_data {
    uint64_t kernel_rsp;
    uint64_t user_rsp;
};
extern struct cpu_local_data current_cpu;

struct thread* current_thread = 0;
static uint32_t next_tid = 1;
volatile uint32_t preempt_disable_count = 0;
volatile uint32_t need_resched = 0;

extern void switch_to(struct thread* current, struct thread* next);
extern void syscall_child_return(void);
extern void set_tss_rsp0(uint64_t rsp0);
extern void normalize_kernel_gs(void);
extern void set_user_fs_base(uint64_t base);

static int thread_uses_user_gs(void)
{
    return current_thread != 0 && current_thread->process != kernel_process;
}

/* thread_count 包含可 join 的 zombie；只有最后一个仍运行的线程退出时，
 * 才应把整个进程转成 zombie，避免“主线程先退出”后剩余线程全部僵死。 */
static uint32_t process_live_thread_count(const struct process* process)
{
    const struct thread* thread;
    uint32_t live = 0;

    if (process == 0) return 0;
    thread = process->thread_head;
    while (thread != 0) {
        if (thread->status != TASK_ZOMBIE && thread->status != TASK_DEAD) live++;
        thread = thread->process_next;
    }
    return live;
}

static void link_thread_to_process(struct process* process,
                                   struct thread* thread)
{
    if (process == 0 || thread == 0) return;
    thread->process = process;
    thread->process_next = process->thread_head;
    process->thread_head = thread;
    process->thread_count++;
    if (process->main_thread == 0) process->main_thread = thread;
}

static void unlink_thread_from_process(struct thread* victim)
{
    struct thread** link;
    struct process* process;

    if (victim == 0 || victim->process == 0) return;
    process = victim->process;
    link = &process->thread_head;
    while (*link != 0 && *link != victim) link = &(*link)->process_next;
    if (*link == victim) {
        *link = victim->process_next;
        if (process->main_thread == victim) process->main_thread = process->thread_head;
        if (process->thread_count != 0) process->thread_count--;
    }
    victim->process_next = 0;
    victim->process = 0;
}

struct thread* thread_alloc_for_process(struct process* process,
                                        uint32_t priority)
{
    paddr_t object_paddr = alloc_page_owned(PAGE_OWNER_THREAD);
    paddr_t stack_paddr;
    struct thread* thread;

    if (object_paddr == 0) return 0;
    stack_paddr = alloc_page_owned(PAGE_OWNER_THREAD);
    if (stack_paddr == 0) {
        free_page_owned(object_paddr, PAGE_OWNER_THREAD);
        return 0;
    }

    thread = (struct thread*)P2V(object_paddr);
    memset(thread, 0, PAGE_SIZE);
    thread->object_paddr = object_paddr;
    thread->stack_base = (uint64_t*)P2V(stack_paddr);
    thread->ticks = priority;
    thread->priority = priority;
    thread->status = TASK_READY;
    thread->lifecycle = THREAD_JOINABLE_RUNNING;
    thread->tid = next_tid++;
    thread->ipc_receive_from = IPC_ANY;
    link_thread_to_process(process, thread);
    return thread;
}

void thread_free_object(struct thread* thread)
{
    paddr_t object_paddr;
    paddr_t stack_paddr;
    struct process* process;

    if (thread == 0) return;
    ASSERT(thread != current_thread);
    ASSERT(!thread_in_scheduler_ring(thread));
    timer_cancel_thread_sleep(thread);
    process = thread->process;
    object_paddr = thread->object_paddr;
    stack_paddr = thread->stack_base == 0 ? 0 : V2P(thread->stack_base);
    if (process != 0 && process->cr3_paddr != 0) {
        /* 回收线程私有映射必须与同进程 mmap/munmap 串行化。 */
        spinlock_acquire(&process->address_space_lock);
        if (thread->user_stack_paddr != 0) {
            if (unmap_user_page(process->cr3_paddr, thread->user_stack_base,
                                PAGE_OWNER_USER) != 0) {
                print_error("[THREAD] failed to reclaim user stack.\n");
            }
        }
        if (thread->tls_paddr != 0) {
            if (unmap_user_page(process->cr3_paddr, thread->tls_base,
                                PAGE_OWNER_USER) != 0) {
                print_error("[THREAD] failed to reclaim TLS page.\n");
            }
        }
        spinlock_release(&process->address_space_lock);
    }
    thread->user_stack_paddr = 0;
    thread->tls_paddr = 0;
    unlink_thread_from_process(thread);
    thread->object_paddr = 0;
    thread->stack_base = 0;
    if (stack_paddr != 0 &&
        free_page_owned(stack_paddr, PAGE_OWNER_THREAD) != 0) {
        print_error("[THREAD] failed to reclaim kernel stack.\n");
    }
    if (object_paddr != 0 &&
        free_page_owned(object_paddr, PAGE_OWNER_THREAD) != 0) {
        print_error("[THREAD] failed to reclaim thread object.\n");
    }
}

void thread_init(void)
{
    struct thread* boot_thread;

    process_init();
    if (kernel_process == 0) return;
    boot_thread = thread_alloc_for_process(kernel_process, 5);
    if (boot_thread == 0) return;
    /* 启动线程继续使用 loader 建立的启动栈。 */
    free_page_owned(V2P(boot_thread->stack_base), PAGE_OWNER_THREAD);
    boot_thread->stack_base = 0;
    boot_thread->status = TASK_RUNNING;
    boot_thread->next = boot_thread;
    current_thread = boot_thread;
}

struct thread* thread_create(void (*function)(void), uint32_t priority)
{
    struct thread* thread = thread_alloc_for_process(kernel_process, priority);
    uint64_t stack_top;
    struct thread_context* context;

    if (thread == 0) return 0;
    stack_top = (uint64_t)thread->stack_base + PAGE_SIZE;
    stack_top -= sizeof(struct thread_context);
    context = (struct thread_context*)stack_top;
    memset(context, 0, sizeof(*context));
    context->rip = (uint64_t)function;
    thread->rsp = stack_top;
    return thread;
}

int thread_in_scheduler_ring(const struct thread* wanted)
{
    const struct thread* thread;

    if (wanted == 0 || current_thread == 0) return 0;
    thread = current_thread;
    do {
        if (thread == wanted) return 1;
        thread = thread->next;
    } while (thread != current_thread);
    return 0;
}

void thread_append(struct thread* new_thread)
{
    struct thread* tail;

    if (new_thread == 0 || new_thread->status != TASK_READY ||
        thread_in_scheduler_ring(new_thread)) {
        print_error("[SCHED] rejected duplicate or non-ready thread.\n");
        return;
    }
    if (current_thread == 0) {
        current_thread = new_thread;
        new_thread->next = new_thread;
        new_thread->status = TASK_RUNNING;
        return;
    }
    tail = current_thread;
    while (tail->next != current_thread) tail = tail->next;
    tail->next = new_thread;
    new_thread->next = current_thread;
}

void thread_remove_from_scheduler(struct thread* victim)
{
    struct thread* previous;

    if (victim == 0 || current_thread == 0 || victim == current_thread) return;
    previous = current_thread;
    while (previous->next != current_thread && previous->next != victim) {
        previous = previous->next;
    }
    if (previous->next == victim) {
        previous->next = victim->next;
        victim->next = 0;
    }
}

static void reap_kernel_thread(struct thread* victim)
{
    if (victim == 0 || victim == current_thread ||
        victim->status != TASK_ZOMBIE) return;
    thread_remove_from_scheduler(victim);
    victim->status = TASK_DEAD;
    victim->lifecycle = THREAD_REAPED;
    thread_free_object(victim);
}

/* detached zombie 不能等待 join；在切换到下一个线程前回收其调度实体。 */
void thread_reap_detached(void)
{
    struct thread* scan;
    struct thread* next;

    if (current_thread == 0) return;
    scan = current_thread->next;
    while (scan != current_thread) {
        next = scan->next;
        if (scan->status == TASK_ZOMBIE &&
            scan->lifecycle == THREAD_DETACHED_ZOMBIE) {
            struct process* process = scan->process;
            if (process != 0) spinlock_acquire(&process->lifecycle_lock);
            if (scan->status == TASK_ZOMBIE &&
                scan->lifecycle == THREAD_DETACHED_ZOMBIE) {
                thread_remove_from_scheduler(scan);
                scan->status = TASK_DEAD;
                scan->lifecycle = THREAD_REAPED;
                thread_free_object(scan);
            }
            if (process != 0) spinlock_release(&process->lifecycle_lock);
        }
        scan = next;
    }
}

static void check_scheduler_invariants(void)
{
    struct thread* thread = current_thread;
    uint32_t running = 0;
    uint32_t count = 0;

    ASSERT(current_thread != 0);
    do {
        ASSERT(thread != 0 && thread->process != 0);
        if (thread->status == TASK_RUNNING) running++;
        ASSERT(++count < 4096);
        thread = thread->next;
    } while (thread != current_thread);
    ASSERT(running <= 1);
}

void schedule(void)
{
    struct thread* previous;
    struct thread* next;

    if (current_thread == 0 || current_thread->next == current_thread) return;
    check_scheduler_invariants();
    process_reap_orphans();
    thread_reap_detached();
    previous = current_thread;
    next = current_thread->next;
    while (next->status == TASK_BLOCKED || next->status == TASK_ZOMBIE ||
           next->status == TASK_DEAD) {
        next = next->next;
        if (next == current_thread) return;
    }
    ASSERT(next->status == TASK_READY);
    /* current_cpu.user_rsp 只是 syscall 入口的短暂镜像；真正的值
       必须随调度实体保存，否则阻塞 syscall 返回时会使用别的线程栈。 */
    if (previous->process != kernel_process) {
        previous->user_rsp = current_cpu.user_rsp;
    }
    current_cpu.user_rsp = next->user_rsp;
    if (next->kernel_stack_top != 0) {
        set_tss_rsp0(next->kernel_stack_top);
        current_cpu.kernel_rsp = next->kernel_stack_top;
    }
    if (next->process->cr3_paddr != previous->process->cr3_paddr) {
        __asm__ volatile("mov %0, %%cr3" ::
                         "r"(next->process->cr3_paddr) : "memory");
    }
    set_user_fs_base(next->process == kernel_process ? 0 : next->tls_base);
    /* 所有上下文切换都从确定的内核 GS 开始；用户入口负责 swapgs。 */
    normalize_kernel_gs();
    if (previous->status == TASK_RUNNING) previous->status = TASK_READY;
    next->status = TASK_RUNNING;
    current_thread = next;
    switch_to(previous, next);
}

void thread_preempt_disable(void) { preempt_disable_count++; }

void thread_preempt_enable(void)
{
    ASSERT(preempt_disable_count != 0);
    preempt_disable_count--;
}

uint64_t thread_current_user_rsp(void)
{
    return current_thread == 0 ? 0 : current_thread->user_rsp;
}

void thread_set_current_user_rsp(uint64_t user_rsp)
{
    if (current_thread != 0) current_thread->user_rsp = user_rsp;
    current_cpu.user_rsp = user_rsp;
}

void thread_note_user_interrupt_rsp(uint64_t user_rsp)
{
    thread_set_current_user_rsp(user_rsp);
}

void thread_request_reschedule(void) { need_resched = 1; }

void thread_preempt_point(void)
{
    uint64_t rflags;
    if (current_thread == 0 || preempt_disable_count != 0 || !need_resched) return;
    __asm__ volatile("pushfq; popq %0" : "=r"(rflags));
    __asm__ volatile("cli");
    if (preempt_disable_count == 0 && need_resched) {
        need_resched = 0;
        schedule();
    }
    __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
}

void thread_yield(void)
{
    uint64_t rflags;
    int user_gs = thread_uses_user_gs();
    __asm__ volatile("pushfq; popq %0" : "=r"(rflags));
    __asm__ volatile("cli");
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    need_resched = 0;
    schedule();
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
}

void thread_block(void)
{
    uint64_t rflags;
    int user_gs = thread_uses_user_gs();
    ASSERT(current_thread != 0);
    __asm__ volatile("pushfq; popq %0" : "=r"(rflags));
    __asm__ volatile("cli");
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    current_thread->status = TASK_BLOCKED;
    schedule();
    while (current_thread->status == TASK_BLOCKED) {
        __asm__ volatile("sti; hlt; cli" ::: "memory");
        schedule();
    }
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
}

/* 调用者持有 guard；状态切换和释放 guard 之间不能被 wakeup 插入，
 * 用于管道等“检查条件—入队—阻塞”必须原子的等待队列。 */
void thread_block_with_lock(spinlock_t* guard)
{
    uint64_t rflags;
    int user_gs = thread_uses_user_gs();
    ASSERT(current_thread != 0 && guard != 0);
    __asm__ volatile("pushfq; popq %0" : "=r"(rflags));
    __asm__ volatile("cli");
    current_thread->status = TASK_BLOCKED;
    spinlock_release(guard);
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    schedule();
    while (current_thread->status == TASK_BLOCKED) {
        __asm__ volatile("sti; hlt; cli" ::: "memory");
        schedule();
    }
    if (user_gs) __asm__ volatile("swapgs" ::: "memory");
    __asm__ volatile("pushq %0; popfq" :: "r"(rflags) : "memory", "cc");
}

void thread_unblock(struct thread* thread)
{
    if (thread == 0 || thread->status != TASK_BLOCKED) return;
    thread->waiting_lock = 0;
    thread->status = TASK_READY;
}

void thread_exit(void)
{
    thread_exit_with_status(0);
}

void thread_exit_with_status(int status)
{
    struct process* process;

    if (current_thread == 0) while (1) __asm__ volatile("hlt");
    process = current_thread->process;
    if (process != kernel_process && process_live_thread_count(process) <= 1) {
        process_exit(status);
        while (1) __asm__ volatile("hlt");
    }

    futex_cancel_thread(current_thread, FUTEX_ERR_INTR);
    __asm__ volatile("cli");
    ipc_abort_current();
    spinlock_acquire(&process->lifecycle_lock);
    current_thread->exit_status = status;
    current_thread->status = TASK_ZOMBIE;
    current_thread->lifecycle =
        current_thread->lifecycle == THREAD_DETACHED_RUNNING
            ? THREAD_DETACHED_ZOMBIE : THREAD_JOINABLE_ZOMBIE;
    if (current_thread->join_waiter != 0) {
        thread_unblock(current_thread->join_waiter);
    }
    spinlock_release(&process->lifecycle_lock);
    while (1) thread_yield();
}

struct thread* thread_find_by_tid(struct process* process, uint32_t tid)
{
    struct thread* thread;

    if (process == 0 || tid == 0) return 0;
    thread = process->thread_head;
    while (thread != 0) {
        if (thread->tid == tid) return thread;
        thread = thread->process_next;
    }
    return 0;
}

int thread_join(struct thread* target, int* status)
{
    struct process* process;

    if (target == 0 || target == current_thread || current_thread == 0 ||
        target->process != current_thread->process) return -1;
    process = current_thread->process;
    spinlock_acquire(&process->lifecycle_lock);
    if (target->lifecycle != THREAD_JOINABLE_RUNNING &&
        target->lifecycle != THREAD_JOINABLE_ZOMBIE) {
        spinlock_release(&process->lifecycle_lock);
        return -1;
    }
    if (target->lifecycle_claimed != 0) {
        spinlock_release(&process->lifecycle_lock);
        return -1;
    }
    target->lifecycle_claimed = 1;
    if (target->status != TASK_ZOMBIE) {
        target->join_waiter = current_thread;
        spinlock_release(&process->lifecycle_lock);
        while (target->status != TASK_ZOMBIE) thread_block();
    } else {
        spinlock_release(&process->lifecycle_lock);
    }
    target->join_waiter = 0;
    if (status != 0) *status = target->exit_status;
    reap_kernel_thread(target);
    return 0;
}

int thread_detach(struct thread* target)
{
    struct process* process;
    int reap = 0;

    if (target == 0 || target == current_thread || current_thread == 0 ||
        target->process != current_thread->process) return -1;
    process = current_thread->process;
    spinlock_acquire(&process->lifecycle_lock);
    if (target->lifecycle != THREAD_JOINABLE_RUNNING &&
        target->lifecycle != THREAD_JOINABLE_ZOMBIE) {
        spinlock_release(&process->lifecycle_lock);
        return -1;
    }
    if (target->lifecycle_claimed != 0) {
        spinlock_release(&process->lifecycle_lock);
        return -1;
    }
    target->lifecycle_claimed = 1;
    if (target->status == TASK_ZOMBIE) {
        target->lifecycle = THREAD_DETACHED_ZOMBIE;
        reap = 1;
    } else {
        target->lifecycle = THREAD_DETACHED_RUNNING;
    }
    spinlock_release(&process->lifecycle_lock);
    if (reap) reap_kernel_thread(target);
    return 0;
}
