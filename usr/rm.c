#include "libc.h"

int main(int argc, char** argv)
{
    int result = argc > 1 ? 0 : 1;
    for (int i = 1; i < argc; i++) {
        if (unlink(argv[i]) != 0) { printf("rm: failed: %s\n", argv[i]); result = 1; }
    }
    return result;
}
