
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	48 83 ec 08          	sub    $0x8,%rsp
    1906:	e8 d5 08 00 00       	call   21e0 <clear_screen>
    190b:	bf 17 2f 00 00       	mov    $0x2f17,%edi
    1910:	e8 5b 0a 00 00       	call   2370 <print_string>
    1915:	e8 66 02 00 00       	call   1b80 <idt_init>
    191a:	e8 11 08 00 00       	call   2130 <pic_init>
    191f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    1924:	e6 21                	out    %al,$0x21
    1926:	bf 38 2f 00 00       	mov    $0x2f38,%edi
    192b:	e8 40 0a 00 00       	call   2370 <print_string>
    1930:	fb                   	sti    
    1931:	bf 68 2f 00 00       	mov    $0x2f68,%edi
    1936:	e8 35 0a 00 00       	call   2370 <print_string>
    193b:	e8 b0 0c 00 00       	call   25f0 <shell_init>
    1940:	f4                   	hlt    
    1941:	eb fd                	jmp    1940 <kernel_main+0x40>
    1943:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    194a:	00 00 00 
    194d:	0f 1f 00             	nopl   (%rax)

0000000000001950 <isr32_timer>:
    1950:	50                   	push   %rax
    1951:	48 8b 05 28 2a 00 00 	mov    0x2a28(%rip),%rax        # 4380 <system_ticks>
    1958:	48 83 c0 01          	add    $0x1,%rax
    195c:	48 89 05 1d 2a 00 00 	mov    %rax,0x2a1d(%rip)        # 4380 <system_ticks>
    1963:	b8 20 00 00 00       	mov    $0x20,%eax
    1968:	e6 20                	out    %al,$0x20
    196a:	58                   	pop    %rax
    196b:	48 cf                	iretq  
    196d:	0f 1f 00             	nopl   (%rax)

0000000000001970 <isr0_divide_by_zero>:
    1970:	41 53                	push   %r11
    1972:	41 52                	push   %r10
    1974:	41 51                	push   %r9
    1976:	41 50                	push   %r8
    1978:	57                   	push   %rdi
    1979:	bf 00 2d 00 00       	mov    $0x2d00,%edi
    197e:	56                   	push   %rsi
    197f:	51                   	push   %rcx
    1980:	52                   	push   %rdx
    1981:	50                   	push   %rax
    1982:	fc                   	cld    
    1983:	e8 e8 09 00 00       	call   2370 <print_string>
    1988:	bf 38 2d 00 00       	mov    $0x2d38,%edi
    198d:	e8 de 09 00 00       	call   2370 <print_string>
    1992:	bf 68 2d 00 00       	mov    $0x2d68,%edi
    1997:	e8 d4 09 00 00       	call   2370 <print_string>
    199c:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    19a1:	e8 fa 09 00 00       	call   23a0 <print_hex>
    19a6:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    19ab:	e8 c0 09 00 00       	call   2370 <print_string>
    19b0:	bf 90 2d 00 00       	mov    $0x2d90,%edi
    19b5:	e8 b6 09 00 00       	call   2370 <print_string>
    19ba:	bf 50 2e 00 00       	mov    $0x2e50,%edi
    19bf:	e8 ac 09 00 00       	call   2370 <print_string>
    19c4:	0f 1f 40 00          	nopl   0x0(%rax)
    19c8:	f4                   	hlt    
    19c9:	eb fd                	jmp    19c8 <isr0_divide_by_zero+0x58>
    19cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000019d0 <isr13_gpf>:
    19d0:	41 53                	push   %r11
    19d2:	41 52                	push   %r10
    19d4:	41 51                	push   %r9
    19d6:	41 50                	push   %r8
    19d8:	55                   	push   %rbp
    19d9:	57                   	push   %rdi
    19da:	bf 00 2d 00 00       	mov    $0x2d00,%edi
    19df:	56                   	push   %rsi
    19e0:	51                   	push   %rcx
    19e1:	52                   	push   %rdx
    19e2:	50                   	push   %rax
    19e3:	48 8b 6c 24 50       	mov    0x50(%rsp),%rbp
    19e8:	fc                   	cld    
    19e9:	e8 02 0b 00 00       	call   24f0 <print_error>
    19ee:	bf c8 2d 00 00       	mov    $0x2dc8,%edi
    19f3:	e8 f8 0a 00 00       	call   24f0 <print_error>
    19f8:	bf 60 2e 00 00       	mov    $0x2e60,%edi
    19fd:	e8 6e 09 00 00       	call   2370 <print_string>
    1a02:	48 89 ef             	mov    %rbp,%rdi
    1a05:	e8 96 09 00 00       	call   23a0 <print_hex>
    1a0a:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    1a0f:	e8 5c 09 00 00       	call   2370 <print_string>
    1a14:	bf 6d 2e 00 00       	mov    $0x2e6d,%edi
    1a19:	e8 52 09 00 00       	call   2370 <print_string>
    1a1e:	48 8b 7c 24 58       	mov    0x58(%rsp),%rdi
    1a23:	e8 78 09 00 00       	call   23a0 <print_hex>
    1a28:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    1a2d:	e8 3e 09 00 00       	call   2370 <print_string>
    1a32:	bf 50 2e 00 00       	mov    $0x2e50,%edi
    1a37:	e8 b4 0a 00 00       	call   24f0 <print_error>
    1a3c:	0f 1f 40 00          	nopl   0x0(%rax)
    1a40:	f4                   	hlt    
    1a41:	eb fd                	jmp    1a40 <isr13_gpf+0x70>
    1a43:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1a4a:	00 00 00 00 
    1a4e:	66 90                	xchg   %ax,%ax

0000000000001a50 <isr14_page_fault>:
    1a50:	41 54                	push   %r12
    1a52:	41 53                	push   %r11
    1a54:	41 52                	push   %r10
    1a56:	41 51                	push   %r9
    1a58:	41 50                	push   %r8
    1a5a:	55                   	push   %rbp
    1a5b:	57                   	push   %rdi
    1a5c:	56                   	push   %rsi
    1a5d:	51                   	push   %rcx
    1a5e:	52                   	push   %rdx
    1a5f:	50                   	push   %rax
    1a60:	48 83 ec 08          	sub    $0x8,%rsp
    1a64:	48 8b 6c 24 60       	mov    0x60(%rsp),%rbp
    1a69:	41 0f 20 d4          	mov    %cr2,%r12
    1a6d:	bf 00 2d 00 00       	mov    $0x2d00,%edi
    1a72:	fc                   	cld    
    1a73:	e8 78 0a 00 00       	call   24f0 <print_error>
    1a78:	bf 00 2e 00 00       	mov    $0x2e00,%edi
    1a7d:	e8 6e 0a 00 00       	call   24f0 <print_error>
    1a82:	bf 30 2e 00 00       	mov    $0x2e30,%edi
    1a87:	e8 e4 08 00 00       	call   2370 <print_string>
    1a8c:	4c 89 e7             	mov    %r12,%rdi
    1a8f:	e8 0c 09 00 00       	call   23a0 <print_hex>
    1a94:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    1a99:	e8 d2 08 00 00       	call   2370 <print_string>
    1a9e:	bf 60 2e 00 00       	mov    $0x2e60,%edi
    1aa3:	e8 c8 08 00 00       	call   2370 <print_string>
    1aa8:	48 89 ef             	mov    %rbp,%rdi
    1aab:	e8 f0 08 00 00       	call   23a0 <print_hex>
    1ab0:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    1ab5:	e8 b6 08 00 00       	call   2370 <print_string>
    1aba:	bf 6d 2e 00 00       	mov    $0x2e6d,%edi
    1abf:	e8 ac 08 00 00       	call   2370 <print_string>
    1ac4:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
    1ac9:	e8 d2 08 00 00       	call   23a0 <print_hex>
    1ace:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    1ad3:	e8 98 08 00 00       	call   2370 <print_string>
    1ad8:	bf 50 2e 00 00       	mov    $0x2e50,%edi
    1add:	e8 0e 0a 00 00       	call   24f0 <print_error>
    1ae2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1ae8:	f4                   	hlt    
    1ae9:	eb fd                	jmp    1ae8 <isr14_page_fault+0x98>
    1aeb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001af0 <isr33_keyboard>:
    1af0:	41 53                	push   %r11
    1af2:	41 52                	push   %r10
    1af4:	41 51                	push   %r9
    1af6:	41 50                	push   %r8
    1af8:	57                   	push   %rdi
    1af9:	56                   	push   %rsi
    1afa:	51                   	push   %rcx
    1afb:	52                   	push   %rdx
    1afc:	50                   	push   %rax
    1afd:	e4 60                	in     $0x60,%al
    1aff:	84 c0                	test   %al,%al
    1b01:	78 0f                	js     1b12 <isr33_keyboard+0x22>
    1b03:	0f b6 c0             	movzbl %al,%eax
    1b06:	0f be b8 80 2c 00 00 	movsbl 0x2c80(%rax),%edi
    1b0d:	40 84 ff             	test   %dil,%dil
    1b10:	75 1e                	jne    1b30 <isr33_keyboard+0x40>
    1b12:	b8 20 00 00 00       	mov    $0x20,%eax
    1b17:	e6 20                	out    %al,$0x20
    1b19:	58                   	pop    %rax
    1b1a:	5a                   	pop    %rdx
    1b1b:	59                   	pop    %rcx
    1b1c:	5e                   	pop    %rsi
    1b1d:	5f                   	pop    %rdi
    1b1e:	41 58                	pop    %r8
    1b20:	41 59                	pop    %r9
    1b22:	41 5a                	pop    %r10
    1b24:	41 5b                	pop    %r11
    1b26:	48 cf                	iretq  
    1b28:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b2f:	00 
    1b30:	fc                   	cld    
    1b31:	e8 4a 0f 00 00       	call   2a80 <shell_take_char>
    1b36:	eb da                	jmp    1b12 <isr33_keyboard+0x22>
    1b38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b3f:	00 

