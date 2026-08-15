#include "libc.h"

int main(int argc, char** argv)
{
    char buffer[512];
    (void)argv;
    if (argc > 1) {
        puts("ls: path arguments are not implemented by this FS ABI");
        return 1;
    }
    long count = sys_list(buffer, sizeof(buffer));
    if (count < 0) { puts("ls: failed"); return 1; }
    if (count != 0) write(1, buffer, (size_t)count);
    return 0;
}
