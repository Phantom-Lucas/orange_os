
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	48 83 ec 08          	sub    $0x8,%rsp
    1906:	e8 a5 04 00 00       	call   1db0 <clear_screen>
    190b:	bf 67 28 00 00       	mov    $0x2867,%edi
    1910:	e8 2b 06 00 00       	call   1f40 <print_string>
    1915:	e8 66 02 00 00       	call   1b80 <idt_init>
    191a:	e8 e1 03 00 00       	call   1d00 <pic_init>
    191f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    1924:	e6 21                	out    %al,$0x21
    1926:	bf 88 28 00 00       	mov    $0x2888,%edi
    192b:	e8 10 06 00 00       	call   1f40 <print_string>
    1930:	fb                   	sti    
    1931:	bf b8 28 00 00       	mov    $0x28b8,%edi
    1936:	e8 05 06 00 00       	call   1f40 <print_string>
    193b:	e8 80 08 00 00       	call   21c0 <shell_init>
    1940:	f4                   	hlt    
    1941:	eb fd                	jmp    1940 <kernel_main+0x40>
    1943:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    194a:	00 00 00 
    194d:	0f 1f 00             	nopl   (%rax)

0000000000001950 <isr32_timer>:
    1950:	50                   	push   %rax
    1951:	48 8b 05 08 22 00 00 	mov    0x2208(%rip),%rax        # 3b60 <system_ticks>
    1958:	48 83 c0 01          	add    $0x1,%rax
    195c:	48 89 05 fd 21 00 00 	mov    %rax,0x21fd(%rip)        # 3b60 <system_ticks>
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
    1979:	bf e0 26 00 00       	mov    $0x26e0,%edi
    197e:	56                   	push   %rsi
    197f:	51                   	push   %rcx
    1980:	52                   	push   %rdx
    1981:	50                   	push   %rax
    1982:	fc                   	cld    
    1983:	e8 b8 05 00 00       	call   1f40 <print_string>
    1988:	bf 18 27 00 00       	mov    $0x2718,%edi
    198d:	e8 ae 05 00 00       	call   1f40 <print_string>
    1992:	bf 48 27 00 00       	mov    $0x2748,%edi
    1997:	e8 a4 05 00 00       	call   1f40 <print_string>
    199c:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    19a1:	e8 ca 05 00 00       	call   1f70 <print_hex>
    19a6:	bf 7f 28 00 00       	mov    $0x287f,%edi
    19ab:	e8 90 05 00 00       	call   1f40 <print_string>
    19b0:	bf 70 27 00 00       	mov    $0x2770,%edi
    19b5:	e8 86 05 00 00       	call   1f40 <print_string>
    19ba:	bf 30 28 00 00       	mov    $0x2830,%edi
    19bf:	e8 7c 05 00 00       	call   1f40 <print_string>
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
    19da:	bf e0 26 00 00       	mov    $0x26e0,%edi
    19df:	56                   	push   %rsi
    19e0:	51                   	push   %rcx
    19e1:	52                   	push   %rdx
    19e2:	50                   	push   %rax
    19e3:	48 8b 6c 24 50       	mov    0x50(%rsp),%rbp
    19e8:	fc                   	cld    
    19e9:	e8 d2 06 00 00       	call   20c0 <print_error>
    19ee:	bf a8 27 00 00       	mov    $0x27a8,%edi
    19f3:	e8 c8 06 00 00       	call   20c0 <print_error>
    19f8:	bf 40 28 00 00       	mov    $0x2840,%edi
    19fd:	e8 3e 05 00 00       	call   1f40 <print_string>
    1a02:	48 89 ef             	mov    %rbp,%rdi
    1a05:	e8 66 05 00 00       	call   1f70 <print_hex>
    1a0a:	bf 7f 28 00 00       	mov    $0x287f,%edi
    1a0f:	e8 2c 05 00 00       	call   1f40 <print_string>
    1a14:	bf 4d 28 00 00       	mov    $0x284d,%edi
    1a19:	e8 22 05 00 00       	call   1f40 <print_string>
    1a1e:	48 8b 7c 24 58       	mov    0x58(%rsp),%rdi
    1a23:	e8 48 05 00 00       	call   1f70 <print_hex>
    1a28:	bf 7f 28 00 00       	mov    $0x287f,%edi
    1a2d:	e8 0e 05 00 00       	call   1f40 <print_string>
    1a32:	bf 30 28 00 00       	mov    $0x2830,%edi
    1a37:	e8 84 06 00 00       	call   20c0 <print_error>
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
    1a6d:	bf e0 26 00 00       	mov    $0x26e0,%edi
    1a72:	fc                   	cld    
    1a73:	e8 48 06 00 00       	call   20c0 <print_error>
    1a78:	bf e0 27 00 00       	mov    $0x27e0,%edi
    1a7d:	e8 3e 06 00 00       	call   20c0 <print_error>
    1a82:	bf 10 28 00 00       	mov    $0x2810,%edi
    1a87:	e8 b4 04 00 00       	call   1f40 <print_string>
    1a8c:	4c 89 e7             	mov    %r12,%rdi
    1a8f:	e8 dc 04 00 00       	call   1f70 <print_hex>
    1a94:	bf 7f 28 00 00       	mov    $0x287f,%edi
    1a99:	e8 a2 04 00 00       	call   1f40 <print_string>
    1a9e:	bf 40 28 00 00       	mov    $0x2840,%edi
    1aa3:	e8 98 04 00 00       	call   1f40 <print_string>
    1aa8:	48 89 ef             	mov    %rbp,%rdi
    1aab:	e8 c0 04 00 00       	call   1f70 <print_hex>
    1ab0:	bf 7f 28 00 00       	mov    $0x287f,%edi
    1ab5:	e8 86 04 00 00       	call   1f40 <print_string>
    1aba:	bf 4d 28 00 00       	mov    $0x284d,%edi
    1abf:	e8 7c 04 00 00       	call   1f40 <print_string>
    1ac4:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
    1ac9:	e8 a2 04 00 00       	call   1f70 <print_hex>
    1ace:	bf 7f 28 00 00       	mov    $0x287f,%edi
    1ad3:	e8 68 04 00 00       	call   1f40 <print_string>
    1ad8:	bf 30 28 00 00       	mov    $0x2830,%edi
    1add:	e8 de 05 00 00       	call   20c0 <print_error>
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
    1b06:	0f be b8 60 26 00 00 	movsbl 0x2660(%rax),%edi
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
    1b31:	e8 3a 09 00 00       	call   2470 <shell_take_char>
    1b36:	eb da                	jmp    1b12 <isr33_keyboard+0x22>
    1b38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b3f:	00 