0000000000001b40 <set_idt_gate>:
    1b40:	48 63 ff             	movslq %edi,%rdi
    1b43:	48 89 f2             	mov    %rsi,%rdx
    1b46:	48 c1 e7 04          	shl    $0x4,%rdi
    1b4a:	48 c1 ea 10          	shr    $0x10,%rdx
    1b4e:	66 89 b7 80 33 00 00 	mov    %si,0x3380(%rdi)
    1b55:	48 c1 ee 20          	shr    $0x20,%rsi
    1b59:	c7 87 82 33 00 00 08 	movl   $0x8e000008,0x3382(%rdi)
    1b60:	00 00 8e 
    1b63:	66 89 97 86 33 00 00 	mov    %dx,0x3386(%rdi)
    1b6a:	89 b7 88 33 00 00    	mov    %esi,0x3388(%rdi)
    1b70:	c7 87 8c 33 00 00 00 	movl   $0x0,0x338c(%rdi)
    1b77:	00 00 00 
    1b7a:	c3                   	ret    
    1b7b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001b80 <idt_init>:
    1b80:	b8 80 33 00 00       	mov    $0x3380,%eax
    1b85:	0f 1f 00             	nopl   (%rax)
    1b88:	31 d2                	xor    %edx,%edx
    1b8a:	b9 08 00 00 00       	mov    $0x8,%ecx
    1b8f:	31 f6                	xor    %esi,%esi
    1b91:	c6 40 04 00          	movb   $0x0,0x4(%rax)
    1b95:	66 89 10             	mov    %dx,(%rax)
    1b98:	48 83 c0 10          	add    $0x10,%rax
    1b9c:	66 89 48 f2          	mov    %cx,-0xe(%rax)
    1ba0:	c6 40 f5 8e          	movb   $0x8e,-0xb(%rax)
    1ba4:	66 89 70 f6          	mov    %si,-0xa(%rax)
    1ba8:	c7 40 f8 00 00 00 00 	movl   $0x0,-0x8(%rax)
    1baf:	c7 40 fc 00 00 00 00 	movl   $0x0,-0x4(%rax)
    1bb6:	48 3d 80 43 00 00    	cmp    $0x4380,%rax
    1bbc:	75 ca                	jne    1b88 <idt_init+0x8>
    1bbe:	c7 05 ba 17 00 00 08 	movl   $0x8e000008,0x17ba(%rip)        # 3382 <idt+0x2>
    1bc5:	00 00 8e 
    1bc8:	b8 70 19 00 00       	mov    $0x1970,%eax
    1bcd:	66 89 05 ac 17 00 00 	mov    %ax,0x17ac(%rip)        # 3380 <idt>
    1bd4:	48 89 c2             	mov    %rax,%rdx
    1bd7:	48 c1 e8 20          	shr    $0x20,%rax
    1bdb:	48 c1 ea 10          	shr    $0x10,%rdx
    1bdf:	89 05 a3 17 00 00    	mov    %eax,0x17a3(%rip)        # 3388 <idt+0x8>
    1be5:	b8 d0 19 00 00       	mov    $0x19d0,%eax
    1bea:	66 89 15 95 17 00 00 	mov    %dx,0x1795(%rip)        # 3386 <idt+0x6>
    1bf1:	48 89 c2             	mov    %rax,%rdx
    1bf4:	66 89 05 55 18 00 00 	mov    %ax,0x1855(%rip)        # 3450 <idt+0xd0>
    1bfb:	48 c1 e8 20          	shr    $0x20,%rax
    1bff:	48 c1 ea 10          	shr    $0x10,%rdx
    1c03:	89 05 4f 18 00 00    	mov    %eax,0x184f(%rip)        # 3458 <idt+0xd8>
    1c09:	b8 50 1a 00 00       	mov    $0x1a50,%eax
    1c0e:	66 89 15 41 18 00 00 	mov    %dx,0x1841(%rip)        # 3456 <idt+0xd6>
    1c15:	48 89 c2             	mov    %rax,%rdx
    1c18:	66 89 05 41 18 00 00 	mov    %ax,0x1841(%rip)        # 3460 <idt+0xe0>
    1c1f:	48 c1 e8 20          	shr    $0x20,%rax
    1c23:	48 c1 ea 10          	shr    $0x10,%rdx
    1c27:	89 05 3b 18 00 00    	mov    %eax,0x183b(%rip)        # 3468 <idt+0xe8>
    1c2d:	b8 50 19 00 00       	mov    $0x1950,%eax
    1c32:	66 89 15 2d 18 00 00 	mov    %dx,0x182d(%rip)        # 3466 <idt+0xe6>
    1c39:	48 89 c2             	mov    %rax,%rdx
    1c3c:	66 89 05 3d 19 00 00 	mov    %ax,0x193d(%rip)        # 3580 <idt+0x200>
    1c43:	48 c1 e8 20          	shr    $0x20,%rax
    1c47:	48 c1 ea 10          	shr    $0x10,%rdx
    1c4b:	89 05 37 19 00 00    	mov    %eax,0x1937(%rip)        # 3588 <idt+0x208>
    1c51:	b8 f0 1a 00 00       	mov    $0x1af0,%eax
    1c56:	66 89 15 29 19 00 00 	mov    %dx,0x1929(%rip)        # 3586 <idt+0x206>
    1c5d:	48 89 c2             	mov    %rax,%rdx
    1c60:	66 89 05 29 19 00 00 	mov    %ax,0x1929(%rip)        # 3590 <idt+0x210>
    1c67:	48 c1 e8 20          	shr    $0x20,%rax
    1c6b:	48 c1 ea 10          	shr    $0x10,%rdx
    1c6f:	89 05 23 19 00 00    	mov    %eax,0x1923(%rip)        # 3598 <idt+0x218>
    1c75:	b8 ff 0f 00 00       	mov    $0xfff,%eax
    1c7a:	c7 05 08 17 00 00 00 	movl   $0x0,0x1708(%rip)        # 338c <idt+0xc>
    1c81:	00 00 00 
    1c84:	c7 05 c4 17 00 00 08 	movl   $0x8e000008,0x17c4(%rip)        # 3452 <idt+0xd2>
    1c8b:	00 00 8e 
    1c8e:	c7 05 c4 17 00 00 00 	movl   $0x0,0x17c4(%rip)        # 345c <idt+0xdc>
    1c95:	00 00 00 
    1c98:	c7 05 c0 17 00 00 08 	movl   $0x8e000008,0x17c0(%rip)        # 3462 <idt+0xe2>
    1c9f:	00 00 8e 
    1ca2:	c7 05 c0 17 00 00 00 	movl   $0x0,0x17c0(%rip)        # 346c <idt+0xec>
    1ca9:	00 00 00 
    1cac:	c7 05 cc 18 00 00 08 	movl   $0x8e000008,0x18cc(%rip)        # 3582 <idt+0x202>
    1cb3:	00 00 8e 
    1cb6:	c7 05 cc 18 00 00 00 	movl   $0x0,0x18cc(%rip)        # 358c <idt+0x20c>
    1cbd:	00 00 00 
    1cc0:	c7 05 c8 18 00 00 08 	movl   $0x8e000008,0x18c8(%rip)        # 3592 <idt+0x212>
    1cc7:	00 00 8e 
    1cca:	66 89 15 c5 18 00 00 	mov    %dx,0x18c5(%rip)        # 3596 <idt+0x216>
    1cd1:	c7 05 c1 18 00 00 00 	movl   $0x0,0x18c1(%rip)        # 359c <idt+0x21c>
    1cd8:	00 00 00 
    1cdb:	66 89 05 7e 16 00 00 	mov    %ax,0x167e(%rip)        # 3360 <idtr_reg>
    1ce2:	48 c7 05 75 16 00 00 	movq   $0x3380,0x1675(%rip)        # 3362 <idtr_reg+0x2>
    1ce9:	80 33 00 00 
    1ced:	0f 01 1d 6c 16 00 00 	lidt   0x166c(%rip)        # 3360 <idtr_reg>
    1cf4:	c3                   	ret    
    1cf5:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1cfc:	00 00 00 
    1cff:	90                   	nop

0000000000001d00 <kmalloc_init>:
    1d00:	48 83 ec 08          	sub    $0x8,%rsp
    1d04:	31 c0                	xor    %eax,%eax
    1d06:	e8 65 03 00 00       	call   2070 <alloc_page>
    1d0b:	48 85 c0             	test   %rax,%rax
    1d0e:	74 30                	je     1d40 <kmalloc_init+0x40>
    1d10:	48 89 05 71 26 00 00 	mov    %rax,0x2671(%rip)        # 4388 <heap_head>
    1d17:	bf c0 2e 00 00       	mov    $0x2ec0,%edi
    1d1c:	48 c7 40 10 e8 0f 00 	movq   $0xfe8,0x10(%rax)
    1d23:	00 
    1d24:	c6 40 08 01          	movb   $0x1,0x8(%rax)
    1d28:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    1d2f:	48 83 c4 08          	add    $0x8,%rsp
    1d33:	e9 38 06 00 00       	jmp    2370 <print_string>
    1d38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1d3f:	00 
    1d40:	bf 88 2e 00 00       	mov    $0x2e88,%edi
    1d45:	48 83 c4 08          	add    $0x8,%rsp
    1d49:	e9 22 06 00 00       	jmp    2370 <print_string>
    1d4e:	66 90                	xchg   %ax,%ax

