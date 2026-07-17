
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	48 83 ec 08          	sub    $0x8,%rsp
    1906:	e8 d5 09 00 00       	call   22e0 <clear_screen>
    190b:	bf c1 2f 00 00       	mov    $0x2fc1,%edi
    1910:	e8 5b 0b 00 00       	call   2470 <print_string>
    1915:	e8 66 02 00 00       	call   1b80 <idt_init>
    191a:	e8 11 09 00 00       	call   2230 <pic_init>
    191f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    1924:	e6 21                	out    %al,$0x21
    1926:	bf e0 2f 00 00       	mov    $0x2fe0,%edi
    192b:	e8 40 0b 00 00       	call   2470 <print_string>
    1930:	fb                   	sti    
    1931:	bf 10 30 00 00       	mov    $0x3010,%edi
    1936:	e8 35 0b 00 00       	call   2470 <print_string>
    193b:	e8 b0 0d 00 00       	call   26f0 <shell_init>
    1940:	f4                   	hlt    
    1941:	eb fd                	jmp    1940 <kernel_main+0x40>
    1943:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    194a:	00 00 00 
    194d:	0f 1f 00             	nopl   (%rax)

0000000000001950 <isr32_timer>:
    1950:	50                   	push   %rax
    1951:	48 8b 05 a8 2a 00 00 	mov    0x2aa8(%rip),%rax        # 4400 <system_ticks>
    1958:	48 83 c0 01          	add    $0x1,%rax
    195c:	48 89 05 9d 2a 00 00 	mov    %rax,0x2a9d(%rip)        # 4400 <system_ticks>
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
    1979:	bf a0 2d 00 00       	mov    $0x2da0,%edi
    197e:	56                   	push   %rsi
    197f:	51                   	push   %rcx
    1980:	52                   	push   %rdx
    1981:	50                   	push   %rax
    1982:	fc                   	cld    
    1983:	e8 e8 0a 00 00       	call   2470 <print_string>
    1988:	bf d8 2d 00 00       	mov    $0x2dd8,%edi
    198d:	e8 de 0a 00 00       	call   2470 <print_string>
    1992:	bf 08 2e 00 00       	mov    $0x2e08,%edi
    1997:	e8 d4 0a 00 00       	call   2470 <print_string>
    199c:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    19a1:	e8 fa 0a 00 00       	call   24a0 <print_hex>
    19a6:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    19ab:	e8 c0 0a 00 00       	call   2470 <print_string>
    19b0:	bf 30 2e 00 00       	mov    $0x2e30,%edi
    19b5:	e8 b6 0a 00 00       	call   2470 <print_string>
    19ba:	bf f0 2e 00 00       	mov    $0x2ef0,%edi
    19bf:	e8 ac 0a 00 00       	call   2470 <print_string>
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
    19da:	bf a0 2d 00 00       	mov    $0x2da0,%edi
    19df:	56                   	push   %rsi
    19e0:	51                   	push   %rcx
    19e1:	52                   	push   %rdx
    19e2:	50                   	push   %rax
    19e3:	48 8b 6c 24 50       	mov    0x50(%rsp),%rbp
    19e8:	fc                   	cld    
    19e9:	e8 02 0c 00 00       	call   25f0 <print_error>
    19ee:	bf 68 2e 00 00       	mov    $0x2e68,%edi
    19f3:	e8 f8 0b 00 00       	call   25f0 <print_error>
    19f8:	bf 00 2f 00 00       	mov    $0x2f00,%edi
    19fd:	e8 6e 0a 00 00       	call   2470 <print_string>
    1a02:	48 89 ef             	mov    %rbp,%rdi
    1a05:	e8 96 0a 00 00       	call   24a0 <print_hex>
    1a0a:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    1a0f:	e8 5c 0a 00 00       	call   2470 <print_string>
    1a14:	bf 0d 2f 00 00       	mov    $0x2f0d,%edi
    1a19:	e8 52 0a 00 00       	call   2470 <print_string>
    1a1e:	48 8b 7c 24 58       	mov    0x58(%rsp),%rdi
    1a23:	e8 78 0a 00 00       	call   24a0 <print_hex>
    1a28:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    1a2d:	e8 3e 0a 00 00       	call   2470 <print_string>
    1a32:	bf f0 2e 00 00       	mov    $0x2ef0,%edi
    1a37:	e8 b4 0b 00 00       	call   25f0 <print_error>
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
    1a6d:	bf a0 2d 00 00       	mov    $0x2da0,%edi
    1a72:	fc                   	cld    
    1a73:	e8 78 0b 00 00       	call   25f0 <print_error>
    1a78:	bf a0 2e 00 00       	mov    $0x2ea0,%edi
    1a7d:	e8 6e 0b 00 00       	call   25f0 <print_error>
    1a82:	bf d0 2e 00 00       	mov    $0x2ed0,%edi
    1a87:	e8 e4 09 00 00       	call   2470 <print_string>
    1a8c:	4c 89 e7             	mov    %r12,%rdi
    1a8f:	e8 0c 0a 00 00       	call   24a0 <print_hex>
    1a94:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    1a99:	e8 d2 09 00 00       	call   2470 <print_string>
    1a9e:	bf 00 2f 00 00       	mov    $0x2f00,%edi
    1aa3:	e8 c8 09 00 00       	call   2470 <print_string>
    1aa8:	48 89 ef             	mov    %rbp,%rdi
    1aab:	e8 f0 09 00 00       	call   24a0 <print_hex>
    1ab0:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    1ab5:	e8 b6 09 00 00       	call   2470 <print_string>
    1aba:	bf 0d 2f 00 00       	mov    $0x2f0d,%edi
    1abf:	e8 ac 09 00 00       	call   2470 <print_string>
    1ac4:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
    1ac9:	e8 d2 09 00 00       	call   24a0 <print_hex>
    1ace:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    1ad3:	e8 98 09 00 00       	call   2470 <print_string>
    1ad8:	bf f0 2e 00 00       	mov    $0x2ef0,%edi
    1add:	e8 0e 0b 00 00       	call   25f0 <print_error>
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
    1b06:	0f be b8 20 2d 00 00 	movsbl 0x2d20(%rax),%edi
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
    1b31:	e8 ca 0f 00 00       	call   2b00 <shell_take_char>
    1b36:	eb da                	jmp    1b12 <isr33_keyboard+0x22>
    1b38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b3f:	00 

0000000000001b40 <set_idt_gate>:
    1b40:	48 63 ff             	movslq %edi,%rdi
    1b43:	48 89 f2             	mov    %rsi,%rdx
    1b46:	48 c1 e7 04          	shl    $0x4,%rdi
    1b4a:	48 c1 ea 10          	shr    $0x10,%rdx
    1b4e:	66 89 b7 00 34 00 00 	mov    %si,0x3400(%rdi)
    1b55:	48 c1 ee 20          	shr    $0x20,%rsi
    1b59:	c7 87 02 34 00 00 08 	movl   $0x8e000008,0x3402(%rdi)
    1b60:	00 00 8e 
    1b63:	66 89 97 06 34 00 00 	mov    %dx,0x3406(%rdi)
    1b6a:	89 b7 08 34 00 00    	mov    %esi,0x3408(%rdi)
    1b70:	c7 87 0c 34 00 00 00 	movl   $0x0,0x340c(%rdi)
    1b77:	00 00 00 
    1b7a:	c3                   	ret    
    1b7b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001b80 <idt_init>:
    1b80:	b8 00 34 00 00       	mov    $0x3400,%eax
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
    1bb6:	48 3d 00 44 00 00    	cmp    $0x4400,%rax
    1bbc:	75 ca                	jne    1b88 <idt_init+0x8>
    1bbe:	c7 05 3a 18 00 00 08 	movl   $0x8e000008,0x183a(%rip)        # 3402 <idt+0x2>
    1bc5:	00 00 8e 
    1bc8:	b8 70 19 00 00       	mov    $0x1970,%eax
    1bcd:	66 89 05 2c 18 00 00 	mov    %ax,0x182c(%rip)        # 3400 <idt>
    1bd4:	48 89 c2             	mov    %rax,%rdx
    1bd7:	48 c1 e8 20          	shr    $0x20,%rax
    1bdb:	48 c1 ea 10          	shr    $0x10,%rdx
    1bdf:	89 05 23 18 00 00    	mov    %eax,0x1823(%rip)        # 3408 <idt+0x8>
    1be5:	b8 d0 19 00 00       	mov    $0x19d0,%eax
    1bea:	66 89 15 15 18 00 00 	mov    %dx,0x1815(%rip)        # 3406 <idt+0x6>
    1bf1:	48 89 c2             	mov    %rax,%rdx
    1bf4:	66 89 05 d5 18 00 00 	mov    %ax,0x18d5(%rip)        # 34d0 <idt+0xd0>
    1bfb:	48 c1 e8 20          	shr    $0x20,%rax
    1bff:	48 c1 ea 10          	shr    $0x10,%rdx
    1c03:	89 05 cf 18 00 00    	mov    %eax,0x18cf(%rip)        # 34d8 <idt+0xd8>
    1c09:	b8 50 1a 00 00       	mov    $0x1a50,%eax
    1c0e:	66 89 15 c1 18 00 00 	mov    %dx,0x18c1(%rip)        # 34d6 <idt+0xd6>
    1c15:	48 89 c2             	mov    %rax,%rdx
    1c18:	66 89 05 c1 18 00 00 	mov    %ax,0x18c1(%rip)        # 34e0 <idt+0xe0>
    1c1f:	48 c1 e8 20          	shr    $0x20,%rax
    1c23:	48 c1 ea 10          	shr    $0x10,%rdx
    1c27:	89 05 bb 18 00 00    	mov    %eax,0x18bb(%rip)        # 34e8 <idt+0xe8>
    1c2d:	b8 50 19 00 00       	mov    $0x1950,%eax
    1c32:	66 89 15 ad 18 00 00 	mov    %dx,0x18ad(%rip)        # 34e6 <idt+0xe6>
    1c39:	48 89 c2             	mov    %rax,%rdx
    1c3c:	66 89 05 bd 19 00 00 	mov    %ax,0x19bd(%rip)        # 3600 <idt+0x200>
    1c43:	48 c1 e8 20          	shr    $0x20,%rax
    1c47:	48 c1 ea 10          	shr    $0x10,%rdx
    1c4b:	89 05 b7 19 00 00    	mov    %eax,0x19b7(%rip)        # 3608 <idt+0x208>
    1c51:	b8 f0 1a 00 00       	mov    $0x1af0,%eax
    1c56:	66 89 15 a9 19 00 00 	mov    %dx,0x19a9(%rip)        # 3606 <idt+0x206>
    1c5d:	48 89 c2             	mov    %rax,%rdx
    1c60:	66 89 05 a9 19 00 00 	mov    %ax,0x19a9(%rip)        # 3610 <idt+0x210>
    1c67:	48 c1 e8 20          	shr    $0x20,%rax
    1c6b:	48 c1 ea 10          	shr    $0x10,%rdx
    1c6f:	89 05 a3 19 00 00    	mov    %eax,0x19a3(%rip)        # 3618 <idt+0x218>
    1c75:	b8 ff 0f 00 00       	mov    $0xfff,%eax
    1c7a:	c7 05 88 17 00 00 00 	movl   $0x0,0x1788(%rip)        # 340c <idt+0xc>
    1c81:	00 00 00 
    1c84:	c7 05 44 18 00 00 08 	movl   $0x8e000008,0x1844(%rip)        # 34d2 <idt+0xd2>
    1c8b:	00 00 8e 
    1c8e:	c7 05 44 18 00 00 00 	movl   $0x0,0x1844(%rip)        # 34dc <idt+0xdc>
    1c95:	00 00 00 
    1c98:	c7 05 40 18 00 00 08 	movl   $0x8e000008,0x1840(%rip)        # 34e2 <idt+0xe2>
    1c9f:	00 00 8e 
    1ca2:	c7 05 40 18 00 00 00 	movl   $0x0,0x1840(%rip)        # 34ec <idt+0xec>
    1ca9:	00 00 00 
    1cac:	c7 05 4c 19 00 00 08 	movl   $0x8e000008,0x194c(%rip)        # 3602 <idt+0x202>
    1cb3:	00 00 8e 
    1cb6:	c7 05 4c 19 00 00 00 	movl   $0x0,0x194c(%rip)        # 360c <idt+0x20c>
    1cbd:	00 00 00 
    1cc0:	c7 05 48 19 00 00 08 	movl   $0x8e000008,0x1948(%rip)        # 3612 <idt+0x212>
    1cc7:	00 00 8e 
    1cca:	66 89 15 45 19 00 00 	mov    %dx,0x1945(%rip)        # 3616 <idt+0x216>
    1cd1:	c7 05 41 19 00 00 00 	movl   $0x0,0x1941(%rip)        # 361c <idt+0x21c>
    1cd8:	00 00 00 
    1cdb:	66 89 05 fe 16 00 00 	mov    %ax,0x16fe(%rip)        # 33e0 <idtr_reg>
    1ce2:	48 c7 05 f5 16 00 00 	movq   $0x3400,0x16f5(%rip)        # 33e2 <idtr_reg+0x2>
    1ce9:	00 34 00 00 
    1ced:	0f 01 1d ec 16 00 00 	lidt   0x16ec(%rip)        # 33e0 <idtr_reg>
    1cf4:	c3                   	ret    
    1cf5:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1cfc:	00 00 00 
    1cff:	90                   	nop

