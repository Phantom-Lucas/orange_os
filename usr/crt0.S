.text
.global _start
.type _start, @function

/* ELF loader 在用户栈顶构造 argc、argv；所有 libc 程序从这里统一进入 main。 */
_start:
    mov (%rsp), %edi
    lea 8(%rsp), %rsi
    call main
    mov %eax, %edi
    mov $7, %eax
    syscall
1:
    hlt
    jmp 1b
.size _start, .-_start
