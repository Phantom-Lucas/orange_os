
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	48 83 ec 08          	sub    $0x8,%rsp
    1906:	e8 05 03 00 00       	call   1c10 <clear_screen>
    190b:	bf 52 20 00 00       	mov    $0x2052,%edi
    1910:	e8 8b 04 00 00       	call   1da0 <print_string>
    1915:	e8 36 01 00 00       	call   1a50 <idt_init>
    191a:	e8 41 02 00 00       	call   1b60 <pic_init>
    191f:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    1924:	e6 21                	out    %al,$0x21
    1926:	bf 70 20 00 00       	mov    $0x2070,%edi
    192b:	e8 70 04 00 00       	call   1da0 <print_string>
    1930:	fb                   	sti    
    1931:	bf a0 20 00 00       	mov    $0x20a0,%edi
    1936:	e8 65 04 00 00       	call   1da0 <print_string>
    193b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1940:	f4                   	hlt    
    1941:	eb fd                	jmp    1940 <kernel_main+0x40>
    1943:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    194a:	00 00 00 
    194d:	0f 1f 00             	nopl   (%rax)

0000000000001950 <isr32_timer>:
    1950:	50                   	push   %rax
    1951:	b8 20 00 00 00       	mov    $0x20,%eax
    1956:	e6 20                	out    %al,$0x20
    1958:	58                   	pop    %rax
    1959:	48 cf                	iretq  
    195b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001960 <isr0_divide_by_zero>:
    1960:	41 53                	push   %r11
    1962:	41 52                	push   %r10
    1964:	41 51                	push   %r9
    1966:	41 50                	push   %r8
    1968:	57                   	push   %rdi
    1969:	bf 80 1f 00 00       	mov    $0x1f80,%edi
    196e:	56                   	push   %rsi
    196f:	51                   	push   %rcx
    1970:	52                   	push   %rdx
    1971:	50                   	push   %rax
    1972:	fc                   	cld    
    1973:	e8 28 04 00 00       	call   1da0 <print_string>
    1978:	bf b8 1f 00 00       	mov    $0x1fb8,%edi
    197d:	e8 1e 04 00 00       	call   1da0 <print_string>
    1982:	bf e8 1f 00 00       	mov    $0x1fe8,%edi
    1987:	e8 14 04 00 00       	call   1da0 <print_string>
    198c:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    1991:	e8 3a 04 00 00       	call   1dd0 <print_hex>
    1996:	bf 6a 20 00 00       	mov    $0x206a,%edi
    199b:	e8 00 04 00 00       	call   1da0 <print_string>
    19a0:	bf 10 20 00 00       	mov    $0x2010,%edi
    19a5:	e8 f6 03 00 00       	call   1da0 <print_string>
    19aa:	bf 42 20 00 00       	mov    $0x2042,%edi
    19af:	e8 ec 03 00 00       	call   1da0 <print_string>
    19b4:	0f 1f 40 00          	nopl   0x0(%rax)
    19b8:	f4                   	hlt    
    19b9:	eb fd                	jmp    19b8 <isr0_divide_by_zero+0x58>
    19bb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