0000000000001d00 <kmalloc_init>:
    1d00:	48 83 ec 08          	sub    $0x8,%rsp
    1d04:	31 c0                	xor    %eax,%eax
    1d06:	e8 c5 04 00 00       	call   21d0 <alloc_page>
    1d0b:	48 85 c0             	test   %rax,%rax
    1d0e:	74 30                	je     1d40 <kmalloc_init+0x40>
    1d10:	48 89 05 f1 26 00 00 	mov    %rax,0x26f1(%rip)        # 4408 <heap_head>
    1d17:	bf 60 2f 00 00       	mov    $0x2f60,%edi
    1d1c:	48 c7 40 10 e8 0f 00 	movq   $0xfe8,0x10(%rax)
    1d23:	00 
    1d24:	c6 40 08 01          	movb   $0x1,0x8(%rax)
    1d28:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    1d2f:	48 83 c4 08          	add    $0x8,%rsp
    1d33:	e9 38 07 00 00       	jmp    2470 <print_string>
    1d38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1d3f:	00 
    1d40:	bf 28 2f 00 00       	mov    $0x2f28,%edi
    1d45:	48 83 c4 08          	add    $0x8,%rsp
    1d49:	e9 22 07 00 00       	jmp    2470 <print_string>
    1d4e:	66 90                	xchg   %ax,%ax

0000000000001d50 <kmalloc>:
    1d50:	41 55                	push   %r13
    1d52:	41 54                	push   %r12
    1d54:	55                   	push   %rbp
    1d55:	53                   	push   %rbx
    1d56:	48 83 ec 08          	sub    $0x8,%rsp
    1d5a:	48 85 ff             	test   %rdi,%rdi
    1d5d:	0f 84 ec 00 00 00    	je     1e4f <kmalloc+0xff>
    1d63:	48 8d 5f 07          	lea    0x7(%rdi),%rbx
    1d67:	48 8b 05 9a 26 00 00 	mov    0x269a(%rip),%rax        # 4408 <heap_head>
    1d6e:	48 83 e3 f8          	and    $0xfffffffffffffff8,%rbx
    1d72:	48 8d ab 17 10 00 00 	lea    0x1017(%rbx),%rbp
    1d79:	48 c1 ed 0c          	shr    $0xc,%rbp
    1d7d:	41 89 ed             	mov    %ebp,%r13d
    1d80:	c1 e5 0c             	shl    $0xc,%ebp
    1d83:	48 83 ed 18          	sub    $0x18,%rbp
    1d87:	eb 19                	jmp    1da2 <kmalloc+0x52>
    1d89:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1d90:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1d94:	74 09                	je     1d9f <kmalloc+0x4f>
    1d96:	48 8b 50 10          	mov    0x10(%rax),%rdx
    1d9a:	48 39 da             	cmp    %rbx,%rdx
    1d9d:	73 61                	jae    1e00 <kmalloc+0xb0>
    1d9f:	48 8b 00             	mov    (%rax),%rax
    1da2:	48 85 c0             	test   %rax,%rax
    1da5:	75 e9                	jne    1d90 <kmalloc+0x40>
    1da7:	44 89 ef             	mov    %r13d,%edi
    1daa:	e8 41 03 00 00       	call   20f0 <alloc_pages>
    1daf:	49 89 c4             	mov    %rax,%r12
    1db2:	48 85 c0             	test   %rax,%rax
    1db5:	0f 84 88 00 00 00    	je     1e43 <kmalloc+0xf3>
    1dbb:	48 89 68 10          	mov    %rbp,0x10(%rax)
    1dbf:	c6 40 08 01          	movb   $0x1,0x8(%rax)
    1dc3:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
    1dca:	48 8b 05 37 26 00 00 	mov    0x2637(%rip),%rax        # 4408 <heap_head>
    1dd1:	48 89 c2             	mov    %rax,%rdx
    1dd4:	48 85 c0             	test   %rax,%rax
    1dd7:	75 0f                	jne    1de8 <kmalloc+0x98>
    1dd9:	4c 89 25 28 26 00 00 	mov    %r12,0x2628(%rip)        # 4408 <heap_head>
    1de0:	4c 89 e0             	mov    %r12,%rax
    1de3:	eb bd                	jmp    1da2 <kmalloc+0x52>
    1de5:	0f 1f 00             	nopl   (%rax)
    1de8:	48 89 d1             	mov    %rdx,%rcx
    1deb:	48 8b 12             	mov    (%rdx),%rdx
    1dee:	48 85 d2             	test   %rdx,%rdx
    1df1:	75 f5                	jne    1de8 <kmalloc+0x98>
    1df3:	4c 89 21             	mov    %r12,(%rcx)
    1df6:	eb aa                	jmp    1da2 <kmalloc+0x52>
    1df8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1dff:	00 
    1e00:	48 8d 4b 20          	lea    0x20(%rbx),%rcx
    1e04:	48 39 ca             	cmp    %rcx,%rdx
    1e07:	73 17                	jae    1e20 <kmalloc+0xd0>
    1e09:	c6 40 08 00          	movb   $0x0,0x8(%rax)
    1e0d:	4c 8d 60 18          	lea    0x18(%rax),%r12
    1e11:	48 83 c4 08          	add    $0x8,%rsp
    1e15:	4c 89 e0             	mov    %r12,%rax
    1e18:	5b                   	pop    %rbx
    1e19:	5d                   	pop    %rbp
    1e1a:	41 5c                	pop    %r12
    1e1c:	41 5d                	pop    %r13
    1e1e:	c3                   	ret    
    1e1f:	90                   	nop
    1e20:	48 29 da             	sub    %rbx,%rdx
    1e23:	48 8d 4c 18 18       	lea    0x18(%rax,%rbx,1),%rcx
    1e28:	48 83 ea 18          	sub    $0x18,%rdx
    1e2c:	c6 41 08 01          	movb   $0x1,0x8(%rcx)
    1e30:	48 89 51 10          	mov    %rdx,0x10(%rcx)
    1e34:	48 8b 10             	mov    (%rax),%rdx
    1e37:	48 89 11             	mov    %rdx,(%rcx)
    1e3a:	48 89 58 10          	mov    %rbx,0x10(%rax)
    1e3e:	48 89 08             	mov    %rcx,(%rax)
    1e41:	eb c6                	jmp    1e09 <kmalloc+0xb9>
    1e43:	bf 98 2f 00 00       	mov    $0x2f98,%edi
    1e48:	e8 23 06 00 00       	call   2470 <print_string>
    1e4d:	eb c2                	jmp    1e11 <kmalloc+0xc1>
    1e4f:	45 31 e4             	xor    %r12d,%r12d
    1e52:	eb bd                	jmp    1e11 <kmalloc+0xc1>
    1e54:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1e5b:	00 00 00 00 
    1e5f:	90                   	nop