0000000000001d50 <kmalloc>:
    1d50:	48 85 ff             	test   %rdi,%rdi
    1d53:	0f 84 7f 00 00 00    	je     1dd8 <kmalloc+0x88>
    1d59:	48 8b 05 28 26 00 00 	mov    0x2628(%rip),%rax        # 4388 <heap_head>
    1d60:	48 83 c7 07          	add    $0x7,%rdi
    1d64:	48 83 e7 f8          	and    $0xfffffffffffffff8,%rdi
    1d68:	48 85 c0             	test   %rax,%rax
    1d6b:	74 1a                	je     1d87 <kmalloc+0x37>
    1d6d:	0f 1f 00             	nopl   (%rax)
    1d70:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1d74:	74 09                	je     1d7f <kmalloc+0x2f>
    1d76:	48 8b 50 10          	mov    0x10(%rax),%rdx
    1d7a:	48 39 fa             	cmp    %rdi,%rdx
    1d7d:	73 21                	jae    1da0 <kmalloc+0x50>
    1d7f:	48 8b 00             	mov    (%rax),%rax
    1d82:	48 85 c0             	test   %rax,%rax
    1d85:	75 e9                	jne    1d70 <kmalloc+0x20>
    1d87:	48 83 ec 08          	sub    $0x8,%rsp
    1d8b:	bf f8 2e 00 00       	mov    $0x2ef8,%edi
    1d90:	e8 db 05 00 00       	call   2370 <print_string>
    1d95:	31 c0                	xor    %eax,%eax
    1d97:	48 83 c4 08          	add    $0x8,%rsp
    1d9b:	c3                   	ret    
    1d9c:	0f 1f 40 00          	nopl   0x0(%rax)
    1da0:	48 8d 4f 20          	lea    0x20(%rdi),%rcx
    1da4:	48 39 ca             	cmp    %rcx,%rdx
    1da7:	72 21                	jb     1dca <kmalloc+0x7a>
    1da9:	48 29 fa             	sub    %rdi,%rdx
    1dac:	48 8d 4c 38 18       	lea    0x18(%rax,%rdi,1),%rcx
    1db1:	48 83 ea 18          	sub    $0x18,%rdx
    1db5:	c6 41 08 01          	movb   $0x1,0x8(%rcx)
    1db9:	48 89 51 10          	mov    %rdx,0x10(%rcx)
    1dbd:	48 8b 10             	mov    (%rax),%rdx
    1dc0:	48 89 11             	mov    %rdx,(%rcx)
    1dc3:	48 89 78 10          	mov    %rdi,0x10(%rax)
    1dc7:	48 89 08             	mov    %rcx,(%rax)
    1dca:	c6 40 08 00          	movb   $0x0,0x8(%rax)
    1dce:	48 83 c0 18          	add    $0x18,%rax
    1dd2:	c3                   	ret    
    1dd3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1dd8:	31 c0                	xor    %eax,%eax
    1dda:	c3                   	ret    
    1ddb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001de0 <kfree>:
    1de0:	48 85 ff             	test   %rdi,%rdi
    1de3:	74 33                	je     1e18 <kfree+0x38>
    1de5:	48 8b 47 e8          	mov    -0x18(%rdi),%rax
    1de9:	c6 47 f0 01          	movb   $0x1,-0x10(%rdi)
    1ded:	48 8d 4f e8          	lea    -0x18(%rdi),%rcx
    1df1:	48 85 c0             	test   %rax,%rax
    1df4:	74 06                	je     1dfc <kfree+0x1c>
    1df6:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1dfa:	75 24                	jne    1e20 <kfree+0x40>
    1dfc:	48 8b 05 85 25 00 00 	mov    0x2585(%rip),%rax        # 4388 <heap_head>
    1e03:	eb 0e                	jmp    1e13 <kfree+0x33>
    1e05:	0f 1f 00             	nopl   (%rax)
    1e08:	48 8b 10             	mov    (%rax),%rdx
    1e0b:	48 39 ca             	cmp    %rcx,%rdx
    1e0e:	74 30                	je     1e40 <kfree+0x60>
    1e10:	48 89 d0             	mov    %rdx,%rax
    1e13:	48 85 c0             	test   %rax,%rax
    1e16:	75 f0                	jne    1e08 <kfree+0x28>
    1e18:	c3                   	ret    
    1e19:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1e20:	48 8b 50 10          	mov    0x10(%rax),%rdx
    1e24:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    1e28:	48 8b 00             	mov    (%rax),%rax
    1e2b:	48 8d 54 16 18       	lea    0x18(%rsi,%rdx,1),%rdx
    1e30:	48 89 57 f8          	mov    %rdx,-0x8(%rdi)
    1e34:	48 89 47 e8          	mov    %rax,-0x18(%rdi)
    1e38:	eb c2                	jmp    1dfc <kfree+0x1c>
    1e3a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1e40:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1e44:	74 d2                	je     1e18 <kfree+0x38>
    1e46:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    1e4a:	48 8d 56 18          	lea    0x18(%rsi),%rdx
    1e4e:	48 01 50 10          	add    %rdx,0x10(%rax)
    1e52:	48 8b 57 e8          	mov    -0x18(%rdi),%rdx
    1e56:	48 89 10             	mov    %rdx,(%rax)
    1e59:	c3                   	ret    
    1e5a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001e60 <init_phy_mem_map>:
    1e60:	53                   	push   %rbx
    1e61:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    1e68:	85 c0                	test   %eax,%eax
    1e6a:	0f 84 54 01 00 00    	je     1fc4 <init_phy_mem_map+0x164>
    1e70:	83 e8 01             	sub    $0x1,%eax
    1e73:	31 d2                	xor    %edx,%edx
    1e75:	48 8d 04 80          	lea    (%rax,%rax,4),%rax
    1e79:	48 8d 1c 85 18 80 00 	lea    0x8018(,%rax,4),%rbx
    1e80:	00 
    1e81:	b8 04 80 00 00       	mov    $0x8004,%eax
    1e86:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1e8d:	00 00 00 
    1e90:	83 78 10 01          	cmpl   $0x1,0x10(%rax)
    1e94:	75 0e                	jne    1ea4 <init_phy_mem_map+0x44>
    1e96:	48 8b 48 08          	mov    0x8(%rax),%rcx
    1e9a:	48 03 08             	add    (%rax),%rcx
    1e9d:	48 39 ca             	cmp    %rcx,%rdx
    1ea0:	48 0f 42 d1          	cmovb  %rcx,%rdx
    1ea4:	48 83 c0 14          	add    $0x14,%rax
    1ea8:	48 39 c3             	cmp    %rax,%rbx
    1eab:	75 e3                	jne    1e90 <init_phy_mem_map+0x30>
    1ead:	48 c1 ea 0c          	shr    $0xc,%rdx
    1eb1:	be ff 00 00 00       	mov    $0xff,%esi
    1eb6:	bf 00 00 20 00       	mov    $0x200000,%edi
    1ebb:	48 c7 05 ca 24 00 00 	movq   $0x200000,0x24ca(%rip)        # 4390 <phy_mem_map>
    1ec2:	00 00 20 00 
    1ec6:	48 83 c2 07          	add    $0x7,%rdx
    1eca:	48 c1 ea 03          	shr    $0x3,%rdx
    1ece:	48 89 15 c3 24 00 00 	mov    %rdx,0x24c3(%rip)        # 4398 <phy_mem_map+0x8>
    1ed5:	e8 26 0d 00 00       	call   2c00 <memset>
    1eda:	be 04 80 00 00       	mov    $0x8004,%esi
    1edf:	48 8b 15 b2 24 00 00 	mov    0x24b2(%rip),%rdx        # 4398 <phy_mem_map+0x8>
    1ee6:	41 b8 01 00 00 00    	mov    $0x1,%r8d
    1eec:	eb 0b                	jmp    1ef9 <init_phy_mem_map+0x99>
    1eee:	66 90                	xchg   %ax,%ax
    1ef0:	48 83 c6 14          	add    $0x14,%rsi
    1ef4:	48 39 f3             	cmp    %rsi,%rbx
    1ef7:	74 77                	je     1f70 <init_phy_mem_map+0x110>
    1ef9:	83 7e 10 01          	cmpl   $0x1,0x10(%rsi)
    1efd:	75 f1                	jne    1ef0 <init_phy_mem_map+0x90>
    1eff:	48 8b 3e             	mov    (%rsi),%rdi
    1f02:	48 89 f8             	mov    %rdi,%rax
    1f05:	48 03 7e 08          	add    0x8(%rsi),%rdi
    1f09:	48 c1 e8 0c          	shr    $0xc,%rax
    1f0d:	48 c1 ef 0c          	shr    $0xc,%rdi
    1f11:	48 39 f8             	cmp    %rdi,%rax
    1f14:	73 da                	jae    1ef0 <init_phy_mem_map+0x90>
    1f16:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1f1d:	00 00 00 
    1f20:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
    1f27:	00 
    1f28:	48 39 c1             	cmp    %rax,%rcx
    1f2b:	76 27                	jbe    1f54 <init_phy_mem_map+0xf4>
    1f2d:	89 c1                	mov    %eax,%ecx
    1f2f:	45 89 c1             	mov    %r8d,%r9d
    1f32:	48 89 c2             	mov    %rax,%rdx
    1f35:	83 e1 07             	and    $0x7,%ecx
    1f38:	48 c1 ea 03          	shr    $0x3,%rdx
    1f3c:	48 03 15 4d 24 00 00 	add    0x244d(%rip),%rdx        # 4390 <phy_mem_map>
    1f43:	41 d3 e1             	shl    %cl,%r9d
    1f46:	44 89 c9             	mov    %r9d,%ecx
    1f49:	f7 d1                	not    %ecx
    1f4b:	20 0a                	and    %cl,(%rdx)
    1f4d:	48 8b 15 44 24 00 00 	mov    0x2444(%rip),%rdx        # 4398 <phy_mem_map+0x8>
    1f54:	48 83 c0 01          	add    $0x1,%rax
    1f58:	48 39 c7             	cmp    %rax,%rdi
    1f5b:	75 c3                	jne    1f20 <init_phy_mem_map+0xc0>
    1f5d:	48 83 c6 14          	add    $0x14,%rsi
    1f61:	48 39 f3             	cmp    %rsi,%rbx
    1f64:	75 93                	jne    1ef9 <init_phy_mem_map+0x99>
    1f66:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1f6d:	00 00 00 
    1f70:	48 8b 05 19 24 00 00 	mov    0x2419(%rip),%rax        # 4390 <phy_mem_map>
    1f77:	48 8d b4 10 ff 0f 00 	lea    0xfff(%rax,%rdx,1),%rsi
    1f7e:	00 
    1f7f:	48 c1 ee 0c          	shr    $0xc,%rsi
    1f83:	74 3d                	je     1fc2 <init_phy_mem_map+0x162>
    1f85:	31 c0                	xor    %eax,%eax
    1f87:	bf 01 00 00 00       	mov    $0x1,%edi
    1f8c:	eb 09                	jmp    1f97 <init_phy_mem_map+0x137>
    1f8e:	66 90                	xchg   %ax,%ax
    1f90:	48 8b 15 01 24 00 00 	mov    0x2401(%rip),%rdx        # 4398 <phy_mem_map+0x8>
    1f97:	48 c1 e2 03          	shl    $0x3,%rdx
    1f9b:	48 39 c2             	cmp    %rax,%rdx
    1f9e:	76 19                	jbe    1fb9 <init_phy_mem_map+0x159>
    1fa0:	48 89 c2             	mov    %rax,%rdx
    1fa3:	89 c1                	mov    %eax,%ecx
    1fa5:	89 fb                	mov    %edi,%ebx
    1fa7:	48 c1 ea 03          	shr    $0x3,%rdx
    1fab:	83 e1 07             	and    $0x7,%ecx
    1fae:	48 03 15 db 23 00 00 	add    0x23db(%rip),%rdx        # 4390 <phy_mem_map>
    1fb5:	d3 e3                	shl    %cl,%ebx
    1fb7:	08 1a                	or     %bl,(%rdx)
    1fb9:	48 83 c0 01          	add    $0x1,%rax
    1fbd:	48 39 c6             	cmp    %rax,%rsi
    1fc0:	75 ce                	jne    1f90 <init_phy_mem_map+0x130>
    1fc2:	5b                   	pop    %rbx
    1fc3:	c3                   	ret    
    1fc4:	31 d2                	xor    %edx,%edx
    1fc6:	be ff 00 00 00       	mov    $0xff,%esi
    1fcb:	bf 00 00 20 00       	mov    $0x200000,%edi
    1fd0:	48 c7 05 b5 23 00 00 	movq   $0x200000,0x23b5(%rip)        # 4390 <phy_mem_map>
    1fd7:	00 00 20 00 
    1fdb:	48 c7 05 b2 23 00 00 	movq   $0x0,0x23b2(%rip)        # 4398 <phy_mem_map+0x8>
    1fe2:	00 00 00 00 
    1fe6:	e8 15 0c 00 00       	call   2c00 <memset>
    1feb:	48 8b 15 a6 23 00 00 	mov    0x23a6(%rip),%rdx        # 4398 <phy_mem_map+0x8>
    1ff2:	e9 79 ff ff ff       	jmp    1f70 <init_phy_mem_map+0x110>
    1ff7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    1ffe:	00 00 

