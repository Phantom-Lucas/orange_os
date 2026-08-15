#include "libc.h"

int main(int argc, char** argv)
{
    int result = 0;
    for (int i = 1; i < argc; i++) {
        if (mkdir(argv[i]) != 0) { printf("mkdir: failed: %s\n", argv[i]); result = 1; }
    }
    return argc > 1 ? result : 1;
}