0000000000001b40 <set_idt_gate>:
    1b40:	48 63 ff             	movslq %edi,%rdi
    1b43:	48 89 f2             	mov    %rsi,%rdx
    1b46:	48 c1 e7 04          	shl    $0x4,%rdi
    1b4a:	48 c1 ea 10          	shr    $0x10,%rdx
    1b4e:	66 89 b7 60 2b 00 00 	mov    %si,0x2b60(%rdi)
    1b55:	48 c1 ee 20          	shr    $0x20,%rsi
    1b59:	c7 87 62 2b 00 00 08 	movl   $0x8e000008,0x2b62(%rdi)
    1b60:	00 00 8e 
    1b63:	66 89 97 66 2b 00 00 	mov    %dx,0x2b66(%rdi)
    1b6a:	89 b7 68 2b 00 00    	mov    %esi,0x2b68(%rdi)
    1b70:	c7 87 6c 2b 00 00 00 	movl   $0x0,0x2b6c(%rdi)
    1b77:	00 00 00 
    1b7a:	c3                   	ret    
    1b7b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001b80 <idt_init>:
    1b80:	b8 60 2b 00 00       	mov    $0x2b60,%eax
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
    1bb6:	48 3d 60 3b 00 00    	cmp    $0x3b60,%rax
    1bbc:	75 ca                	jne    1b88 <idt_init+0x8>
    1bbe:	c7 05 9a 0f 00 00 08 	movl   $0x8e000008,0xf9a(%rip)        # 2b62 <idt+0x2>
    1bc5:	00 00 8e 
    1bc8:	b8 70 19 00 00       	mov    $0x1970,%eax
    1bcd:	66 89 05 8c 0f 00 00 	mov    %ax,0xf8c(%rip)        # 2b60 <idt>
    1bd4:	48 89 c2             	mov    %rax,%rdx
    1bd7:	48 c1 e8 20          	shr    $0x20,%rax
    1bdb:	48 c1 ea 10          	shr    $0x10,%rdx
    1bdf:	89 05 83 0f 00 00    	mov    %eax,0xf83(%rip)        # 2b68 <idt+0x8>
    1be5:	b8 d0 19 00 00       	mov    $0x19d0,%eax
    1bea:	66 89 15 75 0f 00 00 	mov    %dx,0xf75(%rip)        # 2b66 <idt+0x6>
    1bf1:	48 89 c2             	mov    %rax,%rdx
    1bf4:	66 89 05 35 10 00 00 	mov    %ax,0x1035(%rip)        # 2c30 <idt+0xd0>
    1bfb:	48 c1 e8 20          	shr    $0x20,%rax
    1bff:	48 c1 ea 10          	shr    $0x10,%rdx
    1c03:	89 05 2f 10 00 00    	mov    %eax,0x102f(%rip)        # 2c38 <idt+0xd8>
    1c09:	b8 50 1a 00 00       	mov    $0x1a50,%eax
    1c0e:	66 89 15 21 10 00 00 	mov    %dx,0x1021(%rip)        # 2c36 <idt+0xd6>
    1c15:	48 89 c2             	mov    %rax,%rdx
    1c18:	66 89 05 21 10 00 00 	mov    %ax,0x1021(%rip)        # 2c40 <idt+0xe0>
    1c1f:	48 c1 e8 20          	shr    $0x20,%rax
    1c23:	48 c1 ea 10          	shr    $0x10,%rdx
    1c27:	89 05 1b 10 00 00    	mov    %eax,0x101b(%rip)        # 2c48 <idt+0xe8>
    1c2d:	b8 50 19 00 00       	mov    $0x1950,%eax
    1c32:	66 89 15 0d 10 00 00 	mov    %dx,0x100d(%rip)        # 2c46 <idt+0xe6>
    1c39:	48 89 c2             	mov    %rax,%rdx
    1c3c:	66 89 05 1d 11 00 00 	mov    %ax,0x111d(%rip)        # 2d60 <idt+0x200>
    1c43:	48 c1 e8 20          	shr    $0x20,%rax
    1c47:	48 c1 ea 10          	shr    $0x10,%rdx
    1c4b:	89 05 17 11 00 00    	mov    %eax,0x1117(%rip)        # 2d68 <idt+0x208>
    1c51:	b8 f0 1a 00 00       	mov    $0x1af0,%eax
    1c56:	66 89 15 09 11 00 00 	mov    %dx,0x1109(%rip)        # 2d66 <idt+0x206>
    1c5d:	48 89 c2             	mov    %rax,%rdx
    1c60:	66 89 05 09 11 00 00 	mov    %ax,0x1109(%rip)        # 2d70 <idt+0x210>
    1c67:	48 c1 e8 20          	shr    $0x20,%rax
    1c6b:	48 c1 ea 10          	shr    $0x10,%rdx
    1c6f:	89 05 03 11 00 00    	mov    %eax,0x1103(%rip)        # 2d78 <idt+0x218>
    1c75:	b8 ff 0f 00 00       	mov    $0xfff,%eax
    1c7a:	c7 05 e8 0e 00 00 00 	movl   $0x0,0xee8(%rip)        # 2b6c <idt+0xc>
    1c81:	00 00 00 
    1c84:	c7 05 a4 0f 00 00 08 	movl   $0x8e000008,0xfa4(%rip)        # 2c32 <idt+0xd2>
    1c8b:	00 00 8e 
    1c8e:	c7 05 a4 0f 00 00 00 	movl   $0x0,0xfa4(%rip)        # 2c3c <idt+0xdc>
    1c95:	00 00 00 
    1c98:	c7 05 a0 0f 00 00 08 	movl   $0x8e000008,0xfa0(%rip)        # 2c42 <idt+0xe2>
    1c9f:	00 00 8e 
    1ca2:	c7 05 a0 0f 00 00 00 	movl   $0x0,0xfa0(%rip)        # 2c4c <idt+0xec>
    1ca9:	00 00 00 
    1cac:	c7 05 ac 10 00 00 08 	movl   $0x8e000008,0x10ac(%rip)        # 2d62 <idt+0x202>
    1cb3:	00 00 8e 
    1cb6:	c7 05 ac 10 00 00 00 	movl   $0x0,0x10ac(%rip)        # 2d6c <idt+0x20c>
    1cbd:	00 00 00 
    1cc0:	c7 05 a8 10 00 00 08 	movl   $0x8e000008,0x10a8(%rip)        # 2d72 <idt+0x212>
    1cc7:	00 00 8e 
    1cca:	66 89 15 a5 10 00 00 	mov    %dx,0x10a5(%rip)        # 2d76 <idt+0x216>
    1cd1:	c7 05 a1 10 00 00 00 	movl   $0x0,0x10a1(%rip)        # 2d7c <idt+0x21c>
    1cd8:	00 00 00 
    1cdb:	66 89 05 5e 0e 00 00 	mov    %ax,0xe5e(%rip)        # 2b40 <idtr_reg>
    1ce2:	48 c7 05 55 0e 00 00 	movq   $0x2b60,0xe55(%rip)        # 2b42 <idtr_reg+0x2>
    1ce9:	60 2b 00 00 
    1ced:	0f 01 1d 4c 0e 00 00 	lidt   0xe4c(%rip)        # 2b40 <idtr_reg>
    1cf4:	c3                   	ret    
    1cf5:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1cfc:	00 00 00 
    1cff:	90                   	nop

