#include "libc.h"

#define USER_ALLOC_MAGIC 0x4F52414E47454D41ULL
#define USER_PAGE_SIZE 4096ULL

struct allocation_header {
    uint64_t magic;
    uint64_t mapping_length;
    uint64_t user_size;
};

static int* errno_slot(void) {
    uint64_t base;
    __asm__ volatile("movq %%fs:0, %0" : "=r"(base));
    return (int*)(base + 8);
}

int* __errno_location(void) { return errno_slot(); }

static long checked_result(long result)
{
    if (result < 0) errno = LIBC_EINVAL;
    return result;
}

void* memset(void* destination, int value, size_t length) {
    unsigned char* output = (unsigned char*)destination;
    for (size_t i = 0; i < length; i++) output[i] = (unsigned char)value;
    return destination;
}

void* memcpy(void* destination, const void* source, size_t length) {
    unsigned char* output = (unsigned char*)destination;
    const unsigned char* input = (const unsigned char*)source;
    for (size_t i = 0; i < length; i++) output[i] = input[i];
    return destination;
}

void* memmove(void* destination, const void* source, size_t length) {
    unsigned char* output = (unsigned char*)destination;
    const unsigned char* input = (const unsigned char*)source;
    if (output < input) return memcpy(destination, source, length);
    while (length != 0) {
        length--;
        output[length] = input[length];
    }
    return destination;
}

int memcmp(const void* left, const void* right, size_t length) {
    const unsigned char* a = (const unsigned char*)left;
    const unsigned char* b = (const unsigned char*)right;
    for (size_t i = 0; i < length; i++) {
        if (a[i] != b[i]) return a[i] < b[i] ? -1 : 1;
    }
    return 0;
}

size_t strlen(const char* string) {
    size_t length = 0;
    if (string == 0) return 0;
    while (string[length] != '\0') length++;
    return length;
}

int strcmp(const char* left, const char* right) {
    while (*left != '\0' && *left == *right) { left++; right++; }
    return (unsigned char)*left - (unsigned char)*right;
}

int strncmp(const char* left, const char* right, size_t length) {
    while (length != 0 && *left != '\0' && *left == *right) {
        left++; right++; length--;
    }
    if (length == 0) return 0;
    return (unsigned char)*left - (unsigned char)*right;
}

char* strcpy(char* destination, const char* source) {
    char* result = destination;
    while ((*destination++ = *source++) != '\0') { }
    return result;
}

char* strncpy(char* destination, const char* source, size_t length) {
    size_t i = 0;
    for (; i < length && source[i] != '\0'; i++) destination[i] = source[i];
    for (; i < length; i++) destination[i] = '\0';
    return destination;
}

void* malloc(size_t size) {
    if (size == 0) size = 1;
    if (size > UINT64_MAX - sizeof(struct allocation_header) - USER_PAGE_SIZE) {
        errno = LIBC_ENOMEM;
        return 0;
    }
    size_t total = sizeof(struct allocation_header) + size;
    size_t mapping_length = (total + USER_PAGE_SIZE - 1) & ~(USER_PAGE_SIZE - 1);
    void* mapping = sys_mmap(0, mapping_length, PROT_READ | PROT_WRITE,
                             MAP_PRIVATE | MAP_ANONYMOUS);
    if (mapping == 0) {
        errno = LIBC_ENOMEM;
        return 0;
    }
    struct allocation_header* header = (struct allocation_header*)mapping;
    header->magic = USER_ALLOC_MAGIC;
    header->mapping_length = mapping_length;
    header->user_size = size;
    return header + 1;
}

void* calloc(size_t count, size_t size) {
    if (size != 0 && count > SIZE_MAX / size) {
        errno = LIBC_ENOMEM;
        return 0;
    }
    void* result = malloc(count * size);
    if (result != 0) memset(result, 0, count * size);
    return result;
}

void free(void* pointer) {
    if (pointer == 0) return;
    struct allocation_header* header = ((struct allocation_header*)pointer) - 1;
    if (header->magic != USER_ALLOC_MAGIC ||
        header->mapping_length == 0 ||
        (header->mapping_length & (USER_PAGE_SIZE - 1)) != 0) {
        errno = LIBC_EINVAL;
        return;
    }
    header->magic = 0;
    (void)sys_munmap(header, header->mapping_length);
}

void* realloc(void* pointer, size_t size) {
    if (pointer == 0) return malloc(size);
    if (size == 0) { free(pointer); return 0; }
    struct allocation_header* header = ((struct allocation_header*)pointer) - 1;
    if (header->magic != USER_ALLOC_MAGIC) { errno = LIBC_EINVAL; return 0; }
    void* result = malloc(size);
    if (result == 0) return 0;
    memcpy(result, pointer, header->user_size < size ? header->user_size : size);
    free(pointer);
    return result;
}

