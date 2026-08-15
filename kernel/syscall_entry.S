/* kernel/syscall_entry.S */
.global syscall_entry

.section .text
syscall_entry:
    /* 进入内核 GS，并切换到当前线程的内核栈。 */
    swapgs
    movq %rsp, %gs:8
    movq %gs:0, %rsp

    /* 2. 安全换栈：绝对的并发安全！
       %gs:8 代表 current_cpu.user_rsp
       %gs:0 代表 current_cpu.kernel_rsp */
    /* 3. 硬件行为：syscall 会把用户跳回的地址存在 rcx，状态存在 r11 */
    pushq %rcx
    pushq %r11
    
    /* 4. 保存可能被 C 语言函数破坏的寄存器 */
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %r8
    pushq %r9
    pushq %r10

    /* fork 的子进程会跳过 C 函数返回，因此这些用户态 callee-saved
       寄存器也必须显式保存在可复制的 syscall 返回帧中。 */
    pushq %rbx
    pushq %rbp
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    /* 所有现场已保存后，才使用 R10/R11 临时保存当前线程的用户 RSP；
       这样不会破坏 syscall 的 RAX 编号或 sysret 所需的 RCX/R11。 */
    movabs $current_thread, %r11
    movq (%r11), %r11
    movq %gs:8, %r10
    movq %r10, 8(%r11)
    
    /* 5. 移形换影：重新排列参数，匹配 System V ABI */
    movq %rdx, %rcx  /* C: arg3 = Syscall: arg2 */
    movq %rsi, %rdx  /* C: arg2 = Syscall: arg1 */
    movq %rdi, %rsi  /* C: arg1 = Syscall: arg1 (实际上应该是参数1) */
    movq %rax, %rdi  /* C: sys_num = Syscall: rax (功能号) */
    movq %rsp, %r8   /* C: syscall_frame_rsp，用于 fork 复制返回现场 */

    /*
       调用前共压入 8 个寄存器（64 字节），因此保持内核栈的 16 字节对齐。
       C 函数的返回值留在 rax，作为用户态系统调用的返回值。
    */
    call syscall_handler

    jmp syscall_return_from_handler

 .global syscall_child_return
syscall_child_return:
    /* 调度切入内核上下文时已经处于内核 GS。 */
    xorq %rax, %rax  /* fork 子进程的返回值 */

 .global syscall_return_from_handler
syscall_return_from_handler:
    /* 6. 办事完毕，恢复寄存器 */
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbp
    popq %rbx
    popq %r10
    popq %r9
    popq %r8
    popq %rdx
    popq %rsi
    popq %rdi
    
    popq %r11
    popq %rcx

    /* 7. 换回平民的栈指针 */
    movq %gs:8, %rsp

    /* 8. 恢复平民的 GS 寄存器 (把我们在内核里用的 GS 藏回硬件 MSR 里) */
    swapgs
    
    /* 9. sysretq：极速返回 Ring 3！ */
    sysretq