00000000000019c0 <isr33_keyboard>:
    19c0:	41 53                	push   %r11
    19c2:	41 52                	push   %r10
    19c4:	41 51                	push   %r9
    19c6:	41 50                	push   %r8
    19c8:	57                   	push   %rdi
    19c9:	56                   	push   %rsi
    19ca:	51                   	push   %rcx
    19cb:	52                   	push   %rdx
    19cc:	50                   	push   %rax
    19cd:	e4 60                	in     $0x60,%al
    19cf:	84 c0                	test   %al,%al
    19d1:	78 0f                	js     19e2 <isr33_keyboard+0x22>
    19d3:	0f b6 c0             	movzbl %al,%eax
    19d6:	0f be b8 00 1f 00 00 	movsbl 0x1f00(%rax),%edi
    19dd:	40 84 ff             	test   %dil,%dil
    19e0:	75 1e                	jne    1a00 <isr33_keyboard+0x40>
    19e2:	b8 20 00 00 00       	mov    $0x20,%eax
    19e7:	e6 20                	out    %al,$0x20
    19e9:	58                   	pop    %rax
    19ea:	5a                   	pop    %rdx
    19eb:	59                   	pop    %rcx
    19ec:	5e                   	pop    %rsi
    19ed:	5f                   	pop    %rdi
    19ee:	41 58                	pop    %r8
    19f0:	41 59                	pop    %r9
    19f2:	41 5a                	pop    %r10
    19f4:	41 5b                	pop    %r11
    19f6:	48 cf                	iretq  
    19f8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    19ff:	00 
    1a00:	fc                   	cld    
    1a01:	e8 5a 02 00 00       	call   1c60 <put_char>
    1a06:	eb da                	jmp    19e2 <isr33_keyboard+0x22>
    1a08:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1a0f:	00 