0000000000001e60 <kfree>:
    1e60:	48 85 ff             	test   %rdi,%rdi
    1e63:	74 33                	je     1e98 <kfree+0x38>
    1e65:	48 8b 47 e8          	mov    -0x18(%rdi),%rax
    1e69:	c6 47 f0 01          	movb   $0x1,-0x10(%rdi)
    1e6d:	48 8d 4f e8          	lea    -0x18(%rdi),%rcx
    1e71:	48 85 c0             	test   %rax,%rax
    1e74:	74 06                	je     1e7c <kfree+0x1c>
    1e76:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1e7a:	75 24                	jne    1ea0 <kfree+0x40>
    1e7c:	48 8b 05 85 25 00 00 	mov    0x2585(%rip),%rax        # 4408 <heap_head>
    1e83:	eb 0e                	jmp    1e93 <kfree+0x33>
    1e85:	0f 1f 00             	nopl   (%rax)
    1e88:	48 8b 10             	mov    (%rax),%rdx
    1e8b:	48 39 ca             	cmp    %rcx,%rdx
    1e8e:	74 30                	je     1ec0 <kfree+0x60>
    1e90:	48 89 d0             	mov    %rdx,%rax
    1e93:	48 85 c0             	test   %rax,%rax
    1e96:	75 f0                	jne    1e88 <kfree+0x28>
    1e98:	c3                   	ret    
    1e99:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1ea0:	48 8b 50 10          	mov    0x10(%rax),%rdx
    1ea4:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    1ea8:	48 8b 00             	mov    (%rax),%rax
    1eab:	48 8d 54 16 18       	lea    0x18(%rsi,%rdx,1),%rdx
    1eb0:	48 89 57 f8          	mov    %rdx,-0x8(%rdi)
    1eb4:	48 89 47 e8          	mov    %rax,-0x18(%rdi)
    1eb8:	eb c2                	jmp    1e7c <kfree+0x1c>
    1eba:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1ec0:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
    1ec4:	74 d2                	je     1e98 <kfree+0x38>
    1ec6:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
    1eca:	48 8d 56 18          	lea    0x18(%rsi),%rdx
    1ece:	48 01 50 10          	add    %rdx,0x10(%rax)
    1ed2:	48 8b 57 e8          	mov    -0x18(%rdi),%rdx
    1ed6:	48 89 10             	mov    %rdx,(%rax)
    1ed9:	c3                   	ret    
    1eda:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001ee0 <init_phy_mem_map>:
    1ee0:	53                   	push   %rbx
    1ee1:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    1ee8:	85 c0                	test   %eax,%eax
    1eea:	0f 84 54 01 00 00    	je     2044 <init_phy_mem_map+0x164>
    1ef0:	83 e8 01             	sub    $0x1,%eax
    1ef3:	31 d2                	xor    %edx,%edx
    1ef5:	48 8d 04 80          	lea    (%rax,%rax,4),%rax
    1ef9:	48 8d 1c 85 18 80 00 	lea    0x8018(,%rax,4),%rbx
    1f00:	00 
    1f01:	b8 04 80 00 00       	mov    $0x8004,%eax
    1f06:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1f0d:	00 00 00 
    1f10:	83 78 10 01          	cmpl   $0x1,0x10(%rax)
    1f14:	75 0e                	jne    1f24 <init_phy_mem_map+0x44>
    1f16:	48 8b 48 08          	mov    0x8(%rax),%rcx
    1f1a:	48 03 08             	add    (%rax),%rcx
    1f1d:	48 39 ca             	cmp    %rcx,%rdx
    1f20:	48 0f 42 d1          	cmovb  %rcx,%rdx
    1f24:	48 83 c0 14          	add    $0x14,%rax
    1f28:	48 39 c3             	cmp    %rax,%rbx
    1f2b:	75 e3                	jne    1f10 <init_phy_mem_map+0x30>
    1f2d:	48 c1 ea 0c          	shr    $0xc,%rdx
    1f31:	be ff 00 00 00       	mov    $0xff,%esi
    1f36:	bf 00 00 20 00       	mov    $0x200000,%edi
    1f3b:	48 c7 05 ca 24 00 00 	movq   $0x200000,0x24ca(%rip)        # 4410 <phy_mem_map>
    1f42:	00 00 20 00 
    1f46:	48 83 c2 07          	add    $0x7,%rdx
    1f4a:	48 c1 ea 03          	shr    $0x3,%rdx
    1f4e:	48 89 15 c3 24 00 00 	mov    %rdx,0x24c3(%rip)        # 4418 <phy_mem_map+0x8>
    1f55:	e8 26 0d 00 00       	call   2c80 <memset>
    1f5a:	be 04 80 00 00       	mov    $0x8004,%esi
    1f5f:	48 8b 15 b2 24 00 00 	mov    0x24b2(%rip),%rdx        # 4418 <phy_mem_map+0x8>
    1f66:	41 b8 01 00 00 00    	mov    $0x1,%r8d
    1f6c:	eb 0b                	jmp    1f79 <init_phy_mem_map+0x99>
    1f6e:	66 90                	xchg   %ax,%ax
    1f70:	48 83 c6 14          	add    $0x14,%rsi
    1f74:	48 39 f3             	cmp    %rsi,%rbx
    1f77:	74 77                	je     1ff0 <init_phy_mem_map+0x110>
    1f79:	83 7e 10 01          	cmpl   $0x1,0x10(%rsi)
    1f7d:	75 f1                	jne    1f70 <init_phy_mem_map+0x90>
    1f7f:	48 8b 3e             	mov    (%rsi),%rdi
    1f82:	48 89 f8             	mov    %rdi,%rax
    1f85:	48 03 7e 08          	add    0x8(%rsi),%rdi
    1f89:	48 c1 e8 0c          	shr    $0xc,%rax
    1f8d:	48 c1 ef 0c          	shr    $0xc,%rdi
    1f91:	48 39 f8             	cmp    %rdi,%rax
    1f94:	73 da                	jae    1f70 <init_phy_mem_map+0x90>
    1f96:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1f9d:	00 00 00 
    1fa0:	48 8d 0c d5 00 00 00 	lea    0x0(,%rdx,8),%rcx
    1fa7:	00 
    1fa8:	48 39 c1             	cmp    %rax,%rcx
    1fab:	76 27                	jbe    1fd4 <init_phy_mem_map+0xf4>
    1fad:	89 c1                	mov    %eax,%ecx
    1faf:	45 89 c1             	mov    %r8d,%r9d
    1fb2:	48 89 c2             	mov    %rax,%rdx
    1fb5:	83 e1 07             	and    $0x7,%ecx
    1fb8:	48 c1 ea 03          	shr    $0x3,%rdx
    1fbc:	48 03 15 4d 24 00 00 	add    0x244d(%rip),%rdx        # 4410 <phy_mem_map>
    1fc3:	41 d3 e1             	shl    %cl,%r9d
    1fc6:	44 89 c9             	mov    %r9d,%ecx
    1fc9:	f7 d1                	not    %ecx
    1fcb:	20 0a                	and    %cl,(%rdx)
    1fcd:	48 8b 15 44 24 00 00 	mov    0x2444(%rip),%rdx        # 4418 <phy_mem_map+0x8>
    1fd4:	48 83 c0 01          	add    $0x1,%rax
    1fd8:	48 39 c7             	cmp    %rax,%rdi
    1fdb:	75 c3                	jne    1fa0 <init_phy_mem_map+0xc0>
    1fdd:	48 83 c6 14          	add    $0x14,%rsi
    1fe1:	48 39 f3             	cmp    %rsi,%rbx
    1fe4:	75 93                	jne    1f79 <init_phy_mem_map+0x99>
    1fe6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1fed:	00 00 00 
    1ff0:	48 8b 05 19 24 00 00 	mov    0x2419(%rip),%rax        # 4410 <phy_mem_map>
    1ff7:	48 8d b4 10 ff 0f 00 	lea    0xfff(%rax,%rdx,1),%rsi
    1ffe:	00 
    1fff:	48 c1 ee 0c          	shr    $0xc,%rsi
    2003:	74 3d                	je     2042 <init_phy_mem_map+0x162>
    2005:	31 c0                	xor    %eax,%eax
    2007:	bf 01 00 00 00       	mov    $0x1,%edi
    200c:	eb 09                	jmp    2017 <init_phy_mem_map+0x137>
    200e:	66 90                	xchg   %ax,%ax
    2010:	48 8b 15 01 24 00 00 	mov    0x2401(%rip),%rdx        # 4418 <phy_mem_map+0x8>
    2017:	48 c1 e2 03          	shl    $0x3,%rdx
    201b:	48 39 c2             	cmp    %rax,%rdx
    201e:	76 19                	jbe    2039 <init_phy_mem_map+0x159>
    2020:	48 89 c2             	mov    %rax,%rdx
    2023:	89 c1                	mov    %eax,%ecx
    2025:	89 fb                	mov    %edi,%ebx
    2027:	48 c1 ea 03          	shr    $0x3,%rdx
    202b:	83 e1 07             	and    $0x7,%ecx
    202e:	48 03 15 db 23 00 00 	add    0x23db(%rip),%rdx        # 4410 <phy_mem_map>
    2035:	d3 e3                	shl    %cl,%ebx
    2037:	08 1a                	or     %bl,(%rdx)
    2039:	48 83 c0 01          	add    $0x1,%rax
    203d:	48 39 c6             	cmp    %rax,%rsi
    2040:	75 ce                	jne    2010 <init_phy_mem_map+0x130>
    2042:	5b                   	pop    %rbx
    2043:	c3                   	ret    
    2044:	31 d2                	xor    %edx,%edx
    2046:	be ff 00 00 00       	mov    $0xff,%esi
    204b:	bf 00 00 20 00       	mov    $0x200000,%edi
    2050:	48 c7 05 b5 23 00 00 	movq   $0x200000,0x23b5(%rip)        # 4410 <phy_mem_map>
    2057:	00 00 20 00 
    205b:	48 c7 05 b2 23 00 00 	movq   $0x0,0x23b2(%rip)        # 4418 <phy_mem_map+0x8>
    2062:	00 00 00 00 
    2066:	e8 15 0c 00 00       	call   2c80 <memset>
    206b:	48 8b 15 a6 23 00 00 	mov    0x23a6(%rip),%rdx        # 4418 <phy_mem_map+0x8>
    2072:	e9 79 ff ff ff       	jmp    1ff0 <init_phy_mem_map+0x110>
    2077:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    207e:	00 00 

0000000000002080 <set_bit>:
    2080:	48 8b 47 08          	mov    0x8(%rdi),%rax
    2084:	48 89 f1             	mov    %rsi,%rcx
    2087:	48 c1 e0 03          	shl    $0x3,%rax
    208b:	48 39 f0             	cmp    %rsi,%rax
    208e:	76 20                	jbe    20b0 <set_bit+0x30>
    2090:	83 e1 07             	and    $0x7,%ecx
    2093:	b8 01 00 00 00       	mov    $0x1,%eax
    2098:	48 c1 ee 03          	shr    $0x3,%rsi
    209c:	48 03 37             	add    (%rdi),%rsi
    209f:	d3 e0                	shl    %cl,%eax
    20a1:	89 c1                	mov    %eax,%ecx
    20a3:	0a 06                	or     (%rsi),%al
    20a5:	f7 d1                	not    %ecx
    20a7:	22 0e                	and    (%rsi),%cl
    20a9:	84 d2                	test   %dl,%dl
    20ab:	0f 44 c1             	cmove  %ecx,%eax
    20ae:	88 06                	mov    %al,(%rsi)
    20b0:	c3                   	ret    
    20b1:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    20b8:	00 00 00 00 
    20bc:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000020c0 <get_bit>:
    20c0:	48 8b 47 08          	mov    0x8(%rdi),%rax
    20c4:	48 89 f1             	mov    %rsi,%rcx
    20c7:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
    20ce:	00 
    20cf:	31 c0                	xor    %eax,%eax
    20d1:	48 39 f2             	cmp    %rsi,%rdx
    20d4:	76 16                	jbe    20ec <get_bit+0x2c>
    20d6:	48 8b 17             	mov    (%rdi),%rdx
    20d9:	48 89 f0             	mov    %rsi,%rax
    20dc:	83 e1 07             	and    $0x7,%ecx
    20df:	48 c1 e8 03          	shr    $0x3,%rax
    20e3:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
    20e7:	d3 f8                	sar    %cl,%eax
    20e9:	83 e0 01             	and    $0x1,%eax
    20ec:	c3                   	ret    
    20ed:	0f 1f 00             	nopl   (%rax)