0000000000002000 <set_bit>:
    2000:	48 8b 47 08          	mov    0x8(%rdi),%rax
    2004:	48 89 f1             	mov    %rsi,%rcx
    2007:	48 c1 e0 03          	shl    $0x3,%rax
    200b:	48 39 f0             	cmp    %rsi,%rax
    200e:	76 20                	jbe    2030 <set_bit+0x30>
    2010:	83 e1 07             	and    $0x7,%ecx
    2013:	b8 01 00 00 00       	mov    $0x1,%eax
    2018:	48 c1 ee 03          	shr    $0x3,%rsi
    201c:	48 03 37             	add    (%rdi),%rsi
    201f:	d3 e0                	shl    %cl,%eax
    2021:	89 c1                	mov    %eax,%ecx
    2023:	0a 06                	or     (%rsi),%al
    2025:	f7 d1                	not    %ecx
    2027:	22 0e                	and    (%rsi),%cl
    2029:	84 d2                	test   %dl,%dl
    202b:	0f 44 c1             	cmove  %ecx,%eax
    202e:	88 06                	mov    %al,(%rsi)
    2030:	c3                   	ret    
    2031:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2038:	00 00 00 00 
    203c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002040 <get_bit>:
    2040:	48 8b 47 08          	mov    0x8(%rdi),%rax
    2044:	48 89 f1             	mov    %rsi,%rcx
    2047:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
    204e:	00 
    204f:	31 c0                	xor    %eax,%eax
    2051:	48 39 f2             	cmp    %rsi,%rdx
    2054:	76 16                	jbe    206c <get_bit+0x2c>
    2056:	48 8b 17             	mov    (%rdi),%rdx
    2059:	48 89 f0             	mov    %rsi,%rax
    205c:	83 e1 07             	and    $0x7,%ecx
    205f:	48 c1 e8 03          	shr    $0x3,%rax
    2063:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
    2067:	d3 f8                	sar    %cl,%eax
    2069:	83 e0 01             	and    $0x1,%eax
    206c:	c3                   	ret    
    206d:	0f 1f 00             	nopl   (%rax)

0000000000002070 <alloc_page>:
    2070:	48 8b 0d 21 23 00 00 	mov    0x2321(%rip),%rcx        # 4398 <phy_mem_map+0x8>
    2077:	48 c1 e1 03          	shl    $0x3,%rcx
    207b:	74 31                	je     20ae <alloc_page+0x3e>
    207d:	48 8b 3d 0c 23 00 00 	mov    0x230c(%rip),%rdi        # 4390 <phy_mem_map>
    2084:	f6 07 01             	testb  $0x1,(%rdi)
    2087:	74 49                	je     20d2 <alloc_page+0x62>
    2089:	31 f6                	xor    %esi,%esi
    208b:	eb 18                	jmp    20a5 <alloc_page+0x35>
    208d:	0f 1f 00             	nopl   (%rax)
    2090:	48 89 f0             	mov    %rsi,%rax
    2093:	48 c1 e8 03          	shr    $0x3,%rax
    2097:	0f b6 14 07          	movzbl (%rdi,%rax,1),%edx
    209b:	89 f0                	mov    %esi,%eax
    209d:	83 e0 07             	and    $0x7,%eax
    20a0:	0f a3 c2             	bt     %eax,%edx
    20a3:	73 13                	jae    20b8 <alloc_page+0x48>
    20a5:	48 83 c6 01          	add    $0x1,%rsi
    20a9:	48 39 ce             	cmp    %rcx,%rsi
    20ac:	75 e2                	jne    2090 <alloc_page+0x20>
    20ae:	45 31 c0             	xor    %r8d,%r8d
    20b1:	4c 89 c0             	mov    %r8,%rax
    20b4:	c3                   	ret    
    20b5:	0f 1f 00             	nopl   (%rax)
    20b8:	49 89 f0             	mov    %rsi,%r8
    20bb:	49 c1 e0 0c          	shl    $0xc,%r8
    20bf:	ba 01 00 00 00       	mov    $0x1,%edx
    20c4:	bf 90 43 00 00       	mov    $0x4390,%edi
    20c9:	e8 32 ff ff ff       	call   2000 <set_bit>
    20ce:	4c 89 c0             	mov    %r8,%rax
    20d1:	c3                   	ret    
    20d2:	45 31 c0             	xor    %r8d,%r8d
    20d5:	31 f6                	xor    %esi,%esi
    20d7:	eb e6                	jmp    20bf <alloc_page+0x4f>
    20d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000020e0 <free_page>:
    20e0:	55                   	push   %rbp
    20e1:	ba 00 10 00 00       	mov    $0x1000,%edx
    20e6:	31 f6                	xor    %esi,%esi
    20e8:	48 89 fd             	mov    %rdi,%rbp
    20eb:	53                   	push   %rbx
    20ec:	48 89 fb             	mov    %rdi,%rbx
    20ef:	48 c1 ed 0c          	shr    $0xc,%rbp
    20f3:	48 83 ec 08          	sub    $0x8,%rsp
    20f7:	e8 04 0b 00 00       	call   2c00 <memset>
    20fc:	48 8b 05 95 22 00 00 	mov    0x2295(%rip),%rax        # 4398 <phy_mem_map+0x8>
    2103:	48 c1 e0 03          	shl    $0x3,%rax
    2107:	48 39 c5             	cmp    %rax,%rbp
    210a:	73 16                	jae    2122 <free_page+0x42>
    210c:	48 c1 eb 0f          	shr    $0xf,%rbx
    2110:	48 03 1d 79 22 00 00 	add    0x2279(%rip),%rbx        # 4390 <phy_mem_map>
    2117:	83 e5 07             	and    $0x7,%ebp
    211a:	0f b6 03             	movzbl (%rbx),%eax
    211d:	0f b3 e8             	btr    %ebp,%eax
    2120:	88 03                	mov    %al,(%rbx)
    2122:	48 83 c4 08          	add    $0x8,%rsp
    2126:	5b                   	pop    %rbx
    2127:	5d                   	pop    %rbp
    2128:	c3                   	ret    
    2129:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000002130 <pic_init>:
    2130:	b8 11 00 00 00       	mov    $0x11,%eax
    2135:	e6 20                	out    %al,$0x20
    2137:	e6 a0                	out    %al,$0xa0
    2139:	b8 20 00 00 00       	mov    $0x20,%eax
    213e:	e6 21                	out    %al,$0x21
    2140:	b8 28 00 00 00       	mov    $0x28,%eax
    2145:	e6 a1                	out    %al,$0xa1
    2147:	b8 04 00 00 00       	mov    $0x4,%eax
    214c:	e6 21                	out    %al,$0x21
    214e:	b8 02 00 00 00       	mov    $0x2,%eax
    2153:	e6 a1                	out    %al,$0xa1
    2155:	b8 01 00 00 00       	mov    $0x1,%eax
    215a:	e6 21                	out    %al,$0x21
    215c:	e6 a1                	out    %al,$0xa1
    215e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2163:	e6 21                	out    %al,$0x21
    2165:	e6 a1                	out    %al,$0xa1
    2167:	bf 90 2f 00 00       	mov    $0x2f90,%edi
    216c:	e9 ff 01 00 00       	jmp    2370 <print_string>
    2171:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2178:	00 00 00 
    217b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002180 <get_cursor>:
    2180:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2185:	b8 0e 00 00 00       	mov    $0xe,%eax
    218a:	89 fa                	mov    %edi,%edx
    218c:	ee                   	out    %al,(%dx)
    218d:	be d5 03 00 00       	mov    $0x3d5,%esi
    2192:	89 f2                	mov    %esi,%edx
    2194:	ec                   	in     (%dx),%al
    2195:	0f b6 c8             	movzbl %al,%ecx
    2198:	89 fa                	mov    %edi,%edx
    219a:	b8 0f 00 00 00       	mov    $0xf,%eax
    219f:	c1 e1 08             	shl    $0x8,%ecx
    21a2:	ee                   	out    %al,(%dx)
    21a3:	89 f2                	mov    %esi,%edx
    21a5:	ec                   	in     (%dx),%al
    21a6:	0f b6 c0             	movzbl %al,%eax
    21a9:	09 c8                	or     %ecx,%eax
    21ab:	c3                   	ret    
    21ac:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000021b0 <set_cursor>:
    21b0:	be d4 03 00 00       	mov    $0x3d4,%esi
    21b5:	41 89 f8             	mov    %edi,%r8d
    21b8:	b8 0e 00 00 00       	mov    $0xe,%eax
    21bd:	89 f2                	mov    %esi,%edx
    21bf:	ee                   	out    %al,(%dx)
    21c0:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    21c5:	66 c1 ef 08          	shr    $0x8,%di
    21c9:	89 f8                	mov    %edi,%eax
    21cb:	89 ca                	mov    %ecx,%edx
    21cd:	ee                   	out    %al,(%dx)
    21ce:	b8 0f 00 00 00       	mov    $0xf,%eax
    21d3:	89 f2                	mov    %esi,%edx
    21d5:	ee                   	out    %al,(%dx)
    21d6:	44 89 c0             	mov    %r8d,%eax
    21d9:	89 ca                	mov    %ecx,%edx
    21db:	ee                   	out    %al,(%dx)
    21dc:	c3                   	ret    
    21dd:	0f 1f 00             	nopl   (%rax)

00000000000021e0 <clear_screen>:
    21e0:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    21e5:	0f 1f 00             	nopl   (%rax)
    21e8:	c6 00 20             	movb   $0x20,(%rax)
    21eb:	48 83 c0 02          	add    $0x2,%rax
    21ef:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    21f3:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    21f9:	75 ed                	jne    21e8 <clear_screen+0x8>
    21fb:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2200:	b8 0e 00 00 00       	mov    $0xe,%eax
    2205:	89 fa                	mov    %edi,%edx
    2207:	ee                   	out    %al,(%dx)
    2208:	31 c9                	xor    %ecx,%ecx
    220a:	be d5 03 00 00       	mov    $0x3d5,%esi
    220f:	89 c8                	mov    %ecx,%eax
    2211:	89 f2                	mov    %esi,%edx
    2213:	ee                   	out    %al,(%dx)
    2214:	b8 0f 00 00 00       	mov    $0xf,%eax
    2219:	89 fa                	mov    %edi,%edx
    221b:	ee                   	out    %al,(%dx)
    221c:	89 c8                	mov    %ecx,%eax
    221e:	89 f2                	mov    %esi,%edx
    2220:	ee                   	out    %al,(%dx)
    2221:	c3                   	ret    
    2222:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2229:	00 00 00 00 
    222d:	0f 1f 00             	nopl   (%rax)

