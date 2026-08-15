#include "ipc.h"

#include "print.h"
#include "sync.h"
#include "thread.h"

static spinlock_t ipc_lock;

static int source_matches(const struct thread* receiver,
                          const struct thread* sender) {
    return receiver->ipc_receive_from == IPC_ANY ||
           receiver->ipc_receive_from == (int32_t)sender->process->pid;
}

static void enqueue_sender(struct thread* receiver, struct thread* sender) {
    sender->ipc_next_sender = 0;
    if (receiver->ipc_sender_tail != 0) {
        receiver->ipc_sender_tail->ipc_next_sender = sender;
    } else {
        receiver->ipc_sender_head = sender;
    }
    receiver->ipc_sender_tail = sender;
}

static void remove_sender(struct thread* receiver, struct thread* sender) {
    struct thread* previous = 0;
    struct thread* current = receiver->ipc_sender_head;
    while (current != 0 && current != sender) {
        previous = current;
        current = current->ipc_next_sender;
    }
    if (current == 0) return;
    if (previous != 0) {
        previous->ipc_next_sender = current->ipc_next_sender;
    } else {
        receiver->ipc_sender_head = current->ipc_next_sender;
    }
    if (receiver->ipc_sender_tail == current) receiver->ipc_sender_tail = previous;
    current->ipc_next_sender = 0;
}

static struct thread* dequeue_matching_sender(struct thread* receiver) {
    struct thread* previous = 0;
    struct thread* sender = receiver->ipc_sender_head;

    while (sender != 0 && !source_matches(receiver, sender)) {
        previous = sender;
        sender = sender->ipc_next_sender;
    }
    if (sender == 0) return 0;

    if (previous != 0) {
        previous->ipc_next_sender = sender->ipc_next_sender;
    } else {
        receiver->ipc_sender_head = sender->ipc_next_sender;
    }
    if (receiver->ipc_sender_tail == sender) {
        receiver->ipc_sender_tail = previous;
    }
    sender->ipc_next_sender = 0;
    return sender;
}

void ipc_init(void) {
    spinlock_init(&ipc_lock);
}

int ipc_send(struct thread* destination, const struct message* message) {
    if (destination == 0 || message == 0 || destination == current_thread ||
        destination->status == TASK_ZOMBIE ||
        destination->status == TASK_DEAD) return -1;
    if (current_thread == 0 || current_thread->process == 0 ||
        destination->process == 0) {
        return -1;
    }

    spinlock_acquire(&ipc_lock);
    if (destination->ipc_receiving && source_matches(destination, current_thread)) {
        destination->ipc_message = *message;
        destination->ipc_message.source_pid = current_thread->process->pid;
        destination->ipc_receiving = 0;
        destination->ipc_receive_from = IPC_ANY;
        thread_unblock(destination);
        spinlock_release(&ipc_lock);
        return 0;
    }

    current_thread->ipc_message = *message;
    current_thread->ipc_message.source_pid = current_thread->process->pid;
    current_thread->ipc_sending = 1;
    current_thread->ipc_status = 0;
    current_thread->ipc_waiting_for = destination;
    enqueue_sender(destination, current_thread);
    spinlock_release(&ipc_lock);

    thread_block();
    return current_thread->ipc_status;
}

int ipc_receive(int32_t source_pid, struct message* message) {
    if (message == 0) return -1;

    spinlock_acquire(&ipc_lock);
    current_thread->ipc_receive_from = source_pid;
    struct thread* sender = dequeue_matching_sender(current_thread);
    if (sender != 0) {
        *message = sender->ipc_message;
        sender->ipc_sending = 0;
        sender->ipc_status = 0;
        sender->ipc_waiting_for = 0;
        thread_unblock(sender);
        current_thread->ipc_receive_from = IPC_ANY;
        spinlock_release(&ipc_lock);
        return 0;
    }

    current_thread->ipc_receiving = 1;
    spinlock_release(&ipc_lock);

    thread_block();
    if (current_thread->ipc_status != 0) return current_thread->ipc_status;
    *message = current_thread->ipc_message;
    return 0;
}

/* 线程退出时，不能把线程指针遗留在 IPC 队列中。 */
void ipc_abort_thread(struct thread* target) {
    if (!target) return;

    spinlock_acquire(&ipc_lock);
    if (target->ipc_sending && target->ipc_waiting_for) {
        remove_sender(target->ipc_waiting_for, target);
    }
    target->ipc_sending = 0;
    target->ipc_receiving = 0;
    target->ipc_waiting_for = 0;
    target->ipc_receive_from = IPC_ANY;

    struct thread* sender = target->ipc_sender_head;
    target->ipc_sender_head = 0;
    target->ipc_sender_tail = 0;
    while (sender != 0) {
        struct thread* next = sender->ipc_next_sender;
        sender->ipc_next_sender = 0;
        sender->ipc_sending = 0;
        sender->ipc_waiting_for = 0;
        sender->ipc_status = -1;
        thread_unblock(sender);
        sender = next;
    }
    spinlock_release(&ipc_lock);
}

void ipc_abort_current(void) {
    ipc_abort_thread(current_thread);
}

static volatile uint32_t self_test_done;
static volatile uint64_t self_test_value;
static struct thread* self_test_receiver;

static void ipc_self_test_receiver(void) {
    struct message message;
    if (ipc_receive(IPC_ANY, &message) == 0 && message.type == 0x49504301) {
        self_test_value = message.value;
    }
    self_test_done++;
    thread_exit();
}

static void ipc_self_test_sender(void) {
    struct message message = {0, 0x49504301, 0x1234ABCDEFULL};
    ipc_send(self_test_receiver, &message);
    self_test_done++;
    thread_exit();
}

void ipc_run_self_test(void) {
    self_test_done = 0;
    self_test_value = 0;
    self_test_receiver = thread_create(ipc_self_test_receiver, 5);
    struct thread* sender = thread_create(ipc_self_test_sender, 5);
    if (self_test_receiver == 0 || sender == 0) {
        print_error("[IPC] Self-test setup failed.\n");
        return;
    }

    thread_append(self_test_receiver);
    thread_append(sender);
    while (self_test_done != 2) {
        thread_yield();
    }

    /* 内核线程没有独立的进程 PID，使用 thread_join 回收调度实体。 */
    int reaped = thread_join(self_test_receiver, 0) == 0 &&
                 thread_join(sender, 0) == 0;
    self_test_receiver = 0;

    if (reaped && self_test_value == 0x1234ABCDEFULL) {
        print_debug("[IPC] Synchronous send/receive self-test PASSED.\n");
    } else {
        print_error("[IPC] Synchronous send/receive self-test FAILED.\n");
    }
}
