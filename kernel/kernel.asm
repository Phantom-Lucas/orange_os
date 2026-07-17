
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	48 83 ec 08          	sub    $0x8,%rsp
    1906:	e8 75 0d 00 00       	call   2680 <print_init>
    190b:	e8 e0 0d 00 00       	call   26f0 <clear_screen>
    1910:	bf 65 38 00 00       	mov    $0x3865,%edi
    1915:	e8 56 0e 00 00       	call   2770 <print_string>
    191a:	e8 51 01 00 00       	call   1a70 <gdt_init>
    191f:	e8 8c 04 00 00       	call   1db0 <idt_init>
    1924:	e8 c7 0b 00 00       	call   24f0 <pic_init>
    1929:	e8 02 1c 00 00       	call   3530 <timer_init>
    192e:	bf 00 00 00 08       	mov    $0x8000000,%edi
    1933:	e8 68 08 00 00       	call   21a0 <init_phy_mem_map>
    1938:	e8 f3 05 00 00       	call   1f30 <kmalloc_init>
    193d:	e8 2e 19 00 00       	call   3270 <syscall_init>
    1942:	bf e0 4c 00 00       	mov    $0x4ce0,%edi
    1947:	48 b8 0a 00 00 00 0a 	movabs $0xa0000000a,%rax
    194e:	00 00 00 
    1951:	c7 05 a5 33 00 00 00 	movl   $0x0,0x33a5(%rip)        # 4d00 <main_thread+0x20>
    1958:	00 00 00 
    195b:	48 89 05 8e 33 00 00 	mov    %rax,0x338e(%rip)        # 4cf0 <main_thread+0x10>
    1962:	48 c7 05 a3 33 00 00 	movq   $0x0,0x33a3(%rip)        # 4d10 <main_thread+0x30>
    1969:	00 00 00 00 
    196d:	e8 ee 19 00 00       	call   3360 <thread_append>
    1972:	be 0a 00 00 00       	mov    $0xa,%esi
    1977:	bf 10 21 00 00       	mov    $0x2110,%edi
    197c:	e8 bf 1a 00 00       	call   3440 <process_create>
    1981:	48 89 c7             	mov    %rax,%rdi
    1984:	e8 d7 19 00 00       	call   3360 <thread_append>
    1989:	be 0a 00 00 00       	mov    $0xa,%esi
    198e:	bf 50 21 00 00       	mov    $0x2150,%edi
    1993:	e8 a8 1a 00 00       	call   3440 <process_create>
    1998:	48 89 c7             	mov    %rax,%rdi
    199b:	e8 c0 19 00 00       	call   3360 <thread_append>
    19a0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    19a5:	e6 21                	out    %al,$0x21
    19a7:	fb                   	sti    
    19a8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    19af:	00 
    19b0:	f4                   	hlt    
    19b1:	eb fd                	jmp    19b0 <kernel_main+0xb0>

00000000000019b3 <gdt_flush>:
    19b3:	0f 01 17             	lgdt   (%rdi)
    19b6:	66 b8 10 00          	mov    $0x10,%ax
    19ba:	8e d8                	mov    %eax,%ds
    19bc:	8e c0                	mov    %eax,%es
    19be:	8e e0                	mov    %eax,%fs
    19c0:	8e e8                	mov    %eax,%gs
    19c2:	8e d0                	mov    %eax,%ss
    19c4:	6a 08                	push   $0x8
    19c6:	48 8d 05 03 00 00 00 	lea    0x3(%rip),%rax        # 19d0 <.flush_cs>
    19cd:	50                   	push   %rax
    19ce:	48 cb                	lretq  

00000000000019d0 <.flush_cs>:
    19d0:	c3                   	ret    

00000000000019d1 <tss_flush>:
    19d1:	66 b8 28 00          	mov    $0x28,%ax
    19d5:	0f 00 d8             	ltr    %ax
    19d8:	c3                   	ret    
    19d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000019e0 <set_gdt_entry>:
    19e0:	48 63 ff             	movslq %edi,%rdi
    19e3:	48 89 34 fd 60 3c 00 	mov    %rsi,0x3c60(,%rdi,8)
    19ea:	00 
    19eb:	c3                   	ret    
    19ec:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000019f0 <write_tss>:
    19f0:	b9 e0 3b 00 00       	mov    $0x3be0,%ecx
    19f5:	48 89 c8             	mov    %rcx,%rax
    19f8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    19ff:	00 
    1a00:	c6 00 00             	movb   $0x0,(%rax)
    1a03:	48 83 c0 01          	add    $0x1,%rax
    1a07:	48 3d 48 3c 00 00    	cmp    $0x3c48,%rax
    1a0d:	75 f1                	jne    1a00 <write_tss+0x10>
    1a0f:	b8 68 00 00 00       	mov    $0x68,%eax
    1a14:	48 63 f7             	movslq %edi,%rsi
    1a17:	48 ba 00 00 ff ff ff 	movabs $0xffffff0000,%rdx
    1a1e:	00 00 00 
    1a21:	66 89 05 1e 22 00 00 	mov    %ax,0x221e(%rip)        # 3c46 <tss+0x66>
    1a28:	48 89 c8             	mov    %rcx,%rax
    1a2b:	48 c1 e9 20          	shr    $0x20,%rcx
    1a2f:	48 c1 e0 10          	shl    $0x10,%rax
    1a33:	48 21 d0             	and    %rdx,%rax
    1a36:	ba e0 3b 00 00       	mov    $0x3be0,%edx
    1a3b:	c1 ea 18             	shr    $0x18,%edx
    1a3e:	48 c1 e2 38          	shl    $0x38,%rdx
    1a42:	48 09 d0             	or     %rdx,%rax
    1a45:	48 ba 67 00 00 00 00 	movabs $0x890000000067,%rdx
    1a4c:	89 00 00 
    1a4f:	48 09 d0             	or     %rdx,%rax
    1a52:	48 89 04 f5 60 3c 00 	mov    %rax,0x3c60(,%rsi,8)
    1a59:	00 
    1a5a:	8d 47 01             	lea    0x1(%rdi),%eax
    1a5d:	48 98                	cltq   
    1a5f:	48 89 0c c5 60 3c 00 	mov    %rcx,0x3c60(,%rax,8)
    1a66:	00 
    1a67:	c3                   	ret    
    1a68:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1a6f:	00 

0000000000001a70 <gdt_init>:
    1a70:	48 83 ec 08          	sub    $0x8,%rsp
    1a74:	ba 37 00 00 00       	mov    $0x37,%edx
    1a79:	b9 e0 3b 00 00       	mov    $0x3be0,%ecx
    1a7e:	48 b8 ff ff 00 00 00 	movabs $0xaf98000000ffff,%rax
    1a85:	98 af 00 
    1a88:	48 89 05 d9 21 00 00 	mov    %rax,0x21d9(%rip)        # 3c68 <gdt_entries+0x8>
    1a8f:	48 b8 ff ff 00 00 00 	movabs $0xaf92000000ffff,%rax
    1a96:	92 af 00 
    1a99:	48 89 05 d0 21 00 00 	mov    %rax,0x21d0(%rip)        # 3c70 <gdt_entries+0x10>
    1aa0:	48 b8 ff ff 00 00 00 	movabs $0xaff2000000ffff,%rax
    1aa7:	f2 af 00 
    1aaa:	66 89 15 97 21 00 00 	mov    %dx,0x2197(%rip)        # 3c48 <gdt_ptr>
    1ab1:	48 c7 05 8e 21 00 00 	movq   $0x3c60,0x218e(%rip)        # 3c4a <gdt_ptr+0x2>
    1ab8:	60 3c 00 00 
    1abc:	48 c7 05 99 21 00 00 	movq   $0x0,0x2199(%rip)        # 3c60 <gdt_entries>
    1ac3:	00 00 00 00 
    1ac7:	48 89 05 aa 21 00 00 	mov    %rax,0x21aa(%rip)        # 3c78 <gdt_entries+0x18>
    1ace:	48 b8 ff ff 00 00 00 	movabs $0xaff8000000ffff,%rax
    1ad5:	f8 af 00 
    1ad8:	48 89 05 a1 21 00 00 	mov    %rax,0x21a1(%rip)        # 3c80 <gdt_entries+0x20>
    1adf:	48 89 c8             	mov    %rcx,%rax
    1ae2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1ae8:	c6 00 00             	movb   $0x0,(%rax)
    1aeb:	48 83 c0 01          	add    $0x1,%rax
    1aef:	48 3d 48 3c 00 00    	cmp    $0x3c48,%rax
    1af5:	75 f1                	jne    1ae8 <gdt_init+0x78>
    1af7:	b8 68 00 00 00       	mov    $0x68,%eax
    1afc:	be e0 3b 00 00       	mov    $0x3be0,%esi
    1b01:	bf 48 3c 00 00       	mov    $0x3c48,%edi
    1b06:	48 ba 00 00 ff ff ff 	movabs $0xffffff0000,%rdx
    1b0d:	00 00 00 
    1b10:	66 89 05 2f 21 00 00 	mov    %ax,0x212f(%rip)        # 3c46 <tss+0x66>
    1b17:	48 89 c8             	mov    %rcx,%rax
    1b1a:	48 c1 e9 20          	shr    $0x20,%rcx
    1b1e:	48 c1 e0 10          	shl    $0x10,%rax
    1b22:	48 89 0d 67 21 00 00 	mov    %rcx,0x2167(%rip)        # 3c90 <gdt_entries+0x30>
    1b29:	48 21 d0             	and    %rdx,%rax
    1b2c:	8d 16                	lea    (%rsi),%edx
    1b2e:	c1 ea 18             	shr    $0x18,%edx
    1b31:	48 c1 e2 38          	shl    $0x38,%rdx
    1b35:	48 09 d0             	or     %rdx,%rax
    1b38:	48 ba 67 00 00 00 00 	movabs $0x890000000067,%rdx
    1b3f:	89 00 00 
    1b42:	48 09 d0             	or     %rdx,%rax
    1b45:	48 89 05 3c 21 00 00 	mov    %rax,0x213c(%rip)        # 3c88 <gdt_entries+0x28>
    1b4c:	e8 62 fe ff ff       	call   19b3 <gdt_flush>
    1b51:	48 83 c4 08          	add    $0x8,%rsp
    1b55:	e9 77 fe ff ff       	jmp    19d1 <tss_flush>
    1b5a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001b60 <set_tss_rsp0>:
    1b60:	48 89 3d 7d 20 00 00 	mov    %rdi,0x207d(%rip)        # 3be4 <tss+0x4>
    1b67:	c3                   	ret    
    1b68:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b6f:	00 

0000000000001b70 <isr0_divide_by_zero>:
    1b70:	41 53                	push   %r11
    1b72:	41 52                	push   %r10
    1b74:	41 51                	push   %r9
    1b76:	41 50                	push   %r8
    1b78:	57                   	push   %rdi
    1b79:	bf 40 36 00 00       	mov    $0x3640,%edi
    1b7e:	56                   	push   %rsi
    1b7f:	51                   	push   %rcx
    1b80:	52                   	push   %rdx
    1b81:	50                   	push   %rax
    1b82:	fc                   	cld    
    1b83:	e8 e8 0b 00 00       	call   2770 <print_string>
    1b88:	bf 78 36 00 00       	mov    $0x3678,%edi
    1b8d:	e8 de 0b 00 00       	call   2770 <print_string>
    1b92:	bf a8 36 00 00       	mov    $0x36a8,%edi
    1b97:	e8 d4 0b 00 00       	call   2770 <print_string>
    1b9c:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    1ba1:	e8 0a 0c 00 00       	call   27b0 <print_hex>
    1ba6:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1bab:	e8 c0 0b 00 00       	call   2770 <print_string>
    1bb0:	bf d0 36 00 00       	mov    $0x36d0,%edi
    1bb5:	e8 b6 0b 00 00       	call   2770 <print_string>
    1bba:	bf 90 37 00 00       	mov    $0x3790,%edi
    1bbf:	e8 ac 0b 00 00       	call   2770 <print_string>
    1bc4:	0f 1f 40 00          	nopl   0x0(%rax)
    1bc8:	f4                   	hlt    
    1bc9:	eb fd                	jmp    1bc8 <isr0_divide_by_zero+0x58>
    1bcb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001bd0 <isr13_gpf>:
    1bd0:	41 53                	push   %r11
    1bd2:	41 52                	push   %r10
    1bd4:	41 51                	push   %r9
    1bd6:	41 50                	push   %r8
    1bd8:	55                   	push   %rbp
    1bd9:	57                   	push   %rdi
    1bda:	bf 40 36 00 00       	mov    $0x3640,%edi
    1bdf:	56                   	push   %rsi
    1be0:	51                   	push   %rcx
    1be1:	52                   	push   %rdx
    1be2:	50                   	push   %rax
    1be3:	48 8b 6c 24 50       	mov    0x50(%rsp),%rbp
    1be8:	fc                   	cld    
    1be9:	e8 62 0d 00 00       	call   2950 <print_error>
    1bee:	bf 08 37 00 00       	mov    $0x3708,%edi
    1bf3:	e8 58 0d 00 00       	call   2950 <print_error>
    1bf8:	bf a0 37 00 00       	mov    $0x37a0,%edi
    1bfd:	e8 6e 0b 00 00       	call   2770 <print_string>
    1c02:	48 89 ef             	mov    %rbp,%rdi
    1c05:	e8 a6 0b 00 00       	call   27b0 <print_hex>
    1c0a:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1c0f:	e8 5c 0b 00 00       	call   2770 <print_string>
    1c14:	bf ad 37 00 00       	mov    $0x37ad,%edi
    1c19:	e8 52 0b 00 00       	call   2770 <print_string>
    1c1e:	48 8b 7c 24 58       	mov    0x58(%rsp),%rdi
    1c23:	e8 88 0b 00 00       	call   27b0 <print_hex>
    1c28:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1c2d:	e8 3e 0b 00 00       	call   2770 <print_string>
    1c32:	bf 90 37 00 00       	mov    $0x3790,%edi
    1c37:	e8 14 0d 00 00       	call   2950 <print_error>
    1c3c:	0f 1f 40 00          	nopl   0x0(%rax)
    1c40:	f4                   	hlt    
    1c41:	eb fd                	jmp    1c40 <isr13_gpf+0x70>
    1c43:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1c4a:	00 00 00 00 
    1c4e:	66 90                	xchg   %ax,%ax

