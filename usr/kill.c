#include "libc.h"

static unsigned parse_pid(const char* text)
{
    unsigned value = 0;
    while (*text >= '0' && *text <= '9') value = value * 10 + (unsigned)(*text++ - '0');
    return value;
}

int main(int argc, char** argv)
{
    if (argc != 2) { puts("usage: kill PID"); return 1; }
    return kill((pid_t)parse_pid(argv[1]), 15) == 0 ? 0 : 1;
}
