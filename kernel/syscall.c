#include "syscall.h"
#include "print.h"

// 硬件规定的 4 个 MSR 寄存器地址
#define MSR_EFER  0xC0000080
#define MSR_STAR  0xC0000081
#define MSR_LSTAR 0xC0000082
#define MSR_FMASK 0xC0000084

// 声明即将用汇编写的传送门函数
extern void syscall_entry(void);

// 读写 MSR 的内置汇编函数
static inline void wrmsr(uint32_t msr, uint64_t val) {
    uint32_t low = (uint32_t)val;
    uint32_t high = (uint32_t)(val >> 32);
    asm volatile("wrmsr" : : "c"(msr), "a"(low), "d"(high));
}

static inline uint64_t rdmsr(uint32_t msr) {
    uint32_t low, high;
    asm volatile("rdmsr" : "=a"(low), "=d"(high) : "c"(msr));
    return ((uint64_t)high << 32) | low;
}

// ==========================================
// 1. 初始化系统调用机制
// ==========================================
void syscall_init() {
    // 1. 开启 EFER 寄存器中的 SCE (System Call Enable) 位
    uint64_t efer = rdmsr(MSR_EFER);
    wrmsr(MSR_EFER, efer | 1);
    
    // 2. 配置 STAR 寄存器 (告诉 CPU 切换特权级时该用哪个 GDT 段)
    // 你的 GDT 是完美按标准排布的，所以这里刚好是：内核段 0x08，用户基址 0x10
    wrmsr(MSR_STAR, (0x10ULL << 48) | (0x08ULL << 32));
    
    // 3. 配置 LSTAR 寄存器 (告诉 CPU 警铃响了之后，跳到哪个函数执行)
    wrmsr(MSR_LSTAR, (uint64_t)syscall_entry);
    
    // 4. 配置 FMASK 寄存器 (进入内核时，自动屏蔽硬件中断，防止被时钟打扰)
    wrmsr(MSR_FMASK, 0x200); // 0x200 代表屏蔽 IF 中断位
}

// ==========================================
// 2. 真正的系统调用处理中心 (由汇编传送门调用)
// ==========================================
// 参数约定：sys_num 是功能号，arg1~arg3 是传递的参数
void syscall_handler(uint64_t sys_num, uint64_t arg1, uint64_t arg2, uint64_t arg3) {
    if (sys_num == 1) { 
        // 约定：系统调用号 1 代表 print_string
        // 因为内核可以访问所有内存，所以可以直接把 Ring 3 传来的字符串指针拿来用！
        print_string((char*)arg1);
    }
    // 未来你可以加上 sys_num == 2 (键盘输入) 等等
}