0000000000001c50 <isr14_page_fault>:
    1c50:	41 54                	push   %r12
    1c52:	41 53                	push   %r11
    1c54:	41 52                	push   %r10
    1c56:	41 51                	push   %r9
    1c58:	41 50                	push   %r8
    1c5a:	55                   	push   %rbp
    1c5b:	57                   	push   %rdi
    1c5c:	56                   	push   %rsi
    1c5d:	51                   	push   %rcx
    1c5e:	52                   	push   %rdx
    1c5f:	50                   	push   %rax
    1c60:	48 83 ec 08          	sub    $0x8,%rsp
    1c64:	48 8b 6c 24 60       	mov    0x60(%rsp),%rbp
    1c69:	41 0f 20 d4          	mov    %cr2,%r12
    1c6d:	bf 40 36 00 00       	mov    $0x3640,%edi
    1c72:	fc                   	cld    
    1c73:	e8 d8 0c 00 00       	call   2950 <print_error>
    1c78:	bf 40 37 00 00       	mov    $0x3740,%edi
    1c7d:	e8 ce 0c 00 00       	call   2950 <print_error>
    1c82:	bf 70 37 00 00       	mov    $0x3770,%edi
    1c87:	e8 e4 0a 00 00       	call   2770 <print_string>
    1c8c:	4c 89 e7             	mov    %r12,%rdi
    1c8f:	e8 1c 0b 00 00       	call   27b0 <print_hex>
    1c94:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1c99:	e8 d2 0a 00 00       	call   2770 <print_string>
    1c9e:	bf a0 37 00 00       	mov    $0x37a0,%edi
    1ca3:	e8 c8 0a 00 00       	call   2770 <print_string>
    1ca8:	48 89 ef             	mov    %rbp,%rdi
    1cab:	e8 00 0b 00 00       	call   27b0 <print_hex>
    1cb0:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1cb5:	e8 b6 0a 00 00       	call   2770 <print_string>
    1cba:	bf ad 37 00 00       	mov    $0x37ad,%edi
    1cbf:	e8 ac 0a 00 00       	call   2770 <print_string>
    1cc4:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
    1cc9:	e8 e2 0a 00 00       	call   27b0 <print_hex>
    1cce:	bf 7d 38 00 00       	mov    $0x387d,%edi
    1cd3:	e8 98 0a 00 00       	call   2770 <print_string>
    1cd8:	bf 90 37 00 00       	mov    $0x3790,%edi
    1cdd:	e8 6e 0c 00 00       	call   2950 <print_error>
    1ce2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1ce8:	f4                   	hlt    
    1ce9:	eb fd                	jmp    1ce8 <isr14_page_fault+0x98>
    1ceb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001cf0 <isr32_timer>:
    1cf0:	41 53                	push   %r11
    1cf2:	41 52                	push   %r10
    1cf4:	41 51                	push   %r9
    1cf6:	41 50                	push   %r8
    1cf8:	57                   	push   %rdi
    1cf9:	56                   	push   %rsi
    1cfa:	51                   	push   %rcx
    1cfb:	52                   	push   %rdx
    1cfc:	50                   	push   %rax
    1cfd:	fc                   	cld    
    1cfe:	e8 4d 18 00 00       	call   3550 <timer_interrupt_handler>
    1d03:	58                   	pop    %rax
    1d04:	5a                   	pop    %rdx
    1d05:	59                   	pop    %rcx
    1d06:	5e                   	pop    %rsi
    1d07:	5f                   	pop    %rdi
    1d08:	41 58                	pop    %r8
    1d0a:	41 59                	pop    %r9
    1d0c:	41 5a                	pop    %r10
    1d0e:	41 5b                	pop    %r11
    1d10:	48 cf                	iretq  
    1d12:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1d19:	00 00 00 00 
    1d1d:	0f 1f 00             	nopl   (%rax)

0000000000001d20 <isr33_keyboard>:
    1d20:	41 53                	push   %r11
    1d22:	41 52                	push   %r10
    1d24:	41 51                	push   %r9
    1d26:	41 50                	push   %r8
    1d28:	57                   	push   %rdi
    1d29:	56                   	push   %rsi
    1d2a:	51                   	push   %rcx
    1d2b:	52                   	push   %rdx
    1d2c:	50                   	push   %rax
    1d2d:	e4 60                	in     $0x60,%al
    1d2f:	84 c0                	test   %al,%al
    1d31:	78 0f                	js     1d42 <isr33_keyboard+0x22>
    1d33:	0f b6 c0             	movzbl %al,%eax
    1d36:	0f be b8 c0 35 00 00 	movsbl 0x35c0(%rax),%edi
    1d3d:	40 84 ff             	test   %dil,%dil
    1d40:	75 1e                	jne    1d60 <isr33_keyboard+0x40>
    1d42:	b8 20 00 00 00       	mov    $0x20,%eax
    1d47:	e6 20                	out    %al,$0x20
    1d49:	58                   	pop    %rax
    1d4a:	5a                   	pop    %rdx
    1d4b:	59                   	pop    %rcx
    1d4c:	5e                   	pop    %rsi
    1d4d:	5f                   	pop    %rdi
    1d4e:	41 58                	pop    %r8
    1d50:	41 59                	pop    %r9
    1d52:	41 5a                	pop    %r10
    1d54:	41 5b                	pop    %r11
    1d56:	48 cf                	iretq  
    1d58:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1d5f:	00 
    1d60:	fc                   	cld    
    1d61:	e8 da 10 00 00       	call   2e40 <shell_take_char>
    1d66:	eb da                	jmp    1d42 <isr33_keyboard+0x22>
    1d68:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1d6f:	00 

0000000000001d70 <set_idt_gate>:
    1d70:	48 63 ff             	movslq %edi,%rdi
    1d73:	48 89 f2             	mov    %rsi,%rdx
    1d76:	48 c1 e7 04          	shl    $0x4,%rdi
    1d7a:	48 c1 ea 10          	shr    $0x10,%rdx
    1d7e:	66 89 b7 c0 3c 00 00 	mov    %si,0x3cc0(%rdi)
    1d85:	48 c1 ee 20          	shr    $0x20,%rsi
    1d89:	c7 87 c2 3c 00 00 08 	movl   $0x8e000008,0x3cc2(%rdi)
    1d90:	00 00 8e 
    1d93:	66 89 97 c6 3c 00 00 	mov    %dx,0x3cc6(%rdi)
    1d9a:	89 b7 c8 3c 00 00    	mov    %esi,0x3cc8(%rdi)
    1da0:	c7 87 cc 3c 00 00 00 	movl   $0x0,0x3ccc(%rdi)
    1da7:	00 00 00 
    1daa:	c3                   	ret    
    1dab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001db0 <idt_init>:
    1db0:	b8 c0 3c 00 00       	mov    $0x3cc0,%eax
    1db5:	0f 1f 00             	nopl   (%rax)
    1db8:	31 d2                	xor    %edx,%edx
    1dba:	b9 08 00 00 00       	mov    $0x8,%ecx
    1dbf:	31 f6                	xor    %esi,%esi
    1dc1:	c6 40 04 00          	movb   $0x0,0x4(%rax)
    1dc5:	66 89 10             	mov    %dx,(%rax)
    1dc8:	48 83 c0 10          	add    $0x10,%rax
    1dcc:	66 89 48 f2          	mov    %cx,-0xe(%rax)
    1dd0:	c6 40 f5 8e          	movb   $0x8e,-0xb(%rax)
    1dd4:	66 89 70 f6          	mov    %si,-0xa(%rax)
    1dd8:	c7 40 f8 00 00 00 00 	movl   $0x0,-0x8(%rax)
    1ddf:	c7 40 fc 00 00 00 00 	movl   $0x0,-0x4(%rax)
    1de6:	48 3d c0 4c 00 00    	cmp    $0x4cc0,%rax
    1dec:	75 ca                	jne    1db8 <idt_init+0x8>
    1dee:	c7 05 ca 1e 00 00 08 	movl   $0x8e000008,0x1eca(%rip)        # 3cc2 <idt+0x2>
    1df5:	00 00 8e 
    1df8:	b8 70 1b 00 00       	mov    $0x1b70,%eax
    1dfd:	66 89 05 bc 1e 00 00 	mov    %ax,0x1ebc(%rip)        # 3cc0 <idt>
    1e04:	48 89 c2             	mov    %rax,%rdx
    1e07:	48 c1 e8 20          	shr    $0x20,%rax
    1e0b:	48 c1 ea 10          	shr    $0x10,%rdx
    1e0f:	89 05 b3 1e 00 00    	mov    %eax,0x1eb3(%rip)        # 3cc8 <idt+0x8>
    1e15:	b8 d0 1b 00 00       	mov    $0x1bd0,%eax
    1e1a:	66 89 15 a5 1e 00 00 	mov    %dx,0x1ea5(%rip)        # 3cc6 <idt+0x6>
    1e21:	48 89 c2             	mov    %rax,%rdx
    1e24:	66 89 05 65 1f 00 00 	mov    %ax,0x1f65(%rip)        # 3d90 <idt+0xd0>
    1e2b:	48 c1 e8 20          	shr    $0x20,%rax
    1e2f:	48 c1 ea 10          	shr    $0x10,%rdx
    1e33:	89 05 5f 1f 00 00    	mov    %eax,0x1f5f(%rip)        # 3d98 <idt+0xd8>
    1e39:	b8 50 1c 00 00       	mov    $0x1c50,%eax
    1e3e:	66 89 15 51 1f 00 00 	mov    %dx,0x1f51(%rip)        # 3d96 <idt+0xd6>
    1e45:	48 89 c2             	mov    %rax,%rdx
    1e48:	66 89 05 51 1f 00 00 	mov    %ax,0x1f51(%rip)        # 3da0 <idt+0xe0>
    1e4f:	48 c1 e8 20          	shr    $0x20,%rax
    1e53:	48 c1 ea 10          	shr    $0x10,%rdx
    1e57:	89 05 4b 1f 00 00    	mov    %eax,0x1f4b(%rip)        # 3da8 <idt+0xe8>
    1e5d:	b8 f0 1c 00 00       	mov    $0x1cf0,%eax
    1e62:	66 89 15 3d 1f 00 00 	mov    %dx,0x1f3d(%rip)        # 3da6 <idt+0xe6>
    1e69:	48 89 c2             	mov    %rax,%rdx
    1e6c:	66 89 05 4d 20 00 00 	mov    %ax,0x204d(%rip)        # 3ec0 <idt+0x200>
    1e73:	48 c1 e8 20          	shr    $0x20,%rax
    1e77:	48 c1 ea 10          	shr    $0x10,%rdx
    1e7b:	89 05 47 20 00 00    	mov    %eax,0x2047(%rip)        # 3ec8 <idt+0x208>
    1e81:	b8 20 1d 00 00       	mov    $0x1d20,%eax
    1e86:	66 89 15 39 20 00 00 	mov    %dx,0x2039(%rip)        # 3ec6 <idt+0x206>
    1e8d:	48 89 c2             	mov    %rax,%rdx
    1e90:	66 89 05 39 20 00 00 	mov    %ax,0x2039(%rip)        # 3ed0 <idt+0x210>
    1e97:	48 c1 e8 20          	shr    $0x20,%rax
    1e9b:	48 c1 ea 10          	shr    $0x10,%rdx
    1e9f:	89 05 33 20 00 00    	mov    %eax,0x2033(%rip)        # 3ed8 <idt+0x218>
    1ea5:	b8 ff 0f 00 00       	mov    $0xfff,%eax
    1eaa:	c7 05 18 1e 00 00 00 	movl   $0x0,0x1e18(%rip)        # 3ccc <idt+0xc>
    1eb1:	00 00 00 
    1eb4:	c7 05 d4 1e 00 00 08 	movl   $0x8e000008,0x1ed4(%rip)        # 3d92 <idt+0xd2>
    1ebb:	00 00 8e 
    1ebe:	c7 05 d4 1e 00 00 00 	movl   $0x0,0x1ed4(%rip)        # 3d9c <idt+0xdc>
    1ec5:	00 00 00 
    1ec8:	c7 05 d0 1e 00 00 08 	movl   $0x8e000008,0x1ed0(%rip)        # 3da2 <idt+0xe2>
    1ecf:	00 00 8e 
    1ed2:	c7 05 d0 1e 00 00 00 	movl   $0x0,0x1ed0(%rip)        # 3dac <idt+0xec>
    1ed9:	00 00 00 
    1edc:	c7 05 dc 1f 00 00 08 	movl   $0x8e000008,0x1fdc(%rip)        # 3ec2 <idt+0x202>
    1ee3:	00 00 8e 
    1ee6:	c7 05 dc 1f 00 00 00 	movl   $0x0,0x1fdc(%rip)        # 3ecc <idt+0x20c>
    1eed:	00 00 00 
    1ef0:	c7 05 d8 1f 00 00 08 	movl   $0x8e000008,0x1fd8(%rip)        # 3ed2 <idt+0x212>
    1ef7:	00 00 8e 
    1efa:	66 89 15 d5 1f 00 00 	mov    %dx,0x1fd5(%rip)        # 3ed6 <idt+0x216>
    1f01:	c7 05 d1 1f 00 00 00 	movl   $0x0,0x1fd1(%rip)        # 3edc <idt+0x21c>
    1f08:	00 00 00 
    1f0b:	66 89 05 8e 1d 00 00 	mov    %ax,0x1d8e(%rip)        # 3ca0 <idtr_reg>
    1f12:	48 c7 05 85 1d 00 00 	movq   $0x3cc0,0x1d85(%rip)        # 3ca2 <idtr_reg+0x2>
    1f19:	c0 3c 00 00 
    1f1d:	0f 01 1d 7c 1d 00 00 	lidt   0x1d7c(%rip)        # 3ca0 <idtr_reg>
    1f24:	c3                   	ret    
    1f25:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1f2c:	00 00 00 
    1f2f:	90                   	nop

0000000000001f30 <kmalloc_init>:
    1f30:	48 83 ec 08          	sub    $0x8,%rsp
    1f34:	31 c0                	xor    %eax,%eax
    1f36:	e8 55 05 00 00       	call   2490 <alloc_page>
    1f3b:	48 85 c0             	test   %rax,%rax
    1f3e:	74 30                	je     1f70 <kmalloc_init+0x40>
    1f40:	48 89 05 79 2d 00 00 	mov    %rax,0x2d79(%rip)        # 4cc0 <heap_head>
    1f47:	bf 00 38 00 00       	mov    $0x3800,%edi
    1f4c:	48 c7 40 10 e8 0f 00 	movq   $0xfe8,0x10(%rax)
    1f53:	00 
    1f54:	c6 40 08 01          	movb   $0x1,0x8(%rax)
    1f58:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    1f5f:	48 83 c4 08          	add    $0x8,%rsp
    1f63:	e9 08 08 00 00       	jmp    2770 <print_string>
    1f68:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1f6f:	00 
    1f70:	bf c8 37 00 00       	mov    $0x37c8,%edi
    1f75:	48 83 c4 08          	add    $0x8,%rsp
    1f79:	e9 f2 07 00 00       	jmp    2770 <print_string>
    1f7e:	66 90                	xchg   %ax,%ax

0000000000001f80 <kmalloc>:
    1f80:	41 55                	push   %r13
    1f82:	41 54                	push   %r12
    1f84:	55                   	push   %rbp
    1f85:	53                   	push   %rbx
    1f86:	48 83 ec 08          	sub    $0x8,%rsp
    1f8a:	48 85 ff             	test   %rdi,%rdi
    1f8d:	0f 84 ec 00 00 00    	je     207f <kmalloc+0xff>
    1f93:	48 8d 5f 07          	lea    0x7(%rdi),%rbx
    1f97:	48 8b 05 22 2d 00 00 	mov    0x2d22(%rip),%rax        # 4cc0 <heap_head>
    1f9e:	48 83 e3 f8          	and    $0xfffffffffffffff8,%rbx
    1fa2:	48 8d ab 17 10 00 00 	lea    0x1017(%rbx),%rbp
    1fa9:	48 c1 ed 0c          	shr    $0xc,%rbp
    1fad:	41 89 ed             	mov    %ebp,%r13d
    1fb0:	c1 e5 0c             	shl    $0xc,%ebp
    1fb3:	48 83 ed 18          	sub    $0x18,%rbp
    1fb7:	eb 19                	jmp    1fd2 <kmalloc+0x52>
    1fb9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1fc0:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1fc4:	74 09                	je     1fcf <kmalloc+0x4f>
    1fc6:	48 8b 50 10          	mov    0x10(%rax),%rdx
    1fca:	48 39 da             	cmp    %rbx,%rdx
    1fcd:	73 61                	jae    2030 <kmalloc+0xb0>
    1fcf:	48 8b 00             	mov    (%rax),%rax
    1fd2:	48 85 c0             	test   %rax,%rax
    1fd5:	75 e9                	jne    1fc0 <kmalloc+0x40>
    1fd7:	44 89 ef             	mov    %r13d,%edi
    1fda:	e8 d1 03 00 00       	call   23b0 <alloc_pages>
    1fdf:	49 89 c4             	mov    %rax,%r12
    1fe2:	48 85 c0             	test   %rax,%rax
    1fe5:	0f 84 88 00 00 00    	je     2073 <kmalloc+0xf3>
    1feb:	48 89 68 10          	mov    %rbp,0x10(%rax)
    1fef:	c6 40 08 01          	movb   $0x1,0x8(%rax)
    1ff3:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    1ffa:	48 8b 05 bf 2c 00 00 	mov    0x2cbf(%rip),%rax        # 4cc0 <heap_head>
    2001:	48 89 c2             	mov    %rax,%rdx
    2004:	48 85 c0             	test   %rax,%rax
    2007:	75 0f                	jne    2018 <kmalloc+0x98>
    2009:	4c 89 25 b0 2c 00 00 	mov    %r12,0x2cb0(%rip)        # 4cc0 <heap_head>
    2010:	4c 89 e0             	mov    %r12,%rax
    2013:	eb bd                	jmp    1fd2 <kmalloc+0x52>
    2015:	0f 1f 00             	nopl   (%rax)
    2018:	48 89 d1             	mov    %rdx,%rcx
    201b:	48 8b 12             	mov    (%rdx),%rdx
    201e:	48 85 d2             	test   %rdx,%rdx
    2021:	75 f5                	jne    2018 <kmalloc+0x98>
    2023:	4c 89 21             	mov    %r12,(%rcx)
    2026:	eb aa                	jmp    1fd2 <kmalloc+0x52>
    2028:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    202f:	00 
    2030:	48 8d 4b 20          	lea    0x20(%rbx),%rcx
    2034:	48 39 ca             	cmp    %rcx,%rdx
    2037:	73 17                	jae    2050 <kmalloc+0xd0>
    2039:	c6 40 08 00          	movb   $0x0,0x8(%rax)
    203d:	4c 8d 60 18          	lea    0x18(%rax),%r12
    2041:	48 83 c4 08          	add    $0x8,%rsp
    2045:	4c 89 e0             	mov    %r12,%rax
    2048:	5b                   	pop    %rbx
    2049:	5d                   	pop    %rbp
    204a:	41 5c                	pop    %r12
    204c:	41 5d                	pop    %r13
    204e:	c3                   	ret    
    204f:	90                   	nop
    2050:	48 29 da             	sub    %rbx,%rdx
    2053:	48 8d 4c 18 18       	lea    0x18(%rax,%rbx,1),%rcx
    2058:	48 83 ea 18          	sub    $0x18,%rdx
    205c:	c6 41 08 01          	movb   $0x1,0x8(%rcx)
    2060:	48 89 51 10          	mov    %rdx,0x10(%rcx)
    2064:	48 8b 10             	mov    (%rax),%rdx
    2067:	48 89 11             	mov    %rdx,(%rcx)
    206a:	48 89 58 10          	mov    %rbx,0x10(%rax)
    206e:	48 89 08             	mov    %rcx,(%rax)
    2071:	eb c6                	jmp    2039 <kmalloc+0xb9>
    2073:	bf 38 38 00 00       	mov    $0x3838,%edi
    2078:	e8 f3 06 00 00       	call   2770 <print_string>
    207d:	eb c2                	jmp    2041 <kmalloc+0xc1>
    207f:	45 31 e4             	xor    %r12d,%r12d
    2082:	eb bd                	jmp    2041 <kmalloc+0xc1>
    2084:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    208b:	00 00 00 00 
    208f:	90                   	nop