0000000000001d00 <pic_init>:
    1d00:	b8 11 00 00 00       	mov    $0x11,%eax
    1d05:	e6 20                	out    %al,$0x20
    1d07:	e6 a0                	out    %al,$0xa0
    1d09:	b8 20 00 00 00       	mov    $0x20,%eax
    1d0e:	e6 21                	out    %al,$0x21
    1d10:	b8 28 00 00 00       	mov    $0x28,%eax
    1d15:	e6 a1                	out    %al,$0xa1
    1d17:	b8 04 00 00 00       	mov    $0x4,%eax
    1d1c:	e6 21                	out    %al,$0x21
    1d1e:	b8 02 00 00 00       	mov    $0x2,%eax
    1d23:	e6 a1                	out    %al,$0xa1
    1d25:	b8 01 00 00 00       	mov    $0x1,%eax
    1d2a:	e6 21                	out    %al,$0x21
    1d2c:	e6 a1                	out    %al,$0xa1
    1d2e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    1d33:	e6 21                	out    %al,$0x21
    1d35:	e6 a1                	out    %al,$0xa1
    1d37:	bf e0 28 00 00       	mov    $0x28e0,%edi
    1d3c:	e9 ff 01 00 00       	jmp    1f40 <print_string>
    1d41:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1d48:	00 00 00 
    1d4b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001d50 <get_cursor>:
    1d50:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1d55:	b8 0e 00 00 00       	mov    $0xe,%eax
    1d5a:	89 fa                	mov    %edi,%edx
    1d5c:	ee                   	out    %al,(%dx)
    1d5d:	be d5 03 00 00       	mov    $0x3d5,%esi
    1d62:	89 f2                	mov    %esi,%edx
    1d64:	ec                   	in     (%dx),%al
    1d65:	0f b6 c8             	movzbl %al,%ecx
    1d68:	89 fa                	mov    %edi,%edx
    1d6a:	b8 0f 00 00 00       	mov    $0xf,%eax
    1d6f:	c1 e1 08             	shl    $0x8,%ecx
    1d72:	ee                   	out    %al,(%dx)
    1d73:	89 f2                	mov    %esi,%edx
    1d75:	ec                   	in     (%dx),%al
    1d76:	0f b6 c0             	movzbl %al,%eax
    1d79:	09 c8                	or     %ecx,%eax
    1d7b:	c3                   	ret    
    1d7c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000001d80 <set_cursor>:
    1d80:	be d4 03 00 00       	mov    $0x3d4,%esi
    1d85:	41 89 f8             	mov    %edi,%r8d
    1d88:	b8 0e 00 00 00       	mov    $0xe,%eax
    1d8d:	89 f2                	mov    %esi,%edx
    1d8f:	ee                   	out    %al,(%dx)
    1d90:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    1d95:	66 c1 ef 08          	shr    $0x8,%di
    1d99:	89 f8                	mov    %edi,%eax
    1d9b:	89 ca                	mov    %ecx,%edx
    1d9d:	ee                   	out    %al,(%dx)
    1d9e:	b8 0f 00 00 00       	mov    $0xf,%eax
    1da3:	89 f2                	mov    %esi,%edx
    1da5:	ee                   	out    %al,(%dx)
    1da6:	44 89 c0             	mov    %r8d,%eax
    1da9:	89 ca                	mov    %ecx,%edx
    1dab:	ee                   	out    %al,(%dx)
    1dac:	c3                   	ret    
    1dad:	0f 1f 00             	nopl   (%rax)

0000000000001db0 <clear_screen>:
    1db0:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    1db5:	0f 1f 00             	nopl   (%rax)
    1db8:	c6 00 20             	movb   $0x20,(%rax)
    1dbb:	48 83 c0 02          	add    $0x2,%rax
    1dbf:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1dc3:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1dc9:	75 ed                	jne    1db8 <clear_screen+0x8>
    1dcb:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1dd0:	b8 0e 00 00 00       	mov    $0xe,%eax
    1dd5:	89 fa                	mov    %edi,%edx
    1dd7:	ee                   	out    %al,(%dx)
    1dd8:	31 c9                	xor    %ecx,%ecx
    1dda:	be d5 03 00 00       	mov    $0x3d5,%esi
    1ddf:	89 c8                	mov    %ecx,%eax
    1de1:	89 f2                	mov    %esi,%edx
    1de3:	ee                   	out    %al,(%dx)
    1de4:	b8 0f 00 00 00       	mov    $0xf,%eax
    1de9:	89 fa                	mov    %edi,%edx
    1deb:	ee                   	out    %al,(%dx)
    1dec:	89 c8                	mov    %ecx,%eax
    1dee:	89 f2                	mov    %esi,%edx
    1df0:	ee                   	out    %al,(%dx)
    1df1:	c3                   	ret    
    1df2:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1df9:	00 00 00 00 
    1dfd:	0f 1f 00             	nopl   (%rax)

