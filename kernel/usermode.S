/* kernel/usermode.S (全选覆盖) */
.global enter_user_mode

/* 
 * void enter_user_mode(uint64_t rip, uint64_t rsp, uint64_t cr3);
 * %rdi = rip, %rsi = rsp, %rdx = cr3
 */
enter_user_mode:
    cli

    /* 1. 安全切换页表。现在的 %rdx 才是真正干净的物理地址！ */
    mov %rdx, %cr3

    /* 2. 清零数据段，这是 64 位下最安全的做法，防止模拟器拦截 */
    xor %eax, %eax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    /* 3. 伪造 iretq 需要的 5 层堆栈 */
    
    /* 第 5 层: SS (用户态栈段 0x1B) */
    mov $0x1B, %rax
    pushq %rax
    
    /* 第 4 层: RSP (用户态栈顶指针) */
    pushq %rsi

    /* 第 3 层: RFLAGS (IF=1 开启中断) */
    mov $0x202, %rax
    pushq %rax

    /* 第 2 层: CS (用户态代码段 0x23) */
    mov $0x23, %rax
    pushq %rax

    /* 第 1 层: RIP (用户代码入口点) */
    pushq %rdi

    /* 4. 信仰之跃 */
    iretq

.global return_to_user
return_to_user:
    iretq