0000000000002090 <kfree>:
    2090:	48 85 ff             	test   %rdi,%rdi
    2093:	74 33                	je     20c8 <kfree+0x38>
    2095:	48 8b 47 e8          	mov    -0x18(%rdi),%rax
    2099:	c6 47 f0 01          	movb   $0x1,-0x10(%rdi)
    209d:	48 8d 4f e8          	lea    -0x18(%rdi),%rcx
    20a1:	48 85 c0             	test   %rax,%rax
    20a4:	74 06                	je     20ac <kfree+0x1c>
    20a6:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    20aa:	75 24                	jne    20d0 <kfree+0x40>
    20ac:	48 8b 05 0d 2c 00 00 	mov    0x2c0d(%rip),%rax        # 4cc0 <heap_head>
    20b3:	eb 0e                	jmp    20c3 <kfree+0x33>
    20b5:	0f 1f 00             	nopl   (%rax)
    20b8:	48 8b 10             	mov    (%rax),%rdx
    20bb:	48 39 ca             	cmp    %rcx,%rdx
    20be:	74 30                	je     20f0 <kfree+0x60>
    20c0:	48 89 d0             	mov    %rdx,%rax
    20c3:	48 85 c0             	test   %rax,%rax
    20c6:	75 f0                	jne    20b8 <kfree+0x28>
    20c8:	c3                   	ret    
    20c9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    20d0:	48 8b 50 10          	mov    0x10(%rax),%rdx
    20d4:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    20d8:	48 8b 00             	mov    (%rax),%rax
    20db:	48 8d 54 16 18       	lea    0x18(%rsi,%rdx,1),%rdx
    20e0:	48 89 57 f8          	mov    %rdx,-0x8(%rdi)
    20e4:	48 89 47 e8          	mov    %rax,-0x18(%rdi)
    20e8:	eb c2                	jmp    20ac <kfree+0x1c>
    20ea:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    20f0:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    20f4:	74 d2                	je     20c8 <kfree+0x38>
    20f6:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    20fa:	48 8d 56 18          	lea    0x18(%rsi),%rdx
    20fe:	48 01 50 10          	add    %rdx,0x10(%rax)
    2102:	48 8b 57 e8          	mov    -0x18(%rdi),%rdx
    2106:	48 89 10             	mov    %rdx,(%rax)
    2109:	c3                   	ret    
    210a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000002110 <user_app_a>:
    2110:	50                   	push   %rax
    2111:	58                   	pop    %rax
    2112:	bf 61 38 00 00       	mov    $0x3861,%edi
    2117:	b8 01 00 00 00       	mov    $0x1,%eax
    211c:	48 83 ec 10          	sub    $0x10,%rsp
    2120:	0f 05                	syscall 
    2122:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%rsp)
    2129:	00 
    212a:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    212e:	81 fa 7f 96 98 00    	cmp    $0x98967f,%edx
    2134:	7f ea                	jg     2120 <user_app_a+0x10>
    2136:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    213a:	83 c2 01             	add    $0x1,%edx
    213d:	89 54 24 0c          	mov    %edx,0xc(%rsp)
    2141:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    2145:	81 fa 7f 96 98 00    	cmp    $0x98967f,%edx
    214b:	7e e9                	jle    2136 <user_app_a+0x26>
    214d:	eb d1                	jmp    2120 <user_app_a+0x10>
    214f:	90                   	nop

0000000000002150 <user_app_b>:
    2150:	50                   	push   %rax
    2151:	58                   	pop    %rax
    2152:	bf 63 38 00 00       	mov    $0x3863,%edi
    2157:	b8 01 00 00 00       	mov    $0x1,%eax
    215c:	48 83 ec 10          	sub    $0x10,%rsp
    2160:	0f 05                	syscall 
    2162:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%rsp)
    2169:	00 
    216a:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    216e:	81 fa 7f 96 98 00    	cmp    $0x98967f,%edx
    2174:	7f ea                	jg     2160 <user_app_b+0x10>
    2176:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    217a:	83 c2 01             	add    $0x1,%edx
    217d:	89 54 24 0c          	mov    %edx,0xc(%rsp)
    2181:	8b 54 24 0c          	mov    0xc(%rsp),%edx
    2185:	81 fa 7f 96 98 00    	cmp    $0x98967f,%edx
    218b:	7e e9                	jle    2176 <user_app_b+0x26>
    218d:	eb d1                	jmp    2160 <user_app_b+0x10>
    218f:	90                   	nop

0000000000002190 <user_print>:
    2190:	b8 01 00 00 00       	mov    $0x1,%eax
    2195:	0f 05                	syscall 
    2197:	c3                   	ret    
    2198:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    219f:	00 

00000000000021a0 <init_phy_mem_map>:
    21a0:	53                   	push   %rbx
    21a1:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    21a8:	85 c0                	test   %eax,%eax
    21aa:	0f 84 54 01 00 00    	je     2304 <init_phy_mem_map+0x164>
    21b0:	83 e8 01             	sub    $0x1,%eax
    21b3:	31 d2                	xor    %edx,%edx
    21b5:	48 8d 04 80          	lea    (%rax,%rax,4),%rax
    21b9:	48 8d 1c 85 18 80 00 	lea    0x8018(,%rax,4),%rbx
    21c0:	00 
    21c1:	b8 04 80 00 00       	mov    $0x8004,%eax
    21c6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    21cd:	00 00 00 
    21d0:	83 78 10 01          	cmpl   $0x1,0x10(%rax)
    21d4:	75 0e                	jne    21e4 <init_phy_mem_map+0x44>
    21d6:	48 8b 48 08          	mov    0x8(%rax),%rcx
    21da:	48 03 08             	add    (%rax),%rcx
    21dd:	48 39 ca             	cmp    %rcx,%rdx
    21e0:	48 0f 42 d1          	cmovb  %rcx,%rdx
    21e4:	48 83 c0 14          	add    $0x14,%rax
    21e8:	48 39 c3             	cmp    %rax,%rbx
    21eb:	75 e3                	jne    21d0 <init_phy_mem_map+0x30>
    21ed:	48 c1 ea 0c          	shr    $0xc,%rdx
    21f1:	be ff 00 00 00       	mov    $0xff,%esi
    21f6:	bf 00 00 20 00       	mov    $0x200000,%edi
    21fb:	48 c7 05 1a 2b 00 00 	movq   $0x200000,0x2b1a(%rip)        # 4d20 <phy_mem_map>
    2202:	00 00 20 00 
    2206:	48 83 c2 07          	add    $0x7,%rdx
    220a:	48 c1 ea 03          	shr    $0x3,%rdx
    220e:	48 89 15 13 2b 00 00 	mov    %rdx,0x2b13(%rip)        # 4d28 <phy_mem_map+0x8>
    2215:	e8 a6 0d 00 00       	call   2fc0 <memset>
    221a:	be 04 80 00 00       	mov    $0x8004,%esi
    221f:	48 8b 15 02 2b 00 00 	mov    0x2b02(%rip),%rdx        # 4d28 <phy_mem_map+0x8>
    2226:	41 b8 01 00 00 00    	mov    $0x1,%r8d
    222c:	eb 0b                	jmp    2239 <init_phy_mem_map+0x99>
    222e:	66 90                	xchg   %ax,%ax
    2230:	48 83 c6 14          	add    $0x14,%rsi
    2234:	48 39 f3             	cmp    %rsi,%rbx
    2237:	74 77                	je     22b0 <init_phy_mem_map+0x110>
    2239:	83 7e 10 01          	cmpl   $0x1,0x10(%rsi)
    223d:	75 f1                	jne    2230 <init_phy_mem_map+0x90>
    223f:	48 8b 3e             	mov    (%rsi),%rdi
    2242:	48 89 f8             	mov    %rdi,%rax
    2245:	48 03 7e 08          	add    0x8(%rsi),%rdi
    2249:	48 c1 e8 0c          	shr    $0xc,%rax
    224d:	48 c1 ef 0c          	shr    $0xc,%rdi
    2251:	48 39 f8             	cmp    %rdi,%rax
    2254:	73 da                	jae    2230 <init_phy_mem_map+0x90>
    2256:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    225d:	00 00 00 
    2260:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
    2267:	00 
    2268:	48 39 c1             	cmp    %rax,%rcx
    226b:	76 27                	jbe    2294 <init_phy_mem_map+0xf4>
    226d:	89 c1                	mov    %eax,%ecx
    226f:	45 89 c1             	mov    %r8d,%r9d
    2272:	48 89 c2             	mov    %rax,%rdx
    2275:	83 e1 07             	and    $0x7,%ecx
    2278:	48 c1 ea 03          	shr    $0x3,%rdx
    227c:	48 03 15 9d 2a 00 00 	add    0x2a9d(%rip),%rdx        # 4d20 <phy_mem_map>
    2283:	41 d3 e1             	shl    %cl,%r9d
    2286:	44 89 c9             	mov    %r9d,%ecx
    2289:	f7 d1                	not    %ecx
    228b:	20 0a                	and    %cl,(%rdx)
    228d:	48 8b 15 94 2a 00 00 	mov    0x2a94(%rip),%rdx        # 4d28 <phy_mem_map+0x8>
    2294:	48 83 c0 01          	add    $0x1,%rax
    2298:	48 39 c7             	cmp    %rax,%rdi
    229b:	75 c3                	jne    2260 <init_phy_mem_map+0xc0>
    229d:	48 83 c6 14          	add    $0x14,%rsi
    22a1:	48 39 f3             	cmp    %rsi,%rbx
    22a4:	75 93                	jne    2239 <init_phy_mem_map+0x99>
    22a6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    22ad:	00 00 00 
    22b0:	48 8b 05 69 2a 00 00 	mov    0x2a69(%rip),%rax        # 4d20 <phy_mem_map>
    22b7:	48 8d b4 10 ff 0f 00 	lea    0xfff(%rax,%rdx,1),%rsi
    22be:	00 
    22bf:	48 c1 ee 0c          	shr    $0xc,%rsi
    22c3:	74 3d                	je     2302 <init_phy_mem_map+0x162>
    22c5:	31 c0                	xor    %eax,%eax
    22c7:	bf 01 00 00 00       	mov    $0x1,%edi
    22cc:	eb 09                	jmp    22d7 <init_phy_mem_map+0x137>
    22ce:	66 90                	xchg   %ax,%ax
    22d0:	48 8b 15 51 2a 00 00 	mov    0x2a51(%rip),%rdx        # 4d28 <phy_mem_map+0x8>
    22d7:	48 c1 e2 03          	shl    $0x3,%rdx
    22db:	48 39 c2             	cmp    %rax,%rdx
    22de:	76 19                	jbe    22f9 <init_phy_mem_map+0x159>
    22e0:	48 89 c2             	mov    %rax,%rdx
    22e3:	89 c1                	mov    %eax,%ecx
    22e5:	89 fb                	mov    %edi,%ebx
    22e7:	48 c1 ea 03          	shr    $0x3,%rdx
    22eb:	83 e1 07             	and    $0x7,%ecx
    22ee:	48 03 15 2b 2a 00 00 	add    0x2a2b(%rip),%rdx        # 4d20 <phy_mem_map>
    22f5:	d3 e3                	shl    %cl,%ebx
    22f7:	08 1a                	or     %bl,(%rdx)
    22f9:	48 83 c0 01          	add    $0x1,%rax
    22fd:	48 39 c6             	cmp    %rax,%rsi
    2300:	75 ce                	jne    22d0 <init_phy_mem_map+0x130>
    2302:	5b                   	pop    %rbx
    2303:	c3                   	ret    
    2304:	31 d2                	xor    %edx,%edx
    2306:	be ff 00 00 00       	mov    $0xff,%esi
    230b:	bf 00 00 20 00       	mov    $0x200000,%edi
    2310:	48 c7 05 05 2a 00 00 	movq   $0x200000,0x2a05(%rip)        # 4d20 <phy_mem_map>
    2317:	00 00 20 00 
    231b:	48 c7 05 02 2a 00 00 	movq   $0x0,0x2a02(%rip)        # 4d28 <phy_mem_map+0x8>
    2322:	00 00 00 00 
    2326:	e8 95 0c 00 00       	call   2fc0 <memset>
    232b:	48 8b 15 f6 29 00 00 	mov    0x29f6(%rip),%rdx        # 4d28 <phy_mem_map+0x8>
    2332:	e9 79 ff ff ff       	jmp    22b0 <init_phy_mem_map+0x110>
    2337:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    233e:	00 00 

0000000000002340 <set_bit>:
    2340:	48 8b 47 08          	mov    0x8(%rdi),%rax
    2344:	48 89 f1             	mov    %rsi,%rcx
    2347:	48 c1 e0 03          	shl    $0x3,%rax
    234b:	48 39 f0             	cmp    %rsi,%rax
    234e:	76 20                	jbe    2370 <set_bit+0x30>
    2350:	83 e1 07             	and    $0x7,%ecx
    2353:	b8 01 00 00 00       	mov    $0x1,%eax
    2358:	48 c1 ee 03          	shr    $0x3,%rsi
    235c:	48 03 37             	add    (%rdi),%rsi
    235f:	d3 e0                	shl    %cl,%eax
    2361:	89 c1                	mov    %eax,%ecx
    2363:	0a 06                	or     (%rsi),%al
    2365:	f7 d1                	not    %ecx
    2367:	22 0e                	and    (%rsi),%cl
    2369:	84 d2                	test   %dl,%dl
    236b:	0f 44 c1             	cmove  %ecx,%eax
    236e:	88 06                	mov    %al,(%rsi)
    2370:	c3                   	ret    
    2371:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2378:	00 00 00 00 
    237c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002380 <get_bit>:
    2380:	48 8b 47 08          	mov    0x8(%rdi),%rax
    2384:	48 89 f1             	mov    %rsi,%rcx
    2387:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
    238e:	00 
    238f:	31 c0                	xor    %eax,%eax
    2391:	48 39 f2             	cmp    %rsi,%rdx
    2394:	76 16                	jbe    23ac <get_bit+0x2c>
    2396:	48 8b 17             	mov    (%rdi),%rdx
    2399:	48 89 f0             	mov    %rsi,%rax
    239c:	83 e1 07             	and    $0x7,%ecx
    239f:	48 c1 e8 03          	shr    $0x3,%rax
    23a3:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
    23a7:	d3 f8                	sar    %cl,%eax
    23a9:	83 e0 01             	and    $0x1,%eax
    23ac:	c3                   	ret    
    23ad:	0f 1f 00             	nopl   (%rax)

