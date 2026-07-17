global switch_to

; void switch_to(struct task_struct* current, struct task_struct* next);
switch_to:
    ; 1. 保存当前线程的执行现场 (Callee-saved registers)
    ; 调用 switch_to 时，CPU 已经自动将返回地址 (RIP) 压入栈中了
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; 2. 切换栈指针
    ; rdi 指向 current，且 current 的第一个成员是 rsp (偏移量 0)
    mov [rdi], rsp    ; current->rsp = 真实的 RSP
    
    ; rsi 指向 next，且 next 的第一个成员是 rsp (偏移量 0)
    mov rsp, [rsi]    ; 真实的 RSP = next->rsp
    ; --- 此时，CPU 已经“灵魂出窍”，当前处于新线程的栈空间中 ---

    ; 3. 恢复新线程的执行现场
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp

    ; 4. 返回
    ; 此时栈顶正好是 next 线程上次切换时保留的 RIP（或者是 thread_create 伪造的 RIP）
    ret