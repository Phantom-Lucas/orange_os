
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	53                   	push   %rbx
    1901:	bb 01 00 00 00       	mov    $0x1,%ebx
    1906:	e8 15 01 00 00       	call   1a20 <clear_screen>
    190b:	bf 10 1d 00 00       	mov    $0x1d10,%edi
    1910:	e8 9b 02 00 00       	call   1bb0 <print_string>
    1915:	bf 71 1e 00 00       	mov    $0x1e71,%edi
    191a:	e8 91 02 00 00       	call   1bb0 <print_string>
    191f:	bf 48 1d 00 00       	mov    $0x1d48,%edi
    1924:	e8 87 02 00 00       	call   1bb0 <print_string>
    1929:	bf 68 1d 00 00       	mov    $0x1d68,%edi
    192e:	e8 7d 02 00 00       	call   1bb0 <print_string>
    1933:	bf a0 1d 00 00       	mov    $0x1da0,%edi
    1938:	e8 73 02 00 00       	call   1bb0 <print_string>
    193d:	48 bf ef cd ab 90 78 	movabs $0x1234567890abcdef,%rdi
    1944:	56 34 12 
    1947:	e8 94 02 00 00       	call   1be0 <print_hex>
    194c:	bf 8f 1e 00 00       	mov    $0x1e8f,%edi
    1951:	e8 5a 02 00 00       	call   1bb0 <print_string>
    1956:	bf c8 1d 00 00       	mov    $0x1dc8,%edi
    195b:	e8 50 02 00 00       	call   1bb0 <print_string>
    1960:	48 c7 c7 58 23 0a fa 	mov    $0xfffffffffa0a2358,%rdi
    1967:	e8 14 03 00 00       	call   1c80 <print_int>
    196c:	bf 8e 1e 00 00       	mov    $0x1e8e,%edi
    1971:	e8 3a 02 00 00       	call   1bb0 <print_string>
    1976:	bf 91 1e 00 00       	mov    $0x1e91,%edi
    197b:	e8 30 02 00 00       	call   1bb0 <print_string>
    1980:	bf aa 1e 00 00       	mov    $0x1eaa,%edi
    1985:	e8 26 02 00 00       	call   1bb0 <print_string>
    198a:	48 89 df             	mov    %rbx,%rdi
    198d:	48 83 c3 01          	add    $0x1,%rbx
    1991:	e8 ea 02 00 00       	call   1c80 <print_int>
    1996:	bf f0 1d 00 00       	mov    $0x1df0,%edi
    199b:	e8 10 02 00 00       	call   1bb0 <print_string>
    19a0:	48 83 fb 1f          	cmp    $0x1f,%rbx
    19a4:	75 da                	jne    1980 <kernel_main+0x80>
    19a6:	bf 20 1e 00 00       	mov    $0x1e20,%edi
    19ab:	e8 00 02 00 00       	call   1bb0 <print_string>
    19b0:	f4                   	hlt    
    19b1:	eb fd                	jmp    19b0 <kernel_main+0xb0>
    19b3:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    19ba:	00 00 00 
    19bd:	0f 1f 00             	nopl   (%rax)

00000000000019c0 <get_cursor>:
    19c0:	bf d4 03 00 00       	mov    $0x3d4,%edi
    19c5:	b8 0e 00 00 00       	mov    $0xe,%eax
    19ca:	89 fa                	mov    %edi,%edx
    19cc:	ee                   	out    %al,(%dx)
    19cd:	be d5 03 00 00       	mov    $0x3d5,%esi
    19d2:	89 f2                	mov    %esi,%edx
    19d4:	ec                   	in     (%dx),%al
    19d5:	0f b6 c8             	movzbl %al,%ecx
    19d8:	89 fa                	mov    %edi,%edx
    19da:	b8 0f 00 00 00       	mov    $0xf,%eax
    19df:	c1 e1 08             	shl    $0x8,%ecx
    19e2:	ee                   	out    %al,(%dx)
    19e3:	89 f2                	mov    %esi,%edx
    19e5:	ec                   	in     (%dx),%al
    19e6:	0f b6 c0             	movzbl %al,%eax
    19e9:	09 c8                	or     %ecx,%eax
    19eb:	c3                   	ret    
    19ec:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000019f0 <set_cursor>:
    19f0:	be d4 03 00 00       	mov    $0x3d4,%esi
    19f5:	41 89 f8             	mov    %edi,%r8d
    19f8:	b8 0e 00 00 00       	mov    $0xe,%eax
    19fd:	89 f2                	mov    %esi,%edx
    19ff:	ee                   	out    %al,(%dx)
    1a00:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    1a05:	66 c1 ef 08          	shr    $0x8,%di
    1a09:	89 f8                	mov    %edi,%eax
    1a0b:	89 ca                	mov    %ecx,%edx
    1a0d:	ee                   	out    %al,(%dx)
    1a0e:	b8 0f 00 00 00       	mov    $0xf,%eax
    1a13:	89 f2                	mov    %esi,%edx
    1a15:	ee                   	out    %al,(%dx)
    1a16:	44 89 c0             	mov    %r8d,%eax
    1a19:	89 ca                	mov    %ecx,%edx
    1a1b:	ee                   	out    %al,(%dx)
    1a1c:	c3                   	ret    
    1a1d:	0f 1f 00             	nopl   (%rax)