00000000000023b0 <alloc_pages>:
    23b0:	85 ff                	test   %edi,%edi
    23b2:	0f 84 d0 00 00 00    	je     2488 <alloc_pages+0xd8>
    23b8:	4c 8b 1d 69 29 00 00 	mov    0x2969(%rip),%r11        # 4d28 <phy_mem_map+0x8>
    23bf:	45 89 da             	mov    %r11d,%r10d
    23c2:	41 c1 e2 03          	shl    $0x3,%r10d
    23c6:	0f 84 bc 00 00 00    	je     2488 <alloc_pages+0xd8>
    23cc:	55                   	push   %rbp
    23cd:	45 89 d2             	mov    %r10d,%r10d
    23d0:	48 8b 2d 49 29 00 00 	mov    0x2949(%rip),%rbp        # 4d20 <phy_mem_map>
    23d7:	31 c0                	xor    %eax,%eax
    23d9:	53                   	push   %rbx
    23da:	31 f6                	xor    %esi,%esi
    23dc:	4a 8d 1c dd 00 00 00 	lea    0x0(,%r11,8),%rbx
    23e3:	00 
    23e4:	31 d2                	xor    %edx,%edx
    23e6:	eb 2d                	jmp    2415 <alloc_pages+0x65>
    23e8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    23ef:	00 
    23f0:	49 89 c0             	mov    %rax,%r8
    23f3:	49 c1 e8 03          	shr    $0x3,%r8
    23f7:	46 0f b6 4c 05 00    	movzbl 0x0(%rbp,%r8,1),%r9d
    23fd:	41 89 c0             	mov    %eax,%r8d
    2400:	41 83 e0 07          	and    $0x7,%r8d
    2404:	45 0f a3 c1          	bt     %r8d,%r9d
    2408:	73 12                	jae    241c <alloc_pages+0x6c>
    240a:	31 d2                	xor    %edx,%edx
    240c:	48 83 c0 01          	add    $0x1,%rax
    2410:	49 39 c2             	cmp    %rax,%r10
    2413:	74 6b                	je     2480 <alloc_pages+0xd0>
    2415:	89 c1                	mov    %eax,%ecx
    2417:	48 39 c3             	cmp    %rax,%rbx
    241a:	77 d4                	ja     23f0 <alloc_pages+0x40>
    241c:	85 d2                	test   %edx,%edx
    241e:	0f 44 f1             	cmove  %ecx,%esi
    2421:	83 c2 01             	add    $0x1,%edx
    2424:	39 d7                	cmp    %edx,%edi
    2426:	75 e4                	jne    240c <alloc_pages+0x5c>
    2428:	41 b9 01 00 00 00    	mov    $0x1,%r9d
    242e:	89 f7                	mov    %esi,%edi
    2430:	45 89 c8             	mov    %r9d,%r8d
    2433:	41 29 f0             	sub    %esi,%r8d
    2436:	eb 12                	jmp    244a <alloc_pages+0x9a>
    2438:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    243f:	00 
    2440:	4c 8b 1d e1 28 00 00 	mov    0x28e1(%rip),%r11        # 4d28 <phy_mem_map+0x8>
    2447:	83 c7 01             	add    $0x1,%edi
    244a:	89 f8                	mov    %edi,%eax
    244c:	49 c1 e3 03          	shl    $0x3,%r11
    2450:	4c 39 d8             	cmp    %r11,%rax
    2453:	73 17                	jae    246c <alloc_pages+0xbc>
    2455:	89 f9                	mov    %edi,%ecx
    2457:	48 c1 e8 03          	shr    $0x3,%rax
    245b:	44 89 cb             	mov    %r9d,%ebx
    245e:	48 03 05 bb 28 00 00 	add    0x28bb(%rip),%rax        # 4d20 <phy_mem_map>
    2465:	83 e1 07             	and    $0x7,%ecx
    2468:	d3 e3                	shl    %cl,%ebx
    246a:	08 18                	or     %bl,(%rax)
    246c:	41 8d 04 38          	lea    (%r8,%rdi,1),%eax
    2470:	39 d0                	cmp    %edx,%eax
    2472:	72 cc                	jb     2440 <alloc_pages+0x90>
    2474:	89 f0                	mov    %esi,%eax
    2476:	5b                   	pop    %rbx
    2477:	5d                   	pop    %rbp
    2478:	48 c1 e0 0c          	shl    $0xc,%rax
    247c:	c3                   	ret    
    247d:	0f 1f 00             	nopl   (%rax)
    2480:	31 c0                	xor    %eax,%eax
    2482:	5b                   	pop    %rbx
    2483:	5d                   	pop    %rbp
    2484:	c3                   	ret    
    2485:	0f 1f 00             	nopl   (%rax)
    2488:	31 c0                	xor    %eax,%eax
    248a:	c3                   	ret    
    248b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002490 <alloc_page>:
    2490:	bf 01 00 00 00       	mov    $0x1,%edi
    2495:	e9 16 ff ff ff       	jmp    23b0 <alloc_pages>
    249a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000024a0 <free_page>:
    24a0:	55                   	push   %rbp
    24a1:	ba 00 10 00 00       	mov    $0x1000,%edx
    24a6:	31 f6                	xor    %esi,%esi
    24a8:	48 89 fd             	mov    %rdi,%rbp
    24ab:	53                   	push   %rbx
    24ac:	48 89 fb             	mov    %rdi,%rbx
    24af:	48 c1 ed 0c          	shr    $0xc,%rbp
    24b3:	48 83 ec 08          	sub    $0x8,%rsp
    24b7:	e8 04 0b 00 00       	call   2fc0 <memset>
    24bc:	48 8b 05 65 28 00 00 	mov    0x2865(%rip),%rax        # 4d28 <phy_mem_map+0x8>
    24c3:	48 c1 e0 03          	shl    $0x3,%rax
    24c7:	48 39 c5             	cmp    %rax,%rbp
    24ca:	73 16                	jae    24e2 <free_page+0x42>
    24cc:	48 c1 eb 0f          	shr    $0xf,%rbx
    24d0:	48 03 1d 49 28 00 00 	add    0x2849(%rip),%rbx        # 4d20 <phy_mem_map>
    24d7:	83 e5 07             	and    $0x7,%ebp
    24da:	0f b6 03             	movzbl (%rbx),%eax
    24dd:	0f b3 e8             	btr    %ebp,%eax
    24e0:	88 03                	mov    %al,(%rbx)
    24e2:	48 83 c4 08          	add    $0x8,%rsp
    24e6:	5b                   	pop    %rbx
    24e7:	5d                   	pop    %rbp
    24e8:	c3                   	ret    
    24e9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000024f0 <pic_init>:
    24f0:	b8 11 00 00 00       	mov    $0x11,%eax
    24f5:	e6 20                	out    %al,$0x20
    24f7:	e6 a0                	out    %al,$0xa0
    24f9:	b8 20 00 00 00       	mov    $0x20,%eax
    24fe:	e6 21                	out    %al,$0x21
    2500:	b8 28 00 00 00       	mov    $0x28,%eax
    2505:	e6 a1                	out    %al,$0xa1
    2507:	b8 04 00 00 00       	mov    $0x4,%eax
    250c:	e6 21                	out    %al,$0x21
    250e:	b8 02 00 00 00       	mov    $0x2,%eax
    2513:	e6 a1                	out    %al,$0xa1
    2515:	b8 01 00 00 00       	mov    $0x1,%eax
    251a:	e6 21                	out    %al,$0x21
    251c:	e6 a1                	out    %al,$0xa1
    251e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2523:	e6 21                	out    %al,$0x21
    2525:	e6 a1                	out    %al,$0xa1
    2527:	bf 80 38 00 00       	mov    $0x3880,%edi
    252c:	e9 3f 02 00 00       	jmp    2770 <print_string>
    2531:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2538:	00 00 00 
    253b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002540 <_put_char>:
    2540:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    2546:	53                   	push   %rbx
    2547:	b8 0e 00 00 00       	mov    $0xe,%eax
    254c:	44 89 c2             	mov    %r8d,%edx
    254f:	ee                   	out    %al,(%dx)
    2550:	be d5 03 00 00       	mov    $0x3d5,%esi
    2555:	89 f2                	mov    %esi,%edx
    2557:	ec                   	in     (%dx),%al
    2558:	0f b6 c8             	movzbl %al,%ecx
    255b:	44 89 c2             	mov    %r8d,%edx
    255e:	b8 0f 00 00 00       	mov    $0xf,%eax
    2563:	c1 e1 08             	shl    $0x8,%ecx
    2566:	ee                   	out    %al,(%dx)
    2567:	89 f2                	mov    %esi,%edx
    2569:	ec                   	in     (%dx),%al
    256a:	0f b6 c0             	movzbl %al,%eax
    256d:	09 c8                	or     %ecx,%eax
    256f:	40 80 ff 0d          	cmp    $0xd,%dil
    2573:	0f 84 b7 00 00 00    	je     2630 <_put_char+0xf0>
    2579:	40 80 ff 0a          	cmp    $0xa,%dil
    257d:	74 5c                	je     25db <_put_char+0x9b>
    257f:	40 80 ff 08          	cmp    $0x8,%dil
    2583:	0f 84 be 00 00 00    	je     2647 <_put_char+0x107>
    2589:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    258d:	0f b6 0d 29 16 00 00 	movzbl 0x1629(%rip),%ecx        # 3bbd <current_color>
    2594:	83 c0 01             	add    $0x1,%eax
    2597:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    259d:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    25a4:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    25aa:	66 3d cf 07          	cmp    $0x7cf,%ax
    25ae:	77 44                	ja     25f4 <_put_char+0xb4>
    25b0:	0f b6 dc             	movzbl %ah,%ebx
    25b3:	89 c1                	mov    %eax,%ecx
    25b5:	bf d4 03 00 00       	mov    $0x3d4,%edi
    25ba:	b8 0e 00 00 00       	mov    $0xe,%eax
    25bf:	89 fa                	mov    %edi,%edx
    25c1:	ee                   	out    %al,(%dx)
    25c2:	be d5 03 00 00       	mov    $0x3d5,%esi
    25c7:	89 d8                	mov    %ebx,%eax
    25c9:	89 f2                	mov    %esi,%edx
    25cb:	ee                   	out    %al,(%dx)
    25cc:	b8 0f 00 00 00       	mov    $0xf,%eax
    25d1:	89 fa                	mov    %edi,%edx
    25d3:	ee                   	out    %al,(%dx)
    25d4:	89 c8                	mov    %ecx,%eax
    25d6:	89 f2                	mov    %esi,%edx
    25d8:	ee                   	out    %al,(%dx)
    25d9:	5b                   	pop    %rbx
    25da:	c3                   	ret    
    25db:	0f b7 c0             	movzwl %ax,%eax
    25de:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    25e4:	c1 e8 16             	shr    $0x16,%eax
    25e7:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    25eb:	c1 e0 04             	shl    $0x4,%eax
    25ee:	66 3d cf 07          	cmp    $0x7cf,%ax
    25f2:	76 bc                	jbe    25b0 <_put_char+0x70>
    25f4:	ba 00 0f 00 00       	mov    $0xf00,%edx
    25f9:	be a0 80 0b 00       	mov    $0xb80a0,%esi
    25fe:	bf 00 80 0b 00       	mov    $0xb8000,%edi
    2603:	e8 d8 09 00 00       	call   2fe0 <memcpy>
    2608:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    260d:	0f 1f 00             	nopl   (%rax)
    2610:	c6 00 20             	movb   $0x20,(%rax)
    2613:	48 83 c0 02          	add    $0x2,%rax
    2617:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    261b:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    2621:	75 ed                	jne    2610 <_put_char+0xd0>
    2623:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    2628:	bb 07 00 00 00       	mov    $0x7,%ebx
    262d:	eb 86                	jmp    25b5 <_put_char+0x75>
    262f:	90                   	nop
    2630:	0f b7 c0             	movzwl %ax,%eax
    2633:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    2639:	c1 e8 16             	shr    $0x16,%eax
    263c:	8d 04 80             	lea    (%rax,%rax,4),%eax
    263f:	c1 e0 04             	shl    $0x4,%eax
    2642:	e9 63 ff ff ff       	jmp    25aa <_put_char+0x6a>
    2647:	66 85 c0             	test   %ax,%ax
    264a:	74 26                	je     2672 <_put_char+0x132>
    264c:	83 e8 01             	sub    $0x1,%eax
    264f:	0f b6 0d 67 15 00 00 	movzbl 0x1567(%rip),%ecx        # 3bbd <current_color>
    2656:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    265a:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    2660:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    2667:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    266d:	e9 38 ff ff ff       	jmp    25aa <_put_char+0x6a>
    2672:	31 c9                	xor    %ecx,%ecx
    2674:	31 db                	xor    %ebx,%ebx
    2676:	e9 3a ff ff ff       	jmp    25b5 <_put_char+0x75>
    267b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002680 <print_init>:
    2680:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2685:	e9 36 0a 00 00       	jmp    30c0 <mutex_init>
    268a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000002690 <_get_cursor>:
    2690:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2695:	b8 0e 00 00 00       	mov    $0xe,%eax
    269a:	89 fa                	mov    %edi,%edx
    269c:	ee                   	out    %al,(%dx)
    269d:	be d5 03 00 00       	mov    $0x3d5,%esi
    26a2:	89 f2                	mov    %esi,%edx
    26a4:	ec                   	in     (%dx),%al
    26a5:	0f b6 c8             	movzbl %al,%ecx
    26a8:	89 fa                	mov    %edi,%edx
    26aa:	b8 0f 00 00 00       	mov    $0xf,%eax
    26af:	c1 e1 08             	shl    $0x8,%ecx
    26b2:	ee                   	out    %al,(%dx)
    26b3:	89 f2                	mov    %esi,%edx
    26b5:	ec                   	in     (%dx),%al
    26b6:	0f b6 c0             	movzbl %al,%eax
    26b9:	09 c8                	or     %ecx,%eax
    26bb:	c3                   	ret    
    26bc:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000026c0 <_set_cursor>:
    26c0:	be d4 03 00 00       	mov    $0x3d4,%esi
    26c5:	41 89 f8             	mov    %edi,%r8d
    26c8:	b8 0e 00 00 00       	mov    $0xe,%eax
    26cd:	89 f2                	mov    %esi,%edx
    26cf:	ee                   	out    %al,(%dx)
    26d0:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    26d5:	66 c1 ef 08          	shr    $0x8,%di
    26d9:	89 f8                	mov    %edi,%eax
    26db:	89 ca                	mov    %ecx,%edx
    26dd:	ee                   	out    %al,(%dx)
    26de:	b8 0f 00 00 00       	mov    $0xf,%eax
    26e3:	89 f2                	mov    %esi,%edx
    26e5:	ee                   	out    %al,(%dx)
    26e6:	44 89 c0             	mov    %r8d,%eax
    26e9:	89 ca                	mov    %ecx,%edx
    26eb:	ee                   	out    %al,(%dx)
    26ec:	c3                   	ret    
    26ed:	0f 1f 00             	nopl   (%rax)