0000000000001a10 <set_idt_gate>:
    1a10:	48 63 ff             	movslq %edi,%rdi
    1a13:	48 89 f2             	mov    %rsi,%rdx
    1a16:	48 c1 e7 04          	shl    $0x4,%rdi
    1a1a:	48 c1 ea 10          	shr    $0x10,%rdx
    1a1e:	66 89 b7 40 21 00 00 	mov    %si,0x2140(%rdi)
    1a25:	48 c1 ee 20          	shr    $0x20,%rsi
    1a29:	c7 87 42 21 00 00 08 	movl   $0x8e000008,0x2142(%rdi)
    1a30:	00 00 8e 
    1a33:	66 89 97 46 21 00 00 	mov    %dx,0x2146(%rdi)
    1a3a:	89 b7 48 21 00 00    	mov    %esi,0x2148(%rdi)
    1a40:	c7 87 4c 21 00 00 00 	movl   $0x0,0x214c(%rdi)
    1a47:	00 00 00 
    1a4a:	c3                   	ret    
    1a4b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001a50 <idt_init>:
    1a50:	b8 40 21 00 00       	mov    $0x2140,%eax
    1a55:	0f 1f 00             	nopl   (%rax)
    1a58:	31 d2                	xor    %edx,%edx
    1a5a:	b9 08 00 00 00       	mov    $0x8,%ecx
    1a5f:	31 f6                	xor    %esi,%esi
    1a61:	c6 40 04 00          	movb   $0x0,0x4(%rax)
    1a65:	66 89 10             	mov    %dx,(%rax)
    1a68:	48 83 c0 10          	add    $0x10,%rax
    1a6c:	66 89 48 f2          	mov    %cx,-0xe(%rax)
    1a70:	c6 40 f5 8e          	movb   $0x8e,-0xb(%rax)
    1a74:	66 89 70 f6          	mov    %si,-0xa(%rax)
    1a78:	c7 40 f8 00 00 00 00 	movl   $0x0,-0x8(%rax)
    1a7f:	c7 40 fc 00 00 00 00 	movl   $0x0,-0x4(%rax)
    1a86:	48 3d 40 31 00 00    	cmp    $0x3140,%rax
    1a8c:	75 ca                	jne    1a58 <idt_init+0x8>
    1a8e:	c7 05 aa 06 00 00 08 	movl   $0x8e000008,0x6aa(%rip)        # 2142 <idt+0x2>
    1a95:	00 00 8e 
    1a98:	b8 60 19 00 00       	mov    $0x1960,%eax
    1a9d:	66 89 05 9c 06 00 00 	mov    %ax,0x69c(%rip)        # 2140 <idt>
    1aa4:	48 89 c2             	mov    %rax,%rdx
    1aa7:	48 c1 e8 20          	shr    $0x20,%rax
    1aab:	48 c1 ea 10          	shr    $0x10,%rdx
    1aaf:	89 05 93 06 00 00    	mov    %eax,0x693(%rip)        # 2148 <idt+0x8>
    1ab5:	b8 50 19 00 00       	mov    $0x1950,%eax
    1aba:	66 89 15 85 06 00 00 	mov    %dx,0x685(%rip)        # 2146 <idt+0x6>
    1ac1:	48 89 c2             	mov    %rax,%rdx
    1ac4:	66 89 05 75 08 00 00 	mov    %ax,0x875(%rip)        # 2340 <idt+0x200>
    1acb:	48 c1 e8 20          	shr    $0x20,%rax
    1acf:	48 c1 ea 10          	shr    $0x10,%rdx
    1ad3:	89 05 6f 08 00 00    	mov    %eax,0x86f(%rip)        # 2348 <idt+0x208>
    1ad9:	b8 c0 19 00 00       	mov    $0x19c0,%eax
    1ade:	66 89 15 61 08 00 00 	mov    %dx,0x861(%rip)        # 2346 <idt+0x206>
    1ae5:	48 89 c2             	mov    %rax,%rdx
    1ae8:	66 89 05 61 08 00 00 	mov    %ax,0x861(%rip)        # 2350 <idt+0x210>
    1aef:	48 c1 e8 20          	shr    $0x20,%rax
    1af3:	48 c1 ea 10          	shr    $0x10,%rdx
    1af7:	89 05 5b 08 00 00    	mov    %eax,0x85b(%rip)        # 2358 <idt+0x218>
    1afd:	b8 ff 0f 00 00       	mov    $0xfff,%eax
    1b02:	c7 05 40 06 00 00 00 	movl   $0x0,0x640(%rip)        # 214c <idt+0xc>
    1b09:	00 00 00 
    1b0c:	c7 05 2c 08 00 00 08 	movl   $0x8e000008,0x82c(%rip)        # 2342 <idt+0x202>
    1b13:	00 00 8e 
    1b16:	c7 05 2c 08 00 00 00 	movl   $0x0,0x82c(%rip)        # 234c <idt+0x20c>
    1b1d:	00 00 00 
    1b20:	c7 05 28 08 00 00 08 	movl   $0x8e000008,0x828(%rip)        # 2352 <idt+0x212>
    1b27:	00 00 8e 
    1b2a:	66 89 15 25 08 00 00 	mov    %dx,0x825(%rip)        # 2356 <idt+0x216>
    1b31:	c7 05 21 08 00 00 00 	movl   $0x0,0x821(%rip)        # 235c <idt+0x21c>
    1b38:	00 00 00 
    1b3b:	66 89 05 de 05 00 00 	mov    %ax,0x5de(%rip)        # 2120 <idtr_reg>
    1b42:	48 c7 05 d5 05 00 00 	movq   $0x2140,0x5d5(%rip)        # 2122 <idtr_reg+0x2>
    1b49:	40 21 00 00 
    1b4d:	0f 01 1d cc 05 00 00 	lidt   0x5cc(%rip)        # 2120 <idtr_reg>
    1b54:	c3                   	ret    
    1b55:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1b5c:	00 00 00 
    1b5f:	90                   	nop

0000000000001b60 <pic_init>:
    1b60:	b8 11 00 00 00       	mov    $0x11,%eax
    1b65:	e6 20                	out    %al,$0x20
    1b67:	e6 a0                	out    %al,$0xa0
    1b69:	b8 20 00 00 00       	mov    $0x20,%eax
    1b6e:	e6 21                	out    %al,$0x21
    1b70:	b8 28 00 00 00       	mov    $0x28,%eax
    1b75:	e6 a1                	out    %al,$0xa1
    1b77:	b8 04 00 00 00       	mov    $0x4,%eax
    1b7c:	e6 21                	out    %al,$0x21
    1b7e:	b8 02 00 00 00       	mov    $0x2,%eax
    1b83:	e6 a1                	out    %al,$0xa1
    1b85:	b8 01 00 00 00       	mov    $0x1,%eax
    1b8a:	e6 21                	out    %al,$0x21
    1b8c:	e6 a1                	out    %al,$0xa1
    1b8e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
    1b93:	e6 21                	out    %al,$0x21
    1b95:	e6 a1                	out    %al,$0xa1
    1b97:	bf c8 20 00 00       	mov    $0x20c8,%edi
    1b9c:	e9 ff 01 00 00       	jmp    1da0 <print_string>
    1ba1:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1ba8:	00 00 00 
    1bab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

