#include "libc.h"

int main(int argc, char** argv)
{
    char buffer[512];
    if (argc < 2) argv = (char*[]) { "cat", "-", 0 }, argc = 2;
    for (int i = 1; i < argc; i++) {
        int fd = strcmp(argv[i], "-") == 0 ? 0 : open(argv[i], 0);
        if (fd < 0) { printf("cat: cannot open %s\n", argv[i]); return 1; }
        ssize_t count;
        while ((count = read(fd, buffer, sizeof(buffer))) > 0)
            write(1, buffer, (size_t)count);
        if (fd != 0) close(fd);
        if (count < 0) return 1;
    }
    return 0;
}