00000000000026f0 <clear_screen>:
    26f0:	48 83 ec 08          	sub    $0x8,%rsp
    26f4:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    26f9:	e8 e2 09 00 00       	call   30e0 <mutex_acquire>
    26fe:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    2703:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2708:	c6 00 20             	movb   $0x20,(%rax)
    270b:	48 83 c0 02          	add    $0x2,%rax
    270f:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    2713:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    2719:	75 ed                	jne    2708 <clear_screen+0x18>
    271b:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2720:	b8 0e 00 00 00       	mov    $0xe,%eax
    2725:	89 fa                	mov    %edi,%edx
    2727:	ee                   	out    %al,(%dx)
    2728:	31 c9                	xor    %ecx,%ecx
    272a:	be d5 03 00 00       	mov    $0x3d5,%esi
    272f:	89 c8                	mov    %ecx,%eax
    2731:	89 f2                	mov    %esi,%edx
    2733:	ee                   	out    %al,(%dx)
    2734:	b8 0f 00 00 00       	mov    $0xf,%eax
    2739:	89 fa                	mov    %edi,%edx
    273b:	ee                   	out    %al,(%dx)
    273c:	89 c8                	mov    %ecx,%eax
    273e:	89 f2                	mov    %esi,%edx
    2740:	ee                   	out    %al,(%dx)
    2741:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2746:	48 83 c4 08          	add    $0x8,%rsp
    274a:	e9 31 0a 00 00       	jmp    3180 <mutex_release>
    274f:	90                   	nop

0000000000002750 <put_char>:
    2750:	53                   	push   %rbx
    2751:	89 fb                	mov    %edi,%ebx
    2753:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2758:	e8 83 09 00 00       	call   30e0 <mutex_acquire>
    275d:	0f be fb             	movsbl %bl,%edi
    2760:	e8 db fd ff ff       	call   2540 <_put_char>
    2765:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    276a:	5b                   	pop    %rbx
    276b:	e9 10 0a 00 00       	jmp    3180 <mutex_release>

0000000000002770 <print_string>:
    2770:	53                   	push   %rbx
    2771:	48 89 fb             	mov    %rdi,%rbx
    2774:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2779:	e8 62 09 00 00       	call   30e0 <mutex_acquire>
    277e:	0f be 3b             	movsbl (%rbx),%edi
    2781:	40 84 ff             	test   %dil,%dil
    2784:	74 1c                	je     27a2 <print_string+0x32>
    2786:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    278d:	00 00 00 
    2790:	e8 ab fd ff ff       	call   2540 <_put_char>
    2795:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2799:	48 83 c3 01          	add    $0x1,%rbx
    279d:	40 84 ff             	test   %dil,%dil
    27a0:	75 ee                	jne    2790 <print_string+0x20>
    27a2:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    27a7:	5b                   	pop    %rbx
    27a8:	e9 d3 09 00 00       	jmp    3180 <mutex_release>
    27ad:	0f 1f 00             	nopl   (%rax)

00000000000027b0 <print_hex>:
    27b0:	55                   	push   %rbp
    27b1:	48 89 fd             	mov    %rdi,%rbp
    27b4:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    27b9:	53                   	push   %rbx
    27ba:	bb ac 38 00 00       	mov    $0x38ac,%ebx
    27bf:	48 83 ec 18          	sub    $0x18,%rsp
    27c3:	e8 18 09 00 00       	call   30e0 <mutex_acquire>
    27c8:	bf 30 00 00 00       	mov    $0x30,%edi
    27cd:	0f 1f 00             	nopl   (%rax)
    27d0:	e8 6b fd ff ff       	call   2540 <_put_char>
    27d5:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    27d9:	48 83 c3 01          	add    $0x1,%rbx
    27dd:	40 84 ff             	test   %dil,%dil
    27e0:	75 ee                	jne    27d0 <print_hex+0x20>
    27e2:	b8 01 00 00 00       	mov    $0x1,%eax
    27e7:	48 85 ed             	test   %rbp,%rbp
    27ea:	74 5c                	je     2848 <print_hex+0x98>
    27ec:	0f 1f 40 00          	nopl   0x0(%rax)
    27f0:	48 89 ea             	mov    %rbp,%rdx
    27f3:	48 63 d8             	movslq %eax,%rbx
    27f6:	83 e2 0f             	and    $0xf,%edx
    27f9:	0f be ba af 38 00 00 	movsbl 0x38af(%rdx),%edi
    2800:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    2805:	48 83 c0 01          	add    $0x1,%rax
    2809:	48 c1 ed 04          	shr    $0x4,%rbp
    280d:	75 e1                	jne    27f0 <print_hex+0x40>
    280f:	e8 2c fd ff ff       	call   2540 <_put_char>
    2814:	48 83 eb 01          	sub    $0x1,%rbx
    2818:	85 db                	test   %ebx,%ebx
    281a:	74 16                	je     2832 <print_hex+0x82>
    281c:	0f 1f 40 00          	nopl   0x0(%rax)
    2820:	0f be 7c 1c ff       	movsbl -0x1(%rsp,%rbx,1),%edi
    2825:	48 83 eb 01          	sub    $0x1,%rbx
    2829:	e8 12 fd ff ff       	call   2540 <_put_char>
    282e:	85 db                	test   %ebx,%ebx
    2830:	75 ee                	jne    2820 <print_hex+0x70>
    2832:	48 83 c4 18          	add    $0x18,%rsp
    2836:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    283b:	5b                   	pop    %rbx
    283c:	5d                   	pop    %rbp
    283d:	e9 3e 09 00 00       	jmp    3180 <mutex_release>
    2842:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2848:	bf 30 00 00 00       	mov    $0x30,%edi
    284d:	e8 ee fc ff ff       	call   2540 <_put_char>
    2852:	48 83 c4 18          	add    $0x18,%rsp
    2856:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    285b:	5b                   	pop    %rbx
    285c:	5d                   	pop    %rbp
    285d:	e9 1e 09 00 00       	jmp    3180 <mutex_release>
    2862:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2869:	00 00 00 00 
    286d:	0f 1f 00             	nopl   (%rax)

0000000000002870 <print_int>:
    2870:	53                   	push   %rbx
    2871:	48 89 fb             	mov    %rdi,%rbx
    2874:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2879:	48 83 ec 20          	sub    $0x20,%rsp
    287d:	e8 5e 08 00 00       	call   30e0 <mutex_acquire>
    2882:	48 85 db             	test   %rbx,%rbx
    2885:	0f 84 85 00 00 00    	je     2910 <print_int+0xa0>
    288b:	78 6b                	js     28f8 <print_int+0x88>
    288d:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    2894:	cc cc cc 
    2897:	be 01 00 00 00       	mov    $0x1,%esi
    289c:	0f 1f 40 00          	nopl   0x0(%rax)
    28a0:	48 89 d8             	mov    %rbx,%rax
    28a3:	89 f1                	mov    %esi,%ecx
    28a5:	49 f7 e0             	mul    %r8
    28a8:	48 c1 ea 03          	shr    $0x3,%rdx
    28ac:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    28b0:	48 01 c0             	add    %rax,%rax
    28b3:	48 29 c3             	sub    %rax,%rbx
    28b6:	8d 7b 30             	lea    0x30(%rbx),%edi
    28b9:	48 89 d3             	mov    %rdx,%rbx
    28bc:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    28c1:	48 83 c6 01          	add    $0x1,%rsi
    28c5:	48 85 d2             	test   %rdx,%rdx
    28c8:	75 d6                	jne    28a0 <print_int+0x30>
    28ca:	48 63 d9             	movslq %ecx,%rbx
    28cd:	eb 06                	jmp    28d5 <print_int+0x65>
    28cf:	90                   	nop
    28d0:	0f b6 7c 1c 0b       	movzbl 0xb(%rsp,%rbx,1),%edi
    28d5:	40 0f be ff          	movsbl %dil,%edi
    28d9:	48 83 eb 01          	sub    $0x1,%rbx
    28dd:	e8 5e fc ff ff       	call   2540 <_put_char>
    28e2:	85 db                	test   %ebx,%ebx
    28e4:	75 ea                	jne    28d0 <print_int+0x60>
    28e6:	48 83 c4 20          	add    $0x20,%rsp
    28ea:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    28ef:	5b                   	pop    %rbx
    28f0:	e9 8b 08 00 00       	jmp    3180 <mutex_release>
    28f5:	0f 1f 00             	nopl   (%rax)
    28f8:	bf 2d 00 00 00       	mov    $0x2d,%edi
    28fd:	48 f7 db             	neg    %rbx
    2900:	e8 3b fc ff ff       	call   2540 <_put_char>
    2905:	eb 86                	jmp    288d <print_int+0x1d>
    2907:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    290e:	00 00 
    2910:	bf 30 00 00 00       	mov    $0x30,%edi
    2915:	e8 26 fc ff ff       	call   2540 <_put_char>
    291a:	48 83 c4 20          	add    $0x20,%rsp
    291e:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2923:	5b                   	pop    %rbx
    2924:	e9 57 08 00 00       	jmp    3180 <mutex_release>
    2929:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000002930 <set_print_color>:
    2930:	c1 e6 04             	shl    $0x4,%esi
    2933:	83 e7 0f             	and    $0xf,%edi
    2936:	09 fe                	or     %edi,%esi
    2938:	40 88 35 7e 12 00 00 	mov    %sil,0x127e(%rip)        # 3bbd <current_color>
    293f:	c3                   	ret    

0000000000002940 <reset_print_color>:
    2940:	c6 05 76 12 00 00 0f 	movb   $0xf,0x1276(%rip)        # 3bbd <current_color>
    2947:	c3                   	ret    
    2948:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    294f:	00 

0000000000002950 <print_error>:
    2950:	53                   	push   %rbx
    2951:	48 89 fb             	mov    %rdi,%rbx
    2954:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2959:	e8 82 07 00 00       	call   30e0 <mutex_acquire>
    295e:	c6 05 58 12 00 00 0c 	movb   $0xc,0x1258(%rip)        # 3bbd <current_color>
    2965:	0f be 3b             	movsbl (%rbx),%edi
    2968:	40 84 ff             	test   %dil,%dil
    296b:	74 15                	je     2982 <print_error+0x32>
    296d:	0f 1f 00             	nopl   (%rax)
    2970:	e8 cb fb ff ff       	call   2540 <_put_char>
    2975:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2979:	48 83 c3 01          	add    $0x1,%rbx
    297d:	40 84 ff             	test   %dil,%dil
    2980:	75 ee                	jne    2970 <print_error+0x20>
    2982:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2987:	5b                   	pop    %rbx
    2988:	c6 05 2e 12 00 00 0f 	movb   $0xf,0x122e(%rip)        # 3bbd <current_color>
    298f:	e9 ec 07 00 00       	jmp    3180 <mutex_release>
    2994:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    299b:	00 00 00 00 
    299f:	90                   	nop

00000000000029a0 <print_success>:
    29a0:	53                   	push   %rbx
    29a1:	48 89 fb             	mov    %rdi,%rbx
    29a4:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    29a9:	e8 32 07 00 00       	call   30e0 <mutex_acquire>
    29ae:	c6 05 08 12 00 00 0a 	movb   $0xa,0x1208(%rip)        # 3bbd <current_color>
    29b5:	0f be 3b             	movsbl (%rbx),%edi
    29b8:	40 84 ff             	test   %dil,%dil
    29bb:	74 15                	je     29d2 <print_success+0x32>
    29bd:	0f 1f 00             	nopl   (%rax)
    29c0:	e8 7b fb ff ff       	call   2540 <_put_char>
    29c5:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    29c9:	48 83 c3 01          	add    $0x1,%rbx
    29cd:	40 84 ff             	test   %dil,%dil
    29d0:	75 ee                	jne    29c0 <print_success+0x20>
    29d2:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    29d7:	5b                   	pop    %rbx
    29d8:	c6 05 de 11 00 00 0f 	movb   $0xf,0x11de(%rip)        # 3bbd <current_color>
    29df:	e9 9c 07 00 00       	jmp    3180 <mutex_release>
    29e4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    29eb:	00 00 00 00 
    29ef:	90                   	nop

00000000000029f0 <print_info>:
    29f0:	53                   	push   %rbx
    29f1:	48 89 fb             	mov    %rdi,%rbx
    29f4:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    29f9:	e8 e2 06 00 00       	call   30e0 <mutex_acquire>
    29fe:	c6 05 b8 11 00 00 0b 	movb   $0xb,0x11b8(%rip)        # 3bbd <current_color>
    2a05:	0f be 3b             	movsbl (%rbx),%edi
    2a08:	40 84 ff             	test   %dil,%dil
    2a0b:	74 15                	je     2a22 <print_info+0x32>
    2a0d:	0f 1f 00             	nopl   (%rax)
    2a10:	e8 2b fb ff ff       	call   2540 <_put_char>
    2a15:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2a19:	48 83 c3 01          	add    $0x1,%rbx
    2a1d:	40 84 ff             	test   %dil,%dil
    2a20:	75 ee                	jne    2a10 <print_info+0x20>
    2a22:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2a27:	5b                   	pop    %rbx
    2a28:	c6 05 8e 11 00 00 0f 	movb   $0xf,0x118e(%rip)        # 3bbd <current_color>
    2a2f:	e9 4c 07 00 00       	jmp    3180 <mutex_release>
    2a34:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2a3b:	00 00 00 00 
    2a3f:	90                   	nop

0000000000002a40 <print_warning>:
    2a40:	53                   	push   %rbx
    2a41:	48 89 fb             	mov    %rdi,%rbx
    2a44:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2a49:	e8 92 06 00 00       	call   30e0 <mutex_acquire>
    2a4e:	c6 05 68 11 00 00 0e 	movb   $0xe,0x1168(%rip)        # 3bbd <current_color>
    2a55:	0f be 3b             	movsbl (%rbx),%edi
    2a58:	40 84 ff             	test   %dil,%dil
    2a5b:	74 15                	je     2a72 <print_warning+0x32>
    2a5d:	0f 1f 00             	nopl   (%rax)
    2a60:	e8 db fa ff ff       	call   2540 <_put_char>
    2a65:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2a69:	48 83 c3 01          	add    $0x1,%rbx
    2a6d:	40 84 ff             	test   %dil,%dil
    2a70:	75 ee                	jne    2a60 <print_warning+0x20>
    2a72:	bf 30 4d 00 00       	mov    $0x4d30,%edi
    2a77:	5b                   	pop    %rbx
    2a78:	c6 05 3e 11 00 00 0f 	movb   $0xf,0x113e(%rip)        # 3bbd <current_color>
    2a7f:	e9 fc 06 00 00       	jmp    3180 <mutex_release>
    2a84:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2a8b:	00 00 00 
    2a8e:	66 90                	xchg   %ax,%ax