0000000000001bb0 <get_cursor>:
    1bb0:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1bb5:	b8 0e 00 00 00       	mov    $0xe,%eax
    1bba:	89 fa                	mov    %edi,%edx
    1bbc:	ee                   	out    %al,(%dx)
    1bbd:	be d5 03 00 00       	mov    $0x3d5,%esi
    1bc2:	89 f2                	mov    %esi,%edx
    1bc4:	ec                   	in     (%dx),%al
    1bc5:	0f b6 c8             	movzbl %al,%ecx
    1bc8:	89 fa                	mov    %edi,%edx
    1bca:	b8 0f 00 00 00       	mov    $0xf,%eax
    1bcf:	c1 e1 08             	shl    $0x8,%ecx
    1bd2:	ee                   	out    %al,(%dx)
    1bd3:	89 f2                	mov    %esi,%edx
    1bd5:	ec                   	in     (%dx),%al
    1bd6:	0f b6 c0             	movzbl %al,%eax
    1bd9:	09 c8                	or     %ecx,%eax
    1bdb:	c3                   	ret    
    1bdc:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000001be0 <set_cursor>:
    1be0:	be d4 03 00 00       	mov    $0x3d4,%esi
    1be5:	41 89 f8             	mov    %edi,%r8d
    1be8:	b8 0e 00 00 00       	mov    $0xe,%eax
    1bed:	89 f2                	mov    %esi,%edx
    1bef:	ee                   	out    %al,(%dx)
    1bf0:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    1bf5:	66 c1 ef 08          	shr    $0x8,%di
    1bf9:	89 f8                	mov    %edi,%eax
    1bfb:	89 ca                	mov    %ecx,%edx
    1bfd:	ee                   	out    %al,(%dx)
    1bfe:	b8 0f 00 00 00       	mov    $0xf,%eax
    1c03:	89 f2                	mov    %esi,%edx
    1c05:	ee                   	out    %al,(%dx)
    1c06:	44 89 c0             	mov    %r8d,%eax
    1c09:	89 ca                	mov    %ecx,%edx
    1c0b:	ee                   	out    %al,(%dx)
    1c0c:	c3                   	ret    
    1c0d:	0f 1f 00             	nopl   (%rax)

0000000000001c10 <clear_screen>:
    1c10:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    1c15:	0f 1f 00             	nopl   (%rax)
    1c18:	c6 00 20             	movb   $0x20,(%rax)
    1c1b:	48 83 c0 02          	add    $0x2,%rax
    1c1f:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1c23:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1c29:	75 ed                	jne    1c18 <clear_screen+0x8>
    1c2b:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1c30:	b8 0e 00 00 00       	mov    $0xe,%eax
    1c35:	89 fa                	mov    %edi,%edx
    1c37:	ee                   	out    %al,(%dx)
    1c38:	31 c9                	xor    %ecx,%ecx
    1c3a:	be d5 03 00 00       	mov    $0x3d5,%esi
    1c3f:	89 c8                	mov    %ecx,%eax
    1c41:	89 f2                	mov    %esi,%edx
    1c43:	ee                   	out    %al,(%dx)
    1c44:	b8 0f 00 00 00       	mov    $0xf,%eax
    1c49:	89 fa                	mov    %edi,%edx
    1c4b:	ee                   	out    %al,(%dx)
    1c4c:	89 c8                	mov    %ecx,%eax
    1c4e:	89 f2                	mov    %esi,%edx
    1c50:	ee                   	out    %al,(%dx)
    1c51:	c3                   	ret    
    1c52:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1c59:	00 00 00 00 
    1c5d:	0f 1f 00             	nopl   (%rax)