0000000000001e00 <put_char>:
    1e00:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    1e06:	53                   	push   %rbx
    1e07:	b8 0e 00 00 00       	mov    $0xe,%eax
    1e0c:	44 89 c2             	mov    %r8d,%edx
    1e0f:	ee                   	out    %al,(%dx)
    1e10:	be d5 03 00 00       	mov    $0x3d5,%esi
    1e15:	89 f2                	mov    %esi,%edx
    1e17:	ec                   	in     (%dx),%al
    1e18:	0f b6 c8             	movzbl %al,%ecx
    1e1b:	44 89 c2             	mov    %r8d,%edx
    1e1e:	b8 0f 00 00 00       	mov    $0xf,%eax
    1e23:	c1 e1 08             	shl    $0x8,%ecx
    1e26:	ee                   	out    %al,(%dx)
    1e27:	89 f2                	mov    %esi,%edx
    1e29:	ec                   	in     (%dx),%al
    1e2a:	0f b6 c0             	movzbl %al,%eax
    1e2d:	09 c8                	or     %ecx,%eax
    1e2f:	40 80 ff 0d          	cmp    $0xd,%dil
    1e33:	0f 84 b7 00 00 00    	je     1ef0 <put_char+0xf0>
    1e39:	40 80 ff 0a          	cmp    $0xa,%dil
    1e3d:	74 5c                	je     1e9b <put_char+0x9b>
    1e3f:	40 80 ff 08          	cmp    $0x8,%dil
    1e43:	0f 84 be 00 00 00    	je     1f07 <put_char+0x107>
    1e49:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1e4d:	0f b6 0d d3 0c 00 00 	movzbl 0xcd3(%rip),%ecx        # 2b27 <current_color>
    1e54:	83 c0 01             	add    $0x1,%eax
    1e57:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1e5d:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    1e64:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    1e6a:	66 3d cf 07          	cmp    $0x7cf,%ax
    1e6e:	77 44                	ja     1eb4 <put_char+0xb4>
    1e70:	0f b6 dc             	movzbl %ah,%ebx
    1e73:	89 c1                	mov    %eax,%ecx
    1e75:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1e7a:	b8 0e 00 00 00       	mov    $0xe,%eax
    1e7f:	89 fa                	mov    %edi,%edx
    1e81:	ee                   	out    %al,(%dx)
    1e82:	be d5 03 00 00       	mov    $0x3d5,%esi
    1e87:	89 d8                	mov    %ebx,%eax
    1e89:	89 f2                	mov    %esi,%edx
    1e8b:	ee                   	out    %al,(%dx)
    1e8c:	b8 0f 00 00 00       	mov    $0xf,%eax
    1e91:	89 fa                	mov    %edi,%edx
    1e93:	ee                   	out    %al,(%dx)
    1e94:	89 c8                	mov    %ecx,%eax
    1e96:	89 f2                	mov    %esi,%edx
    1e98:	ee                   	out    %al,(%dx)
    1e99:	5b                   	pop    %rbx
    1e9a:	c3                   	ret    
    1e9b:	0f b7 c0             	movzwl %ax,%eax
    1e9e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1ea4:	c1 e8 16             	shr    $0x16,%eax
    1ea7:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    1eab:	c1 e0 04             	shl    $0x4,%eax
    1eae:	66 3d cf 07          	cmp    $0x7cf,%ax
    1eb2:	76 bc                	jbe    1e70 <put_char+0x70>
    1eb4:	ba 00 0f 00 00       	mov    $0xf00,%edx
    1eb9:	be a0 80 0b 00       	mov    $0xb80a0,%esi
    1ebe:	bf 00 80 0b 00       	mov    $0xb8000,%edi
    1ec3:	e8 48 07 00 00       	call   2610 <memcpy>
    1ec8:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    1ecd:	0f 1f 00             	nopl   (%rax)
    1ed0:	c6 00 20             	movb   $0x20,(%rax)
    1ed3:	48 83 c0 02          	add    $0x2,%rax
    1ed7:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1edb:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1ee1:	75 ed                	jne    1ed0 <put_char+0xd0>
    1ee3:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    1ee8:	bb 07 00 00 00       	mov    $0x7,%ebx
    1eed:	eb 86                	jmp    1e75 <put_char+0x75>
    1eef:	90                   	nop
    1ef0:	0f b7 c0             	movzwl %ax,%eax
    1ef3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1ef9:	c1 e8 16             	shr    $0x16,%eax
    1efc:	8d 04 80             	lea    (%rax,%rax,4),%eax
    1eff:	c1 e0 04             	shl    $0x4,%eax
    1f02:	e9 63 ff ff ff       	jmp    1e6a <put_char+0x6a>
    1f07:	66 85 c0             	test   %ax,%ax
    1f0a:	74 26                	je     1f32 <put_char+0x132>
    1f0c:	83 e8 01             	sub    $0x1,%eax
    1f0f:	0f b6 0d 11 0c 00 00 	movzbl 0xc11(%rip),%ecx        # 2b27 <current_color>
    1f16:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1f1a:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1f20:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    1f27:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    1f2d:	e9 38 ff ff ff       	jmp    1e6a <put_char+0x6a>
    1f32:	31 c9                	xor    %ecx,%ecx
    1f34:	31 db                	xor    %ebx,%ebx
    1f36:	e9 3a ff ff ff       	jmp    1e75 <put_char+0x75>
    1f3b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001f40 <print_string>:
    1f40:	53                   	push   %rbx
    1f41:	48 89 fb             	mov    %rdi,%rbx
    1f44:	0f be 3f             	movsbl (%rdi),%edi
    1f47:	40 84 ff             	test   %dil,%dil
    1f4a:	74 16                	je     1f62 <print_string+0x22>
    1f4c:	0f 1f 40 00          	nopl   0x0(%rax)
    1f50:	e8 ab fe ff ff       	call   1e00 <put_char>
    1f55:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    1f59:	48 83 c3 01          	add    $0x1,%rbx
    1f5d:	40 84 ff             	test   %dil,%dil
    1f60:	75 ee                	jne    1f50 <print_string+0x10>
    1f62:	5b                   	pop    %rbx
    1f63:	c3                   	ret    
    1f64:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1f6b:	00 00 00 00 
    1f6f:	90                   	nop

0000000000001f70 <print_hex>:
    1f70:	55                   	push   %rbp
    1f71:	48 89 fd             	mov    %rdi,%rbp
    1f74:	bf 30 00 00 00       	mov    $0x30,%edi
    1f79:	53                   	push   %rbx
    1f7a:	bb 0c 29 00 00       	mov    $0x290c,%ebx
    1f7f:	48 83 ec 18          	sub    $0x18,%rsp
    1f83:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1f88:	e8 73 fe ff ff       	call   1e00 <put_char>
    1f8d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    1f91:	48 83 c3 01          	add    $0x1,%rbx
    1f95:	40 84 ff             	test   %dil,%dil
    1f98:	75 ee                	jne    1f88 <print_hex+0x18>
    1f9a:	b8 01 00 00 00       	mov    $0x1,%eax
    1f9f:	48 85 ed             	test   %rbp,%rbp
    1fa2:	74 54                	je     1ff8 <print_hex+0x88>
    1fa4:	0f 1f 40 00          	nopl   0x0(%rax)
    1fa8:	48 89 ea             	mov    %rbp,%rdx
    1fab:	48 63 d8             	movslq %eax,%rbx
    1fae:	83 e2 0f             	and    $0xf,%edx
    1fb1:	0f be ba 0f 29 00 00 	movsbl 0x290f(%rdx),%edi
    1fb8:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    1fbd:	48 83 c0 01          	add    $0x1,%rax
    1fc1:	48 c1 ed 04          	shr    $0x4,%rbp
    1fc5:	75 e1                	jne    1fa8 <print_hex+0x38>
    1fc7:	e8 34 fe ff ff       	call   1e00 <put_char>
    1fcc:	48 83 eb 01          	sub    $0x1,%rbx
    1fd0:	85 db                	test   %ebx,%ebx
    1fd2:	74 16                	je     1fea <print_hex+0x7a>
    1fd4:	0f 1f 40 00          	nopl   0x0(%rax)
    1fd8:	0f be 7c 1c ff       	movsbl -0x1(%rsp,%rbx,1),%edi
    1fdd:	48 83 eb 01          	sub    $0x1,%rbx
    1fe1:	e8 1a fe ff ff       	call   1e00 <put_char>
    1fe6:	85 db                	test   %ebx,%ebx
    1fe8:	75 ee                	jne    1fd8 <print_hex+0x68>
    1fea:	48 83 c4 18          	add    $0x18,%rsp
    1fee:	5b                   	pop    %rbx
    1fef:	5d                   	pop    %rbp
    1ff0:	c3                   	ret    
    1ff1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1ff8:	48 83 c4 18          	add    $0x18,%rsp
    1ffc:	bf 30 00 00 00       	mov    $0x30,%edi
    2001:	5b                   	pop    %rbx
    2002:	5d                   	pop    %rbp
    2003:	e9 f8 fd ff ff       	jmp    1e00 <put_char>
    2008:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    200f:	00 