0000000000002a90 <shell_init>:
    2a90:	bf c0 38 00 00       	mov    $0x38c0,%edi
    2a95:	e9 d6 fc ff ff       	jmp    2770 <print_string>
    2a9a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000002aa0 <execute_command>:
    2aa0:	48 63 05 b9 22 00 00 	movslq 0x22b9(%rip),%rax        # 4d60 <cmd_index>
    2aa7:	85 c0                	test   %eax,%eax
    2aa9:	75 05                	jne    2ab0 <execute_command+0x10>
    2aab:	c3                   	ret    
    2aac:	0f 1f 40 00          	nopl   0x0(%rax)
    2ab0:	41 54                	push   %r12
    2ab2:	be c8 38 00 00       	mov    $0x38c8,%esi
    2ab7:	55                   	push   %rbp
    2ab8:	48 89 fd             	mov    %rdi,%rbp
    2abb:	53                   	push   %rbx
    2abc:	48 83 ec 70          	sub    $0x70,%rsp
    2ac0:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    2ac4:	e8 77 04 00 00       	call   2f40 <strcmp>
    2ac9:	85 c0                	test   %eax,%eax
    2acb:	75 43                	jne    2b10 <execute_command+0x70>
    2acd:	bf cd 38 00 00       	mov    $0x38cd,%edi
    2ad2:	e8 99 fc ff ff       	call   2770 <print_string>
    2ad7:	bf e2 38 00 00       	mov    $0x38e2,%edi
    2adc:	e8 8f fc ff ff       	call   2770 <print_string>
    2ae1:	bf ff 38 00 00       	mov    $0x38ff,%edi
    2ae6:	e8 85 fc ff ff       	call   2770 <print_string>
    2aeb:	bf 30 3a 00 00       	mov    $0x3a30,%edi
    2af0:	e8 7b fc ff ff       	call   2770 <print_string>
    2af5:	c7 05 61 22 00 00 00 	movl   $0x0,0x2261(%rip)        # 4d60 <cmd_index>
    2afc:	00 00 00 
    2aff:	48 83 c4 70          	add    $0x70,%rsp
    2b03:	5b                   	pop    %rbx
    2b04:	5d                   	pop    %rbp
    2b05:	41 5c                	pop    %r12
    2b07:	c3                   	ret    
    2b08:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    2b0f:	00 
    2b10:	be 1b 39 00 00       	mov    $0x391b,%esi
    2b15:	48 89 ef             	mov    %rbp,%rdi
    2b18:	e8 23 04 00 00       	call   2f40 <strcmp>
    2b1d:	85 c0                	test   %eax,%eax
    2b1f:	74 1f                	je     2b40 <execute_command+0xa0>
    2b21:	be 21 39 00 00       	mov    $0x3921,%esi
    2b26:	48 89 ef             	mov    %rbp,%rdi
    2b29:	e8 12 04 00 00       	call   2f40 <strcmp>
    2b2e:	85 c0                	test   %eax,%eax
    2b30:	75 1e                	jne    2b50 <execute_command+0xb0>
    2b32:	bf 50 3a 00 00       	mov    $0x3a50,%edi
    2b37:	e8 64 fe ff ff       	call   29a0 <print_success>
    2b3c:	eb b7                	jmp    2af5 <execute_command+0x55>
    2b3e:	66 90                	xchg   %ax,%ax
    2b40:	e8 ab fb ff ff       	call   26f0 <clear_screen>
    2b45:	eb ae                	jmp    2af5 <execute_command+0x55>
    2b47:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    2b4e:	00 00 
    2b50:	be 27 39 00 00       	mov    $0x3927,%esi
    2b55:	48 89 ef             	mov    %rbp,%rdi
    2b58:	e8 e3 03 00 00       	call   2f40 <strcmp>
    2b5d:	85 c0                	test   %eax,%eax
    2b5f:	74 4f                	je     2bb0 <execute_command+0x110>
    2b61:	be 49 39 00 00       	mov    $0x3949,%esi
    2b66:	48 89 ef             	mov    %rbp,%rdi
    2b69:	e8 d2 03 00 00       	call   2f40 <strcmp>
    2b6e:	85 c0                	test   %eax,%eax
    2b70:	75 7e                	jne    2bf0 <execute_command+0x150>
    2b72:	0f a2                	cpuid  
    2b74:	bf 51 39 00 00       	mov    $0x3951,%edi
    2b79:	89 54 24 42          	mov    %edx,0x42(%rsp)
    2b7d:	89 4c 24 46          	mov    %ecx,0x46(%rsp)
    2b81:	89 5c 24 3e          	mov    %ebx,0x3e(%rsp)
    2b85:	c6 44 24 4a 00       	movb   $0x0,0x4a(%rsp)
    2b8a:	e8 e1 fb ff ff       	call   2770 <print_string>
    2b8f:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2b94:	e8 d7 fb ff ff       	call   2770 <print_string>
    2b99:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2b9e:	e8 cd fb ff ff       	call   2770 <print_string>
    2ba3:	e9 4d ff ff ff       	jmp    2af5 <execute_command+0x55>
    2ba8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    2baf:	00 
    2bb0:	48 8b 2d d1 22 00 00 	mov    0x22d1(%rip),%rbp        # 4e88 <system_ticks>
    2bb7:	bf 2e 39 00 00       	mov    $0x392e,%edi
    2bbc:	e8 af fb ff ff       	call   2770 <print_string>
    2bc1:	48 ba c3 f5 28 5c 8f 	movabs $0x28f5c28f5c28f5c3,%rdx
    2bc8:	c2 f5 28 
    2bcb:	48 c1 ed 02          	shr    $0x2,%rbp
    2bcf:	48 89 e8             	mov    %rbp,%rax
    2bd2:	48 f7 e2             	mul    %rdx
    2bd5:	48 c1 ea 02          	shr    $0x2,%rdx
    2bd9:	48 89 d7             	mov    %rdx,%rdi
    2bdc:	e8 8f fc ff ff       	call   2870 <print_int>
    2be1:	bf 3e 39 00 00       	mov    $0x393e,%edi
    2be6:	e8 85 fb ff ff       	call   2770 <print_string>
    2beb:	e9 05 ff ff ff       	jmp    2af5 <execute_command+0x55>
    2bf0:	ba 05 00 00 00       	mov    $0x5,%edx
    2bf5:	be 5e 39 00 00       	mov    $0x395e,%esi
    2bfa:	48 89 ef             	mov    %rbp,%rdi
    2bfd:	e8 6e 03 00 00       	call   2f70 <strncmp>
    2c02:	85 c0                	test   %eax,%eax
    2c04:	75 18                	jne    2c1e <execute_command+0x17e>
    2c06:	48 8d 7d 05          	lea    0x5(%rbp),%rdi
    2c0a:	e8 61 fb ff ff       	call   2770 <print_string>
    2c0f:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2c14:	e8 57 fb ff ff       	call   2770 <print_string>
    2c19:	e9 d7 fe ff ff       	jmp    2af5 <execute_command+0x55>
    2c1e:	be 64 39 00 00       	mov    $0x3964,%esi
    2c23:	48 89 ef             	mov    %rbp,%rdi
    2c26:	e8 15 03 00 00       	call   2f40 <strcmp>
    2c2b:	85 c0                	test   %eax,%eax
    2c2d:	75 0c                	jne    2c3b <execute_command+0x19b>
    2c2f:	bf 6a 39 00 00       	mov    $0x396a,%edi
    2c34:	e8 37 fb ff ff       	call   2770 <print_string>
    2c39:	0f 0b                	ud2    
    2c3b:	be 86 39 00 00       	mov    $0x3986,%esi
    2c40:	48 89 ef             	mov    %rbp,%rdi
    2c43:	e8 f8 02 00 00       	call   2f40 <strcmp>
    2c48:	85 c0                	test   %eax,%eax
    2c4a:	0f 85 8f 00 00 00    	jne    2cdf <execute_command+0x23f>
    2c50:	ba 0a 00 00 00       	mov    $0xa,%edx
    2c55:	be 41 00 00 00       	mov    $0x41,%esi
    2c5a:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    2c5f:	e8 5c 03 00 00       	call   2fc0 <memset>
    2c64:	bf 90 3a 00 00       	mov    $0x3a90,%edi
    2c69:	c6 44 24 16 00       	movb   $0x0,0x16(%rsp)
    2c6e:	e8 fd fa ff ff       	call   2770 <print_string>
    2c73:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    2c78:	e8 f3 fa ff ff       	call   2770 <print_string>
    2c7d:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2c82:	e8 e9 fa ff ff       	call   2770 <print_string>
    2c87:	be 8e 39 00 00       	mov    $0x398e,%esi
    2c8c:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2c91:	e8 7a 03 00 00       	call   3010 <strcpy>
    2c96:	bf 9c 39 00 00       	mov    $0x399c,%edi
    2c9b:	e8 d0 fa ff ff       	call   2770 <print_string>
    2ca0:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2ca5:	e8 c6 fa ff ff       	call   2770 <print_string>
    2caa:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2caf:	e8 bc fa ff ff       	call   2770 <print_string>
    2cb4:	bf b8 3a 00 00       	mov    $0x3ab8,%edi
    2cb9:	e8 b2 fa ff ff       	call   2770 <print_string>
    2cbe:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2cc3:	e8 48 02 00 00       	call   2f10 <strlen>
    2cc8:	48 89 c7             	mov    %rax,%rdi
    2ccb:	e8 a0 fb ff ff       	call   2870 <print_int>
    2cd0:	bf aa 39 00 00       	mov    $0x39aa,%edi
    2cd5:	e8 96 fa ff ff       	call   2770 <print_string>
    2cda:	e9 16 fe ff ff       	jmp    2af5 <execute_command+0x55>
    2cdf:	be ba 39 00 00       	mov    $0x39ba,%esi
    2ce4:	48 89 ef             	mov    %rbp,%rdi
    2ce7:	e8 54 02 00 00       	call   2f40 <strcmp>
    2cec:	85 c0                	test   %eax,%eax
    2cee:	75 20                	jne    2d10 <execute_command+0x270>
    2cf0:	bf d8 3a 00 00       	mov    $0x3ad8,%edi
    2cf5:	e8 76 fa ff ff       	call   2770 <print_string>
    2cfa:	bf 00 3b 00 00       	mov    $0x3b00,%edi
    2cff:	8b 04 25 ff ff ff ff 	mov    0xffffffffffffffff,%eax
    2d06:	e8 65 fa ff ff       	call   2770 <print_string>
    2d0b:	e9 e5 fd ff ff       	jmp    2af5 <execute_command+0x55>
    2d10:	be c1 39 00 00       	mov    $0x39c1,%esi
    2d15:	48 89 ef             	mov    %rbp,%rdi
    2d18:	e8 23 02 00 00       	call   2f40 <strcmp>
    2d1d:	85 c0                	test   %eax,%eax
    2d1f:	75 22                	jne    2d43 <execute_command+0x2a3>
    2d21:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    2d28:	83 e8 01             	sub    $0x1,%eax
    2d2b:	83 f8 12             	cmp    $0x12,%eax
    2d2e:	0f 87 cb 00 00 00    	ja     2dff <execute_command+0x35f>
    2d34:	bf 20 3b 00 00       	mov    $0x3b20,%edi
    2d39:	e8 62 fc ff ff       	call   29a0 <print_success>
    2d3e:	e9 b2 fd ff ff       	jmp    2af5 <execute_command+0x55>
    2d43:	be c9 39 00 00       	mov    $0x39c9,%esi
    2d48:	48 89 ef             	mov    %rbp,%rdi
    2d4b:	e8 f0 01 00 00       	call   2f40 <strcmp>
    2d50:	85 c0                	test   %eax,%eax
    2d52:	0f 85 b6 00 00 00    	jne    2e0e <execute_command+0x36e>
    2d58:	8b 1c 25 00 80 00 00 	mov    0x8000,%ebx
    2d5f:	bf d1 39 00 00       	mov    $0x39d1,%edi
    2d64:	e8 07 fa ff ff       	call   2770 <print_string>
    2d69:	85 db                	test   %ebx,%ebx
    2d6b:	0f 84 be 00 00 00    	je     2e2f <execute_command+0x38f>
    2d71:	8d 43 ff             	lea    -0x1(%rbx),%eax
    2d74:	31 ed                	xor    %ebp,%ebp
    2d76:	bb 04 80 00 00       	mov    $0x8004,%ebx
    2d7b:	48 6b c0 14          	imul   $0x14,%rax,%rax
    2d7f:	4c 8d a0 18 80 00 00 	lea    0x8018(%rax),%r12
    2d86:	bf ee 39 00 00       	mov    $0x39ee,%edi
    2d8b:	e8 e0 f9 ff ff       	call   2770 <print_string>
    2d90:	48 8b 3b             	mov    (%rbx),%rdi
    2d93:	e8 18 fa ff ff       	call   27b0 <print_hex>
    2d98:	bf fd 39 00 00       	mov    $0x39fd,%edi
    2d9d:	e8 ce f9 ff ff       	call   2770 <print_string>
    2da2:	48 8b 7b 08          	mov    0x8(%rbx),%rdi
    2da6:	e8 05 fa ff ff       	call   27b0 <print_hex>
    2dab:	bf 08 3a 00 00       	mov    $0x3a08,%edi
    2db0:	e8 bb f9 ff ff       	call   2770 <print_string>
    2db5:	8b 7b 10             	mov    0x10(%rbx),%edi
    2db8:	e8 b3 fa ff ff       	call   2870 <print_int>
    2dbd:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2dc2:	e8 a9 f9 ff ff       	call   2770 <print_string>
    2dc7:	83 7b 10 01          	cmpl   $0x1,0x10(%rbx)
    2dcb:	75 04                	jne    2dd1 <execute_command+0x331>
    2dcd:	48 03 6b 08          	add    0x8(%rbx),%rbp
    2dd1:	48 83 c3 14          	add    $0x14,%rbx
    2dd5:	4c 39 e3             	cmp    %r12,%rbx
    2dd8:	75 ac                	jne    2d86 <execute_command+0x2e6>
    2dda:	bf 70 3b 00 00       	mov    $0x3b70,%edi
    2ddf:	e8 8c f9 ff ff       	call   2770 <print_string>
    2de4:	48 89 ef             	mov    %rbp,%rdi
    2de7:	48 c1 ef 14          	shr    $0x14,%rdi
    2deb:	e8 80 fa ff ff       	call   2870 <print_int>
    2df0:	bf 11 3a 00 00       	mov    $0x3a11,%edi
    2df5:	e8 76 f9 ff ff       	call   2770 <print_string>
    2dfa:	e9 f6 fc ff ff       	jmp    2af5 <execute_command+0x55>
    2dff:	bf 48 3b 00 00       	mov    $0x3b48,%edi
    2e04:	e8 47 fb ff ff       	call   2950 <print_error>
    2e09:	e9 e7 fc ff ff       	jmp    2af5 <execute_command+0x55>
    2e0e:	bf 16 3a 00 00       	mov    $0x3a16,%edi
    2e13:	e8 38 fb ff ff       	call   2950 <print_error>
    2e18:	48 89 ef             	mov    %rbp,%rdi
    2e1b:	e8 30 fb ff ff       	call   2950 <print_error>
    2e20:	bf 7d 38 00 00       	mov    $0x387d,%edi
    2e25:	e8 26 fb ff ff       	call   2950 <print_error>
    2e2a:	e9 c6 fc ff ff       	jmp    2af5 <execute_command+0x55>
    2e2f:	31 ed                	xor    %ebp,%ebp
    2e31:	eb a7                	jmp    2dda <execute_command+0x33a>
    2e33:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2e3a:	00 00 00 00 
    2e3e:	66 90                	xchg   %ax,%ax

0000000000002e40 <shell_take_char>:
    2e40:	48 83 ec 08          	sub    $0x8,%rsp
    2e44:	40 80 ff 0a          	cmp    $0xa,%dil
    2e48:	74 76                	je     2ec0 <shell_take_char+0x80>
    2e4a:	8b 05 10 1f 00 00    	mov    0x1f10(%rip),%eax        # 4d60 <cmd_index>
    2e50:	40 80 ff 08          	cmp    $0x8,%dil
    2e54:	74 4a                	je     2ea0 <shell_take_char+0x60>
    2e56:	40 80 ff 1b          	cmp    $0x1b,%dil
    2e5a:	74 2d                	je     2e89 <shell_take_char+0x49>
    2e5c:	3d fe 00 00 00       	cmp    $0xfe,%eax
    2e61:	0f 8e 89 00 00 00    	jle    2ef0 <shell_take_char+0xb0>
    2e67:	48 83 c4 08          	add    $0x8,%rsp
    2e6b:	c3                   	ret    
    2e6c:	0f 1f 40 00          	nopl   0x0(%rax)
    2e70:	bf 08 00 00 00       	mov    $0x8,%edi
    2e75:	e8 d6 f8 ff ff       	call   2750 <put_char>
    2e7a:	8b 05 e0 1e 00 00    	mov    0x1ee0(%rip),%eax        # 4d60 <cmd_index>
    2e80:	83 e8 01             	sub    $0x1,%eax
    2e83:	89 05 d7 1e 00 00    	mov    %eax,0x1ed7(%rip)        # 4d60 <cmd_index>
    2e89:	85 c0                	test   %eax,%eax
    2e8b:	7f e3                	jg     2e70 <shell_take_char+0x30>
    2e8d:	c6 05 ec 1e 00 00 00 	movb   $0x0,0x1eec(%rip)        # 4d80 <cmd_buffer>
    2e94:	48 83 c4 08          	add    $0x8,%rsp
    2e98:	c3                   	ret    
    2e99:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2ea0:	85 c0                	test   %eax,%eax
    2ea2:	7e c3                	jle    2e67 <shell_take_char+0x27>
    2ea4:	83 e8 01             	sub    $0x1,%eax
    2ea7:	bf 08 00 00 00       	mov    $0x8,%edi
    2eac:	89 05 ae 1e 00 00    	mov    %eax,0x1eae(%rip)        # 4d60 <cmd_index>
    2eb2:	48 83 c4 08          	add    $0x8,%rsp
    2eb6:	e9 95 f8 ff ff       	jmp    2750 <put_char>
    2ebb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2ec0:	bf 0a 00 00 00       	mov    $0xa,%edi
    2ec5:	e8 86 f8 ff ff       	call   2750 <put_char>
    2eca:	48 63 05 8f 1e 00 00 	movslq 0x1e8f(%rip),%rax        # 4d60 <cmd_index>
    2ed1:	bf 80 4d 00 00       	mov    $0x4d80,%edi
    2ed6:	c6 80 80 4d 00 00 00 	movb   $0x0,0x4d80(%rax)
    2edd:	e8 be fb ff ff       	call   2aa0 <execute_command>
    2ee2:	bf c0 38 00 00       	mov    $0x38c0,%edi
    2ee7:	48 83 c4 08          	add    $0x8,%rsp
    2eeb:	e9 80 f8 ff ff       	jmp    2770 <print_string>
    2ef0:	48 63 d0             	movslq %eax,%rdx
    2ef3:	83 c0 01             	add    $0x1,%eax
    2ef6:	40 88 ba 80 4d 00 00 	mov    %dil,0x4d80(%rdx)
    2efd:	40 0f be ff          	movsbl %dil,%edi
    2f01:	89 05 59 1e 00 00    	mov    %eax,0x1e59(%rip)        # 4d60 <cmd_index>
    2f07:	48 83 c4 08          	add    $0x8,%rsp
    2f0b:	e9 40 f8 ff ff       	jmp    2750 <put_char>