0000000000002230 <put_char>:
    2230:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    2236:	53                   	push   %rbx
    2237:	b8 0e 00 00 00       	mov    $0xe,%eax
    223c:	44 89 c2             	mov    %r8d,%edx
    223f:	ee                   	out    %al,(%dx)
    2240:	be d5 03 00 00       	mov    $0x3d5,%esi
    2245:	89 f2                	mov    %esi,%edx
    2247:	ec                   	in     (%dx),%al
    2248:	0f b6 c8             	movzbl %al,%ecx
    224b:	44 89 c2             	mov    %r8d,%edx
    224e:	b8 0f 00 00 00       	mov    $0xf,%eax
    2253:	c1 e1 08             	shl    $0x8,%ecx
    2256:	ee                   	out    %al,(%dx)
    2257:	89 f2                	mov    %esi,%edx
    2259:	ec                   	in     (%dx),%al
    225a:	0f b6 c0             	movzbl %al,%eax
    225d:	09 c8                	or     %ecx,%eax
    225f:	40 80 ff 0d          	cmp    $0xd,%dil
    2263:	0f 84 b7 00 00 00    	je     2320 <put_char+0xf0>
    2269:	40 80 ff 0a          	cmp    $0xa,%dil
    226d:	74 5c                	je     22cb <put_char+0x9b>
    226f:	40 80 ff 08          	cmp    $0x8,%dil
    2273:	0f 84 be 00 00 00    	je     2337 <put_char+0x107>
    2279:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    227d:	0f b6 0d d3 10 00 00 	movzbl 0x10d3(%rip),%ecx        # 3357 <current_color>
    2284:	83 c0 01             	add    $0x1,%eax
    2287:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    228d:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    2294:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    229a:	66 3d cf 07          	cmp    $0x7cf,%ax
    229e:	77 44                	ja     22e4 <put_char+0xb4>
    22a0:	0f b6 dc             	movzbl %ah,%ebx
    22a3:	89 c1                	mov    %eax,%ecx
    22a5:	bf d4 03 00 00       	mov    $0x3d4,%edi
    22aa:	b8 0e 00 00 00       	mov    $0xe,%eax
    22af:	89 fa                	mov    %edi,%edx
    22b1:	ee                   	out    %al,(%dx)
    22b2:	be d5 03 00 00       	mov    $0x3d5,%esi
    22b7:	89 d8                	mov    %ebx,%eax
    22b9:	89 f2                	mov    %esi,%edx
    22bb:	ee                   	out    %al,(%dx)
    22bc:	b8 0f 00 00 00       	mov    $0xf,%eax
    22c1:	89 fa                	mov    %edi,%edx
    22c3:	ee                   	out    %al,(%dx)
    22c4:	89 c8                	mov    %ecx,%eax
    22c6:	89 f2                	mov    %esi,%edx
    22c8:	ee                   	out    %al,(%dx)
    22c9:	5b                   	pop    %rbx
    22ca:	c3                   	ret    
    22cb:	0f b7 c0             	movzwl %ax,%eax
    22ce:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    22d4:	c1 e8 16             	shr    $0x16,%eax
    22d7:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    22db:	c1 e0 04             	shl    $0x4,%eax
    22de:	66 3d cf 07          	cmp    $0x7cf,%ax
    22e2:	76 bc                	jbe    22a0 <put_char+0x70>
    22e4:	ba 00 0f 00 00       	mov    $0xf00,%edx
    22e9:	be a0 80 0b 00       	mov    $0xb80a0,%esi
    22ee:	bf 00 80 0b 00       	mov    $0xb8000,%edi
    22f3:	e8 28 09 00 00       	call   2c20 <memcpy>
    22f8:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    22fd:	0f 1f 00             	nopl   (%rax)
    2300:	c6 00 20             	movb   $0x20,(%rax)
    2303:	48 83 c0 02          	add    $0x2,%rax
    2307:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    230b:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    2311:	75 ed                	jne    2300 <put_char+0xd0>
    2313:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    2318:	bb 07 00 00 00       	mov    $0x7,%ebx
    231d:	eb 86                	jmp    22a5 <put_char+0x75>
    231f:	90                   	nop
    2320:	0f b7 c0             	movzwl %ax,%eax
    2323:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    2329:	c1 e8 16             	shr    $0x16,%eax
    232c:	8d 04 80             	lea    (%rax,%rax,4),%eax
    232f:	c1 e0 04             	shl    $0x4,%eax
    2332:	e9 63 ff ff ff       	jmp    229a <put_char+0x6a>
    2337:	66 85 c0             	test   %ax,%ax
    233a:	74 26                	je     2362 <put_char+0x132>
    233c:	83 e8 01             	sub    $0x1,%eax
    233f:	0f b6 0d 11 10 00 00 	movzbl 0x1011(%rip),%ecx        # 3357 <current_color>
    2346:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    234a:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    2350:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    2357:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    235d:	e9 38 ff ff ff       	jmp    229a <put_char+0x6a>
    2362:	31 c9                	xor    %ecx,%ecx
    2364:	31 db                	xor    %ebx,%ebx
    2366:	e9 3a ff ff ff       	jmp    22a5 <put_char+0x75>
    236b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002370 <print_string>:
    2370:	53                   	push   %rbx
    2371:	48 89 fb             	mov    %rdi,%rbx
    2374:	0f be 3f             	movsbl (%rdi),%edi
    2377:	40 84 ff             	test   %dil,%dil
    237a:	74 16                	je     2392 <print_string+0x22>
    237c:	0f 1f 40 00          	nopl   0x0(%rax)
    2380:	e8 ab fe ff ff       	call   2230 <put_char>
    2385:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2389:	48 83 c3 01          	add    $0x1,%rbx
    238d:	40 84 ff             	test   %dil,%dil
    2390:	75 ee                	jne    2380 <print_string+0x10>
    2392:	5b                   	pop    %rbx
    2393:	c3                   	ret    
    2394:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    239b:	00 00 00 00 
    239f:	90                   	nop

00000000000023a0 <print_hex>:
    23a0:	55                   	push   %rbp
    23a1:	48 89 fd             	mov    %rdi,%rbp
    23a4:	bf 30 00 00 00       	mov    $0x30,%edi
    23a9:	53                   	push   %rbx
    23aa:	bb 01 30 00 00       	mov    $0x3001,%ebx
    23af:	48 83 ec 18          	sub    $0x18,%rsp
    23b3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    23b8:	e8 73 fe ff ff       	call   2230 <put_char>
    23bd:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    23c1:	48 83 c3 01          	add    $0x1,%rbx
    23c5:	40 84 ff             	test   %dil,%dil
    23c8:	75 ee                	jne    23b8 <print_hex+0x18>
    23ca:	b8 01 00 00 00       	mov    $0x1,%eax
    23cf:	48 85 ed             	test   %rbp,%rbp
    23d2:	74 54                	je     2428 <print_hex+0x88>
    23d4:	0f 1f 40 00          	nopl   0x0(%rax)
    23d8:	48 89 ea             	mov    %rbp,%rdx
    23db:	48 63 d8             	movslq %eax,%rbx
    23de:	83 e2 0f             	and    $0xf,%edx
    23e1:	0f be ba bc 2f 00 00 	movsbl 0x2fbc(%rdx),%edi
    23e8:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    23ed:	48 83 c0 01          	add    $0x1,%rax
    23f1:	48 c1 ed 04          	shr    $0x4,%rbp
    23f5:	75 e1                	jne    23d8 <print_hex+0x38>
    23f7:	e8 34 fe ff ff       	call   2230 <put_char>
    23fc:	48 83 eb 01          	sub    $0x1,%rbx
    2400:	85 db                	test   %ebx,%ebx
    2402:	74 16                	je     241a <print_hex+0x7a>
    2404:	0f 1f 40 00          	nopl   0x0(%rax)
    2408:	0f be 7c 1c ff       	movsbl -0x1(%rsp,%rbx,1),%edi
    240d:	48 83 eb 01          	sub    $0x1,%rbx
    2411:	e8 1a fe ff ff       	call   2230 <put_char>
    2416:	85 db                	test   %ebx,%ebx
    2418:	75 ee                	jne    2408 <print_hex+0x68>
    241a:	48 83 c4 18          	add    $0x18,%rsp
    241e:	5b                   	pop    %rbx
    241f:	5d                   	pop    %rbp
    2420:	c3                   	ret    
    2421:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2428:	48 83 c4 18          	add    $0x18,%rsp
    242c:	bf 30 00 00 00       	mov    $0x30,%edi
    2431:	5b                   	pop    %rbx
    2432:	5d                   	pop    %rbp
    2433:	e9 f8 fd ff ff       	jmp    2230 <put_char>
    2438:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    243f:	00 

0000000000002440 <print_int>:
    2440:	53                   	push   %rbx
    2441:	48 83 ec 20          	sub    $0x20,%rsp
    2445:	48 85 ff             	test   %rdi,%rdi
    2448:	74 76                	je     24c0 <print_int+0x80>
    244a:	48 89 fb             	mov    %rdi,%rbx
    244d:	78 61                	js     24b0 <print_int+0x70>
    244f:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    2456:	cc cc cc 
    2459:	be 01 00 00 00       	mov    $0x1,%esi
    245e:	66 90                	xchg   %ax,%ax
    2460:	48 89 d8             	mov    %rbx,%rax
    2463:	89 f1                	mov    %esi,%ecx
    2465:	49 f7 e0             	mul    %r8
    2468:	48 c1 ea 03          	shr    $0x3,%rdx
    246c:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    2470:	48 01 c0             	add    %rax,%rax
    2473:	48 29 c3             	sub    %rax,%rbx
    2476:	8d 7b 30             	lea    0x30(%rbx),%edi
    2479:	48 89 d3             	mov    %rdx,%rbx
    247c:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    2481:	48 83 c6 01          	add    $0x1,%rsi
    2485:	48 85 d2             	test   %rdx,%rdx
    2488:	75 d6                	jne    2460 <print_int+0x20>
    248a:	48 63 d9             	movslq %ecx,%rbx
    248d:	eb 06                	jmp    2495 <print_int+0x55>
    248f:	90                   	nop
    2490:	0f b6 7c 1c 0b       	movzbl 0xb(%rsp,%rbx,1),%edi
    2495:	40 0f be ff          	movsbl %dil,%edi
    2499:	48 83 eb 01          	sub    $0x1,%rbx
    249d:	e8 8e fd ff ff       	call   2230 <put_char>
    24a2:	85 db                	test   %ebx,%ebx
    24a4:	75 ea                	jne    2490 <print_int+0x50>
    24a6:	48 83 c4 20          	add    $0x20,%rsp
    24aa:	5b                   	pop    %rbx
    24ab:	c3                   	ret    
    24ac:	0f 1f 40 00          	nopl   0x0(%rax)
    24b0:	bf 2d 00 00 00       	mov    $0x2d,%edi
    24b5:	48 f7 db             	neg    %rbx
    24b8:	e8 73 fd ff ff       	call   2230 <put_char>
    24bd:	eb 90                	jmp    244f <print_int+0xf>
    24bf:	90                   	nop
    24c0:	48 83 c4 20          	add    $0x20,%rsp
    24c4:	bf 30 00 00 00       	mov    $0x30,%edi
    24c9:	5b                   	pop    %rbx
    24ca:	e9 61 fd ff ff       	jmp    2230 <put_char>
    24cf:	90                   	nop

