#ifndef THREAD_INTERNAL_H
#define THREAD_INTERNAL_H

#include "thread.h"

/* 仅供 process.c 与 thread.c 共享的线程对象/调度环辅助操作。 */
struct thread* thread_alloc_for_process(struct process* process,
                                        uint32_t priority);
void thread_free_object(struct thread* thread);
int thread_in_scheduler_ring(const struct thread* thread);
void thread_remove_from_scheduler(struct thread* thread);

#endif
