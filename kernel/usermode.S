/* kernel/usermode.S (全选覆盖) */
.global enter_user_mode

.global normalize_kernel_gs
normalize_kernel_gs:
    movabs $current_cpu, %rax
    mov %rax, %rdx
    shr $32, %rdx
    mov $0xC0000101, %ecx
    wrmsr
    xor %eax, %eax
    xor %edx, %edx
    mov $0xC0000102, %ecx
    wrmsr
    ret

.global set_user_fs_base
set_user_fs_base:
    /* %rdi = FS.base; user TLS uses the architectural FS base MSR. */
    mov %rdi, %rax
    mov %rdi, %rdx
    shr $32, %rdx
    mov $0xC0000100, %ecx
    wrmsr
    ret

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
    /* schedule/thread_block 已将当前上下文规范化为内核 GS。 */
    swapgs
    iretq

/*
 * 新用户线程的内核栈布局为：SS, RSP, RFLAGS, CS, RIP, arg。
 * switch_to 返回后 RSP 指向 SS，参数位于 iret frame 后的第六个 qword。
 */
.global return_to_user_with_arg
return_to_user_with_arg:
    /*
     * 新线程可能从 syscall 或用户态中断路径切入，入口时 GS 的交换
     * 历史并不可靠。显式恢复一对固定的 per-CPU GS 基址，确保后续
     * syscall_entry 的 swapgs 总能得到 current_cpu，而不是地址 0x8。
     */
    swapgs
    mov 40(%rsp), %rdi
    iretq

/* 在 syscall 的内核上下文中替换当前进程映像，不返回调用者。 */
.global resume_user_image
resume_user_image:
    /* %rdi = entry, %rsi = user rsp, %rdx = new cr3 */
    mov %rdx, %cr3
    pushq $0x1B
    pushq %rsi
    pushq $0x202
    pushq $0x23
    pushq %rdi
    swapgs
    iretq