00000000000020f0 <alloc_pages>:
    20f0:	85 ff                	test   %edi,%edi
    20f2:	0f 84 d0 00 00 00    	je     21c8 <alloc_pages+0xd8>
    20f8:	4c 8b 1d 19 23 00 00 	mov    0x2319(%rip),%r11        # 4418 <phy_mem_map+0x8>
    20ff:	45 89 da             	mov    %r11d,%r10d
    2102:	41 c1 e2 03          	shl    $0x3,%r10d
    2106:	0f 84 bc 00 00 00    	je     21c8 <alloc_pages+0xd8>
    210c:	55                   	push   %rbp
    210d:	45 89 d2             	mov    %r10d,%r10d
    2110:	48 8b 2d f9 22 00 00 	mov    0x22f9(%rip),%rbp        # 4410 <phy_mem_map>
    2117:	31 c0                	xor    %eax,%eax
    2119:	53                   	push   %rbx
    211a:	31 f6                	xor    %esi,%esi
    211c:	4a 8d 1c dd 00 00 00 	lea    0x0(,%r11,8),%rbx
    2123:	00 
    2124:	31 d2                	xor    %edx,%edx
    2126:	eb 2d                	jmp    2155 <alloc_pages+0x65>
    2128:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    212f:	00 
    2130:	49 89 c0             	mov    %rax,%r8
    2133:	49 c1 e8 03          	shr    $0x3,%r8
    2137:	46 0f b6 4c 05 00    	movzbl 0x0(%rbp,%r8,1),%r9d
    213d:	41 89 c0             	mov    %eax,%r8d
    2140:	41 83 e0 07          	and    $0x7,%r8d
    2144:	45 0f a3 c1          	bt     %r8d,%r9d
    2148:	73 12                	jae    215c <alloc_pages+0x6c>
    214a:	31 d2                	xor    %edx,%edx
    214c:	48 83 c0 01          	add    $0x1,%rax
    2150:	49 39 c2             	cmp    %rax,%r10
    2153:	74 6b                	je     21c0 <alloc_pages+0xd0>
    2155:	89 c1                	mov    %eax,%ecx
    2157:	48 39 c3             	cmp    %rax,%rbx
    215a:	77 d4                	ja     2130 <alloc_pages+0x40>
    215c:	85 d2                	test   %edx,%edx
    215e:	0f 44 f1             	cmove  %ecx,%esi
    2161:	83 c2 01             	add    $0x1,%edx
    2164:	39 d7                	cmp    %edx,%edi
    2166:	75 e4                	jne    214c <alloc_pages+0x5c>
    2168:	41 b9 01 00 00 00    	mov    $0x1,%r9d
    216e:	89 f7                	mov    %esi,%edi
    2170:	45 89 c8             	mov    %r9d,%r8d
    2173:	41 29 f0             	sub    %esi,%r8d
    2176:	eb 12                	jmp    218a <alloc_pages+0x9a>
    2178:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    217f:	00 
    2180:	4c 8b 1d 91 22 00 00 	mov    0x2291(%rip),%r11        # 4418 <phy_mem_map+0x8>
    2187:	83 c7 01             	add    $0x1,%edi
    218a:	89 f8                	mov    %edi,%eax
    218c:	49 c1 e3 03          	shl    $0x3,%r11
    2190:	4c 39 d8             	cmp    %r11,%rax
    2193:	73 17                	jae    21ac <alloc_pages+0xbc>
    2195:	89 f9                	mov    %edi,%ecx
    2197:	48 c1 e8 03          	shr    $0x3,%rax
    219b:	44 89 cb             	mov    %r9d,%ebx
    219e:	48 03 05 6b 22 00 00 	add    0x226b(%rip),%rax        # 4410 <phy_mem_map>
    21a5:	83 e1 07             	and    $0x7,%ecx
    21a8:	d3 e3                	shl    %cl,%ebx
    21aa:	08 18                	or     %bl,(%rax)
    21ac:	41 8d 04 38          	lea    (%r8,%rdi,1),%eax
    21b0:	39 d0                	cmp    %edx,%eax
    21b2:	72 cc                	jb     2180 <alloc_pages+0x90>
    21b4:	89 f0                	mov    %esi,%eax
    21b6:	5b                   	pop    %rbx
    21b7:	5d                   	pop    %rbp
    21b8:	48 c1 e0 0c          	shl    $0xc,%rax
    21bc:	c3                   	ret    
    21bd:	0f 1f 00             	nopl   (%rax)
    21c0:	31 c0                	xor    %eax,%eax
    21c2:	5b                   	pop    %rbx
    21c3:	5d                   	pop    %rbp
    21c4:	c3                   	ret    
    21c5:	0f 1f 00             	nopl   (%rax)
    21c8:	31 c0                	xor    %eax,%eax
    21ca:	c3                   	ret    
    21cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000021d0 <alloc_page>:
    21d0:	bf 01 00 00 00       	mov    $0x1,%edi
    21d5:	e9 16 ff ff ff       	jmp    20f0 <alloc_pages>
    21da:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

00000000000021e0 <free_page>:
    21e0:	55                   	push   %rbp
    21e1:	ba 00 10 00 00       	mov    $0x1000,%edx
    21e6:	31 f6                	xor    %esi,%esi
    21e8:	48 89 fd             	mov    %rdi,%rbp
    21eb:	53                   	push   %rbx
    21ec:	48 89 fb             	mov    %rdi,%rbx
    21ef:	48 c1 ed 0c          	shr    $0xc,%rbp
    21f3:	48 83 ec 08          	sub    $0x8,%rsp
    21f7:	e8 84 0a 00 00       	call   2c80 <memset>
    21fc:	48 8b 05 15 22 00 00 	mov    0x2215(%rip),%rax        # 4418 <phy_mem_map+0x8>
    2203:	48 c1 e0 03          	shl    $0x3,%rax
    2207:	48 39 c5             	cmp    %rax,%rbp
    220a:	73 16                	jae    2222 <free_page+0x42>
    220c:	48 c1 eb 0f          	shr    $0xf,%rbx
    2210:	48 03 1d f9 21 00 00 	add    0x21f9(%rip),%rbx        # 4410 <phy_mem_map>
    2217:	83 e5 07             	and    $0x7,%ebp
    221a:	0f b6 03             	movzbl (%rbx),%eax
    221d:	0f b3 e8             	btr    %ebp,%eax
    2220:	88 03                	mov    %al,(%rbx)
    2222:	48 83 c4 08          	add    $0x8,%rsp
    2226:	5b                   	pop    %rbx
    2227:	5d                   	pop    %rbp
    2228:	c3                   	ret    
    2229:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000002230 <pic_init>:
    2230:	b8 11 00 00 00       	mov    $0x11,%eax
    2235:	e6 20                	out    %al,$0x20
    2237:	e6 a0                	out    %al,$0xa0
    2239:	b8 20 00 00 00       	mov    $0x20,%eax
    223e:	e6 21                	out    %al,$0x21
    2240:	b8 28 00 00 00       	mov    $0x28,%eax
    2245:	e6 a1                	out    %al,$0xa1
    2247:	b8 04 00 00 00       	mov    $0x4,%eax
    224c:	e6 21                	out    %al,$0x21
    224e:	b8 02 00 00 00       	mov    $0x2,%eax
    2253:	e6 a1                	out    %al,$0xa1
    2255:	b8 01 00 00 00       	mov    $0x1,%eax
    225a:	e6 21                	out    %al,$0x21
    225c:	e6 a1                	out    %al,$0xa1
    225e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    2263:	e6 21                	out    %al,$0x21
    2265:	e6 a1                	out    %al,$0xa1
    2267:	bf 38 30 00 00       	mov    $0x3038,%edi
    226c:	e9 ff 01 00 00       	jmp    2470 <print_string>
    2271:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2278:	00 00 00 
    227b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002280 <get_cursor>:
    2280:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2285:	b8 0e 00 00 00       	mov    $0xe,%eax
    228a:	89 fa                	mov    %edi,%edx
    228c:	ee                   	out    %al,(%dx)
    228d:	be d5 03 00 00       	mov    $0x3d5,%esi
    2292:	89 f2                	mov    %esi,%edx
    2294:	ec                   	in     (%dx),%al
    2295:	0f b6 c8             	movzbl %al,%ecx
    2298:	89 fa                	mov    %edi,%edx
    229a:	b8 0f 00 00 00       	mov    $0xf,%eax
    229f:	c1 e1 08             	shl    $0x8,%ecx
    22a2:	ee                   	out    %al,(%dx)
    22a3:	89 f2                	mov    %esi,%edx
    22a5:	ec                   	in     (%dx),%al
    22a6:	0f b6 c0             	movzbl %al,%eax
    22a9:	09 c8                	or     %ecx,%eax
    22ab:	c3                   	ret    
    22ac:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000022b0 <set_cursor>:
    22b0:	be d4 03 00 00       	mov    $0x3d4,%esi
    22b5:	41 89 f8             	mov    %edi,%r8d
    22b8:	b8 0e 00 00 00       	mov    $0xe,%eax
    22bd:	89 f2                	mov    %esi,%edx
    22bf:	ee                   	out    %al,(%dx)
    22c0:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    22c5:	66 c1 ef 08          	shr    $0x8,%di
    22c9:	89 f8                	mov    %edi,%eax
    22cb:	89 ca                	mov    %ecx,%edx
    22cd:	ee                   	out    %al,(%dx)
    22ce:	b8 0f 00 00 00       	mov    $0xf,%eax
    22d3:	89 f2                	mov    %esi,%edx
    22d5:	ee                   	out    %al,(%dx)
    22d6:	44 89 c0             	mov    %r8d,%eax
    22d9:	89 ca                	mov    %ecx,%edx
    22db:	ee                   	out    %al,(%dx)
    22dc:	c3                   	ret    
    22dd:	0f 1f 00             	nopl   (%rax)

00000000000022e0 <clear_screen>:
    22e0:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    22e5:	0f 1f 00             	nopl   (%rax)
    22e8:	c6 00 20             	movb   $0x20,(%rax)
    22eb:	48 83 c0 02          	add    $0x2,%rax
    22ef:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    22f3:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    22f9:	75 ed                	jne    22e8 <clear_screen+0x8>
    22fb:	bf d4 03 00 00       	mov    $0x3d4,%edi
    2300:	b8 0e 00 00 00       	mov    $0xe,%eax
    2305:	89 fa                	mov    %edi,%edx
    2307:	ee                   	out    %al,(%dx)
    2308:	31 c9                	xor    %ecx,%ecx
    230a:	be d5 03 00 00       	mov    $0x3d5,%esi
    230f:	89 c8                	mov    %ecx,%eax
    2311:	89 f2                	mov    %esi,%edx
    2313:	ee                   	out    %al,(%dx)
    2314:	b8 0f 00 00 00       	mov    $0xf,%eax
    2319:	89 fa                	mov    %edi,%edx
    231b:	ee                   	out    %al,(%dx)
    231c:	89 c8                	mov    %ecx,%eax
    231e:	89 f2                	mov    %esi,%edx
    2320:	ee                   	out    %al,(%dx)
    2321:	c3                   	ret    
    2322:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2329:	00 00 00 00 
    232d:	0f 1f 00             	nopl   (%rax)