0000000000002010 <print_int>:
    2010:	53                   	push   %rbx
    2011:	48 83 ec 20          	sub    $0x20,%rsp
    2015:	48 85 ff             	test   %rdi,%rdi
    2018:	74 76                	je     2090 <print_int+0x80>
    201a:	48 89 fb             	mov    %rdi,%rbx
    201d:	78 61                	js     2080 <print_int+0x70>
    201f:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    2026:	cc cc cc 
    2029:	be 01 00 00 00       	mov    $0x1,%esi
    202e:	66 90                	xchg   %ax,%ax
    2030:	48 89 d8             	mov    %rbx,%rax
    2033:	89 f1                	mov    %esi,%ecx
    2035:	49 f7 e0             	mul    %r8
    2038:	48 c1 ea 03          	shr    $0x3,%rdx
    203c:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    2040:	48 01 c0             	add    %rax,%rax
    2043:	48 29 c3             	sub    %rax,%rbx
    2046:	8d 7b 30             	lea    0x30(%rbx),%edi
    2049:	48 89 d3             	mov    %rdx,%rbx
    204c:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    2051:	48 83 c6 01          	add    $0x1,%rsi
    2055:	48 85 d2             	test   %rdx,%rdx
    2058:	75 d6                	jne    2030 <print_int+0x20>
    205a:	48 63 d9             	movslq %ecx,%rbx
    205d:	eb 06                	jmp    2065 <print_int+0x55>
    205f:	90                   	nop
    2060:	0f b6 7c 1c 0b       	movzbl 0xb(%rsp,%rbx,1),%edi
    2065:	40 0f be ff          	movsbl %dil,%edi
    2069:	48 83 eb 01          	sub    $0x1,%rbx
    206d:	e8 8e fd ff ff       	call   1e00 <put_char>
    2072:	85 db                	test   %ebx,%ebx
    2074:	75 ea                	jne    2060 <print_int+0x50>
    2076:	48 83 c4 20          	add    $0x20,%rsp
    207a:	5b                   	pop    %rbx
    207b:	c3                   	ret    
    207c:	0f 1f 40 00          	nopl   0x0(%rax)
    2080:	bf 2d 00 00 00       	mov    $0x2d,%edi
    2085:	48 f7 db             	neg    %rbx
    2088:	e8 73 fd ff ff       	call   1e00 <put_char>
    208d:	eb 90                	jmp    201f <print_int+0xf>
    208f:	90                   	nop
    2090:	48 83 c4 20          	add    $0x20,%rsp
    2094:	bf 30 00 00 00       	mov    $0x30,%edi
    2099:	5b                   	pop    %rbx
    209a:	e9 61 fd ff ff       	jmp    1e00 <put_char>
    209f:	90                   	nop

00000000000020a0 <set_print_color>:
    20a0:	c1 e6 04             	shl    $0x4,%esi
    20a3:	83 e7 0f             	and    $0xf,%edi
    20a6:	09 fe                	or     %edi,%esi
    20a8:	40 88 35 78 0a 00 00 	mov    %sil,0xa78(%rip)        # 2b27 <current_color>
    20af:	c3                   	ret    

00000000000020b0 <reset_print_color>:
    20b0:	c6 05 70 0a 00 00 0f 	movb   $0xf,0xa70(%rip)        # 2b27 <current_color>
    20b7:	c3                   	ret    
    20b8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    20bf:	00 

00000000000020c0 <print_error>:
    20c0:	53                   	push   %rbx
    20c1:	48 89 fb             	mov    %rdi,%rbx
    20c4:	0f be 3f             	movsbl (%rdi),%edi
    20c7:	c6 05 59 0a 00 00 0c 	movb   $0xc,0xa59(%rip)        # 2b27 <current_color>
    20ce:	40 84 ff             	test   %dil,%dil
    20d1:	74 17                	je     20ea <print_error+0x2a>
    20d3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    20d8:	e8 23 fd ff ff       	call   1e00 <put_char>
    20dd:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    20e1:	48 83 c3 01          	add    $0x1,%rbx
    20e5:	40 84 ff             	test   %dil,%dil
    20e8:	75 ee                	jne    20d8 <print_error+0x18>
    20ea:	c6 05 36 0a 00 00 0f 	movb   $0xf,0xa36(%rip)        # 2b27 <current_color>
    20f1:	5b                   	pop    %rbx
    20f2:	c3                   	ret    
    20f3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    20fa:	00 00 00 00 
    20fe:	66 90                	xchg   %ax,%ax

0000000000002100 <print_success>:
    2100:	53                   	push   %rbx
    2101:	48 89 fb             	mov    %rdi,%rbx
    2104:	0f be 3f             	movsbl (%rdi),%edi
    2107:	c6 05 19 0a 00 00 0a 	movb   $0xa,0xa19(%rip)        # 2b27 <current_color>
    210e:	40 84 ff             	test   %dil,%dil
    2111:	74 17                	je     212a <print_success+0x2a>
    2113:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2118:	e8 e3 fc ff ff       	call   1e00 <put_char>
    211d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2121:	48 83 c3 01          	add    $0x1,%rbx
    2125:	40 84 ff             	test   %dil,%dil
    2128:	75 ee                	jne    2118 <print_success+0x18>
    212a:	c6 05 f6 09 00 00 0f 	movb   $0xf,0x9f6(%rip)        # 2b27 <current_color>
    2131:	5b                   	pop    %rbx
    2132:	c3                   	ret    
    2133:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    213a:	00 00 00 00 
    213e:	66 90                	xchg   %ax,%ax

0000000000002140 <print_info>:
    2140:	53                   	push   %rbx
    2141:	48 89 fb             	mov    %rdi,%rbx
    2144:	0f be 3f             	movsbl (%rdi),%edi
    2147:	c6 05 d9 09 00 00 0b 	movb   $0xb,0x9d9(%rip)        # 2b27 <current_color>
    214e:	40 84 ff             	test   %dil,%dil
    2151:	74 17                	je     216a <print_info+0x2a>
    2153:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2158:	e8 a3 fc ff ff       	call   1e00 <put_char>
    215d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2161:	48 83 c3 01          	add    $0x1,%rbx
    2165:	40 84 ff             	test   %dil,%dil
    2168:	75 ee                	jne    2158 <print_info+0x18>
    216a:	c6 05 b6 09 00 00 0f 	movb   $0xf,0x9b6(%rip)        # 2b27 <current_color>
    2171:	5b                   	pop    %rbx
    2172:	c3                   	ret    
    2173:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    217a:	00 00 00 00 
    217e:	66 90                	xchg   %ax,%ax