0000000000001c60 <put_char>:
    1c60:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    1c66:	53                   	push   %rbx
    1c67:	b8 0e 00 00 00       	mov    $0xe,%eax
    1c6c:	44 89 c2             	mov    %r8d,%edx
    1c6f:	ee                   	out    %al,(%dx)
    1c70:	be d5 03 00 00       	mov    $0x3d5,%esi
    1c75:	89 f2                	mov    %esi,%edx
    1c77:	ec                   	in     (%dx),%al
    1c78:	0f b6 c8             	movzbl %al,%ecx
    1c7b:	44 89 c2             	mov    %r8d,%edx
    1c7e:	b8 0f 00 00 00       	mov    $0xf,%eax
    1c83:	c1 e1 08             	shl    $0x8,%ecx
    1c86:	ee                   	out    %al,(%dx)
    1c87:	89 f2                	mov    %esi,%edx
    1c89:	ec                   	in     (%dx),%al
    1c8a:	0f b6 c0             	movzbl %al,%eax
    1c8d:	09 c8                	or     %ecx,%eax
    1c8f:	40 80 ff 0d          	cmp    $0xd,%dil
    1c93:	0f 84 c2 00 00 00    	je     1d5b <put_char+0xfb>
    1c99:	40 80 ff 0a          	cmp    $0xa,%dil
    1c9d:	0f 84 a0 00 00 00    	je     1d43 <put_char+0xe3>
    1ca3:	40 80 ff 08          	cmp    $0x8,%dil
    1ca7:	0f 84 c5 00 00 00    	je     1d72 <put_char+0x112>
    1cad:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1cb1:	83 c0 01             	add    $0x1,%eax
    1cb4:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1cba:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    1cc1:	c6 82 01 80 0b 00 0f 	movb   $0xf,0xb8001(%rdx)
    1cc8:	ba a0 80 0b 00       	mov    $0xb80a0,%edx
    1ccd:	0f b6 dc             	movzbl %ah,%ebx
    1cd0:	89 c1                	mov    %eax,%ecx
    1cd2:	66 3d cf 07          	cmp    $0x7cf,%ax
    1cd6:	76 45                	jbe    1d1d <put_char+0xbd>
    1cd8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1cdf:	00 
    1ce0:	0f b6 02             	movzbl (%rdx),%eax
    1ce3:	48 83 c2 01          	add    $0x1,%rdx
    1ce7:	88 82 5f ff ff ff    	mov    %al,-0xa1(%rdx)
    1ced:	48 81 fa a0 8f 0b 00 	cmp    $0xb8fa0,%rdx
    1cf4:	75 ea                	jne    1ce0 <put_char+0x80>
    1cf6:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    1cfb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1d00:	c6 00 20             	movb   $0x20,(%rax)
    1d03:	48 83 c0 02          	add    $0x2,%rax
    1d07:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1d0b:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1d11:	75 ed                	jne    1d00 <put_char+0xa0>
    1d13:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    1d18:	bb 07 00 00 00       	mov    $0x7,%ebx
    1d1d:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1d22:	b8 0e 00 00 00       	mov    $0xe,%eax
    1d27:	89 fa                	mov    %edi,%edx
    1d29:	ee                   	out    %al,(%dx)
    1d2a:	be d5 03 00 00       	mov    $0x3d5,%esi
    1d2f:	89 d8                	mov    %ebx,%eax
    1d31:	89 f2                	mov    %esi,%edx
    1d33:	ee                   	out    %al,(%dx)
    1d34:	b8 0f 00 00 00       	mov    $0xf,%eax
    1d39:	89 fa                	mov    %edi,%edx
    1d3b:	ee                   	out    %al,(%dx)
    1d3c:	89 c8                	mov    %ecx,%eax
    1d3e:	89 f2                	mov    %esi,%edx
    1d40:	ee                   	out    %al,(%dx)
    1d41:	5b                   	pop    %rbx
    1d42:	c3                   	ret    
    1d43:	0f b7 c0             	movzwl %ax,%eax
    1d46:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1d4c:	c1 e8 16             	shr    $0x16,%eax
    1d4f:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    1d53:	c1 e0 04             	shl    $0x4,%eax
    1d56:	e9 6d ff ff ff       	jmp    1cc8 <put_char+0x68>
    1d5b:	0f b7 c0             	movzwl %ax,%eax
    1d5e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1d64:	c1 e8 16             	shr    $0x16,%eax
    1d67:	8d 04 80             	lea    (%rax,%rax,4),%eax
    1d6a:	c1 e0 04             	shl    $0x4,%eax
    1d6d:	e9 56 ff ff ff       	jmp    1cc8 <put_char+0x68>
    1d72:	66 85 c0             	test   %ax,%ax
    1d75:	74 20                	je     1d97 <put_char+0x137>
    1d77:	83 e8 01             	sub    $0x1,%eax
    1d7a:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1d7e:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1d84:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    1d8b:	c6 82 01 80 0b 00 0f 	movb   $0xf,0xb8001(%rdx)
    1d92:	e9 31 ff ff ff       	jmp    1cc8 <put_char+0x68>
    1d97:	31 c9                	xor    %ecx,%ecx
    1d99:	31 db                	xor    %ebx,%ebx
    1d9b:	eb 80                	jmp    1d1d <put_char+0xbd>
    1d9d:	0f 1f 00             	nopl   (%rax)