0000000000002330 <put_char>:
    2330:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    2336:	53                   	push   %rbx
    2337:	b8 0e 00 00 00       	mov    $0xe,%eax
    233c:	44 89 c2             	mov    %r8d,%edx
    233f:	ee                   	out    %al,(%dx)
    2340:	be d5 03 00 00       	mov    $0x3d5,%esi
    2345:	89 f2                	mov    %esi,%edx
    2347:	ec                   	in     (%dx),%al
    2348:	0f b6 c8             	movzbl %al,%ecx
    234b:	44 89 c2             	mov    %r8d,%edx
    234e:	b8 0f 00 00 00       	mov    $0xf,%eax
    2353:	c1 e1 08             	shl    $0x8,%ecx
    2356:	ee                   	out    %al,(%dx)
    2357:	89 f2                	mov    %esi,%edx
    2359:	ec                   	in     (%dx),%al
    235a:	0f b6 c0             	movzbl %al,%eax
    235d:	09 c8                	or     %ecx,%eax
    235f:	40 80 ff 0d          	cmp    $0xd,%dil
    2363:	0f 84 b7 00 00 00    	je     2420 <put_char+0xf0>
    2369:	40 80 ff 0a          	cmp    $0xa,%dil
    236d:	74 5c                	je     23cb <put_char+0x9b>
    236f:	40 80 ff 08          	cmp    $0x8,%dil
    2373:	0f 84 be 00 00 00    	je     2437 <put_char+0x107>
    2379:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    237d:	0f b6 0d 41 10 00 00 	movzbl 0x1041(%rip),%ecx        # 33c5 <current_color>
    2384:	83 c0 01             	add    $0x1,%eax
    2387:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    238d:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    2394:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    239a:	66 3d cf 07          	cmp    $0x7cf,%ax
    239e:	77 44                	ja     23e4 <put_char+0xb4>
    23a0:	0f b6 dc             	movzbl %ah,%ebx
    23a3:	89 c1                	mov    %eax,%ecx
    23a5:	bf d4 03 00 00       	mov    $0x3d4,%edi
    23aa:	b8 0e 00 00 00       	mov    $0xe,%eax
    23af:	89 fa                	mov    %edi,%edx
    23b1:	ee                   	out    %al,(%dx)
    23b2:	be d5 03 00 00       	mov    $0x3d5,%esi
    23b7:	89 d8                	mov    %ebx,%eax
    23b9:	89 f2                	mov    %esi,%edx
    23bb:	ee                   	out    %al,(%dx)
    23bc:	b8 0f 00 00 00       	mov    $0xf,%eax
    23c1:	89 fa                	mov    %edi,%edx
    23c3:	ee                   	out    %al,(%dx)
    23c4:	89 c8                	mov    %ecx,%eax
    23c6:	89 f2                	mov    %esi,%edx
    23c8:	ee                   	out    %al,(%dx)
    23c9:	5b                   	pop    %rbx
    23ca:	c3                   	ret    
    23cb:	0f b7 c0             	movzwl %ax,%eax
    23ce:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    23d4:	c1 e8 16             	shr    $0x16,%eax
    23d7:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    23db:	c1 e0 04             	shl    $0x4,%eax
    23de:	66 3d cf 07          	cmp    $0x7cf,%ax
    23e2:	76 bc                	jbe    23a0 <put_char+0x70>
    23e4:	ba 00 0f 00 00       	mov    $0xf00,%edx
    23e9:	be a0 80 0b 00       	mov    $0xb80a0,%esi
    23ee:	bf 00 80 0b 00       	mov    $0xb8000,%edi
    23f3:	e8 a8 08 00 00       	call   2ca0 <memcpy>
    23f8:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    23fd:	0f 1f 00             	nopl   (%rax)
    2400:	c6 00 20             	movb   $0x20,(%rax)
    2403:	48 83 c0 02          	add    $0x2,%rax
    2407:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    240b:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    2411:	75 ed                	jne    2400 <put_char+0xd0>
    2413:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    2418:	bb 07 00 00 00       	mov    $0x7,%ebx
    241d:	eb 86                	jmp    23a5 <put_char+0x75>
    241f:	90                   	nop
    2420:	0f b7 c0             	movzwl %ax,%eax
    2423:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    2429:	c1 e8 16             	shr    $0x16,%eax
    242c:	8d 04 80             	lea    (%rax,%rax,4),%eax
    242f:	c1 e0 04             	shl    $0x4,%eax
    2432:	e9 63 ff ff ff       	jmp    239a <put_char+0x6a>
    2437:	66 85 c0             	test   %ax,%ax
    243a:	74 26                	je     2462 <put_char+0x132>
    243c:	83 e8 01             	sub    $0x1,%eax
    243f:	0f b6 0d 7f 0f 00 00 	movzbl 0xf7f(%rip),%ecx        # 33c5 <current_color>
    2446:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    244a:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    2450:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    2457:	88 8a 01 80 0b 00    	mov    %cl,0xb8001(%rdx)
    245d:	e9 38 ff ff ff       	jmp    239a <put_char+0x6a>
    2462:	31 c9                	xor    %ecx,%ecx
    2464:	31 db                	xor    %ebx,%ebx
    2466:	e9 3a ff ff ff       	jmp    23a5 <put_char+0x75>
    246b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000002470 <print_string>:
    2470:	53                   	push   %rbx
    2471:	48 89 fb             	mov    %rdi,%rbx
    2474:	0f be 3f             	movsbl (%rdi),%edi
    2477:	40 84 ff             	test   %dil,%dil
    247a:	74 16                	je     2492 <print_string+0x22>
    247c:	0f 1f 40 00          	nopl   0x0(%rax)
    2480:	e8 ab fe ff ff       	call   2330 <put_char>
    2485:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2489:	48 83 c3 01          	add    $0x1,%rbx
    248d:	40 84 ff             	test   %dil,%dil
    2490:	75 ee                	jne    2480 <print_string+0x10>
    2492:	5b                   	pop    %rbx
    2493:	c3                   	ret    
    2494:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    249b:	00 00 00 00 
    249f:	90                   	nop

00000000000024a0 <print_hex>:
    24a0:	55                   	push   %rbp
    24a1:	48 89 fd             	mov    %rdi,%rbp
    24a4:	bf 30 00 00 00       	mov    $0x30,%edi
    24a9:	53                   	push   %rbx
    24aa:	bb a9 30 00 00       	mov    $0x30a9,%ebx
    24af:	48 83 ec 18          	sub    $0x18,%rsp
    24b3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    24b8:	e8 73 fe ff ff       	call   2330 <put_char>
    24bd:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    24c1:	48 83 c3 01          	add    $0x1,%rbx
    24c5:	40 84 ff             	test   %dil,%dil
    24c8:	75 ee                	jne    24b8 <print_hex+0x18>
    24ca:	b8 01 00 00 00       	mov    $0x1,%eax
    24cf:	48 85 ed             	test   %rbp,%rbp
    24d2:	74 54                	je     2528 <print_hex+0x88>
    24d4:	0f 1f 40 00          	nopl   0x0(%rax)
    24d8:	48 89 ea             	mov    %rbp,%rdx
    24db:	48 63 d8             	movslq %eax,%rbx
    24de:	83 e2 0f             	and    $0xf,%edx
    24e1:	0f be ba 64 30 00 00 	movsbl 0x3064(%rdx),%edi
    24e8:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    24ed:	48 83 c0 01          	add    $0x1,%rax
    24f1:	48 c1 ed 04          	shr    $0x4,%rbp
    24f5:	75 e1                	jne    24d8 <print_hex+0x38>
    24f7:	e8 34 fe ff ff       	call   2330 <put_char>
    24fc:	48 83 eb 01          	sub    $0x1,%rbx
    2500:	85 db                	test   %ebx,%ebx
    2502:	74 16                	je     251a <print_hex+0x7a>
    2504:	0f 1f 40 00          	nopl   0x0(%rax)
    2508:	0f be 7c 1c ff       	movsbl -0x1(%rsp,%rbx,1),%edi
    250d:	48 83 eb 01          	sub    $0x1,%rbx
    2511:	e8 1a fe ff ff       	call   2330 <put_char>
    2516:	85 db                	test   %ebx,%ebx
    2518:	75 ee                	jne    2508 <print_hex+0x68>
    251a:	48 83 c4 18          	add    $0x18,%rsp
    251e:	5b                   	pop    %rbx
    251f:	5d                   	pop    %rbp
    2520:	c3                   	ret    
    2521:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2528:	48 83 c4 18          	add    $0x18,%rsp
    252c:	bf 30 00 00 00       	mov    $0x30,%edi
    2531:	5b                   	pop    %rbx
    2532:	5d                   	pop    %rbp
    2533:	e9 f8 fd ff ff       	jmp    2330 <put_char>
    2538:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    253f:	00 

0000000000002540 <print_int>:
    2540:	53                   	push   %rbx
    2541:	48 83 ec 20          	sub    $0x20,%rsp
    2545:	48 85 ff             	test   %rdi,%rdi
    2548:	74 76                	je     25c0 <print_int+0x80>
    254a:	48 89 fb             	mov    %rdi,%rbx
    254d:	78 61                	js     25b0 <print_int+0x70>
    254f:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    2556:	cc cc cc 
    2559:	be 01 00 00 00       	mov    $0x1,%esi
    255e:	66 90                	xchg   %ax,%ax
    2560:	48 89 d8             	mov    %rbx,%rax
    2563:	89 f1                	mov    %esi,%ecx
    2565:	49 f7 e0             	mul    %r8
    2568:	48 c1 ea 03          	shr    $0x3,%rdx
    256c:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    2570:	48 01 c0             	add    %rax,%rax
    2573:	48 29 c3             	sub    %rax,%rbx
    2576:	8d 7b 30             	lea    0x30(%rbx),%edi
    2579:	48 89 d3             	mov    %rdx,%rbx
    257c:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    2581:	48 83 c6 01          	add    $0x1,%rsi
    2585:	48 85 d2             	test   %rdx,%rdx
    2588:	75 d6                	jne    2560 <print_int+0x20>
    258a:	48 63 d9             	movslq %ecx,%rbx
    258d:	eb 06                	jmp    2595 <print_int+0x55>
    258f:	90                   	nop
    2590:	0f b6 7c 1c 0b       	movzbl 0xb(%rsp,%rbx,1),%edi
    2595:	40 0f be ff          	movsbl %dil,%edi
    2599:	48 83 eb 01          	sub    $0x1,%rbx
    259d:	e8 8e fd ff ff       	call   2330 <put_char>
    25a2:	85 db                	test   %ebx,%ebx
    25a4:	75 ea                	jne    2590 <print_int+0x50>
    25a6:	48 83 c4 20          	add    $0x20,%rsp
    25aa:	5b                   	pop    %rbx
    25ab:	c3                   	ret    
    25ac:	0f 1f 40 00          	nopl   0x0(%rax)
    25b0:	bf 2d 00 00 00       	mov    $0x2d,%edi
    25b5:	48 f7 db             	neg    %rbx
    25b8:	e8 73 fd ff ff       	call   2330 <put_char>
    25bd:	eb 90                	jmp    254f <print_int+0xf>
    25bf:	90                   	nop
    25c0:	48 83 c4 20          	add    $0x20,%rsp
    25c4:	bf 30 00 00 00       	mov    $0x30,%edi
    25c9:	5b                   	pop    %rbx
    25ca:	e9 61 fd ff ff       	jmp    2330 <put_char>
    25cf:	90                   	nop