00000000000024d0 <set_print_color>:
    24d0:	c1 e6 04             	shl    $0x4,%esi
    24d3:	83 e7 0f             	and    $0xf,%edi
    24d6:	09 fe                	or     %edi,%esi
    24d8:	40 88 35 78 0e 00 00 	mov    %sil,0xe78(%rip)        # 3357 <current_color>
    24df:	c3                   	ret    

00000000000024e0 <reset_print_color>:
    24e0:	c6 05 70 0e 00 00 0f 	movb   $0xf,0xe70(%rip)        # 3357 <current_color>
    24e7:	c3                   	ret    
    24e8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    24ef:	00 

00000000000024f0 <print_error>:
    24f0:	53                   	push   %rbx
    24f1:	48 89 fb             	mov    %rdi,%rbx
    24f4:	0f be 3f             	movsbl (%rdi),%edi
    24f7:	c6 05 59 0e 00 00 0c 	movb   $0xc,0xe59(%rip)        # 3357 <current_color>
    24fe:	40 84 ff             	test   %dil,%dil
    2501:	74 17                	je     251a <print_error+0x2a>
    2503:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2508:	e8 23 fd ff ff       	call   2230 <put_char>
    250d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2511:	48 83 c3 01          	add    $0x1,%rbx
    2515:	40 84 ff             	test   %dil,%dil
    2518:	75 ee                	jne    2508 <print_error+0x18>
    251a:	c6 05 36 0e 00 00 0f 	movb   $0xf,0xe36(%rip)        # 3357 <current_color>
    2521:	5b                   	pop    %rbx
    2522:	c3                   	ret    
    2523:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    252a:	00 00 00 00 
    252e:	66 90                	xchg   %ax,%ax

0000000000002530 <print_success>:
    2530:	53                   	push   %rbx
    2531:	48 89 fb             	mov    %rdi,%rbx
    2534:	0f be 3f             	movsbl (%rdi),%edi
    2537:	c6 05 19 0e 00 00 0a 	movb   $0xa,0xe19(%rip)        # 3357 <current_color>
    253e:	40 84 ff             	test   %dil,%dil
    2541:	74 17                	je     255a <print_success+0x2a>
    2543:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2548:	e8 e3 fc ff ff       	call   2230 <put_char>
    254d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2551:	48 83 c3 01          	add    $0x1,%rbx
    2555:	40 84 ff             	test   %dil,%dil
    2558:	75 ee                	jne    2548 <print_success+0x18>
    255a:	c6 05 f6 0d 00 00 0f 	movb   $0xf,0xdf6(%rip)        # 3357 <current_color>
    2561:	5b                   	pop    %rbx
    2562:	c3                   	ret    
    2563:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    256a:	00 00 00 00 
    256e:	66 90                	xchg   %ax,%ax

0000000000002570 <print_info>:
    2570:	53                   	push   %rbx
    2571:	48 89 fb             	mov    %rdi,%rbx
    2574:	0f be 3f             	movsbl (%rdi),%edi
    2577:	c6 05 d9 0d 00 00 0b 	movb   $0xb,0xdd9(%rip)        # 3357 <current_color>
    257e:	40 84 ff             	test   %dil,%dil
    2581:	74 17                	je     259a <print_info+0x2a>
    2583:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2588:	e8 a3 fc ff ff       	call   2230 <put_char>
    258d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2591:	48 83 c3 01          	add    $0x1,%rbx
    2595:	40 84 ff             	test   %dil,%dil
    2598:	75 ee                	jne    2588 <print_info+0x18>
    259a:	c6 05 b6 0d 00 00 0f 	movb   $0xf,0xdb6(%rip)        # 3357 <current_color>
    25a1:	5b                   	pop    %rbx
    25a2:	c3                   	ret    
    25a3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    25aa:	00 00 00 00 
    25ae:	66 90                	xchg   %ax,%ax

00000000000025b0 <print_warning>:
    25b0:	53                   	push   %rbx
    25b1:	48 89 fb             	mov    %rdi,%rbx
    25b4:	0f be 3f             	movsbl (%rdi),%edi
    25b7:	c6 05 99 0d 00 00 0e 	movb   $0xe,0xd99(%rip)        # 3357 <current_color>
    25be:	40 84 ff             	test   %dil,%dil
    25c1:	74 17                	je     25da <print_warning+0x2a>
    25c3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    25c8:	e8 63 fc ff ff       	call   2230 <put_char>
    25cd:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    25d1:	48 83 c3 01          	add    $0x1,%rbx
    25d5:	40 84 ff             	test   %dil,%dil
    25d8:	75 ee                	jne    25c8 <print_warning+0x18>
    25da:	c6 05 76 0d 00 00 0f 	movb   $0xf,0xd76(%rip)        # 3357 <current_color>
    25e1:	5b                   	pop    %rbx
    25e2:	c3                   	ret    
    25e3:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    25ea:	00 00 00 
    25ed:	0f 1f 00             	nopl   (%rax)

00000000000025f0 <shell_init>:
    25f0:	41 54                	push   %r12
    25f2:	bf cd 2f 00 00       	mov    $0x2fcd,%edi
    25f7:	55                   	push   %rbp
    25f8:	48 83 ec 08          	sub    $0x8,%rsp
    25fc:	e8 6f fd ff ff       	call   2370 <print_string>
    2601:	bf d6 2f 00 00       	mov    $0x2fd6,%edi
    2606:	e8 65 fd ff ff       	call   2370 <print_string>
    260b:	48 bf 00 00 00 00 01 	movabs $0x100000000,%rdi
    2612:	00 00 00 
    2615:	e8 46 f8 ff ff       	call   1e60 <init_phy_mem_map>
    261a:	e8 e1 f6 ff ff       	call   1d00 <kmalloc_init>
    261f:	bf a8 31 00 00       	mov    $0x31a8,%edi
    2624:	e8 47 fd ff ff       	call   2370 <print_string>
    2629:	bf 10 00 00 00       	mov    $0x10,%edi
    262e:	e8 1d f7 ff ff       	call   1d50 <kmalloc>
    2633:	bf f0 2f 00 00       	mov    $0x2ff0,%edi
    2638:	48 89 c5             	mov    %rax,%rbp
    263b:	e8 30 fd ff ff       	call   2370 <print_string>
    2640:	48 89 ef             	mov    %rbp,%rdi
    2643:	e8 58 fd ff ff       	call   23a0 <print_hex>
    2648:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    264d:	e8 1e fd ff ff       	call   2370 <print_string>
    2652:	bf 20 00 00 00       	mov    $0x20,%edi
    2657:	e8 f4 f6 ff ff       	call   1d50 <kmalloc>
    265c:	bf 04 30 00 00       	mov    $0x3004,%edi
    2661:	49 89 c4             	mov    %rax,%r12
    2664:	e8 07 fd ff ff       	call   2370 <print_string>
    2669:	4c 89 e7             	mov    %r12,%rdi
    266c:	e8 2f fd ff ff       	call   23a0 <print_hex>
    2671:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    2676:	e8 f5 fc ff ff       	call   2370 <print_string>
    267b:	bf 18 30 00 00       	mov    $0x3018,%edi
    2680:	e8 eb fc ff ff       	call   2370 <print_string>
    2685:	48 89 ef             	mov    %rbp,%rdi
    2688:	e8 53 f7 ff ff       	call   1de0 <kfree>
    268d:	bf 10 00 00 00       	mov    $0x10,%edi
    2692:	e8 b9 f6 ff ff       	call   1d50 <kmalloc>
    2697:	bf d0 31 00 00       	mov    $0x31d0,%edi
    269c:	48 89 c5             	mov    %rax,%rbp
    269f:	e8 cc fc ff ff       	call   2370 <print_string>
    26a4:	48 89 ef             	mov    %rbp,%rdi
    26a7:	e8 f4 fc ff ff       	call   23a0 <print_hex>
    26ac:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    26b1:	e8 ba fc ff ff       	call   2370 <print_string>
    26b6:	4c 89 e7             	mov    %r12,%rdi
    26b9:	e8 22 f7 ff ff       	call   1de0 <kfree>
    26be:	48 89 ef             	mov    %rbp,%rdi
    26c1:	e8 1a f7 ff ff       	call   1de0 <kfree>
    26c6:	48 83 c4 08          	add    $0x8,%rsp
    26ca:	bf 27 30 00 00       	mov    $0x3027,%edi
    26cf:	5d                   	pop    %rbp
    26d0:	41 5c                	pop    %r12
    26d2:	e9 99 fc ff ff       	jmp    2370 <print_string>
    26d7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    26de:	00 00 