0000000000001a20 <clear_screen>:
    1a20:	b8 00 80 0b 00       	mov    $0xb8000,%eax
    1a25:	0f 1f 00             	nopl   (%rax)
    1a28:	c6 00 20             	movb   $0x20,(%rax)
    1a2b:	48 83 c0 02          	add    $0x2,%rax
    1a2f:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1a33:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1a39:	75 ed                	jne    1a28 <clear_screen+0x8>
    1a3b:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1a40:	b8 0e 00 00 00       	mov    $0xe,%eax
    1a45:	89 fa                	mov    %edi,%edx
    1a47:	ee                   	out    %al,(%dx)
    1a48:	31 c9                	xor    %ecx,%ecx
    1a4a:	be d5 03 00 00       	mov    $0x3d5,%esi
    1a4f:	89 c8                	mov    %ecx,%eax
    1a51:	89 f2                	mov    %esi,%edx
    1a53:	ee                   	out    %al,(%dx)
    1a54:	b8 0f 00 00 00       	mov    $0xf,%eax
    1a59:	89 fa                	mov    %edi,%edx
    1a5b:	ee                   	out    %al,(%dx)
    1a5c:	89 c8                	mov    %ecx,%eax
    1a5e:	89 f2                	mov    %esi,%edx
    1a60:	ee                   	out    %al,(%dx)
    1a61:	c3                   	ret    
    1a62:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1a69:	00 00 00 00 
    1a6d:	0f 1f 00             	nopl   (%rax)

