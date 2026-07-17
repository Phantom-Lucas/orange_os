
.global syscall_entry
.global kernel_rsp_scratch

/* 声明两个全局变量，用来在特权级切换时临时存放栈指针 */
.section .data
kernel_rsp_scratch: .quad 0
user_rsp_scratch:   .quad 0

.section .text
syscall_entry:
    /* 1. 极其关键的换栈操作！保护内核安全 */
    movq %rsp, user_rsp_scratch      /* 把平民的栈指针保存起来 */
    movq kernel_rsp_scratch, %rsp    /* 换上属于内核的安全栈指针！ */

    /* 2. 硬件行为：syscall 会把用户跳回的地址存在 rcx，状态存在 r11 */
    pushq %rcx
    pushq %r11
    
    /* 3. 保存可能被 C 语言函数破坏的寄存器 */
    pushq %rax
    pushq %rdi
    pushq %rsi
    pushq %rdx
    pushq %r8
    pushq %r9
    pushq %r10
    
    /* 4. 重新排列参数，为调用 syscall_handler 做准备 
       系统调用约定：功能号在 rax, 参数1在 rdi, 参数2在 rsi, 参数3在 rdx
       C 语言参数约定：第1个参数 rdi, 第2个 rsi, 第3个 rdx, 第4个 rcx 
       所以我们做一次“移形换影” */
    movq %rdx, %rcx  /* C: arg3 = Syscall: arg2 */
    movq %rsi, %rdx  /* C: arg2 = Syscall: arg1 */
    movq %rdi, %rsi  /* C: arg1 = Syscall: arg1 (实际上应该是参数1，稍微借位一下) */
    movq %rax, %rdi  /* C: sys_num = Syscall: rax (功能号) */

    /* 呼叫市政大厅的 C 语言办公员！ */
    call syscall_handler

    /* 5. 办事完毕，恢复寄存器 */
    popq %r10
    popq %r9
    popq %r8
    popq %rdx
    popq %rsi
    popq %rdi
    popq %rax
    
    popq %r11
    popq %rcx

    /* 6. 换回平民的栈指针 */
    movq user_rsp_scratch, %rsp
    
    /* 7. sysretq：极速返回 Ring 3！ */
    sysretq