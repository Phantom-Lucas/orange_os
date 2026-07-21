// usr/hello.c

// 封装一个向内核发起 syscall 的内联汇编函数
// 约定：rax = 1 (print_string 调用号)，rdi = 字符串指针 (参数1)
static inline void sys_print(const char* str) {
    __asm__ volatile (
        "syscall \n"
        : 
        : "a"(1), "D"(str) // "a"约束映射到 rax, "D"约束映射到 rdi
        : "rcx", "r11", "memory" // 声明 syscall 会破坏 rcx 和 r11
    );
}

void _start() {
    // 发起系统调用，跨越特权级的呐喊！
    sys_print("[Ring 3] Hello, OS World!\n");
    sys_print("[Ring 3] My SwapGS Syscall is working perfectly!!!\n");

    // 绝对不能 return！在拥有 exit() 系统调用之前，只能锁死在这里
    while (1) {
        __asm__ volatile ("nop");
    }
}