0000000000002180 <print_warning>:
    2180:	53                   	push   %rbx
    2181:	48 89 fb             	mov    %rdi,%rbx
    2184:	0f be 3f             	movsbl (%rdi),%edi
    2187:	c6 05 99 09 00 00 0e 	movb   $0xe,0x999(%rip)        # 2b27 <current_color>
    218e:	40 84 ff             	test   %dil,%dil
    2191:	74 17                	je     21aa <print_warning+0x2a>
    2193:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2198:	e8 63 fc ff ff       	call   1e00 <put_char>
    219d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    21a1:	48 83 c3 01          	add    $0x1,%rbx
    21a5:	40 84 ff             	test   %dil,%dil
    21a8:	75 ee                	jne    2198 <print_warning+0x18>
    21aa:	c6 05 76 09 00 00 0f 	movb   $0xf,0x976(%rip)        # 2b27 <current_color>
    21b1:	5b                   	pop    %rbx
    21b2:	c3                   	ret    
    21b3:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    21ba:	00 00 00 
    21bd:	0f 1f 00             	nopl   (%rax)

00000000000021c0 <shell_init>:
    21c0:	bf 20 29 00 00       	mov    $0x2920,%edi
    21c5:	e9 76 fd ff ff       	jmp    1f40 <print_string>
    21ca:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000021d0 <execute_command>:
    21d0:	48 63 05 a9 19 00 00 	movslq 0x19a9(%rip),%rax        # 3b80 <cmd_index>
    21d7:	85 c0                	test   %eax,%eax
    21d9:	75 05                	jne    21e0 <execute_command+0x10>
    21db:	c3                   	ret    
    21dc:	0f 1f 40 00          	nopl   0x0(%rax)
    21e0:	55                   	push   %rbp
    21e1:	be 29 29 00 00       	mov    $0x2929,%esi
    21e6:	48 89 fd             	mov    %rdi,%rbp
    21e9:	53                   	push   %rbx
    21ea:	48 83 ec 78          	sub    $0x78,%rsp
    21ee:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    21f2:	e8 79 03 00 00       	call   2570 <strcmp>
    21f7:	85 c0                	test   %eax,%eax
    21f9:	75 3d                	jne    2238 <execute_command+0x68>
    21fb:	bf 2e 29 00 00       	mov    $0x292e,%edi
    2200:	e8 3b fd ff ff       	call   1f40 <print_string>
    2205:	bf 43 29 00 00       	mov    $0x2943,%edi
    220a:	e8 31 fd ff ff       	call   1f40 <print_string>
    220f:	bf 60 29 00 00       	mov    $0x2960,%edi
    2214:	e8 27 fd ff ff       	call   1f40 <print_string>
    2219:	bf 38 2a 00 00       	mov    $0x2a38,%edi
    221e:	e8 1d fd ff ff       	call   1f40 <print_string>
    2223:	c7 05 53 19 00 00 00 	movl   $0x0,0x1953(%rip)        # 3b80 <cmd_index>
    222a:	00 00 00 
    222d:	48 83 c4 78          	add    $0x78,%rsp
    2231:	5b                   	pop    %rbx
    2232:	5d                   	pop    %rbp
    2233:	c3                   	ret    
    2234:	0f 1f 40 00          	nopl   0x0(%rax)
    2238:	be 7c 29 00 00       	mov    $0x297c,%esi
    223d:	48 89 ef             	mov    %rbp,%rdi
    2240:	e8 2b 03 00 00       	call   2570 <strcmp>
    2245:	85 c0                	test   %eax,%eax
    2247:	74 27                	je     2270 <execute_command+0xa0>
    2249:	be 82 29 00 00       	mov    $0x2982,%esi
    224e:	48 89 ef             	mov    %rbp,%rdi
    2251:	e8 1a 03 00 00       	call   2570 <strcmp>
    2256:	85 c0                	test   %eax,%eax
    2258:	75 26                	jne    2280 <execute_command+0xb0>
    225a:	bf 58 2a 00 00       	mov    $0x2a58,%edi
    225f:	e8 9c fe ff ff       	call   2100 <print_success>
    2264:	eb bd                	jmp    2223 <execute_command+0x53>
    2266:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    226d:	00 00 00 
    2270:	e8 3b fb ff ff       	call   1db0 <clear_screen>
    2275:	eb ac                	jmp    2223 <execute_command+0x53>
    2277:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    227e:	00 00 
    2280:	be 88 29 00 00       	mov    $0x2988,%esi
    2285:	48 89 ef             	mov    %rbp,%rdi
    2288:	e8 e3 02 00 00       	call   2570 <strcmp>
    228d:	85 c0                	test   %eax,%eax
    228f:	74 4f                	je     22e0 <execute_command+0x110>
    2291:	be aa 29 00 00       	mov    $0x29aa,%esi
    2296:	48 89 ef             	mov    %rbp,%rdi
    2299:	e8 d2 02 00 00       	call   2570 <strcmp>
    229e:	85 c0                	test   %eax,%eax
    22a0:	75 7e                	jne    2320 <execute_command+0x150>
    22a2:	0f a2                	cpuid  
    22a4:	bf b2 29 00 00       	mov    $0x29b2,%edi
    22a9:	89 54 24 42          	mov    %edx,0x42(%rsp)
    22ad:	89 4c 24 46          	mov    %ecx,0x46(%rsp)
    22b1:	89 5c 24 3e          	mov    %ebx,0x3e(%rsp)
    22b5:	c6 44 24 4a 00       	movb   $0x0,0x4a(%rsp)
    22ba:	e8 81 fc ff ff       	call   1f40 <print_string>
    22bf:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    22c4:	e8 77 fc ff ff       	call   1f40 <print_string>
    22c9:	bf 7f 28 00 00       	mov    $0x287f,%edi
    22ce:	e8 6d fc ff ff       	call   1f40 <print_string>
    22d3:	e9 4b ff ff ff       	jmp    2223 <execute_command+0x53>
    22d8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    22df:	00 
    22e0:	48 8b 2d 79 18 00 00 	mov    0x1879(%rip),%rbp        # 3b60 <system_ticks>
    22e7:	bf 8f 29 00 00       	mov    $0x298f,%edi
    22ec:	e8 4f fc ff ff       	call   1f40 <print_string>
    22f1:	48 ba 8f e3 38 8e e3 	movabs $0xe38e38e38e38e38f,%rdx
    22f8:	38 8e e3 
    22fb:	48 89 e8             	mov    %rbp,%rax
    22fe:	48 f7 e2             	mul    %rdx
    2301:	48 c1 ea 04          	shr    $0x4,%rdx
    2305:	48 89 d7             	mov    %rdx,%rdi
    2308:	e8 03 fd ff ff       	call   2010 <print_int>
    230d:	bf 9f 29 00 00       	mov    $0x299f,%edi
    2312:	e8 29 fc ff ff       	call   1f40 <print_string>
    2317:	e9 07 ff ff ff       	jmp    2223 <execute_command+0x53>
    231c:	0f 1f 40 00          	nopl   0x0(%rax)
    2320:	ba 05 00 00 00       	mov    $0x5,%edx
    2325:	be bf 29 00 00       	mov    $0x29bf,%esi
    232a:	48 89 ef             	mov    %rbp,%rdi
    232d:	e8 6e 02 00 00       	call   25a0 <strncmp>
    2332:	85 c0                	test   %eax,%eax
    2334:	75 18                	jne    234e <execute_command+0x17e>
    2336:	48 8d 7d 05          	lea    0x5(%rbp),%rdi
    233a:	e8 01 fc ff ff       	call   1f40 <print_string>
    233f:	bf 7f 28 00 00       	mov    $0x287f,%edi
    2344:	e8 f7 fb ff ff       	call   1f40 <print_string>
    2349:	e9 d5 fe ff ff       	jmp    2223 <execute_command+0x53>
    234e:	be c5 29 00 00       	mov    $0x29c5,%esi
    2353:	48 89 ef             	mov    %rbp,%rdi
    2356:	e8 15 02 00 00       	call   2570 <strcmp>
    235b:	85 c0                	test   %eax,%eax
    235d:	75 0c                	jne    236b <execute_command+0x19b>
    235f:	bf cb 29 00 00       	mov    $0x29cb,%edi
    2364:	e8 d7 fb ff ff       	call   1f40 <print_string>
    2369:	0f 0b                	ud2    
    236b:	be e7 29 00 00       	mov    $0x29e7,%esi
    2370:	48 89 ef             	mov    %rbp,%rdi
    2373:	e8 f8 01 00 00       	call   2570 <strcmp>
    2378:	85 c0                	test   %eax,%eax
    237a:	0f 85 8f 00 00 00    	jne    240f <execute_command+0x23f>
    2380:	ba 0a 00 00 00       	mov    $0xa,%edx
    2385:	be 41 00 00 00       	mov    $0x41,%esi
    238a:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    238f:	e8 5c 02 00 00       	call   25f0 <memset>
    2394:	bf 98 2a 00 00       	mov    $0x2a98,%edi
    2399:	c6 44 24 16 00       	movb   $0x0,0x16(%rsp)
    239e:	e8 9d fb ff ff       	call   1f40 <print_string>
    23a3:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    23a8:	e8 93 fb ff ff       	call   1f40 <print_string>
    23ad:	bf 7f 28 00 00       	mov    $0x287f,%edi
    23b2:	e8 89 fb ff ff       	call   1f40 <print_string>
    23b7:	be ef 29 00 00       	mov    $0x29ef,%esi
    23bc:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    23c1:	e8 7a 02 00 00       	call   2640 <strcpy>
    23c6:	bf fd 29 00 00       	mov    $0x29fd,%edi
    23cb:	e8 70 fb ff ff       	call   1f40 <print_string>
    23d0:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    23d5:	e8 66 fb ff ff       	call   1f40 <print_string>
    23da:	bf 7f 28 00 00       	mov    $0x287f,%edi
    23df:	e8 5c fb ff ff       	call   1f40 <print_string>
    23e4:	bf c0 2a 00 00       	mov    $0x2ac0,%edi
    23e9:	e8 52 fb ff ff       	call   1f40 <print_string>
    23ee:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    23f3:	e8 48 01 00 00       	call   2540 <strlen>
    23f8:	48 89 c7             	mov    %rax,%rdi
    23fb:	e8 10 fc ff ff       	call   2010 <print_int>
    2400:	bf 0b 2a 00 00       	mov    $0x2a0b,%edi
    2405:	e8 36 fb ff ff       	call   1f40 <print_string>
    240a:	e9 14 fe ff ff       	jmp    2223 <execute_command+0x53>
    240f:	be 1b 2a 00 00       	mov    $0x2a1b,%esi
    2414:	48 89 ef             	mov    %rbp,%rdi
    2417:	e8 54 01 00 00       	call   2570 <strcmp>
    241c:	85 c0                	test   %eax,%eax
    241e:	75 20                	jne    2440 <execute_command+0x270>
    2420:	bf e0 2a 00 00       	mov    $0x2ae0,%edi
    2425:	e8 16 fb ff ff       	call   1f40 <print_string>
    242a:	bf 08 2b 00 00       	mov    $0x2b08,%edi
    242f:	8b 04 25 ff ff ff ff 	mov    0xffffffffffffffff,%eax
    2436:	e8 05 fb ff ff       	call   1f40 <print_string>
    243b:	e9 e3 fd ff ff       	jmp    2223 <execute_command+0x53>
    2440:	bf 22 2a 00 00       	mov    $0x2a22,%edi
    2445:	e8 76 fc ff ff       	call   20c0 <print_error>
    244a:	48 89 ef             	mov    %rbp,%rdi
    244d:	e8 6e fc ff ff       	call   20c0 <print_error>
    2452:	bf 7f 28 00 00       	mov    $0x287f,%edi
    2457:	e8 64 fc ff ff       	call   20c0 <print_error>
    245c:	e9 c2 fd ff ff       	jmp    2223 <execute_command+0x53>
    2461:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2468:	00 00 00 00 
    246c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002470 <shell_take_char>:
    2470:	48 83 ec 08          	sub    $0x8,%rsp
    2474:	40 80 ff 0a          	cmp    $0xa,%dil
    2478:	74 76                	je     24f0 <shell_take_char+0x80>
    247a:	8b 05 00 17 00 00    	mov    0x1700(%rip),%eax        # 3b80 <cmd_index>
    2480:	40 80 ff 08          	cmp    $0x8,%dil
    2484:	74 4a                	je     24d0 <shell_take_char+0x60>
    2486:	40 80 ff 1b          	cmp    $0x1b,%dil
    248a:	74 2d                	je     24b9 <shell_take_char+0x49>
    248c:	3d fe 00 00 00       	cmp    $0xfe,%eax
    2491:	0f 8e 89 00 00 00    	jle    2520 <shell_take_char+0xb0>
    2497:	48 83 c4 08          	add    $0x8,%rsp
    249b:	c3                   	ret    
    249c:	0f 1f 40 00          	nopl   0x0(%rax)
    24a0:	bf 08 00 00 00       	mov    $0x8,%edi
    24a5:	e8 56 f9 ff ff       	call   1e00 <put_char>
    24aa:	8b 05 d0 16 00 00    	mov    0x16d0(%rip),%eax        # 3b80 <cmd_index>
    24b0:	83 e8 01             	sub    $0x1,%eax
    24b3:	89 05 c7 16 00 00    	mov    %eax,0x16c7(%rip)        # 3b80 <cmd_index>
    24b9:	85 c0                	test   %eax,%eax
    24bb:	7f e3                	jg     24a0 <shell_take_char+0x30>
    24bd:	c6 05 dc 16 00 00 00 	movb   $0x0,0x16dc(%rip)        # 3ba0 <cmd_buffer>
    24c4:	48 83 c4 08          	add    $0x8,%rsp
    24c8:	c3                   	ret    
    24c9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    24d0:	85 c0                	test   %eax,%eax
    24d2:	7e c3                	jle    2497 <shell_take_char+0x27>
    24d4:	83 e8 01             	sub    $0x1,%eax
    24d7:	bf 08 00 00 00       	mov    $0x8,%edi
    24dc:	89 05 9e 16 00 00    	mov    %eax,0x169e(%rip)        # 3b80 <cmd_index>
    24e2:	48 83 c4 08          	add    $0x8,%rsp
    24e6:	e9 15 f9 ff ff       	jmp    1e00 <put_char>
    24eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    24f0:	bf 0a 00 00 00       	mov    $0xa,%edi
    24f5:	e8 06 f9 ff ff       	call   1e00 <put_char>
    24fa:	48 63 05 7f 16 00 00 	movslq 0x167f(%rip),%rax        # 3b80 <cmd_index>
    2501:	bf a0 3b 00 00       	mov    $0x3ba0,%edi
    2506:	c6 80 a0 3b 00 00 00 	movb   $0x0,0x3ba0(%rax)
    250d:	e8 be fc ff ff       	call   21d0 <execute_command>
    2512:	bf 21 29 00 00       	mov    $0x2921,%edi
    2517:	48 83 c4 08          	add    $0x8,%rsp
    251b:	e9 20 fa ff ff       	jmp    1f40 <print_string>
    2520:	48 63 d0             	movslq %eax,%rdx
    2523:	83 c0 01             	add    $0x1,%eax
    2526:	40 88 ba a0 3b 00 00 	mov    %dil,0x3ba0(%rdx)
    252d:	40 0f be ff          	movsbl %dil,%edi
    2531:	89 05 49 16 00 00    	mov    %eax,0x1649(%rip)        # 3b80 <cmd_index>
    2537:	48 83 c4 08          	add    $0x8,%rsp
    253b:	e9 c0 f8 ff ff       	jmp    1e00 <put_char>