static void output_char(char* buffer, size_t length, size_t* position, char value) {
    if (*position + 1 < length) buffer[*position] = value;
    (*position)++;
}

static void output_string(char* buffer, size_t length, size_t* position,
                          const char* value) {
    if (value == 0) value = "(null)";
    while (*value != '\0') output_char(buffer, length, position, *value++);
}

static void output_unsigned(char* buffer, size_t length, size_t* position,
                            uint64_t value, unsigned base, int uppercase) {
    char digits[32];
    const char* alphabet = uppercase ? "0123456789ABCDEF" : "0123456789abcdef";
    size_t count = 0;
    do { digits[count++] = alphabet[value % base]; value /= base; } while (value != 0);
    while (count != 0) output_char(buffer, length, position, digits[--count]);
}

int vsnprintf(char* buffer, size_t length, const char* format, va_list arguments) {
    size_t position = 0;
    if (buffer == 0 && length != 0) return -1;
    while (*format != '\0') {
        if (*format != '%') { output_char(buffer, length, &position, *format++); continue; }
        format++;
        if (*format == '%') output_char(buffer, length, &position, *format++);
        else if (*format == 'c') output_char(buffer, length, &position, (char)va_arg(arguments, int)), format++;
        else if (*format == 's') output_string(buffer, length, &position, va_arg(arguments, const char*)), format++;
        else if (*format == 'd' || *format == 'i') {
            int value = va_arg(arguments, int);
            int64_t signed_value = value;
            if (signed_value < 0) { output_char(buffer, length, &position, '-'); signed_value = -signed_value; }
            output_unsigned(buffer, length, &position, (uint64_t)signed_value, 10, 0); format++;
        } else if (*format == 'u') output_unsigned(buffer, length, &position, va_arg(arguments, unsigned), 10, 0), format++;
        else if (*format == 'x') output_unsigned(buffer, length, &position, va_arg(arguments, unsigned), 16, 0), format++;
        else if (*format == 'p') output_unsigned(buffer, length, &position, (uint64_t)va_arg(arguments, void*), 16, 0), format++;
        else { output_char(buffer, length, &position, '%'); output_char(buffer, length, &position, *format++); }
    }
    if (length != 0) buffer[position < length - 1 ? position : length - 1] = '\0';
    return (int)position;
}

int snprintf(char* buffer, size_t length, const char* format, ...) {
    va_list arguments; va_start(arguments, format);
    int result = vsnprintf(buffer, length, format, arguments);
    va_end(arguments); return result;
}

int printf(const char* format, ...) {
    char buffer[1024];
    va_list arguments; va_start(arguments, format);
    int length = vsnprintf(buffer, sizeof(buffer), format, arguments);
    va_end(arguments);
    if (length > 0) write(1, buffer, (size_t)length < sizeof(buffer) ? (size_t)length : sizeof(buffer) - 1);
    return length;
}

int puts(const char* string) { return printf("%s\n", string); }

int open(const char* path, int flags) { return (int)checked_result(sys_open(path, (unsigned)flags)); }
ssize_t read(int fd, void* buffer, size_t length) { return (ssize_t)checked_result(sys_read(fd, buffer, length)); }
ssize_t write(int fd, const void* buffer, size_t length) { return (ssize_t)checked_result(sys_write(fd, buffer, length)); }
int close(int fd) { return (int)checked_result(sys_close(fd)); }
int unlink(const char* path) { return (int)checked_result(sys_unlink(path)); }
int mkdir(const char* path) { return (int)checked_result(sys_mkdir(path)); }
int stat(const char* path, struct sys_stat* result) { return (int)checked_result(sys_stat(path, result)); }
int chdir(const char* path) { return (int)checked_result(sys_chdir(path)); }
char* getcwd(char* buffer, size_t length) { return sys_getcwd(buffer, length) < 0 ? 0 : buffer; }
int dup(int fd) { return (int)checked_result(sys_dup(fd)); }
int dup2(int oldfd, int newfd) { return (int)checked_result(sys_dup2(oldfd, newfd)); }
int pipe(int fds[2]) { return (int)checked_result(sys_pipe(fds)); }
pid_t getpid(void) { return (pid_t)sys_getpid(); }
pid_t fork(void) { return (pid_t)checked_result(sys_fork()); }
pid_t waitpid(pid_t pid, int* status) { return (pid_t)sys_wait((unsigned)pid, status); }
int execv(const char* path, char* const argv[]) { return (int)checked_result(sys_execv(path, (const char* const*)argv)); }
void exit(int status) { (void)sys_exit(status); for (;;) { } }
void _exit(int status) { exit(status); }
unsigned long sleep(unsigned long ticks) { return (unsigned long)sys_sleep(ticks); }
int kill(pid_t pid, int signal) { return (int)checked_result(sys_kill((unsigned)pid, signal)); }
long ps(struct sys_process_info* buffer, size_t count) { return sys_ps(buffer, count); }
