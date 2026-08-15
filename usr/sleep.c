#include "libc.h"

static unsigned long parse_ticks(const char* text)
{
    unsigned long value = 0;
    while (*text >= '0' && *text <= '9') value = value * 10 + (unsigned)(*text++ - '0');
    return value;
}

int main(int argc, char** argv)
{
    if (argc != 2) { puts("usage: sleep TICKS"); return 1; }
    return sleep(parse_ticks(argv[1])) == (unsigned long)-1 ? 1 : 0;
}
