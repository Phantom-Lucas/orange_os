#ifndef DEBUG_H
#define DEBUG_H
#include "print.h"

// 如果 condition 为假，直接触发 Panic，打印出错的文件和行号
#define ASSERT(condition) \
    if (!(condition)) { \
        panic_print("\n[ASSERTION FAILED] "); \
        panic_print(#condition); \
        panic_print(" at "); \
        panic_print(__FILE__); \
        panic_print(":"); \
        panic_print_int(__LINE__); \
        while(1) { __asm__ volatile("hlt"); } \
    }
#endif