00000000000026e0 <execute_command>:
    26e0:	48 63 05 b9 1c 00 00 	movslq 0x1cb9(%rip),%rax        # 43a0 <cmd_index>
    26e7:	85 c0                	test   %eax,%eax
    26e9:	75 05                	jne    26f0 <execute_command+0x10>
    26eb:	c3                   	ret    
    26ec:	0f 1f 40 00          	nopl   0x0(%rax)
    26f0:	41 54                	push   %r12
    26f2:	be 41 30 00 00       	mov    $0x3041,%esi
    26f7:	55                   	push   %rbp
    26f8:	48 89 fd             	mov    %rdi,%rbp
    26fb:	53                   	push   %rbx
    26fc:	48 83 ec 70          	sub    $0x70,%rsp
    2700:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    2704:	e8 77 04 00 00       	call   2b80 <strcmp>
    2709:	85 c0                	test   %eax,%eax
    270b:	75 43                	jne    2750 <execute_command+0x70>
    270d:	bf 46 30 00 00       	mov    $0x3046,%edi
    2712:	e8 59 fc ff ff       	call   2370 <print_string>
    2717:	bf 5b 30 00 00       	mov    $0x305b,%edi
    271c:	e8 4f fc ff ff       	call   2370 <print_string>
    2721:	bf 78 30 00 00       	mov    $0x3078,%edi
    2726:	e8 45 fc ff ff       	call   2370 <print_string>
    272b:	bf f8 31 00 00       	mov    $0x31f8,%edi
    2730:	e8 3b fc ff ff       	call   2370 <print_string>
    2735:	c7 05 61 1c 00 00 00 	movl   $0x0,0x1c61(%rip)        # 43a0 <cmd_index>
    273c:	00 00 00 
    273f:	48 83 c4 70          	add    $0x70,%rsp
    2743:	5b                   	pop    %rbx
    2744:	5d                   	pop    %rbp
    2745:	41 5c                	pop    %r12
    2747:	c3                   	ret    
    2748:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    274f:	00 
    2750:	be 94 30 00 00       	mov    $0x3094,%esi
    2755:	48 89 ef             	mov    %rbp,%rdi
    2758:	e8 23 04 00 00       	call   2b80 <strcmp>
    275d:	85 c0                	test   %eax,%eax
    275f:	74 1f                	je     2780 <execute_command+0xa0>
    2761:	be 9a 30 00 00       	mov    $0x309a,%esi
    2766:	48 89 ef             	mov    %rbp,%rdi
    2769:	e8 12 04 00 00       	call   2b80 <strcmp>
    276e:	85 c0                	test   %eax,%eax
    2770:	75 1e                	jne    2790 <execute_command+0xb0>
    2772:	bf 18 32 00 00       	mov    $0x3218,%edi
    2777:	e8 b4 fd ff ff       	call   2530 <print_success>
    277c:	eb b7                	jmp    2735 <execute_command+0x55>
    277e:	66 90                	xchg   %ax,%ax
    2780:	e8 5b fa ff ff       	call   21e0 <clear_screen>
    2785:	eb ae                	jmp    2735 <execute_command+0x55>
    2787:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    278e:	00 00 
    2790:	be a0 30 00 00       	mov    $0x30a0,%esi
    2795:	48 89 ef             	mov    %rbp,%rdi
    2798:	e8 e3 03 00 00       	call   2b80 <strcmp>
    279d:	85 c0                	test   %eax,%eax
    279f:	74 4f                	je     27f0 <execute_command+0x110>
    27a1:	be c2 30 00 00       	mov    $0x30c2,%esi
    27a6:	48 89 ef             	mov    %rbp,%rdi
    27a9:	e8 d2 03 00 00       	call   2b80 <strcmp>
    27ae:	85 c0                	test   %eax,%eax
    27b0:	75 7e                	jne    2830 <execute_command+0x150>
    27b2:	0f a2                	cpuid  
    27b4:	bf ca 30 00 00       	mov    $0x30ca,%edi
    27b9:	89 54 24 42          	mov    %edx,0x42(%rsp)
    27bd:	89 4c 24 46          	mov    %ecx,0x46(%rsp)
    27c1:	89 5c 24 3e          	mov    %ebx,0x3e(%rsp)
    27c5:	c6 44 24 4a 00       	movb   $0x0,0x4a(%rsp)
    27ca:	e8 a1 fb ff ff       	call   2370 <print_string>
    27cf:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    27d4:	e8 97 fb ff ff       	call   2370 <print_string>
    27d9:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    27de:	e8 8d fb ff ff       	call   2370 <print_string>
    27e3:	e9 4d ff ff ff       	jmp    2735 <execute_command+0x55>
    27e8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    27ef:	00 
    27f0:	48 8b 2d 89 1b 00 00 	mov    0x1b89(%rip),%rbp        # 4380 <system_ticks>
    27f7:	bf a7 30 00 00       	mov    $0x30a7,%edi
    27fc:	e8 6f fb ff ff       	call   2370 <print_string>
    2801:	48 ba 8f e3 38 8e e3 	movabs $0xe38e38e38e38e38f,%rdx
    2808:	38 8e e3 
    280b:	48 89 e8             	mov    %rbp,%rax
    280e:	48 f7 e2             	mul    %rdx
    2811:	48 c1 ea 04          	shr    $0x4,%rdx
    2815:	48 89 d7             	mov    %rdx,%rdi
    2818:	e8 23 fc ff ff       	call   2440 <print_int>
    281d:	bf b7 30 00 00       	mov    $0x30b7,%edi
    2822:	e8 49 fb ff ff       	call   2370 <print_string>
    2827:	e9 09 ff ff ff       	jmp    2735 <execute_command+0x55>
    282c:	0f 1f 40 00          	nopl   0x0(%rax)
    2830:	ba 05 00 00 00       	mov    $0x5,%edx
    2835:	be d7 30 00 00       	mov    $0x30d7,%esi
    283a:	48 89 ef             	mov    %rbp,%rdi
    283d:	e8 6e 03 00 00       	call   2bb0 <strncmp>
    2842:	85 c0                	test   %eax,%eax
    2844:	75 18                	jne    285e <execute_command+0x17e>
    2846:	48 8d 7d 05          	lea    0x5(%rbp),%rdi
    284a:	e8 21 fb ff ff       	call   2370 <print_string>
    284f:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    2854:	e8 17 fb ff ff       	call   2370 <print_string>
    2859:	e9 d7 fe ff ff       	jmp    2735 <execute_command+0x55>
    285e:	be dd 30 00 00       	mov    $0x30dd,%esi
    2863:	48 89 ef             	mov    %rbp,%rdi
    2866:	e8 15 03 00 00       	call   2b80 <strcmp>
    286b:	85 c0                	test   %eax,%eax
    286d:	75 0c                	jne    287b <execute_command+0x19b>
    286f:	bf e3 30 00 00       	mov    $0x30e3,%edi
    2874:	e8 f7 fa ff ff       	call   2370 <print_string>
    2879:	0f 0b                	ud2    
    287b:	be ff 30 00 00       	mov    $0x30ff,%esi
    2880:	48 89 ef             	mov    %rbp,%rdi
    2883:	e8 f8 02 00 00       	call   2b80 <strcmp>
    2888:	85 c0                	test   %eax,%eax
    288a:	0f 85 8f 00 00 00    	jne    291f <execute_command+0x23f>
    2890:	ba 0a 00 00 00       	mov    $0xa,%edx
    2895:	be 41 00 00 00       	mov    $0x41,%esi
    289a:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    289f:	e8 5c 03 00 00       	call   2c00 <memset>
    28a4:	bf 58 32 00 00       	mov    $0x3258,%edi
    28a9:	c6 44 24 16 00       	movb   $0x0,0x16(%rsp)
    28ae:	e8 bd fa ff ff       	call   2370 <print_string>
    28b3:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    28b8:	e8 b3 fa ff ff       	call   2370 <print_string>
    28bd:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    28c2:	e8 a9 fa ff ff       	call   2370 <print_string>
    28c7:	be 07 31 00 00       	mov    $0x3107,%esi
    28cc:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    28d1:	e8 7a 03 00 00       	call   2c50 <strcpy>
    28d6:	bf 15 31 00 00       	mov    $0x3115,%edi
    28db:	e8 90 fa ff ff       	call   2370 <print_string>
    28e0:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    28e5:	e8 86 fa ff ff       	call   2370 <print_string>
    28ea:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    28ef:	e8 7c fa ff ff       	call   2370 <print_string>
    28f4:	bf 80 32 00 00       	mov    $0x3280,%edi
    28f9:	e8 72 fa ff ff       	call   2370 <print_string>
    28fe:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2903:	e8 48 02 00 00       	call   2b50 <strlen>
    2908:	48 89 c7             	mov    %rax,%rdi
    290b:	e8 30 fb ff ff       	call   2440 <print_int>
    2910:	bf 23 31 00 00       	mov    $0x3123,%edi
    2915:	e8 56 fa ff ff       	call   2370 <print_string>
    291a:	e9 16 fe ff ff       	jmp    2735 <execute_command+0x55>
    291f:	be 33 31 00 00       	mov    $0x3133,%esi
    2924:	48 89 ef             	mov    %rbp,%rdi
    2927:	e8 54 02 00 00       	call   2b80 <strcmp>
    292c:	85 c0                	test   %eax,%eax
    292e:	75 20                	jne    2950 <execute_command+0x270>
    2930:	bf a0 32 00 00       	mov    $0x32a0,%edi
    2935:	e8 36 fa ff ff       	call   2370 <print_string>
    293a:	bf c8 32 00 00       	mov    $0x32c8,%edi
    293f:	8b 04 25 ff ff ff ff 	mov    0xffffffffffffffff,%eax
    2946:	e8 25 fa ff ff       	call   2370 <print_string>
    294b:	e9 e5 fd ff ff       	jmp    2735 <execute_command+0x55>
    2950:	be 3a 31 00 00       	mov    $0x313a,%esi
    2955:	48 89 ef             	mov    %rbp,%rdi
    2958:	e8 23 02 00 00       	call   2b80 <strcmp>
    295d:	85 c0                	test   %eax,%eax
    295f:	75 22                	jne    2983 <execute_command+0x2a3>
    2961:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    2968:	83 e8 01             	sub    $0x1,%eax
    296b:	83 f8 12             	cmp    $0x12,%eax
    296e:	0f 87 cb 00 00 00    	ja     2a3f <execute_command+0x35f>
    2974:	bf e8 32 00 00       	mov    $0x32e8,%edi
    2979:	e8 b2 fb ff ff       	call   2530 <print_success>
    297e:	e9 b2 fd ff ff       	jmp    2735 <execute_command+0x55>
    2983:	be 42 31 00 00       	mov    $0x3142,%esi
    2988:	48 89 ef             	mov    %rbp,%rdi
    298b:	e8 f0 01 00 00       	call   2b80 <strcmp>
    2990:	85 c0                	test   %eax,%eax
    2992:	0f 85 b6 00 00 00    	jne    2a4e <execute_command+0x36e>
    2998:	8b 1c 25 00 80 00 00 	mov    0x8000,%ebx
    299f:	bf 4a 31 00 00       	mov    $0x314a,%edi
    29a4:	e8 c7 f9 ff ff       	call   2370 <print_string>
    29a9:	85 db                	test   %ebx,%ebx
    29ab:	0f 84 be 00 00 00    	je     2a6f <execute_command+0x38f>
    29b1:	8d 43 ff             	lea    -0x1(%rbx),%eax
    29b4:	31 ed                	xor    %ebp,%ebp
    29b6:	bb 04 80 00 00       	mov    $0x8004,%ebx
    29bb:	48 6b c0 14          	imul   $0x14,%rax,%rax
    29bf:	4c 8d a0 18 80 00 00 	lea    0x8018(%rax),%r12
    29c6:	bf 67 31 00 00       	mov    $0x3167,%edi
    29cb:	e8 a0 f9 ff ff       	call   2370 <print_string>
    29d0:	48 8b 3b             	mov    (%rbx),%rdi
    29d3:	e8 c8 f9 ff ff       	call   23a0 <print_hex>
    29d8:	bf 76 31 00 00       	mov    $0x3176,%edi
    29dd:	e8 8e f9 ff ff       	call   2370 <print_string>
    29e2:	48 8b 7b 08          	mov    0x8(%rbx),%rdi
    29e6:	e8 b5 f9 ff ff       	call   23a0 <print_hex>
    29eb:	bf 81 31 00 00       	mov    $0x3181,%edi
    29f0:	e8 7b f9 ff ff       	call   2370 <print_string>
    29f5:	8b 7b 10             	mov    0x10(%rbx),%edi
    29f8:	e8 43 fa ff ff       	call   2440 <print_int>
    29fd:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    2a02:	e8 69 f9 ff ff       	call   2370 <print_string>
    2a07:	83 7b 10 01          	cmpl   $0x1,0x10(%rbx)
    2a0b:	75 04                	jne    2a11 <execute_command+0x331>
    2a0d:	48 03 6b 08          	add    0x8(%rbx),%rbp
    2a11:	48 83 c3 14          	add    $0x14,%rbx
    2a15:	4c 39 e3             	cmp    %r12,%rbx
    2a18:	75 ac                	jne    29c6 <execute_command+0x2e6>
    2a1a:	bf 38 33 00 00       	mov    $0x3338,%edi
    2a1f:	e8 4c f9 ff ff       	call   2370 <print_string>
    2a24:	48 89 ef             	mov    %rbp,%rdi
    2a27:	48 c1 ef 14          	shr    $0x14,%rdi
    2a2b:	e8 10 fa ff ff       	call   2440 <print_int>
    2a30:	bf 8a 31 00 00       	mov    $0x318a,%edi
    2a35:	e8 36 f9 ff ff       	call   2370 <print_string>
    2a3a:	e9 f6 fc ff ff       	jmp    2735 <execute_command+0x55>
    2a3f:	bf 10 33 00 00       	mov    $0x3310,%edi
    2a44:	e8 a7 fa ff ff       	call   24f0 <print_error>
    2a49:	e9 e7 fc ff ff       	jmp    2735 <execute_command+0x55>
    2a4e:	bf 8f 31 00 00       	mov    $0x318f,%edi
    2a53:	e8 98 fa ff ff       	call   24f0 <print_error>
    2a58:	48 89 ef             	mov    %rbp,%rdi
    2a5b:	e8 90 fa ff ff       	call   24f0 <print_error>
    2a60:	bf 2f 2f 00 00       	mov    $0x2f2f,%edi
    2a65:	e8 86 fa ff ff       	call   24f0 <print_error>
    2a6a:	e9 c6 fc ff ff       	jmp    2735 <execute_command+0x55>
    2a6f:	31 ed                	xor    %ebp,%ebp
    2a71:	eb a7                	jmp    2a1a <execute_command+0x33a>
    2a73:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2a7a:	00 00 00 00 
    2a7e:	66 90                	xchg   %ax,%ax