0000000000002540 <strlen>:
    2540:	31 c0                	xor    %eax,%eax
    2542:	80 3f 00             	cmpb   $0x0,(%rdi)
    2545:	74 19                	je     2560 <strlen+0x20>
    2547:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    254e:	00 00 
    2550:	48 83 c0 01          	add    $0x1,%rax
    2554:	80 3c 07 00          	cmpb   $0x0,(%rdi,%rax,1)
    2558:	75 f6                	jne    2550 <strlen+0x10>
    255a:	c3                   	ret    
    255b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2560:	c3                   	ret    
    2561:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2568:	00 00 00 00 
    256c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002570 <strcmp>:
    2570:	eb 12                	jmp    2584 <strcmp+0x14>
    2572:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2578:	38 06                	cmp    %al,(%rsi)
    257a:	75 11                	jne    258d <strcmp+0x1d>
    257c:	48 83 c7 01          	add    $0x1,%rdi
    2580:	48 83 c6 01          	add    $0x1,%rsi
    2584:	0f b6 07             	movzbl (%rdi),%eax
    2587:	84 c0                	test   %al,%al
    2589:	75 ed                	jne    2578 <strcmp+0x8>
    258b:	31 c0                	xor    %eax,%eax
    258d:	0f b6 16             	movzbl (%rsi),%edx
    2590:	29 d0                	sub    %edx,%eax
    2592:	c3                   	ret    
    2593:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    259a:	00 00 00 00 
    259e:	66 90                	xchg   %ax,%ax