0000000000001a70 <put_char>:
    1a70:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    1a76:	53                   	push   %rbx
    1a77:	b8 0e 00 00 00       	mov    $0xe,%eax
    1a7c:	44 89 c2             	mov    %r8d,%edx
    1a7f:	ee                   	out    %al,(%dx)
    1a80:	be d5 03 00 00       	mov    $0x3d5,%esi
    1a85:	89 f2                	mov    %esi,%edx
    1a87:	ec                   	in     (%dx),%al
    1a88:	0f b6 c8             	movzbl %al,%ecx
    1a8b:	44 89 c2             	mov    %r8d,%edx
    1a8e:	b8 0f 00 00 00       	mov    $0xf,%eax
    1a93:	c1 e1 08             	shl    $0x8,%ecx
    1a96:	ee                   	out    %al,(%dx)
    1a97:	89 f2                	mov    %esi,%edx
    1a99:	ec                   	in     (%dx),%al
    1a9a:	0f b6 c0             	movzbl %al,%eax
    1a9d:	09 c8                	or     %ecx,%eax
    1a9f:	40 80 ff 0d          	cmp    $0xd,%dil
    1aa3:	0f 84 c2 00 00 00    	je     1b6b <put_char+0xfb>
    1aa9:	40 80 ff 0a          	cmp    $0xa,%dil
    1aad:	0f 84 a0 00 00 00    	je     1b53 <put_char+0xe3>
    1ab3:	40 80 ff 08          	cmp    $0x8,%dil
    1ab7:	0f 84 c5 00 00 00    	je     1b82 <put_char+0x112>
    1abd:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1ac1:	83 c0 01             	add    $0x1,%eax
    1ac4:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1aca:	40 88 ba 00 80 0b 00 	mov    %dil,0xb8000(%rdx)
    1ad1:	c6 82 01 80 0b 00 0f 	movb   $0xf,0xb8001(%rdx)
    1ad8:	ba a0 80 0b 00       	mov    $0xb80a0,%edx
    1add:	0f b6 dc             	movzbl %ah,%ebx
    1ae0:	89 c1                	mov    %eax,%ecx
    1ae2:	66 3d cf 07          	cmp    $0x7cf,%ax
    1ae6:	76 45                	jbe    1b2d <put_char+0xbd>
    1ae8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1aef:	00 
    1af0:	0f b6 02             	movzbl (%rdx),%eax
    1af3:	48 83 c2 01          	add    $0x1,%rdx
    1af7:	88 82 5f ff ff ff    	mov    %al,-0xa1(%rdx)
    1afd:	48 81 fa a0 8f 0b 00 	cmp    $0xb8fa0,%rdx
    1b04:	75 ea                	jne    1af0 <put_char+0x80>
    1b06:	b8 00 8f 0b 00       	mov    $0xb8f00,%eax
    1b0b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1b10:	c6 00 20             	movb   $0x20,(%rax)
    1b13:	48 83 c0 02          	add    $0x2,%rax
    1b17:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
    1b1b:	48 3d a0 8f 0b 00    	cmp    $0xb8fa0,%rax
    1b21:	75 ed                	jne    1b10 <put_char+0xa0>
    1b23:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
    1b28:	bb 07 00 00 00       	mov    $0x7,%ebx
    1b2d:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1b32:	b8 0e 00 00 00       	mov    $0xe,%eax
    1b37:	89 fa                	mov    %edi,%edx
    1b39:	ee                   	out    %al,(%dx)
    1b3a:	be d5 03 00 00       	mov    $0x3d5,%esi
    1b3f:	89 d8                	mov    %ebx,%eax
    1b41:	89 f2                	mov    %esi,%edx
    1b43:	ee                   	out    %al,(%dx)
    1b44:	b8 0f 00 00 00       	mov    $0xf,%eax
    1b49:	89 fa                	mov    %edi,%edx
    1b4b:	ee                   	out    %al,(%dx)
    1b4c:	89 c8                	mov    %ecx,%eax
    1b4e:	89 f2                	mov    %esi,%edx
    1b50:	ee                   	out    %al,(%dx)
    1b51:	5b                   	pop    %rbx
    1b52:	c3                   	ret    
    1b53:	0f b7 c0             	movzwl %ax,%eax
    1b56:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1b5c:	c1 e8 16             	shr    $0x16,%eax
    1b5f:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    1b63:	c1 e0 04             	shl    $0x4,%eax
    1b66:	e9 6d ff ff ff       	jmp    1ad8 <put_char+0x68>
    1b6b:	0f b7 c0             	movzwl %ax,%eax
    1b6e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1b74:	c1 e8 16             	shr    $0x16,%eax
    1b77:	8d 04 80             	lea    (%rax,%rax,4),%eax
    1b7a:	c1 e0 04             	shl    $0x4,%eax
    1b7d:	e9 56 ff ff ff       	jmp    1ad8 <put_char+0x68>
    1b82:	66 85 c0             	test   %ax,%ax
    1b85:	74 20                	je     1ba7 <put_char+0x137>
    1b87:	83 e8 01             	sub    $0x1,%eax
    1b8a:	48 8d 14 00          	lea    (%rax,%rax,1),%rdx
    1b8e:	81 e2 fe ff 01 00    	and    $0x1fffe,%edx
    1b94:	c6 82 00 80 0b 00 20 	movb   $0x20,0xb8000(%rdx)
    1b9b:	c6 82 01 80 0b 00 0f 	movb   $0xf,0xb8001(%rdx)
    1ba2:	e9 31 ff ff ff       	jmp    1ad8 <put_char+0x68>
    1ba7:	31 c9                	xor    %ecx,%ecx
    1ba9:	31 db                	xor    %ebx,%ebx
    1bab:	eb 80                	jmp    1b2d <put_char+0xbd>
    1bad:	0f 1f 00             	nopl   (%rax)

0000000000001bb0 <print_string>:
    1bb0:	49 89 f9             	mov    %rdi,%r9
    1bb3:	0f be 3f             	movsbl (%rdi),%edi
    1bb6:	40 84 ff             	test   %dil,%dil
    1bb9:	74 18                	je     1bd3 <print_string+0x23>
    1bbb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1bc0:	e8 ab fe ff ff       	call   1a70 <put_char>
    1bc5:	41 0f be 79 01       	movsbl 0x1(%r9),%edi
    1bca:	49 83 c1 01          	add    $0x1,%r9
    1bce:	40 84 ff             	test   %dil,%dil
    1bd1:	75 ed                	jne    1bc0 <print_string+0x10>
    1bd3:	c3                   	ret    
    1bd4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    1bdb:	00 00 00 00 
    1bdf:	90                   	nop