0000000000002a80 <shell_take_char>:
    2a80:	48 83 ec 08          	sub    $0x8,%rsp
    2a84:	40 80 ff 0a          	cmp    $0xa,%dil
    2a88:	74 76                	je     2b00 <shell_take_char+0x80>
    2a8a:	8b 05 10 19 00 00    	mov    0x1910(%rip),%eax        # 43a0 <cmd_index>
    2a90:	40 80 ff 08          	cmp    $0x8,%dil
    2a94:	74 4a                	je     2ae0 <shell_take_char+0x60>
    2a96:	40 80 ff 1b          	cmp    $0x1b,%dil
    2a9a:	74 2d                	je     2ac9 <shell_take_char+0x49>
    2a9c:	3d fe 00 00 00       	cmp    $0xfe,%eax
    2aa1:	0f 8e 89 00 00 00    	jle    2b30 <shell_take_char+0xb0>
    2aa7:	48 83 c4 08          	add    $0x8,%rsp
    2aab:	c3                   	ret    
    2aac:	0f 1f 40 00          	nopl   0x0(%rax)
    2ab0:	bf 08 00 00 00       	mov    $0x8,%edi
    2ab5:	e8 76 f7 ff ff       	call   2230 <put_char>
    2aba:	8b 05 e0 18 00 00    	mov    0x18e0(%rip),%eax        # 43a0 <cmd_index>
    2ac0:	83 e8 01             	sub    $0x1,%eax
    2ac3:	89 05 d7 18 00 00    	mov    %eax,0x18d7(%rip)        # 43a0 <cmd_index>
    2ac9:	85 c0                	test   %eax,%eax
    2acb:	7f e3                	jg     2ab0 <shell_take_char+0x30>
    2acd:	c6 05 ec 18 00 00 00 	movb   $0x0,0x18ec(%rip)        # 43c0 <cmd_buffer>
    2ad4:	48 83 c4 08          	add    $0x8,%rsp
    2ad8:	c3                   	ret    
    2ad9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2ae0:	85 c0                	test   %eax,%eax
    2ae2:	7e c3                	jle    2aa7 <shell_take_char+0x27>
    2ae4:	83 e8 01             	sub    $0x1,%eax
    2ae7:	bf 08 00 00 00       	mov    $0x8,%edi
    2aec:	89 05 ae 18 00 00    	mov    %eax,0x18ae(%rip)        # 43a0 <cmd_index>
    2af2:	48 83 c4 08          	add    $0x8,%rsp
    2af6:	e9 35 f7 ff ff       	jmp    2230 <put_char>
    2afb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2b00:	bf 0a 00 00 00       	mov    $0xa,%edi
    2b05:	e8 26 f7 ff ff       	call   2230 <put_char>
    2b0a:	48 63 05 8f 18 00 00 	movslq 0x188f(%rip),%rax        # 43a0 <cmd_index>
    2b11:	bf c0 43 00 00       	mov    $0x43c0,%edi
    2b16:	c6 80 c0 43 00 00 00 	movb   $0x0,0x43c0(%rax)
    2b1d:	e8 be fb ff ff       	call   26e0 <execute_command>
    2b22:	bf ce 2f 00 00       	mov    $0x2fce,%edi
    2b27:	48 83 c4 08          	add    $0x8,%rsp
    2b2b:	e9 40 f8 ff ff       	jmp    2370 <print_string>
    2b30:	48 63 d0             	movslq %eax,%rdx
    2b33:	83 c0 01             	add    $0x1,%eax
    2b36:	40 88 ba c0 43 00 00 	mov    %dil,0x43c0(%rdx)
    2b3d:	40 0f be ff          	movsbl %dil,%edi
    2b41:	89 05 59 18 00 00    	mov    %eax,0x1859(%rip)        # 43a0 <cmd_index>
    2b47:	48 83 c4 08          	add    $0x8,%rsp
    2b4b:	e9 e0 f6 ff ff       	jmp    2230 <put_char>

0000000000002b50 <strlen>:
    2b50:	31 c0                	xor    %eax,%eax
    2b52:	80 3f 00             	cmpb   $0x0,(%rdi)
    2b55:	74 19                	je     2b70 <strlen+0x20>
    2b57:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    2b5e:	00 00 
    2b60:	48 83 c0 01          	add    $0x1,%rax
    2b64:	80 3c 07 00          	cmpb   $0x0,(%rdi,%rax,1)
    2b68:	75 f6                	jne    2b60 <strlen+0x10>
    2b6a:	c3                   	ret    
    2b6b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2b70:	c3                   	ret    
    2b71:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2b78:	00 00 00 00 
    2b7c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002b80 <strcmp>:
    2b80:	eb 12                	jmp    2b94 <strcmp+0x14>
    2b82:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2b88:	38 06                	cmp    %al,(%rsi)
    2b8a:	75 11                	jne    2b9d <strcmp+0x1d>
    2b8c:	48 83 c7 01          	add    $0x1,%rdi
    2b90:	48 83 c6 01          	add    $0x1,%rsi
    2b94:	0f b6 07             	movzbl (%rdi),%eax
    2b97:	84 c0                	test   %al,%al
    2b99:	75 ed                	jne    2b88 <strcmp+0x8>
    2b9b:	31 c0                	xor    %eax,%eax
    2b9d:	0f b6 16             	movzbl (%rsi),%edx
    2ba0:	29 d0                	sub    %edx,%eax
    2ba2:	c3                   	ret    
    2ba3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2baa:	00 00 00 00 
    2bae:	66 90                	xchg   %ax,%ax

0000000000002bb0 <strncmp>:
    2bb0:	85 d2                	test   %edx,%edx
    2bb2:	7f 1d                	jg     2bd1 <strncmp+0x21>
    2bb4:	eb 35                	jmp    2beb <strncmp+0x3b>
    2bb6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2bbd:	00 00 00 
    2bc0:	3a 06                	cmp    (%rsi),%al
    2bc2:	75 14                	jne    2bd8 <strncmp+0x28>
    2bc4:	48 83 c7 01          	add    $0x1,%rdi
    2bc8:	48 83 c6 01          	add    $0x1,%rsi
    2bcc:	83 ea 01             	sub    $0x1,%edx
    2bcf:	74 17                	je     2be8 <strncmp+0x38>
    2bd1:	0f b6 07             	movzbl (%rdi),%eax
    2bd4:	84 c0                	test   %al,%al
    2bd6:	75 e8                	jne    2bc0 <strncmp+0x10>
    2bd8:	0f b6 07             	movzbl (%rdi),%eax
    2bdb:	0f b6 16             	movzbl (%rsi),%edx
    2bde:	29 d0                	sub    %edx,%eax
    2be0:	c3                   	ret    
    2be1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2be8:	31 c0                	xor    %eax,%eax
    2bea:	c3                   	ret    
    2beb:	b8 00 00 00 00       	mov    $0x0,%eax
    2bf0:	75 e6                	jne    2bd8 <strncmp+0x28>
    2bf2:	c3                   	ret    
    2bf3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2bfa:	00 00 00 00 
    2bfe:	66 90                	xchg   %ax,%ax

0000000000002c00 <memset>:
    2c00:	48 89 f8             	mov    %rdi,%rax
    2c03:	4c 8d 04 17          	lea    (%rdi,%rdx,1),%r8
    2c07:	48 89 f9             	mov    %rdi,%rcx
    2c0a:	48 85 d2             	test   %rdx,%rdx
    2c0d:	74 0e                	je     2c1d <memset+0x1d>
    2c0f:	90                   	nop
    2c10:	48 83 c1 01          	add    $0x1,%rcx
    2c14:	40 88 71 ff          	mov    %sil,-0x1(%rcx)
    2c18:	4c 39 c1             	cmp    %r8,%rcx
    2c1b:	75 f3                	jne    2c10 <memset+0x10>
    2c1d:	c3                   	ret    
    2c1e:	66 90                	xchg   %ax,%ax

0000000000002c20 <memcpy>:
    2c20:	48 89 f8             	mov    %rdi,%rax
    2c23:	48 85 d2             	test   %rdx,%rdx
    2c26:	74 1a                	je     2c42 <memcpy+0x22>
    2c28:	31 c9                	xor    %ecx,%ecx
    2c2a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2c30:	44 0f b6 04 0e       	movzbl (%rsi,%rcx,1),%r8d
    2c35:	44 88 04 08          	mov    %r8b,(%rax,%rcx,1)
    2c39:	48 83 c1 01          	add    $0x1,%rcx
    2c3d:	48 39 d1             	cmp    %rdx,%rcx
    2c40:	75 ee                	jne    2c30 <memcpy+0x10>
    2c42:	c3                   	ret    
    2c43:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2c4a:	00 00 00 00 
    2c4e:	66 90                	xchg   %ax,%ax

0000000000002c50 <strcpy>:
    2c50:	48 89 f8             	mov    %rdi,%rax
    2c53:	31 d2                	xor    %edx,%edx
    2c55:	0f 1f 00             	nopl   (%rax)
    2c58:	0f b6 0c 16          	movzbl (%rsi,%rdx,1),%ecx
    2c5c:	88 0c 10             	mov    %cl,(%rax,%rdx,1)
    2c5f:	48 83 c2 01          	add    $0x1,%rdx
    2c63:	84 c9                	test   %cl,%cl
    2c65:	75 f1                	jne    2c58 <strcpy+0x8>
    2c67:	c3                   	ret    
