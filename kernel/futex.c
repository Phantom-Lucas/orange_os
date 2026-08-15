#include "futex.h"
#include "process.h"
#include "thread.h"
#include "sync.h"
#include "string.h"

#define FUTEX_BUCKET_COUNT 64U

struct futex_bucket {
    spinlock_t lock;
    struct thread* head;
};

static struct futex_bucket buckets[FUTEX_BUCKET_COUNT];
static volatile uint32_t waiter_count;

static uint32_t futex_hash(const struct process* process, vaddr_t address)
{
    uint64_t value = (uint64_t)(uintptr_t)process;
    value ^= address >> 12;
    value ^= address >> 27;
    value *= 0x9E3779B185EBCA87ULL;
    return (uint32_t)(value >> 32) & (FUTEX_BUCKET_COUNT - 1);
}

static int valid_address(struct process* process, vaddr_t address)
{
    return process != 0 && process != kernel_process &&
           (address & (sizeof(uint32_t) - 1)) == 0 &&
           process->cr3_paddr != 0 &&
           user_range_is_writable(process->cr3_paddr, address,
                                  sizeof(uint32_t));
}

static void unlink_waiter_locked(struct futex_bucket* bucket,
                                 struct thread* thread)
{
    if (thread->futex_prev != 0) {
        thread->futex_prev->futex_next = thread->futex_next;
    } else if (bucket->head == thread) {
        bucket->head = thread->futex_next;
    }
    if (thread->futex_next != 0) {
        thread->futex_next->futex_prev = thread->futex_prev;
    }
    thread->futex_prev = 0;
    thread->futex_next = 0;
    thread->futex_waiting = 0;
    if (waiter_count != 0) __sync_sub_and_fetch(&waiter_count, 1);
}

static void enqueue_waiter_locked(struct futex_bucket* bucket,
                                  struct thread* thread,
                                  struct process* process,
                                  vaddr_t address,
                                  uint32_t bucket_index)
{
    thread->futex_waiting = 1;
    thread->futex_bucket = bucket_index;
    thread->futex_process = process;
    thread->futex_uaddr = address;
    thread->futex_prev = 0;
    thread->futex_next = bucket->head;
    if (bucket->head != 0) bucket->head->futex_prev = thread;
    bucket->head = thread;
    __sync_add_and_fetch(&waiter_count, 1);
}

void futex_init(void)
{
    uint32_t i;
    waiter_count = 0;
    for (i = 0; i < FUTEX_BUCKET_COUNT; i++) {
        spinlock_init(&buckets[i].lock);
        buckets[i].head = 0;
    }
}

/*
 * 检查、入队和设置 BLOCKED 必须发生在同一个桶锁临界区内：
 * waker 若先拿到桶锁，waiter 随后会重新读到新值；waiter 若先入队，
 * waker 必然能看到它。地址空间锁放在桶锁之前，和页表销毁保持一致。
 */
int futex_wait(struct process* process, vaddr_t user_address,
               uint32_t expected)
{
    struct futex_bucket* bucket;
    struct thread* current = current_thread;
    uint32_t actual;
    uint32_t index;

    if (current == 0 || current->process != process ||
        !valid_address(process, user_address)) return FUTEX_ERR_INVAL;

    index = futex_hash(process, user_address);
    bucket = &buckets[index];
    spinlock_acquire(&process->address_space_lock);
    if (process->exit_requested || !valid_address(process, user_address) ||
        copy_from_user(&actual, user_address, sizeof(actual)) != 0) {
        spinlock_release(&process->address_space_lock);
        return FUTEX_ERR_INVAL;
    }
    spinlock_acquire(&bucket->lock);
    if (copy_from_user(&actual, user_address, sizeof(actual)) != 0) {
        spinlock_release(&bucket->lock);
        spinlock_release(&process->address_space_lock);
        return FUTEX_ERR_INVAL;
    }
    if (actual != expected) {
        spinlock_release(&bucket->lock);
        spinlock_release(&process->address_space_lock);
        return FUTEX_ERR_AGAIN;
    }

    current->futex_result = 0;
    current->status = TASK_BLOCKED;
    enqueue_waiter_locked(bucket, current, process, user_address, index);
    spinlock_release(&bucket->lock);
    spinlock_release(&process->address_space_lock);

    thread_block();
    return current->futex_result;
}

int futex_wake(struct process* process, vaddr_t user_address, uint32_t count)
{
    struct futex_bucket* bucket;
    struct thread* thread;
    uint32_t index;
    int woke = 0;

    if (!valid_address(process, user_address)) return FUTEX_ERR_INVAL;
    if (count == 0) return 0;
    index = futex_hash(process, user_address);
    bucket = &buckets[index];
    spinlock_acquire(&bucket->lock);
    thread = bucket->head;
    while (thread != 0 && (uint32_t)woke < count) {
        struct thread* next = thread->futex_next;
        if (thread->futex_process == process &&
            thread->futex_uaddr == user_address) {
            unlink_waiter_locked(bucket, thread);
            thread->futex_result = 0;
            thread_unblock(thread);
            woke++;
        }
        thread = next;
    }
    spinlock_release(&bucket->lock);
    if (woke != 0) thread_request_reschedule();
    return woke;
}

void futex_cancel_thread(struct thread* thread, int result)
{
    struct futex_bucket* bucket;

    if (thread == 0 || !thread->futex_waiting) return;
    bucket = &buckets[thread->futex_bucket];
    spinlock_acquire(&bucket->lock);
    if (thread->futex_waiting) {
        unlink_waiter_locked(bucket, thread);
        thread->futex_result = result;
        thread_unblock(thread);
    }
    spinlock_release(&bucket->lock);
}

void futex_cancel_process(struct process* process, int result)
{
    uint32_t i;

    if (process == 0) return;
    spinlock_acquire(&process->address_space_lock);
    for (i = 0; i < FUTEX_BUCKET_COUNT; i++) {
        struct thread* thread;
        spinlock_acquire(&buckets[i].lock);
        thread = buckets[i].head;
        while (thread != 0) {
            struct thread* next = thread->futex_next;
            if (thread->futex_process == process) {
                unlink_waiter_locked(&buckets[i], thread);
                thread->futex_result = result;
                thread_unblock(thread);
            }
            thread = next;
        }
        spinlock_release(&buckets[i].lock);
    }
    spinlock_release(&process->address_space_lock);
}

void futex_get_stats(struct futex_stats* stats)
{
    uint32_t i;
    if (stats == 0) return;
    stats->buckets = FUTEX_BUCKET_COUNT;
    stats->waiters = waiter_count;
    stats->nonempty_buckets = 0;
    for (i = 0; i < FUTEX_BUCKET_COUNT; i++) {
        if (buckets[i].head != 0) stats->nonempty_buckets++;
    }
}
