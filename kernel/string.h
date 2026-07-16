// kernel/string.h
#ifndef STRING_H
#define STRING_H

// 计算字符串长度，返回不包括 '\0' 的字符数
unsigned long strlen(const char* str);

// 比较两个字符串。如果相等返回 0；否则返回非 0
int strcmp(const char* s1, const char* s2);

// 比较两个字符串的前 n 个字符。如果相等返回 0；否则返回非 0
int strncmp(const char* s1, const char* s2, int n);

// 将内存区域 dest 的前 count 个字节设置为 val
void* memset(void* dest, int val, unsigned long count);

// 将 src 开始的 count 个字节，拷贝到 dest
void* memcpy(void* dest, const void* src, unsigned long count);

// 将 src 字符串拷贝到 dest (遇到 '\0' 结束)
char* strcpy(char* dest, const char* src);

#endif