0000000000002f10 <strlen>:
    2f10:	31 c0                	xor    %eax,%eax
    2f12:	80 3f 00             	cmpb   $0x0,(%rdi)
    2f15:	74 19                	je     2f30 <strlen+0x20>
    2f17:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    2f1e:	00 00 
    2f20:	48 83 c0 01          	add    $0x1,%rax
    2f24:	80 3c 07 00          	cmpb   $0x0,(%rdi,%rax,1)
    2f28:	75 f6                	jne    2f20 <strlen+0x10>
    2f2a:	c3                   	ret    
    2f2b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2f30:	c3                   	ret    
    2f31:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2f38:	00 00 00 00 
    2f3c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002f40 <strcmp>:
    2f40:	eb 12                	jmp    2f54 <strcmp+0x14>
    2f42:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2f48:	38 06                	cmp    %al,(%rsi)
    2f4a:	75 11                	jne    2f5d <strcmp+0x1d>
    2f4c:	48 83 c7 01          	add    $0x1,%rdi
    2f50:	48 83 c6 01          	add    $0x1,%rsi
    2f54:	0f b6 07             	movzbl (%rdi),%eax
    2f57:	84 c0                	test   %al,%al
    2f59:	75 ed                	jne    2f48 <strcmp+0x8>
    2f5b:	31 c0                	xor    %eax,%eax
    2f5d:	0f b6 16             	movzbl (%rsi),%edx
    2f60:	29 d0                	sub    %edx,%eax
    2f62:	c3                   	ret    
    2f63:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2f6a:	00 00 00 00 
    2f6e:	66 90                	xchg   %ax,%ax

0000000000002f70 <strncmp>:
    2f70:	85 d2                	test   %edx,%edx
    2f72:	7f 1d                	jg     2f91 <strncmp+0x21>
    2f74:	eb 35                	jmp    2fab <strncmp+0x3b>
    2f76:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2f7d:	00 00 00 
    2f80:	3a 06                	cmp    (%rsi),%al
    2f82:	75 14                	jne    2f98 <strncmp+0x28>
    2f84:	48 83 c7 01          	add    $0x1,%rdi
    2f88:	48 83 c6 01          	add    $0x1,%rsi
    2f8c:	83 ea 01             	sub    $0x1,%edx
    2f8f:	74 17                	je     2fa8 <strncmp+0x38>
    2f91:	0f b6 07             	movzbl (%rdi),%eax
    2f94:	84 c0                	test   %al,%al
    2f96:	75 e8                	jne    2f80 <strncmp+0x10>
    2f98:	0f b6 07             	movzbl (%rdi),%eax
    2f9b:	0f b6 16             	movzbl (%rsi),%edx
    2f9e:	29 d0                	sub    %edx,%eax
    2fa0:	c3                   	ret    
    2fa1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2fa8:	31 c0                	xor    %eax,%eax
    2faa:	c3                   	ret    
    2fab:	b8 00 00 00 00       	mov    $0x0,%eax
    2fb0:	75 e6                	jne    2f98 <strncmp+0x28>
    2fb2:	c3                   	ret    
    2fb3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2fba:	00 00 00 00 
    2fbe:	66 90                	xchg   %ax,%ax

0000000000002fc0 <memset>:
    2fc0:	48 89 f8             	mov    %rdi,%rax
    2fc3:	4c 8d 04 17          	lea    (%rdi,%rdx,1),%r8
    2fc7:	48 89 f9             	mov    %rdi,%rcx
    2fca:	48 85 d2             	test   %rdx,%rdx
    2fcd:	74 0e                	je     2fdd <memset+0x1d>
    2fcf:	90                   	nop
    2fd0:	48 83 c1 01          	add    $0x1,%rcx
    2fd4:	40 88 71 ff          	mov    %sil,-0x1(%rcx)
    2fd8:	4c 39 c1             	cmp    %r8,%rcx
    2fdb:	75 f3                	jne    2fd0 <memset+0x10>
    2fdd:	c3                   	ret    
    2fde:	66 90                	xchg   %ax,%ax

0000000000002fe0 <memcpy>:
    2fe0:	48 89 f8             	mov    %rdi,%rax
    2fe3:	48 85 d2             	test   %rdx,%rdx
    2fe6:	74 1a                	je     3002 <memcpy+0x22>
    2fe8:	31 c9                	xor    %ecx,%ecx
    2fea:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2ff0:	44 0f b6 04 0e       	movzbl (%rsi,%rcx,1),%r8d
    2ff5:	44 88 04 08          	mov    %r8b,(%rax,%rcx,1)
    2ff9:	48 83 c1 01          	add    $0x1,%rcx
    2ffd:	48 39 d1             	cmp    %rdx,%rcx
    3000:	75 ee                	jne    2ff0 <memcpy+0x10>
    3002:	c3                   	ret    
    3003:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    300a:	00 00 00 00 
    300e:	66 90                	xchg   %ax,%ax

0000000000003010 <strcpy>:
    3010:	48 89 f8             	mov    %rdi,%rax
    3013:	31 d2                	xor    %edx,%edx
    3015:	0f 1f 00             	nopl   (%rax)
    3018:	0f b6 0c 16          	movzbl (%rsi,%rdx,1),%ecx
    301c:	88 0c 10             	mov    %cl,(%rax,%rdx,1)
    301f:	48 83 c2 01          	add    $0x1,%rdx
    3023:	84 c9                	test   %cl,%cl
    3025:	75 f1                	jne    3018 <strcpy+0x8>
    3027:	c3                   	ret    
    3028:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    302f:	00 

0000000000003030 <switch_to>:
    3030:	55                   	push   %rbp
    3031:	53                   	push   %rbx
    3032:	41 54                	push   %r12
    3034:	41 55                	push   %r13
    3036:	41 56                	push   %r14
    3038:	41 57                	push   %r15
    303a:	48 89 27             	mov    %rsp,(%rdi)
    303d:	48 8b 26             	mov    (%rsi),%rsp
    3040:	41 5f                	pop    %r15
    3042:	41 5e                	pop    %r14
    3044:	41 5d                	pop    %r13
    3046:	41 5c                	pop    %r12
    3048:	5b                   	pop    %rbx
    3049:	5d                   	pop    %rbp
    304a:	c3                   	ret    
    304b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000003050 <spinlock_init>:
    3050:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    3056:	48 c7 47 08 00 00 00 	movq   $0x0,0x8(%rdi)
    305d:	00 
    305e:	c3                   	ret    
    305f:	90                   	nop

0000000000003060 <spinlock_acquire>:
    3060:	9c                   	pushf  
    3061:	5e                   	pop    %rsi
    3062:	fa                   	cli    
    3063:	48 89 f1             	mov    %rsi,%rcx
    3066:	ba 01 00 00 00       	mov    $0x1,%edx
    306b:	81 e1 00 02 00 00    	and    $0x200,%ecx
    3071:	eb 0a                	jmp    307d <spinlock_acquire+0x1d>
    3073:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    3078:	48 85 c9             	test   %rcx,%rcx
    307b:	75 13                	jne    3090 <spinlock_acquire+0x30>
    307d:	89 d0                	mov    %edx,%eax
    307f:	87 07                	xchg   %eax,(%rdi)
    3081:	83 f8 01             	cmp    $0x1,%eax
    3084:	74 f2                	je     3078 <spinlock_acquire+0x18>
    3086:	48 89 77 08          	mov    %rsi,0x8(%rdi)
    308a:	c3                   	ret    
    308b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    3090:	fb                   	sti    
    3091:	90                   	nop
    3092:	fa                   	cli    
    3093:	eb e8                	jmp    307d <spinlock_acquire+0x1d>
    3095:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    309c:	00 00 00 00 

00000000000030a0 <spinlock_release>:
    30a0:	48 8b 47 08          	mov    0x8(%rdi),%rax
    30a4:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    30aa:	f6 c4 02             	test   $0x2,%ah
    30ad:	74 01                	je     30b0 <spinlock_release+0x10>
    30af:	fb                   	sti    
    30b0:	c3                   	ret    
    30b1:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    30b8:	00 00 00 00 
    30bc:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000030c0 <mutex_init>:
    30c0:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    30c6:	48 c7 47 08 00 00 00 	movq   $0x0,0x8(%rdi)
    30cd:	00 
    30ce:	c7 47 10 00 00 00 00 	movl   $0x0,0x10(%rdi)
    30d5:	c3                   	ret    
    30d6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    30dd:	00 00 00 

00000000000030e0 <mutex_acquire>:
    30e0:	b9 01 00 00 00       	mov    $0x1,%ecx
    30e5:	0f 1f 00             	nopl   (%rax)
    30e8:	9c                   	pushf  
    30e9:	5e                   	pop    %rsi
    30ea:	fa                   	cli    
    30eb:	48 89 f2             	mov    %rsi,%rdx
    30ee:	81 e2 00 02 00 00    	and    $0x200,%edx
    30f4:	eb 0f                	jmp    3105 <mutex_acquire+0x25>
    30f6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    30fd:	00 00 00 
    3100:	48 85 d2             	test   %rdx,%rdx
    3103:	75 5b                	jne    3160 <mutex_acquire+0x80>
    3105:	89 c8                	mov    %ecx,%eax
    3107:	87 07                	xchg   %eax,(%rdi)
    3109:	83 f8 01             	cmp    $0x1,%eax
    310c:	74 f2                	je     3100 <mutex_acquire+0x20>
    310e:	8b 47 10             	mov    0x10(%rdi),%eax
    3111:	48 89 77 08          	mov    %rsi,0x8(%rdi)
    3115:	85 c0                	test   %eax,%eax
    3117:	74 4c                	je     3165 <mutex_acquire+0x85>
    3119:	48 8b 05 60 1d 00 00 	mov    0x1d60(%rip),%rax        # 4e80 <current_thread>
    3120:	c7 40 20 01 00 00 00 	movl   $0x1,0x20(%rax)
    3127:	48 89 78 28          	mov    %rdi,0x28(%rax)
    312b:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    3131:	48 85 d2             	test   %rdx,%rdx
    3134:	74 01                	je     3137 <mutex_acquire+0x57>
    3136:	fb                   	sti    
    3137:	48 8b 05 42 1d 00 00 	mov    0x1d42(%rip),%rax        # 4e80 <current_thread>
    313e:	83 78 20 01          	cmpl   $0x1,0x20(%rax)
    3142:	75 a4                	jne    30e8 <mutex_acquire+0x8>
    3144:	0f 1f 40 00          	nopl   0x0(%rax)
    3148:	fb                   	sti    
    3149:	f4                   	hlt    
    314a:	48 8b 05 2f 1d 00 00 	mov    0x1d2f(%rip),%rax        # 4e80 <current_thread>
    3151:	83 78 20 01          	cmpl   $0x1,0x20(%rax)
    3155:	74 f1                	je     3148 <mutex_acquire+0x68>
    3157:	eb 8f                	jmp    30e8 <mutex_acquire+0x8>
    3159:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    3160:	fb                   	sti    
    3161:	90                   	nop
    3162:	fa                   	cli    
    3163:	eb a0                	jmp    3105 <mutex_acquire+0x25>
    3165:	c7 47 10 01 00 00 00 	movl   $0x1,0x10(%rdi)
    316c:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    3172:	48 85 d2             	test   %rdx,%rdx
    3175:	74 02                	je     3179 <mutex_acquire+0x99>
    3177:	fb                   	sti    
    3178:	c3                   	ret    
    3179:	c3                   	ret    
    317a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000003180 <mutex_release>:
    3180:	9c                   	pushf  
    3181:	5e                   	pop    %rsi
    3182:	fa                   	cli    
    3183:	48 89 f1             	mov    %rsi,%rcx
    3186:	ba 01 00 00 00       	mov    $0x1,%edx
    318b:	81 e1 00 02 00 00    	and    $0x200,%ecx
    3191:	eb 0a                	jmp    319d <mutex_release+0x1d>
    3193:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    3198:	48 85 c9             	test   %rcx,%rcx
    319b:	75 73                	jne    3210 <mutex_release+0x90>
    319d:	89 d0                	mov    %edx,%eax
    319f:	87 07                	xchg   %eax,(%rdi)
    31a1:	83 f8 01             	cmp    $0x1,%eax
    31a4:	74 f2                	je     3198 <mutex_release+0x18>
    31a6:	48 8b 15 d3 1c 00 00 	mov    0x1cd3(%rip),%rdx        # 4e80 <current_thread>
    31ad:	48 89 77 08          	mov    %rsi,0x8(%rdi)
    31b1:	c7 47 10 00 00 00 00 	movl   $0x0,0x10(%rdi)
    31b8:	48 85 d2             	test   %rdx,%rdx
    31bb:	74 5b                	je     3218 <mutex_release+0x98>
    31bd:	48 8b 42 18          	mov    0x18(%rdx),%rax
    31c1:	48 39 c2             	cmp    %rax,%rdx
    31c4:	75 13                	jne    31d9 <mutex_release+0x59>
    31c6:	eb 50                	jmp    3218 <mutex_release+0x98>
    31c8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    31cf:	00 
    31d0:	48 8b 40 18          	mov    0x18(%rax),%rax
    31d4:	48 39 c2             	cmp    %rax,%rdx
    31d7:	74 3f                	je     3218 <mutex_release+0x98>
    31d9:	83 78 20 01          	cmpl   $0x1,0x20(%rax)
    31dd:	75 f1                	jne    31d0 <mutex_release+0x50>
    31df:	48 39 78 28          	cmp    %rdi,0x28(%rax)
    31e3:	75 eb                	jne    31d0 <mutex_release+0x50>
    31e5:	48 83 ec 08          	sub    $0x8,%rsp
    31e9:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
    31f0:	48 c7 40 28 00 00 00 	movq   $0x0,0x28(%rax)
    31f7:	00 
    31f8:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    31fe:	48 85 c9             	test   %rcx,%rcx
    3201:	74 01                	je     3204 <mutex_release+0x84>
    3203:	fb                   	sti    
    3204:	fa                   	cli    
    3205:	e8 96 01 00 00       	call   33a0 <schedule>
    320a:	fb                   	sti    
    320b:	48 83 c4 08          	add    $0x8,%rsp
    320f:	c3                   	ret    
    3210:	fb                   	sti    
    3211:	90                   	nop
    3212:	fa                   	cli    
    3213:	eb 88                	jmp    319d <mutex_release+0x1d>
    3215:	0f 1f 00             	nopl   (%rax)
    3218:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
    321e:	48 85 c9             	test   %rcx,%rcx
    3221:	74 05                	je     3228 <mutex_release+0xa8>
    3223:	fb                   	sti    
    3224:	c3                   	ret    
    3225:	0f 1f 00             	nopl   (%rax)
    3228:	c3                   	ret    

