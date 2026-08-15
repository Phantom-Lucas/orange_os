#include "syscall.h"

#define IPC_DEMO_TYPE  0x49504355U
#define IPC_DEMO_VALUE 0x1234ABCDEFULL

static void write_text(const char* text, unsigned long length) {
    (void)sys_write(1, text, length);
}

void _start(void) {
    long child = sys_fork();
    if (child == 0) {
        struct ipc_message message;
        if (sys_receive(IPC_ANY, &message) != 0 ||
            message.type != IPC_DEMO_TYPE || message.value != IPC_DEMO_VALUE) {
            sys_exit(1);
        }
        sys_exit(0);
    }
    if (child < 0) sys_exit(2);

    struct ipc_message message = {0, IPC_DEMO_TYPE, IPC_DEMO_VALUE};
    if (sys_send((unsigned long)child, &message) != 0) sys_exit(3);

    int status = -1;
    if (sys_wait((unsigned long)child, &status) != child || status != 0) sys_exit(4);
    write_text("IPC user demo PASSED\n", 21);
    sys_exit(0);
}
