#include "libc.h"

static const char* state_name(unsigned state)
{
    return state == 0 ? "RUN" : state == 1 ? "ZOMB" : "DEAD";
}

int main(void)
{
    struct sys_process_info entries[32];
    long count = ps(entries, 32);
    if (count < 0) return 1;
    puts("PID  PPID STATE THREADS NAME");
    for (long i = 0; i < count; i++) {
        printf("%u  %u  %s  %u  %s\n", entries[i].pid, entries[i].ppid,
               state_name(entries[i].state), entries[i].threads, entries[i].name);
    }
    return 0;
}