00000000000025a0 <strncmp>:
    25a0:	85 d2                	test   %edx,%edx
    25a2:	7f 1d                	jg     25c1 <strncmp+0x21>
    25a4:	eb 35                	jmp    25db <strncmp+0x3b>
    25a6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    25ad:	00 00 00 
    25b0:	3a 06                	cmp    (%rsi),%al
    25b2:	75 14                	jne    25c8 <strncmp+0x28>
    25b4:	48 83 c7 01          	add    $0x1,%rdi
    25b8:	48 83 c6 01          	add    $0x1,%rsi
    25bc:	83 ea 01             	sub    $0x1,%edx
    25bf:	74 17                	je     25d8 <strncmp+0x38>
    25c1:	0f b6 07             	movzbl (%rdi),%eax
    25c4:	84 c0                	test   %al,%al
    25c6:	75 e8                	jne    25b0 <strncmp+0x10>
    25c8:	0f b6 07             	movzbl (%rdi),%eax
    25cb:	0f b6 16             	movzbl (%rsi),%edx
    25ce:	29 d0                	sub    %edx,%eax
    25d0:	c3                   	ret    
    25d1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    25d8:	31 c0                	xor    %eax,%eax
    25da:	c3                   	ret    
    25db:	b8 00 00 00 00       	mov    $0x0,%eax
    25e0:	75 e6                	jne    25c8 <strncmp+0x28>
    25e2:	c3                   	ret    
    25e3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    25ea:	00 00 00 00 
    25ee:	66 90                	xchg   %ax,%ax

00000000000025f0 <memset>:
    25f0:	48 89 f8             	mov    %rdi,%rax
    25f3:	4c 8d 04 17          	lea    (%rdi,%rdx,1),%r8
    25f7:	48 89 f9             	mov    %rdi,%rcx
    25fa:	48 85 d2             	test   %rdx,%rdx
    25fd:	74 0e                	je     260d <memset+0x1d>
    25ff:	90                   	nop
    2600:	48 83 c1 01          	add    $0x1,%rcx
    2604:	40 88 71 ff          	mov    %sil,-0x1(%rcx)
    2608:	4c 39 c1             	cmp    %r8,%rcx
    260b:	75 f3                	jne    2600 <memset+0x10>
    260d:	c3                   	ret    
    260e:	66 90                	xchg   %ax,%ax

0000000000002610 <memcpy>:
    2610:	48 89 f8             	mov    %rdi,%rax
    2613:	48 85 d2             	test   %rdx,%rdx
    2616:	74 1a                	je     2632 <memcpy+0x22>
    2618:	31 c9                	xor    %ecx,%ecx
    261a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2620:	44 0f b6 04 0e       	movzbl (%rsi,%rcx,1),%r8d
    2625:	44 88 04 08          	mov    %r8b,(%rax,%rcx,1)
    2629:	48 83 c1 01          	add    $0x1,%rcx
    262d:	48 39 d1             	cmp    %rdx,%rcx
    2630:	75 ee                	jne    2620 <memcpy+0x10>
    2632:	c3                   	ret    
    2633:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    263a:	00 00 00 00 
    263e:	66 90                	xchg   %ax,%ax

0000000000002640 <strcpy>:
    2640:	48 89 f8             	mov    %rdi,%rax
    2643:	31 d2                	xor    %edx,%edx
    2645:	0f 1f 00             	nopl   (%rax)
    2648:	0f b6 0c 16          	movzbl (%rsi,%rdx,1),%ecx
    264c:	88 0c 10             	mov    %cl,(%rax,%rdx,1)
    264f:	48 83 c2 01          	add    $0x1,%rdx
    2653:	84 c9                	test   %cl,%cl
    2655:	75 f1                	jne    2648 <strcpy+0x8>
    2657:	c3                   	ret    
