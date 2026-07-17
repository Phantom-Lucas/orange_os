.global jump_to_usermode

/* void jump_to_usermode(uint64_t user_rip, uint64_t user_rsp); */
/* System V ABI 规定：第一个参数(user_rip)在 %rdi，第二个参数(user_rsp)在 %rsi */
jump_to_usermode:
    /* 1. 把所有普通的数据段寄存器，强行切换成 Ring 3 的用户数据段 (0x1B) */
    mov $0x1B, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    /* 2. 开始伪造 iretq 需要的 5 层堆栈 (压栈顺序必须严格从下往上) */
    
    /* 第 5 层：SS (用户态栈段) */
    pushq $0x1B

    /* 第 4 层：RSP (用户态栈顶指针) */
    pushq %rsi

    /* 第 3 层：RFLAGS (状态寄存器) */
    /* 必须是 0x202 (即保留位为 1，同时把第 9 位 IF 中断允许位置为 1) */
    pushq $0x202

    /* 第 2 层：CS (用户态代码段) */
    pushq $0x23

    /* 第 1 层：RIP (用户态指令指针，也就是要执行的用户函数地址) */
    pushq %rdi

    /* 3. 信仰之跃！ */
    /* CPU 会弹出上面的 5 个值，并瞬间将自身状态切换为 Ring 3 */
    iretq

.global return_to_user

/* 这是专门给调度器用的“跳板” */
return_to_user:
    /* 当 switch_to 执行 ret 弹出 RIP 跳转到这里时，
       当前的栈顶 (%rsp) 将精准地指向我们在 C 语言里伪造的 5 层 iretq 结构！
       我们只需要顺水推舟，执行一句 iretq 即可！ */
    iretq