0000000000001da0 <print_string>:
    1da0:	49 89 f9             	mov    %rdi,%r9
    1da3:	0f be 3f             	movsbl (%rdi),%edi
    1da6:	40 84 ff             	test   %dil,%dil
    1da9:	74 18                	je     1dc3 <print_string+0x23>
    1dab:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1db0:	e8 ab fe ff ff       	call   1c60 <put_char>
    1db5:	41 0f be 79 01       	movsbl 0x1(%r9),%edi
    1dba:	49 83 c1 01          	add    $0x1,%r9
    1dbe:	40 84 ff             	test   %dil,%dil
    1dc1:	75 ed                	jne    1db0 <print_string+0x10>
    1dc3:	c3                   	ret    
    1dc4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1dcb:	00 00 00 00 
    1dcf:	90                   	nop

0000000000001dd0 <print_hex>:
    1dd0:	49 89 fa             	mov    %rdi,%r10
    1dd3:	48 83 ec 10          	sub    $0x10,%rsp
    1dd7:	41 b9 f4 20 00 00    	mov    $0x20f4,%r9d
    1ddd:	bf 30 00 00 00       	mov    $0x30,%edi
    1de2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1de8:	e8 73 fe ff ff       	call   1c60 <put_char>
    1ded:	41 0f be 79 01       	movsbl 0x1(%r9),%edi
    1df2:	49 83 c1 01          	add    $0x1,%r9
    1df6:	40 84 ff             	test   %dil,%dil
    1df9:	75 ed                	jne    1de8 <print_hex+0x18>
    1dfb:	b8 01 00 00 00       	mov    $0x1,%eax
    1e00:	4d 85 d2             	test   %r10,%r10
    1e03:	74 53                	je     1e58 <print_hex+0x88>
    1e05:	0f 1f 00             	nopl   (%rax)
    1e08:	4c 89 d2             	mov    %r10,%rdx
    1e0b:	4c 63 c8             	movslq %eax,%r9
    1e0e:	83 e2 0f             	and    $0xf,%edx
    1e11:	0f be ba f7 20 00 00 	movsbl 0x20f7(%rdx),%edi
    1e18:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    1e1d:	48 83 c0 01          	add    $0x1,%rax
    1e21:	49 c1 ea 04          	shr    $0x4,%r10
    1e25:	75 e1                	jne    1e08 <print_hex+0x38>
    1e27:	e8 34 fe ff ff       	call   1c60 <put_char>
    1e2c:	49 83 e9 01          	sub    $0x1,%r9
    1e30:	45 85 c9             	test   %r9d,%r9d
    1e33:	74 17                	je     1e4c <print_hex+0x7c>
    1e35:	0f 1f 00             	nopl   (%rax)
    1e38:	42 0f be 7c 0c ff    	movsbl -0x1(%rsp,%r9,1),%edi
    1e3e:	49 83 e9 01          	sub    $0x1,%r9
    1e42:	e8 19 fe ff ff       	call   1c60 <put_char>
    1e47:	45 85 c9             	test   %r9d,%r9d
    1e4a:	75 ec                	jne    1e38 <print_hex+0x68>
    1e4c:	48 83 c4 10          	add    $0x10,%rsp
    1e50:	c3                   	ret    
    1e51:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1e58:	bf 30 00 00 00       	mov    $0x30,%edi
    1e5d:	48 83 c4 10          	add    $0x10,%rsp
    1e61:	e9 fa fd ff ff       	jmp    1c60 <put_char>
    1e66:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1e6d:	00 00 00 

