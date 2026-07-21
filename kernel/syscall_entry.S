/* kernel/syscall_entry.S */
.global syscall_entry

.section .text
syscall_entry:
    /* 1. 魔法降临：交换 GS 寄存器！
       执行后，GS 基址瞬间变成我们在 C 里设置的 current_cpu 结构体地址 */
    swapgs

    /* 2. 安全换栈：绝对的并发安全！
       %gs:8 代表 current_cpu.user_rsp
       %gs:0 代表 current_cpu.kernel_rsp */
    movq %rsp, %gs:8      /* 把平民的栈指针存入 current_cpu.user_rsp */
    movq %gs:0, %rsp      /* 把 current_cpu.kernel_rsp 的值赋给真正的 rsp！ */

    /* 3. 硬件行为：syscall 会把用户跳回的地址存在 rcx，状态存在 r11 */
    pushq %rcx
    pushq %r11
    
    /* 4. 保存可能被 C 语言函数破坏的寄存器 */
    pushq %rax
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %r8
    pushq %r9
    pushq %r10
    
    /* 5. 移形换影：重新排列参数，匹配 System V ABI */
    movq %rdx, %rcx  /* C: arg3 = Syscall: arg2 */
    movq %rsi, %rdx  /* C: arg2 = Syscall: arg1 */
    movq %rdi, %rsi  /* C: arg1 = Syscall: arg1 (实际上应该是参数1) */
    movq %rax, %rdi  /* C: sys_num = Syscall: rax (功能号) */

    /* 呼叫市政大厅的 C 语言办公员！ */
    call syscall_handler

    /* 6. 办事完毕，恢复寄存器 */
    popq %r10
    popq %r9
    popq %r8
    popq %rdx
    popq %rsi
    popq %rdi
    popq %rax
    
    popq %r11
    popq %rcx

    /* 7. 换回平民的栈指针 */
    movq %gs:8, %rsp
    
    /* 8. 恢复平民的 GS 寄存器 (把我们在内核里用的 GS 藏回硬件 MSR 里) */
    swapgs
    
    /* 9. sysretq：极速返回 Ring 3！ */
    sysretq