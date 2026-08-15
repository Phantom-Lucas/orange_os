#ifndef FUTEX_H
#define FUTEX_H

#include <stdint.h>
#include "memory.h"

struct process;
struct thread;

#define FUTEX_ERR_INVAL (-1)
#define FUTEX_ERR_AGAIN (-2)
#define FUTEX_ERR_INTR  (-4)

struct futex_stats {
    uint32_t buckets;
    uint32_t waiters;
    uint32_t nonempty_buckets;
};

void futex_init(void);
int futex_wait(struct process* process, vaddr_t user_address,
               uint32_t expected);
int futex_wake(struct process* process, vaddr_t user_address,
               uint32_t count);
void futex_cancel_thread(struct thread* thread, int result);
void futex_cancel_process(struct process* process, int result);
void futex_get_stats(struct futex_stats* stats);

#endif