00000000000025d0 <set_print_color>:
    25d0:	c1 e6 04             	shl    $0x4,%esi
    25d3:	83 e7 0f             	and    $0xf,%edi
    25d6:	09 fe                	or     %edi,%esi
    25d8:	40 88 35 e6 0d 00 00 	mov    %sil,0xde6(%rip)        # 33c5 <current_color>
    25df:	c3                   	ret    

00000000000025e0 <reset_print_color>:
    25e0:	c6 05 de 0d 00 00 0f 	movb   $0xf,0xdde(%rip)        # 33c5 <current_color>
    25e7:	c3                   	ret    
    25e8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    25ef:	00 

00000000000025f0 <print_error>:
    25f0:	53                   	push   %rbx
    25f1:	48 89 fb             	mov    %rdi,%rbx
    25f4:	0f be 3f             	movsbl (%rdi),%edi
    25f7:	c6 05 c7 0d 00 00 0c 	movb   $0xc,0xdc7(%rip)        # 33c5 <current_color>
    25fe:	40 84 ff             	test   %dil,%dil
    2601:	74 17                	je     261a <print_error+0x2a>
    2603:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2608:	e8 23 fd ff ff       	call   2330 <put_char>
    260d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2611:	48 83 c3 01          	add    $0x1,%rbx
    2615:	40 84 ff             	test   %dil,%dil
    2618:	75 ee                	jne    2608 <print_error+0x18>
    261a:	c6 05 a4 0d 00 00 0f 	movb   $0xf,0xda4(%rip)        # 33c5 <current_color>
    2621:	5b                   	pop    %rbx
    2622:	c3                   	ret    
    2623:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    262a:	00 00 00 00 
    262e:	66 90                	xchg   %ax,%ax

0000000000002630 <print_success>:
    2630:	53                   	push   %rbx
    2631:	48 89 fb             	mov    %rdi,%rbx
    2634:	0f be 3f             	movsbl (%rdi),%edi
    2637:	c6 05 87 0d 00 00 0a 	movb   $0xa,0xd87(%rip)        # 33c5 <current_color>
    263e:	40 84 ff             	test   %dil,%dil
    2641:	74 17                	je     265a <print_success+0x2a>
    2643:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2648:	e8 e3 fc ff ff       	call   2330 <put_char>
    264d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2651:	48 83 c3 01          	add    $0x1,%rbx
    2655:	40 84 ff             	test   %dil,%dil
    2658:	75 ee                	jne    2648 <print_success+0x18>
    265a:	c6 05 64 0d 00 00 0f 	movb   $0xf,0xd64(%rip)        # 33c5 <current_color>
    2661:	5b                   	pop    %rbx
    2662:	c3                   	ret    
    2663:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    266a:	00 00 00 00 
    266e:	66 90                	xchg   %ax,%ax

0000000000002670 <print_info>:
    2670:	53                   	push   %rbx
    2671:	48 89 fb             	mov    %rdi,%rbx
    2674:	0f be 3f             	movsbl (%rdi),%edi
    2677:	c6 05 47 0d 00 00 0b 	movb   $0xb,0xd47(%rip)        # 33c5 <current_color>
    267e:	40 84 ff             	test   %dil,%dil
    2681:	74 17                	je     269a <print_info+0x2a>
    2683:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2688:	e8 a3 fc ff ff       	call   2330 <put_char>
    268d:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    2691:	48 83 c3 01          	add    $0x1,%rbx
    2695:	40 84 ff             	test   %dil,%dil
    2698:	75 ee                	jne    2688 <print_info+0x18>
    269a:	c6 05 24 0d 00 00 0f 	movb   $0xf,0xd24(%rip)        # 33c5 <current_color>
    26a1:	5b                   	pop    %rbx
    26a2:	c3                   	ret    
    26a3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    26aa:	00 00 00 00 
    26ae:	66 90                	xchg   %ax,%ax

00000000000026b0 <print_warning>:
    26b0:	53                   	push   %rbx
    26b1:	48 89 fb             	mov    %rdi,%rbx
    26b4:	0f be 3f             	movsbl (%rdi),%edi
    26b7:	c6 05 07 0d 00 00 0e 	movb   $0xe,0xd07(%rip)        # 33c5 <current_color>
    26be:	40 84 ff             	test   %dil,%dil
    26c1:	74 17                	je     26da <print_warning+0x2a>
    26c3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    26c8:	e8 63 fc ff ff       	call   2330 <put_char>
    26cd:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
    26d1:	48 83 c3 01          	add    $0x1,%rbx
    26d5:	40 84 ff             	test   %dil,%dil
    26d8:	75 ee                	jne    26c8 <print_warning+0x18>
    26da:	c6 05 e4 0c 00 00 0f 	movb   $0xf,0xce4(%rip)        # 33c5 <current_color>
    26e1:	5b                   	pop    %rbx
    26e2:	c3                   	ret    
    26e3:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    26ea:	00 00 00 
    26ed:	0f 1f 00             	nopl   (%rax)

00000000000026f0 <shell_init>:
    26f0:	55                   	push   %rbp
    26f1:	e8 fa 05 00 00       	call   2cf0 <timer_init>
    26f6:	bf 00 00 00 08       	mov    $0x8000000,%edi
    26fb:	e8 e0 f7 ff ff       	call   1ee0 <init_phy_mem_map>
    2700:	e8 fb f5 ff ff       	call   1d00 <kmalloc_init>
    2705:	bf 75 30 00 00       	mov    $0x3075,%edi
    270a:	e8 61 fd ff ff       	call   2470 <print_string>
    270f:	bf c0 d4 01 00       	mov    $0x1d4c0,%edi
    2714:	e8 37 f6 ff ff       	call   1d50 <kmalloc>
    2719:	bf 8f 30 00 00       	mov    $0x308f,%edi
    271e:	48 89 c5             	mov    %rax,%rbp
    2721:	e8 4a fd ff ff       	call   2470 <print_string>
    2726:	48 89 ef             	mov    %rbp,%rdi
    2729:	e8 72 fd ff ff       	call   24a0 <print_hex>
    272e:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    2733:	e8 38 fd ff ff       	call   2470 <print_string>
    2738:	48 89 ef             	mov    %rbp,%rdi
    273b:	e8 20 f7 ff ff       	call   1e60 <kfree>
    2740:	bf ac 30 00 00       	mov    $0x30ac,%edi
    2745:	e8 26 fd ff ff       	call   2470 <print_string>
    274a:	bf c7 30 00 00       	mov    $0x30c7,%edi
    274f:	5d                   	pop    %rbp
    2750:	e9 1b fd ff ff       	jmp    2470 <print_string>
    2755:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    275c:	00 00 00 00 

