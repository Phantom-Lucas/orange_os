#ifndef IPC_H
#define IPC_H

#include <stdint.h>

#define IPC_ANY (-1)

struct message {
    uint32_t source_pid;
    uint32_t type;
    uint64_t value;
};

struct thread;

void ipc_init(void);
int ipc_send(struct thread* destination, const struct message* message);
int ipc_receive(int32_t source_pid, struct message* message);
void ipc_abort_thread(struct thread* thread);
void ipc_abort_current(void);
void ipc_run_self_test(void);

#endif
