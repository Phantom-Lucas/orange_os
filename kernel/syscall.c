// kernel/syscall.c
#include "syscall.h"
#include "print.h"

// 硬件规定的 4 个 MSR 寄存器地址
#define MSR_EFER           0xC0000080
#define MSR_STAR           0xC0000081
#define MSR_LSTAR          0xC0000082
#define MSR_FMASK          0xC0000084
// 内核 GS 基址寄存器 (用于 swapgs)
#define MSR_KERNEL_GS_BASE 0xC0000102 

// 声明即将用汇编写的传送门函数
extern void syscall_entry(void);

// 定义每 CPU (Per-CPU) 的局部数据结构
// 注意：内存布局必须严格，汇编里依靠硬编码的偏移量 (0x0 和 0x8) 来读写
struct cpu_local_data {
    uint64_t kernel_rsp; // 偏移 0x0：当前线程的内核栈
    uint64_t user_rsp;   // 偏移 0x8：用来临时保存用户的栈
};

// 全局实例化一个 cpu 数据结构 (目前是单核，所以一个就够了)
struct cpu_local_data current_cpu;

// 读写 MSR 的内置汇编函数
static inline void wrmsr(uint32_t msr, uint64_t val) {
    uint32_t low = (uint32_t)val;
    uint32_t high = (uint32_t)(val >> 32);
    __asm__ volatile("wrmsr" : : "c"(msr), "a"(low), "d"(high));
}

static inline uint64_t rdmsr(uint32_t msr) {
    uint32_t low, high;
    __asm__ volatile("rdmsr" : "=a"(low), "=d"(high) : "c"(msr));
    return ((uint64_t)high << 32) | low;
}

// ==========================================
// 1. 初始化系统调用机制
// ==========================================
void syscall_init() {
    // 1. 开启 EFER 寄存器中的 SCE (System Call Enable) 位
    uint64_t efer = rdmsr(MSR_EFER);
    wrmsr(MSR_EFER, efer | 1);
    
    // 2. 配置 STAR 寄存器 (内核段 0x08，用户段基址 0x10)
    wrmsr(MSR_STAR, (0x10ULL << 48) | (0x08ULL << 32));
    
    // 3. 配置 LSTAR 寄存器 (syscall 触发后跳转的内核入口点)
    wrmsr(MSR_LSTAR, (uint64_t)syscall_entry);
    
    // 4. 配置 FMASK 寄存器 (进入内核时，自动屏蔽 IF 中断位 0x200)
    wrmsr(MSR_FMASK, 0x200); 

    // 5. 【极其关键】：把 current_cpu 结构体的地址绑定到 KERNEL_GS_BASE
    wrmsr(MSR_KERNEL_GS_BASE, (uint64_t)&current_cpu);
}

// ==========================================
// 2. 真正的系统调用处理中心 (由汇编传送门调用)
// ==========================================
void syscall_handler(uint64_t sys_num, uint64_t arg1, uint64_t arg2, uint64_t arg3) {
    if (sys_num == 1) { 
        // 约定：系统调用号 1 代表 print_string
        print_string((char*)arg1);
    }
}