0000000000002760 <execute_command>:
    2760:	48 63 05 b9 1c 00 00 	movslq 0x1cb9(%rip),%rax        # 4420 <cmd_index>
    2767:	85 c0                	test   %eax,%eax
    2769:	75 05                	jne    2770 <execute_command+0x10>
    276b:	c3                   	ret    
    276c:	0f 1f 40 00          	nopl   0x0(%rax)
    2770:	41 54                	push   %r12
    2772:	be d0 30 00 00       	mov    $0x30d0,%esi
    2777:	55                   	push   %rbp
    2778:	48 89 fd             	mov    %rdi,%rbp
    277b:	53                   	push   %rbx
    277c:	48 83 ec 70          	sub    $0x70,%rsp
    2780:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    2784:	e8 77 04 00 00       	call   2c00 <strcmp>
    2789:	85 c0                	test   %eax,%eax
    278b:	75 43                	jne    27d0 <execute_command+0x70>
    278d:	bf d5 30 00 00       	mov    $0x30d5,%edi
    2792:	e8 d9 fc ff ff       	call   2470 <print_string>
    2797:	bf ea 30 00 00       	mov    $0x30ea,%edi
    279c:	e8 cf fc ff ff       	call   2470 <print_string>
    27a1:	bf 07 31 00 00       	mov    $0x3107,%edi
    27a6:	e8 c5 fc ff ff       	call   2470 <print_string>
    27ab:	bf 38 32 00 00       	mov    $0x3238,%edi
    27b0:	e8 bb fc ff ff       	call   2470 <print_string>
    27b5:	c7 05 61 1c 00 00 00 	movl   $0x0,0x1c61(%rip)        # 4420 <cmd_index>
    27bc:	00 00 00 
    27bf:	48 83 c4 70          	add    $0x70,%rsp
    27c3:	5b                   	pop    %rbx
    27c4:	5d                   	pop    %rbp
    27c5:	41 5c                	pop    %r12
    27c7:	c3                   	ret    
    27c8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    27cf:	00 
    27d0:	be 23 31 00 00       	mov    $0x3123,%esi
    27d5:	48 89 ef             	mov    %rbp,%rdi
    27d8:	e8 23 04 00 00       	call   2c00 <strcmp>
    27dd:	85 c0                	test   %eax,%eax
    27df:	74 1f                	je     2800 <execute_command+0xa0>
    27e1:	be 29 31 00 00       	mov    $0x3129,%esi
    27e6:	48 89 ef             	mov    %rbp,%rdi
    27e9:	e8 12 04 00 00       	call   2c00 <strcmp>
    27ee:	85 c0                	test   %eax,%eax
    27f0:	75 1e                	jne    2810 <execute_command+0xb0>
    27f2:	bf 58 32 00 00       	mov    $0x3258,%edi
    27f7:	e8 34 fe ff ff       	call   2630 <print_success>
    27fc:	eb b7                	jmp    27b5 <execute_command+0x55>
    27fe:	66 90                	xchg   %ax,%ax
    2800:	e8 db fa ff ff       	call   22e0 <clear_screen>
    2805:	eb ae                	jmp    27b5 <execute_command+0x55>
    2807:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    280e:	00 00 
    2810:	be 2f 31 00 00       	mov    $0x312f,%esi
    2815:	48 89 ef             	mov    %rbp,%rdi
    2818:	e8 e3 03 00 00       	call   2c00 <strcmp>
    281d:	85 c0                	test   %eax,%eax
    281f:	74 4f                	je     2870 <execute_command+0x110>
    2821:	be 51 31 00 00       	mov    $0x3151,%esi
    2826:	48 89 ef             	mov    %rbp,%rdi
    2829:	e8 d2 03 00 00       	call   2c00 <strcmp>
    282e:	85 c0                	test   %eax,%eax
    2830:	75 7e                	jne    28b0 <execute_command+0x150>
    2832:	0f a2                	cpuid  
    2834:	bf 59 31 00 00       	mov    $0x3159,%edi
    2839:	89 54 24 42          	mov    %edx,0x42(%rsp)
    283d:	89 4c 24 46          	mov    %ecx,0x46(%rsp)
    2841:	89 5c 24 3e          	mov    %ebx,0x3e(%rsp)
    2845:	c6 44 24 4a 00       	movb   $0x0,0x4a(%rsp)
    284a:	e8 21 fc ff ff       	call   2470 <print_string>
    284f:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2854:	e8 17 fc ff ff       	call   2470 <print_string>
    2859:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    285e:	e8 0d fc ff ff       	call   2470 <print_string>
    2863:	e9 4d ff ff ff       	jmp    27b5 <execute_command+0x55>
    2868:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    286f:	00 
    2870:	48 8b 2d 89 1b 00 00 	mov    0x1b89(%rip),%rbp        # 4400 <system_ticks>
    2877:	bf 36 31 00 00       	mov    $0x3136,%edi
    287c:	e8 ef fb ff ff       	call   2470 <print_string>
    2881:	48 ba 8f e3 38 8e e3 	movabs $0xe38e38e38e38e38f,%rdx
    2888:	38 8e e3 
    288b:	48 89 e8             	mov    %rbp,%rax
    288e:	48 f7 e2             	mul    %rdx
    2891:	48 c1 ea 04          	shr    $0x4,%rdx
    2895:	48 89 d7             	mov    %rdx,%rdi
    2898:	e8 a3 fc ff ff       	call   2540 <print_int>
    289d:	bf 46 31 00 00       	mov    $0x3146,%edi
    28a2:	e8 c9 fb ff ff       	call   2470 <print_string>
    28a7:	e9 09 ff ff ff       	jmp    27b5 <execute_command+0x55>
    28ac:	0f 1f 40 00          	nopl   0x0(%rax)
    28b0:	ba 05 00 00 00       	mov    $0x5,%edx
    28b5:	be 66 31 00 00       	mov    $0x3166,%esi
    28ba:	48 89 ef             	mov    %rbp,%rdi
    28bd:	e8 6e 03 00 00       	call   2c30 <strncmp>
    28c2:	85 c0                	test   %eax,%eax
    28c4:	75 18                	jne    28de <execute_command+0x17e>
    28c6:	48 8d 7d 05          	lea    0x5(%rbp),%rdi
    28ca:	e8 a1 fb ff ff       	call   2470 <print_string>
    28cf:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    28d4:	e8 97 fb ff ff       	call   2470 <print_string>
    28d9:	e9 d7 fe ff ff       	jmp    27b5 <execute_command+0x55>
    28de:	be 6c 31 00 00       	mov    $0x316c,%esi
    28e3:	48 89 ef             	mov    %rbp,%rdi
    28e6:	e8 15 03 00 00       	call   2c00 <strcmp>
    28eb:	85 c0                	test   %eax,%eax
    28ed:	75 0c                	jne    28fb <execute_command+0x19b>
    28ef:	bf 72 31 00 00       	mov    $0x3172,%edi
    28f4:	e8 77 fb ff ff       	call   2470 <print_string>
    28f9:	0f 0b                	ud2    
    28fb:	be 8e 31 00 00       	mov    $0x318e,%esi
    2900:	48 89 ef             	mov    %rbp,%rdi
    2903:	e8 f8 02 00 00       	call   2c00 <strcmp>
    2908:	85 c0                	test   %eax,%eax
    290a:	0f 85 8f 00 00 00    	jne    299f <execute_command+0x23f>
    2910:	ba 0a 00 00 00       	mov    $0xa,%edx
    2915:	be 41 00 00 00       	mov    $0x41,%esi
    291a:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    291f:	e8 5c 03 00 00       	call   2c80 <memset>
    2924:	bf 98 32 00 00       	mov    $0x3298,%edi
    2929:	c6 44 24 16 00       	movb   $0x0,0x16(%rsp)
    292e:	e8 3d fb ff ff       	call   2470 <print_string>
    2933:	48 8d 7c 24 0c       	lea    0xc(%rsp),%rdi
    2938:	e8 33 fb ff ff       	call   2470 <print_string>
    293d:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    2942:	e8 29 fb ff ff       	call   2470 <print_string>
    2947:	be 96 31 00 00       	mov    $0x3196,%esi
    294c:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2951:	e8 7a 03 00 00       	call   2cd0 <strcpy>
    2956:	bf a4 31 00 00       	mov    $0x31a4,%edi
    295b:	e8 10 fb ff ff       	call   2470 <print_string>
    2960:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2965:	e8 06 fb ff ff       	call   2470 <print_string>
    296a:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    296f:	e8 fc fa ff ff       	call   2470 <print_string>
    2974:	bf c0 32 00 00       	mov    $0x32c0,%edi
    2979:	e8 f2 fa ff ff       	call   2470 <print_string>
    297e:	48 8d 7c 24 3e       	lea    0x3e(%rsp),%rdi
    2983:	e8 48 02 00 00       	call   2bd0 <strlen>
    2988:	48 89 c7             	mov    %rax,%rdi
    298b:	e8 b0 fb ff ff       	call   2540 <print_int>
    2990:	bf b2 31 00 00       	mov    $0x31b2,%edi
    2995:	e8 d6 fa ff ff       	call   2470 <print_string>
    299a:	e9 16 fe ff ff       	jmp    27b5 <execute_command+0x55>
    299f:	be c2 31 00 00       	mov    $0x31c2,%esi
    29a4:	48 89 ef             	mov    %rbp,%rdi
    29a7:	e8 54 02 00 00       	call   2c00 <strcmp>
    29ac:	85 c0                	test   %eax,%eax
    29ae:	75 20                	jne    29d0 <execute_command+0x270>
    29b0:	bf e0 32 00 00       	mov    $0x32e0,%edi
    29b5:	e8 b6 fa ff ff       	call   2470 <print_string>
    29ba:	bf 08 33 00 00       	mov    $0x3308,%edi
    29bf:	8b 04 25 ff ff ff ff 	mov    0xffffffffffffffff,%eax
    29c6:	e8 a5 fa ff ff       	call   2470 <print_string>
    29cb:	e9 e5 fd ff ff       	jmp    27b5 <execute_command+0x55>
    29d0:	be c9 31 00 00       	mov    $0x31c9,%esi
    29d5:	48 89 ef             	mov    %rbp,%rdi
    29d8:	e8 23 02 00 00       	call   2c00 <strcmp>
    29dd:	85 c0                	test   %eax,%eax
    29df:	75 22                	jne    2a03 <execute_command+0x2a3>
    29e1:	8b 04 25 00 80 00 00 	mov    0x8000,%eax
    29e8:	83 e8 01             	sub    $0x1,%eax
    29eb:	83 f8 12             	cmp    $0x12,%eax
    29ee:	0f 87 cb 00 00 00    	ja     2abf <execute_command+0x35f>
    29f4:	bf 28 33 00 00       	mov    $0x3328,%edi
    29f9:	e8 32 fc ff ff       	call   2630 <print_success>
    29fe:	e9 b2 fd ff ff       	jmp    27b5 <execute_command+0x55>
    2a03:	be d1 31 00 00       	mov    $0x31d1,%esi
    2a08:	48 89 ef             	mov    %rbp,%rdi
    2a0b:	e8 f0 01 00 00       	call   2c00 <strcmp>
    2a10:	85 c0                	test   %eax,%eax
    2a12:	0f 85 b6 00 00 00    	jne    2ace <execute_command+0x36e>
    2a18:	8b 1c 25 00 80 00 00 	mov    0x8000,%ebx
    2a1f:	bf d9 31 00 00       	mov    $0x31d9,%edi
    2a24:	e8 47 fa ff ff       	call   2470 <print_string>
    2a29:	85 db                	test   %ebx,%ebx
    2a2b:	0f 84 be 00 00 00    	je     2aef <execute_command+0x38f>
    2a31:	8d 43 ff             	lea    -0x1(%rbx),%eax
    2a34:	31 ed                	xor    %ebp,%ebp
    2a36:	bb 04 80 00 00       	mov    $0x8004,%ebx
    2a3b:	48 6b c0 14          	imul   $0x14,%rax,%rax
    2a3f:	4c 8d a0 18 80 00 00 	lea    0x8018(%rax),%r12
    2a46:	bf f6 31 00 00       	mov    $0x31f6,%edi
    2a4b:	e8 20 fa ff ff       	call   2470 <print_string>
    2a50:	48 8b 3b             	mov    (%rbx),%rdi
    2a53:	e8 48 fa ff ff       	call   24a0 <print_hex>
    2a58:	bf 05 32 00 00       	mov    $0x3205,%edi
    2a5d:	e8 0e fa ff ff       	call   2470 <print_string>
    2a62:	48 8b 7b 08          	mov    0x8(%rbx),%rdi
    2a66:	e8 35 fa ff ff       	call   24a0 <print_hex>
    2a6b:	bf 10 32 00 00       	mov    $0x3210,%edi
    2a70:	e8 fb f9 ff ff       	call   2470 <print_string>
    2a75:	8b 7b 10             	mov    0x10(%rbx),%edi
    2a78:	e8 c3 fa ff ff       	call   2540 <print_int>
    2a7d:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    2a82:	e8 e9 f9 ff ff       	call   2470 <print_string>
    2a87:	83 7b 10 01          	cmpl   $0x1,0x10(%rbx)
    2a8b:	75 04                	jne    2a91 <execute_command+0x331>
    2a8d:	48 03 6b 08          	add    0x8(%rbx),%rbp
    2a91:	48 83 c3 14          	add    $0x14,%rbx
    2a95:	4c 39 e3             	cmp    %r12,%rbx
    2a98:	75 ac                	jne    2a46 <execute_command+0x2e6>
    2a9a:	bf 78 33 00 00       	mov    $0x3378,%edi
    2a9f:	e8 cc f9 ff ff       	call   2470 <print_string>
    2aa4:	48 89 ef             	mov    %rbp,%rdi
    2aa7:	48 c1 ef 14          	shr    $0x14,%rdi
    2aab:	e8 90 fa ff ff       	call   2540 <print_int>
    2ab0:	bf 19 32 00 00       	mov    $0x3219,%edi
    2ab5:	e8 b6 f9 ff ff       	call   2470 <print_string>
    2aba:	e9 f6 fc ff ff       	jmp    27b5 <execute_command+0x55>
    2abf:	bf 50 33 00 00       	mov    $0x3350,%edi
    2ac4:	e8 27 fb ff ff       	call   25f0 <print_error>
    2ac9:	e9 e7 fc ff ff       	jmp    27b5 <execute_command+0x55>
    2ace:	bf 1e 32 00 00       	mov    $0x321e,%edi
    2ad3:	e8 18 fb ff ff       	call   25f0 <print_error>
    2ad8:	48 89 ef             	mov    %rbp,%rdi
    2adb:	e8 10 fb ff ff       	call   25f0 <print_error>
    2ae0:	bf d9 2f 00 00       	mov    $0x2fd9,%edi
    2ae5:	e8 06 fb ff ff       	call   25f0 <print_error>
    2aea:	e9 c6 fc ff ff       	jmp    27b5 <execute_command+0x55>
    2aef:	31 ed                	xor    %ebp,%ebp
    2af1:	eb a7                	jmp    2a9a <execute_command+0x33a>
    2af3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2afa:	00 00 00 00 
    2afe:	66 90                	xchg   %ax,%ax