0000000000001be0 <print_hex>:
    1be0:	49 89 fa             	mov    %rdi,%r10
    1be3:	48 83 ec 10          	sub    $0x10,%rsp
    1be7:	41 b9 bf 1e 00 00    	mov    $0x1ebf,%r9d
    1bed:	bf 30 00 00 00       	mov    $0x30,%edi
    1bf2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1bf8:	e8 73 fe ff ff       	call   1a70 <put_char>
    1bfd:	41 0f be 79 01       	movsbl 0x1(%r9),%edi
    1c02:	49 83 c1 01          	add    $0x1,%r9
    1c06:	40 84 ff             	test   %dil,%dil
    1c09:	75 ed                	jne    1bf8 <print_hex+0x18>
    1c0b:	b8 01 00 00 00       	mov    $0x1,%eax
    1c10:	4d 85 d2             	test   %r10,%r10
    1c13:	74 53                	je     1c68 <print_hex+0x88>
    1c15:	0f 1f 00             	nopl   (%rax)
    1c18:	4c 89 d2             	mov    %r10,%rdx
    1c1b:	4c 63 c8             	movslq %eax,%r9
    1c1e:	83 e2 0f             	and    $0xf,%edx
    1c21:	0f be ba c2 1e 00 00 	movsbl 0x1ec2(%rdx),%edi
    1c28:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
    1c2d:	48 83 c0 01          	add    $0x1,%rax
    1c31:	49 c1 ea 04          	shr    $0x4,%r10
    1c35:	75 e1                	jne    1c18 <print_hex+0x38>
    1c37:	e8 34 fe ff ff       	call   1a70 <put_char>
    1c3c:	49 83 e9 01          	sub    $0x1,%r9
    1c40:	45 85 c9             	test   %r9d,%r9d
    1c43:	74 17                	je     1c5c <print_hex+0x7c>
    1c45:	0f 1f 00             	nopl   (%rax)
    1c48:	42 0f be 7c 0c ff    	movsbl -0x1(%rsp,%r9,1),%edi
    1c4e:	49 83 e9 01          	sub    $0x1,%r9
    1c52:	e8 19 fe ff ff       	call   1a70 <put_char>
    1c57:	45 85 c9             	test   %r9d,%r9d
    1c5a:	75 ec                	jne    1c48 <print_hex+0x68>
    1c5c:	48 83 c4 10          	add    $0x10,%rsp
    1c60:	c3                   	ret    
    1c61:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1c68:	bf 30 00 00 00       	mov    $0x30,%edi
    1c6d:	48 83 c4 10          	add    $0x10,%rsp
    1c71:	e9 fa fd ff ff       	jmp    1a70 <put_char>
    1c76:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    1c7d:	00 00 00 

0000000000001c80 <print_int>:
    1c80:	48 83 ec 20          	sub    $0x20,%rsp
    1c84:	48 85 ff             	test   %rdi,%rdi
    1c87:	74 77                	je     1d00 <print_int+0x80>
    1c89:	49 89 f9             	mov    %rdi,%r9
    1c8c:	78 62                	js     1cf0 <print_int+0x70>
    1c8e:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
    1c95:	cc cc cc 
    1c98:	be 01 00 00 00       	mov    $0x1,%esi
    1c9d:	0f 1f 00             	nopl   (%rax)
    1ca0:	4c 89 c8             	mov    %r9,%rax
    1ca3:	89 f1                	mov    %esi,%ecx
    1ca5:	49 f7 e0             	mul    %r8
    1ca8:	48 c1 ea 03          	shr    $0x3,%rdx
    1cac:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
    1cb0:	48 01 c0             	add    %rax,%rax
    1cb3:	49 29 c1             	sub    %rax,%r9
    1cb6:	41 8d 79 30          	lea    0x30(%r9),%edi
    1cba:	49 89 d1             	mov    %rdx,%r9
    1cbd:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
    1cc2:	48 83 c6 01          	add    $0x1,%rsi
    1cc6:	48 85 d2             	test   %rdx,%rdx
    1cc9:	75 d5                	jne    1ca0 <print_int+0x20>
    1ccb:	4c 63 c9             	movslq %ecx,%r9
    1cce:	eb 06                	jmp    1cd6 <print_int+0x56>
    1cd0:	42 0f b6 7c 0c 0b    	movzbl 0xb(%rsp,%r9,1),%edi
    1cd6:	40 0f be ff          	movsbl %dil,%edi
    1cda:	49 83 e9 01          	sub    $0x1,%r9
    1cde:	e8 8d fd ff ff       	call   1a70 <put_char>
    1ce3:	45 85 c9             	test   %r9d,%r9d
    1ce6:	75 e8                	jne    1cd0 <print_int+0x50>
    1ce8:	48 83 c4 20          	add    $0x20,%rsp
    1cec:	c3                   	ret    
    1ced:	0f 1f 00             	nopl   (%rax)
    1cf0:	bf 2d 00 00 00       	mov    $0x2d,%edi
    1cf5:	49 f7 d9             	neg    %r9
    1cf8:	e8 73 fd ff ff       	call   1a70 <put_char>
    1cfd:	eb 8f                	jmp    1c8e <print_int+0xe>
    1cff:	90                   	nop
    1d00:	bf 30 00 00 00       	mov    $0x30,%edi
    1d05:	48 83 c4 20          	add    $0x20,%rsp
    1d09:	e9 62 fd ff ff       	jmp    1a70 <put_char>
