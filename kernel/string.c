// kernel/string.c
#include "string.h"

// 计算字符串长度，返回不包括 '\0' 的字符数
unsigned long strlen(const char* str) {
    unsigned long len = 0;
    while (*str++) {
        len++;
    }
    return len;
}

// 比较两个字符串。如果相等返回 0；否则返回非 0
int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

// 比较两个字符串的前 n 个字符。如果相等返回 0；否则返回非 0
int strncmp(const char* s1, const char* s2, int n) {
    while (n > 0 && *s1 && (*s1 == *s2)) {
        s1++; s2++; n--;
    }
    if (n == 0) return 0;
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

// 将内存区域 dest 的前 count 个字节设置为 val
void* memset(void* dest, int val, unsigned long count) {
    unsigned char* ptr = (unsigned char*)dest;
    while (count--) {
        *ptr++ = (unsigned char)val;
    }
    return dest;
}

// 将 src 开始的 count 个字节，拷贝到 dest
void* memcpy(void* dest, const void* src, unsigned long count) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    while (count--) {
        *d++ = *s++;
    }
    return dest;
}

// 将 src 字符串拷贝到 dest (遇到 '\0' 结束)
char* strcpy(char* dest, const char* src) {
    char* original_dest = dest;
    while ((*dest++ = *src++));
    return original_dest;
}