0000000000003229 <syscall_entry>:
    3229:	48 89 24 25 c6 3b 00 	mov    %rsp,0x3bc6
    3230:	00 
    3231:	48 8b 24 25 be 3b 00 	mov    0x3bbe,%rsp
    3238:	00 
    3239:	51                   	push   %rcx
    323a:	41 53                	push   %r11
    323c:	50                   	push   %rax
    323d:	57                   	push   %rdi
    323e:	56                   	push   %rsi
    323f:	52                   	push   %rdx
    3240:	41 50                	push   %r8
    3242:	41 51                	push   %r9
    3244:	41 52                	push   %r10
    3246:	48 89 d1             	mov    %rdx,%rcx
    3249:	48 89 f2             	mov    %rsi,%rdx
    324c:	48 89 fe             	mov    %rdi,%rsi
    324f:	48 89 c7             	mov    %rax,%rdi
    3252:	e8 69 00 00 00       	call   32c0 <syscall_handler>
    3257:	41 5a                	pop    %r10
    3259:	41 59                	pop    %r9
    325b:	41 58                	pop    %r8
    325d:	5a                   	pop    %rdx
    325e:	5e                   	pop    %rsi
    325f:	5f                   	pop    %rdi
    3260:	58                   	pop    %rax
    3261:	41 5b                	pop    %r11
    3263:	59                   	pop    %rcx
    3264:	48 8b 24 25 c6 3b 00 	mov    0x3bc6,%rsp
    326b:	00 
    326c:	48 0f 07             	sysretq 
    326f:	90                   	nop

0000000000003270 <syscall_init>:
    3270:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
    3275:	0f 32                	rdmsr  
    3277:	48 c1 e2 20          	shl    $0x20,%rdx
    327b:	89 c0                	mov    %eax,%eax
    327d:	48 09 c2             	or     %rax,%rdx
    3280:	48 89 d0             	mov    %rdx,%rax
    3283:	48 c1 ea 20          	shr    $0x20,%rdx
    3287:	48 83 c8 01          	or     $0x1,%rax
    328b:	0f 30                	wrmsr  
    328d:	31 f6                	xor    %esi,%esi
    328f:	b9 81 00 00 c0       	mov    $0xc0000081,%ecx
    3294:	ba 08 00 10 00       	mov    $0x100008,%edx
    3299:	89 f0                	mov    %esi,%eax
    329b:	0f 30                	wrmsr  
    329d:	b8 29 32 00 00       	mov    $0x3229,%eax
    32a2:	b9 82 00 00 c0       	mov    $0xc0000082,%ecx
    32a7:	48 89 c2             	mov    %rax,%rdx
    32aa:	48 c1 ea 20          	shr    $0x20,%rdx
    32ae:	0f 30                	wrmsr  
    32b0:	b9 84 00 00 c0       	mov    $0xc0000084,%ecx
    32b5:	b8 00 02 00 00       	mov    $0x200,%eax
    32ba:	89 f2                	mov    %esi,%edx
    32bc:	0f 30                	wrmsr  
    32be:	c3                   	ret    
    32bf:	90                   	nop

00000000000032c0 <syscall_handler>:
    32c0:	48 83 ff 01          	cmp    $0x1,%rdi
    32c4:	74 0a                	je     32d0 <syscall_handler+0x10>
    32c6:	c3                   	ret    
    32c7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    32ce:	00 00 
    32d0:	48 89 f7             	mov    %rsi,%rdi
    32d3:	e9 98 f4 ff ff       	jmp    2770 <print_string>
    32d8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    32df:	00 

00000000000032e0 <thread_create>:
    32e0:	55                   	push   %rbp
    32e1:	31 c0                	xor    %eax,%eax
    32e3:	48 89 fd             	mov    %rdi,%rbp
    32e6:	53                   	push   %rbx
    32e7:	89 f3                	mov    %esi,%ebx
    32e9:	48 83 ec 08          	sub    $0x8,%rsp
    32ed:	e8 9e f1 ff ff       	call   2490 <alloc_page>
    32f2:	48 8d 90 c8 0f 00 00 	lea    0xfc8(%rax),%rdx
    32f9:	48 89 40 08          	mov    %rax,0x8(%rax)
    32fd:	89 58 10             	mov    %ebx,0x10(%rax)
    3300:	89 58 14             	mov    %ebx,0x14(%rax)
    3303:	48 c7 40 18 00 00 00 	movq   $0x0,0x18(%rax)
    330a:	00 
    330b:	48 89 a8 f8 0f 00 00 	mov    %rbp,0xff8(%rax)
    3312:	48 c7 80 f0 0f 00 00 	movq   $0x0,0xff0(%rax)
    3319:	00 00 00 00 
    331d:	48 c7 80 e8 0f 00 00 	movq   $0x0,0xfe8(%rax)
    3324:	00 00 00 00 
    3328:	48 c7 80 e0 0f 00 00 	movq   $0x0,0xfe0(%rax)
    332f:	00 00 00 00 
    3333:	48 c7 80 d8 0f 00 00 	movq   $0x0,0xfd8(%rax)
    333a:	00 00 00 00 
    333e:	48 c7 80 d0 0f 00 00 	movq   $0x0,0xfd0(%rax)
    3345:	00 00 00 00 
    3349:	48 c7 80 c8 0f 00 00 	movq   $0x0,0xfc8(%rax)
    3350:	00 00 00 00 
    3354:	48 89 10             	mov    %rdx,(%rax)
    3357:	48 83 c4 08          	add    $0x8,%rsp
    335b:	5b                   	pop    %rbx
    335c:	5d                   	pop    %rbp
    335d:	c3                   	ret    
    335e:	66 90                	xchg   %ax,%ax

0000000000003360 <thread_append>:
    3360:	48 8b 15 19 1b 00 00 	mov    0x1b19(%rip),%rdx        # 4e80 <current_thread>
    3367:	48 89 d0             	mov    %rdx,%rax
    336a:	48 85 d2             	test   %rdx,%rdx
    336d:	74 19                	je     3388 <thread_append+0x28>
    336f:	90                   	nop
    3370:	48 89 c1             	mov    %rax,%rcx
    3373:	48 8b 40 18          	mov    0x18(%rax),%rax
    3377:	48 39 c2             	cmp    %rax,%rdx
    337a:	75 f4                	jne    3370 <thread_append+0x10>
    337c:	48 89 79 18          	mov    %rdi,0x18(%rcx)
    3380:	48 89 57 18          	mov    %rdx,0x18(%rdi)
    3384:	c3                   	ret    
    3385:	0f 1f 00             	nopl   (%rax)
    3388:	48 89 fa             	mov    %rdi,%rdx
    338b:	48 89 3d ee 1a 00 00 	mov    %rdi,0x1aee(%rip)        # 4e80 <current_thread>
    3392:	48 89 57 18          	mov    %rdx,0x18(%rdi)
    3396:	c3                   	ret    
    3397:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    339e:	00 00 

00000000000033a0 <schedule>:
    33a0:	41 54                	push   %r12
    33a2:	55                   	push   %rbp
    33a3:	48 83 ec 08          	sub    $0x8,%rsp
    33a7:	4c 8b 25 d2 1a 00 00 	mov    0x1ad2(%rip),%r12        # 4e80 <current_thread>
    33ae:	4d 85 e4             	test   %r12,%r12
    33b1:	74 4d                	je     3400 <schedule+0x60>
    33b3:	49 8b 6c 24 18       	mov    0x18(%r12),%rbp
    33b8:	49 39 ec             	cmp    %rbp,%r12
    33bb:	75 0c                	jne    33c9 <schedule+0x29>
    33bd:	eb 41                	jmp    3400 <schedule+0x60>
    33bf:	90                   	nop
    33c0:	48 8b 6d 18          	mov    0x18(%rbp),%rbp
    33c4:	49 39 ec             	cmp    %rbp,%r12
    33c7:	74 37                	je     3400 <schedule+0x60>
    33c9:	83 7d 20 01          	cmpl   $0x1,0x20(%rbp)
    33cd:	74 f1                	je     33c0 <schedule+0x20>
    33cf:	49 39 ec             	cmp    %rbp,%r12
    33d2:	74 2c                	je     3400 <schedule+0x60>
    33d4:	48 8b 7d 30          	mov    0x30(%rbp),%rdi
    33d8:	48 85 ff             	test   %rdi,%rdi
    33db:	75 33                	jne    3410 <schedule+0x70>
    33dd:	48 89 2d 9c 1a 00 00 	mov    %rbp,0x1a9c(%rip)        # 4e80 <current_thread>
    33e4:	48 83 c4 08          	add    $0x8,%rsp
    33e8:	48 89 ee             	mov    %rbp,%rsi
    33eb:	4c 89 e7             	mov    %r12,%rdi
    33ee:	5d                   	pop    %rbp
    33ef:	41 5c                	pop    %r12
    33f1:	e9 3a fc ff ff       	jmp    3030 <switch_to>
    33f6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    33fd:	00 00 00 
    3400:	48 83 c4 08          	add    $0x8,%rsp
    3404:	5d                   	pop    %rbp
    3405:	41 5c                	pop    %r12
    3407:	c3                   	ret    
    3408:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    340f:	00 
    3410:	e8 4b e7 ff ff       	call   1b60 <set_tss_rsp0>
    3415:	48 8b 45 30          	mov    0x30(%rbp),%rax
    3419:	48 89 05 9e 07 00 00 	mov    %rax,0x79e(%rip)        # 3bbe <kernel_rsp_scratch>
    3420:	eb bb                	jmp    33dd <schedule+0x3d>
    3422:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    3429:	00 00 00 00 
    342d:	0f 1f 00             	nopl   (%rax)

0000000000003430 <thread_yield>:
    3430:	48 83 ec 08          	sub    $0x8,%rsp
    3434:	fa                   	cli    
    3435:	e8 66 ff ff ff       	call   33a0 <schedule>
    343a:	fb                   	sti    
    343b:	48 83 c4 08          	add    $0x8,%rsp
    343f:	c3                   	ret    

0000000000003440 <process_create>:
    3440:	41 54                	push   %r12
    3442:	31 c0                	xor    %eax,%eax
    3444:	55                   	push   %rbp
    3445:	48 89 fd             	mov    %rdi,%rbp
    3448:	53                   	push   %rbx
    3449:	89 f3                	mov    %esi,%ebx
    344b:	e8 40 f0 ff ff       	call   2490 <alloc_page>
    3450:	89 58 10             	mov    %ebx,0x10(%rax)
    3453:	49 89 c4             	mov    %rax,%r12
    3456:	89 58 14             	mov    %ebx,0x14(%rax)
    3459:	48 8d 98 00 10 00 00 	lea    0x1000(%rax),%rbx
    3460:	48 89 58 30          	mov    %rbx,0x30(%rax)
    3464:	48 89 40 08          	mov    %rax,0x8(%rax)
    3468:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
    346f:	48 c7 40 28 00 00 00 	movq   $0x0,0x28(%rax)
    3476:	00 
    3477:	48 c7 40 18 00 00 00 	movq   $0x0,0x18(%rax)
    347e:	00 
    347f:	31 c0                	xor    %eax,%eax
    3481:	e8 0a f0 ff ff       	call   2490 <alloc_page>
    3486:	49 89 ac 24 d8 0f 00 	mov    %rbp,0xfd8(%r12)
    348d:	00 
    348e:	48 05 00 10 00 00    	add    $0x1000,%rax
    3494:	49 c7 84 24 f8 0f 00 	movq   $0x1b,0xff8(%r12)
    349b:	00 1b 00 00 00 
    34a0:	49 89 84 24 f0 0f 00 	mov    %rax,0xff0(%r12)
    34a7:	00 
    34a8:	49 8d 84 24 a0 0f 00 	lea    0xfa0(%r12),%rax
    34af:	00 
    34b0:	49 89 04 24          	mov    %rax,(%r12)
    34b4:	4c 89 e0             	mov    %r12,%rax
    34b7:	49 c7 84 24 e8 0f 00 	movq   $0x202,0xfe8(%r12)
    34be:	00 02 02 00 00 
    34c3:	49 c7 84 24 e0 0f 00 	movq   $0x23,0xfe0(%r12)
    34ca:	00 23 00 00 00 
    34cf:	49 c7 84 24 d0 0f 00 	movq   $0x35a4,0xfd0(%r12)
    34d6:	00 a4 35 00 00 
    34db:	49 c7 84 24 c8 0f 00 	movq   $0x0,0xfc8(%r12)
    34e2:	00 00 00 00 00 
    34e7:	49 c7 84 24 c0 0f 00 	movq   $0x0,0xfc0(%r12)
    34ee:	00 00 00 00 00 
    34f3:	49 c7 84 24 b8 0f 00 	movq   $0x0,0xfb8(%r12)
    34fa:	00 00 00 00 00 
    34ff:	49 c7 84 24 b0 0f 00 	movq   $0x0,0xfb0(%r12)
    3506:	00 00 00 00 00 
    350b:	49 c7 84 24 a8 0f 00 	movq   $0x0,0xfa8(%r12)
    3512:	00 00 00 00 00 
    3517:	49 c7 84 24 a0 0f 00 	movq   $0x0,0xfa0(%r12)
    351e:	00 00 00 00 00 
    3523:	5b                   	pop    %rbx
    3524:	5d                   	pop    %rbp
    3525:	41 5c                	pop    %r12
    3527:	c3                   	ret    
    3528:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    352f:	00 

0000000000003530 <timer_init>:
    3530:	b8 36 00 00 00       	mov    $0x36,%eax
    3535:	e6 43                	out    %al,$0x43
    3537:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    353c:	e6 40                	out    %al,$0x40
    353e:	b8 2e 00 00 00       	mov    $0x2e,%eax
    3543:	e6 40                	out    %al,$0x40
    3545:	bf 90 3b 00 00       	mov    $0x3b90,%edi
    354a:	e9 21 f2 ff ff       	jmp    2770 <print_string>
    354f:	90                   	nop

0000000000003550 <timer_interrupt_handler>:
    3550:	b8 20 00 00 00       	mov    $0x20,%eax
    3555:	e6 20                	out    %al,$0x20
    3557:	48 8b 05 2a 19 00 00 	mov    0x192a(%rip),%rax        # 4e88 <system_ticks>
    355e:	48 83 c0 01          	add    $0x1,%rax
    3562:	48 89 05 1f 19 00 00 	mov    %rax,0x191f(%rip)        # 4e88 <system_ticks>
    3569:	48 8b 05 10 19 00 00 	mov    0x1910(%rip),%rax        # 4e80 <current_thread>
    3570:	48 85 c0             	test   %rax,%rax
    3573:	74 06                	je     357b <timer_interrupt_handler+0x2b>
    3575:	83 68 10 01          	subl   $0x1,0x10(%rax)
    3579:	74 05                	je     3580 <timer_interrupt_handler+0x30>
    357b:	c3                   	ret    
    357c:	0f 1f 40 00          	nopl   0x0(%rax)
    3580:	8b 50 14             	mov    0x14(%rax),%edx
    3583:	89 50 10             	mov    %edx,0x10(%rax)
    3586:	e9 15 fe ff ff       	jmp    33a0 <schedule>

000000000000358b <jump_to_usermode>:
    358b:	66 b8 1b 00          	mov    $0x1b,%ax
    358f:	8e d8                	mov    %eax,%ds
    3591:	8e c0                	mov    %eax,%es
    3593:	8e e0                	mov    %eax,%fs
    3595:	8e e8                	mov    %eax,%gs
    3597:	6a 1b                	push   $0x1b
    3599:	56                   	push   %rsi
    359a:	68 02 02 00 00       	push   $0x202
    359f:	6a 23                	push   $0x23
    35a1:	57                   	push   %rdi
    35a2:	48 cf                	iretq  

00000000000035a4 <return_to_user>:
    35a4:	48 cf                	iretq  
