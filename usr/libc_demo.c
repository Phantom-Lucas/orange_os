#include "libc.h"

int main(int argc, char** argv) {
    (void)argc;
    (void)argv;

    char* message = (char*)malloc(32);
    if (message == 0) {
        puts("libc-demo: malloc failed");
        return 1;
    }
    strcpy(message, "libc runtime is ready");
    printf("%s (pid=%u)\n", message, (unsigned)getpid());

    char* grown = (char*)realloc(message, 64);
    if (grown == 0 || strcmp(grown, "libc runtime is ready") != 0) {
        free(grown != 0 ? grown : message);
        puts("libc-demo: realloc/string test failed");
        return 2;
    }
    free(grown);

    char* zeroed = (char*)calloc(8, 4);
    if (zeroed == 0 || memcmp(zeroed, "\0\0\0\0", 4) != 0) {
        free(zeroed);
        puts("libc-demo: calloc test failed");
        return 3;
    }
    free(zeroed);
    puts("libc-demo: allocator, strings, formatting passed");
    return 0;
}