0000000000001e70 <print_int>:
    1e70:	48 83 ec 20          	sub    $0x20,%rsp
    1e74:	48 85 ff             	test   %rdi,%rdi
    1e77:	74 77                	je     1ef0 <print_int+0x80>
    1e79:	49 89 f9             	mov    %rdi,%r9
    1e7c:	78 62                	js     1ee0 <print_int+0x70>
    1e7e:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    1e85:	cc cc cc 
    1e88:	be 01 00 00 00       	mov    $0x1,%esi
    1e8d:	0f 1f 00             	nopl   (%rax)
    1e90:	4c 89 c8             	mov    %r9,%rax
    1e93:	89 f1                	mov    %esi,%ecx
    1e95:	49 f7 e0             	mul    %r8
    1e98:	48 c1 ea 03          	shr    $0x3,%rdx
    1e9c:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    1ea0:	48 01 c0             	add    %rax,%rax
    1ea3:	49 29 c1             	sub    %rax,%r9
    1ea6:	41 8d 79 30          	lea    0x30(%r9),%edi
    1eaa:	49 89 d1             	mov    %rdx,%r9
    1ead:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    1eb2:	48 83 c6 01          	add    $0x1,%rsi
    1eb6:	48 85 d2             	test   %rdx,%rdx
    1eb9:	75 d5                	jne    1e90 <print_int+0x20>
    1ebb:	4c 63 c9             	movslq %ecx,%r9
    1ebe:	eb 06                	jmp    1ec6 <print_int+0x56>
    1ec0:	42 0f b6 7c 0c 0b    	movzbl 0xb(%rsp,%r9,1),%edi
    1ec6:	40 0f be ff          	movsbl %dil,%edi
    1eca:	49 83 e9 01          	sub    $0x1,%r9
    1ece:	e8 8d fd ff ff       	call   1c60 <put_char>
    1ed3:	45 85 c9             	test   %r9d,%r9d
    1ed6:	75 e8                	jne    1ec0 <print_int+0x50>
    1ed8:	48 83 c4 20          	add    $0x20,%rsp
    1edc:	c3                   	ret    
    1edd:	0f 1f 00             	nopl   (%rax)
    1ee0:	bf 2d 00 00 00       	mov    $0x2d,%edi
    1ee5:	49 f7 d9             	neg    %r9
    1ee8:	e8 73 fd ff ff       	call   1c60 <put_char>
    1eed:	eb 8f                	jmp    1e7e <print_int+0xe>
    1eef:	90                   	nop
    1ef0:	bf 30 00 00 00       	mov    $0x30,%edi
    1ef5:	48 83 c4 20          	add    $0x20,%rsp
    1ef9:	e9 62 fd ff ff       	jmp    1c60 <put_char>