0000000000002b00 <shell_take_char>:
    2b00:	48 83 ec 08          	sub    $0x8,%rsp
    2b04:	40 80 ff 0a          	cmp    $0xa,%dil
    2b08:	74 76                	je     2b80 <shell_take_char+0x80>
    2b0a:	8b 05 10 19 00 00    	mov    0x1910(%rip),%eax        # 4420 <cmd_index>
    2b10:	40 80 ff 08          	cmp    $0x8,%dil
    2b14:	74 4a                	je     2b60 <shell_take_char+0x60>
    2b16:	40 80 ff 1b          	cmp    $0x1b,%dil
    2b1a:	74 2d                	je     2b49 <shell_take_char+0x49>
    2b1c:	3d fe 00 00 00       	cmp    $0xfe,%eax
    2b21:	0f 8e 89 00 00 00    	jle    2bb0 <shell_take_char+0xb0>
    2b27:	48 83 c4 08          	add    $0x8,%rsp
    2b2b:	c3                   	ret    
    2b2c:	0f 1f 40 00          	nopl   0x0(%rax)
    2b30:	bf 08 00 00 00       	mov    $0x8,%edi
    2b35:	e8 f6 f7 ff ff       	call   2330 <put_char>
    2b3a:	8b 05 e0 18 00 00    	mov    0x18e0(%rip),%eax        # 4420 <cmd_index>
    2b40:	83 e8 01             	sub    $0x1,%eax
    2b43:	89 05 d7 18 00 00    	mov    %eax,0x18d7(%rip)        # 4420 <cmd_index>
    2b49:	85 c0                	test   %eax,%eax
    2b4b:	7f e3                	jg     2b30 <shell_take_char+0x30>
    2b4d:	c6 05 ec 18 00 00 00 	movb   $0x0,0x18ec(%rip)        # 4440 <cmd_buffer>
    2b54:	48 83 c4 08          	add    $0x8,%rsp
    2b58:	c3                   	ret    
    2b59:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2b60:	85 c0                	test   %eax,%eax
    2b62:	7e c3                	jle    2b27 <shell_take_char+0x27>
    2b64:	83 e8 01             	sub    $0x1,%eax
    2b67:	bf 08 00 00 00       	mov    $0x8,%edi
    2b6c:	89 05 ae 18 00 00    	mov    %eax,0x18ae(%rip)        # 4420 <cmd_index>
    2b72:	48 83 c4 08          	add    $0x8,%rsp
    2b76:	e9 b5 f7 ff ff       	jmp    2330 <put_char>
    2b7b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2b80:	bf 0a 00 00 00       	mov    $0xa,%edi
    2b85:	e8 a6 f7 ff ff       	call   2330 <put_char>
    2b8a:	48 63 05 8f 18 00 00 	movslq 0x188f(%rip),%rax        # 4420 <cmd_index>
    2b91:	bf 40 44 00 00       	mov    $0x4440,%edi
    2b96:	c6 80 40 44 00 00 00 	movb   $0x0,0x4440(%rax)
    2b9d:	e8 be fb ff ff       	call   2760 <execute_command>
    2ba2:	bf c8 30 00 00       	mov    $0x30c8,%edi
    2ba7:	48 83 c4 08          	add    $0x8,%rsp
    2bab:	e9 c0 f8 ff ff       	jmp    2470 <print_string>
    2bb0:	48 63 d0             	movslq %eax,%rdx
    2bb3:	83 c0 01             	add    $0x1,%eax
    2bb6:	40 88 ba 40 44 00 00 	mov    %dil,0x4440(%rdx)
    2bbd:	40 0f be ff          	movsbl %dil,%edi
    2bc1:	89 05 59 18 00 00    	mov    %eax,0x1859(%rip)        # 4420 <cmd_index>
    2bc7:	48 83 c4 08          	add    $0x8,%rsp
    2bcb:	e9 60 f7 ff ff       	jmp    2330 <put_char>

0000000000002bd0 <strlen>:
    2bd0:	31 c0                	xor    %eax,%eax
    2bd2:	80 3f 00             	cmpb   $0x0,(%rdi)
    2bd5:	74 19                	je     2bf0 <strlen+0x20>
    2bd7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    2bde:	00 00 
    2be0:	48 83 c0 01          	add    $0x1,%rax
    2be4:	80 3c 07 00          	cmpb   $0x0,(%rdi,%rax,1)
    2be8:	75 f6                	jne    2be0 <strlen+0x10>
    2bea:	c3                   	ret    
    2beb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    2bf0:	c3                   	ret    
    2bf1:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2bf8:	00 00 00 00 
    2bfc:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000002c00 <strcmp>:
    2c00:	eb 12                	jmp    2c14 <strcmp+0x14>
    2c02:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2c08:	38 06                	cmp    %al,(%rsi)
    2c0a:	75 11                	jne    2c1d <strcmp+0x1d>
    2c0c:	48 83 c7 01          	add    $0x1,%rdi
    2c10:	48 83 c6 01          	add    $0x1,%rsi
    2c14:	0f b6 07             	movzbl (%rdi),%eax
    2c17:	84 c0                	test   %al,%al
    2c19:	75 ed                	jne    2c08 <strcmp+0x8>
    2c1b:	31 c0                	xor    %eax,%eax
    2c1d:	0f b6 16             	movzbl (%rsi),%edx
    2c20:	29 d0                	sub    %edx,%eax
    2c22:	c3                   	ret    
    2c23:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2c2a:	00 00 00 00 
    2c2e:	66 90                	xchg   %ax,%ax

0000000000002c30 <strncmp>:
    2c30:	85 d2                	test   %edx,%edx
    2c32:	7f 1d                	jg     2c51 <strncmp+0x21>
    2c34:	eb 35                	jmp    2c6b <strncmp+0x3b>
    2c36:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    2c3d:	00 00 00 
    2c40:	3a 06                	cmp    (%rsi),%al
    2c42:	75 14                	jne    2c58 <strncmp+0x28>
    2c44:	48 83 c7 01          	add    $0x1,%rdi
    2c48:	48 83 c6 01          	add    $0x1,%rsi
    2c4c:	83 ea 01             	sub    $0x1,%edx
    2c4f:	74 17                	je     2c68 <strncmp+0x38>
    2c51:	0f b6 07             	movzbl (%rdi),%eax
    2c54:	84 c0                	test   %al,%al
    2c56:	75 e8                	jne    2c40 <strncmp+0x10>
    2c58:	0f b6 07             	movzbl (%rdi),%eax
    2c5b:	0f b6 16             	movzbl (%rsi),%edx
    2c5e:	29 d0                	sub    %edx,%eax
    2c60:	c3                   	ret    
    2c61:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2c68:	31 c0                	xor    %eax,%eax
    2c6a:	c3                   	ret    
    2c6b:	b8 00 00 00 00       	mov    $0x0,%eax
    2c70:	75 e6                	jne    2c58 <strncmp+0x28>
    2c72:	c3                   	ret    
    2c73:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2c7a:	00 00 00 00 
    2c7e:	66 90                	xchg   %ax,%ax

0000000000002c80 <memset>:
    2c80:	48 89 f8             	mov    %rdi,%rax
    2c83:	4c 8d 04 17          	lea    (%rdi,%rdx,1),%r8
    2c87:	48 89 f9             	mov    %rdi,%rcx
    2c8a:	48 85 d2             	test   %rdx,%rdx
    2c8d:	74 0e                	je     2c9d <memset+0x1d>
    2c8f:	90                   	nop
    2c90:	48 83 c1 01          	add    $0x1,%rcx
    2c94:	40 88 71 ff          	mov    %sil,-0x1(%rcx)
    2c98:	4c 39 c1             	cmp    %r8,%rcx
    2c9b:	75 f3                	jne    2c90 <memset+0x10>
    2c9d:	c3                   	ret    
    2c9e:	66 90                	xchg   %ax,%ax

0000000000002ca0 <memcpy>:
    2ca0:	48 89 f8             	mov    %rdi,%rax
    2ca3:	48 85 d2             	test   %rdx,%rdx
    2ca6:	74 1a                	je     2cc2 <memcpy+0x22>
    2ca8:	31 c9                	xor    %ecx,%ecx
    2caa:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2cb0:	44 0f b6 04 0e       	movzbl (%rsi,%rcx,1),%r8d
    2cb5:	44 88 04 08          	mov    %r8b,(%rax,%rcx,1)
    2cb9:	48 83 c1 01          	add    $0x1,%rcx
    2cbd:	48 39 d1             	cmp    %rdx,%rcx
    2cc0:	75 ee                	jne    2cb0 <memcpy+0x10>
    2cc2:	c3                   	ret    
    2cc3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    2cca:	00 00 00 00 
    2cce:	66 90                	xchg   %ax,%ax

0000000000002cd0 <strcpy>:
    2cd0:	48 89 f8             	mov    %rdi,%rax
    2cd3:	31 d2                	xor    %edx,%edx
    2cd5:	0f 1f 00             	nopl   (%rax)
    2cd8:	0f b6 0c 16          	movzbl (%rsi,%rdx,1),%ecx
    2cdc:	88 0c 10             	mov    %cl,(%rax,%rdx,1)
    2cdf:	48 83 c2 01          	add    $0x1,%rdx
    2ce3:	84 c9                	test   %cl,%cl
    2ce5:	75 f1                	jne    2cd8 <strcpy+0x8>
    2ce7:	c3                   	ret    
    2ce8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    2cef:	00 

0000000000002cf0 <timer_init>:
    2cf0:	b8 36 00 00 00       	mov    $0x36,%eax
    2cf5:	e6 43                	out    %al,$0x43
    2cf7:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2cfc:	e6 40                	out    %al,$0x40
    2cfe:	b8 2e 00 00 00       	mov    $0x2e,%eax
    2d03:	e6 40                	out    %al,$0x40
    2d05:	bf 98 33 00 00       	mov    $0x3398,%edi
    2d0a:	e9 61 f7 ff ff       	jmp    2470 <print_string>
