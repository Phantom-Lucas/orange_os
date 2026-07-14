
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

0000000000001900 <kernel_main>:
    1900:	50                   	push   %rax
    1901:	58                   	pop    %rax
    1902:	bf 4f 00 00 00       	mov    $0x4f,%edi
    1907:	48 83 ec 08          	sub    $0x8,%rsp
    190b:	e8 c0 00 00 00       	call   19d0 <put_char>
    1910:	bf 53 00 00 00       	mov    $0x53,%edi
    1915:	e8 b6 00 00 00       	call   19d0 <put_char>
    191a:	bf 0a 00 00 00       	mov    $0xa,%edi
    191f:	e8 ac 00 00 00       	call   19d0 <put_char>
    1924:	bf 41 00 00 00       	mov    $0x41,%edi
    1929:	e8 a2 00 00 00       	call   19d0 <put_char>
    192e:	bf 42 00 00 00       	mov    $0x42,%edi
    1933:	e8 98 00 00 00       	call   19d0 <put_char>
    1938:	bf 08 00 00 00       	mov    $0x8,%edi
    193d:	e8 8e 00 00 00       	call   19d0 <put_char>
    1942:	bf 43 00 00 00       	mov    $0x43,%edi
    1947:	e8 84 00 00 00       	call   19d0 <put_char>
    194c:	bf 0d 00 00 00       	mov    $0xd,%edi
    1951:	e8 7a 00 00 00       	call   19d0 <put_char>
    1956:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    195d:	00 00 00 
    1960:	f4                   	hlt    
    1961:	eb fd                	jmp    1960 <kernel_main+0x60>
    1963:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    196a:	00 00 00 
    196d:	0f 1f 00             	nopl   (%rax)

0000000000001970 <get_cursor>:
    1970:	bf d4 03 00 00       	mov    $0x3d4,%edi
    1975:	b8 0e 00 00 00       	mov    $0xe,%eax
    197a:	89 fa                	mov    %edi,%edx
    197c:	ee                   	out    %al,(%dx)
    197d:	be d5 03 00 00       	mov    $0x3d5,%esi
    1982:	89 f2                	mov    %esi,%edx
    1984:	ec                   	in     (%dx),%al
    1985:	0f b6 c8             	movzbl %al,%ecx
    1988:	89 fa                	mov    %edi,%edx
    198a:	b8 0f 00 00 00       	mov    $0xf,%eax
    198f:	c1 e1 08             	shl    $0x8,%ecx
    1992:	ee                   	out    %al,(%dx)
    1993:	89 f2                	mov    %esi,%edx
    1995:	ec                   	in     (%dx),%al
    1996:	0f b6 c0             	movzbl %al,%eax
    1999:	09 c8                	or     %ecx,%eax
    199b:	c3                   	ret    
    199c:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000019a0 <set_cursor>:
    19a0:	be d4 03 00 00       	mov    $0x3d4,%esi
    19a5:	41 89 f8             	mov    %edi,%r8d
    19a8:	b8 0e 00 00 00       	mov    $0xe,%eax
    19ad:	89 f2                	mov    %esi,%edx
    19af:	ee                   	out    %al,(%dx)
    19b0:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    19b5:	66 c1 ef 08          	shr    $0x8,%di
    19b9:	89 f8                	mov    %edi,%eax
    19bb:	89 ca                	mov    %ecx,%edx
    19bd:	ee                   	out    %al,(%dx)
    19be:	b8 0f 00 00 00       	mov    $0xf,%eax
    19c3:	89 f2                	mov    %esi,%edx
    19c5:	ee                   	out    %al,(%dx)
    19c6:	44 89 c0             	mov    %r8d,%eax
    19c9:	89 ca                	mov    %ecx,%edx
    19cb:	ee                   	out    %al,(%dx)
    19cc:	c3                   	ret    
    19cd:	0f 1f 00             	nopl   (%rax)

00000000000019d0 <put_char>:
    19d0:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
    19d6:	53                   	push   %rbx
    19d7:	b8 0e 00 00 00       	mov    $0xe,%eax
    19dc:	44 89 c2             	mov    %r8d,%edx
    19df:	ee                   	out    %al,(%dx)
    19e0:	be d5 03 00 00       	mov    $0x3d5,%esi
    19e5:	89 f2                	mov    %esi,%edx
    19e7:	ec                   	in     (%dx),%al
    19e8:	0f b6 c8             	movzbl %al,%ecx
    19eb:	44 89 c2             	mov    %r8d,%edx
    19ee:	b8 0f 00 00 00       	mov    $0xf,%eax
    19f3:	c1 e1 08             	shl    $0x8,%ecx
    19f6:	ee                   	out    %al,(%dx)
    19f7:	89 f2                	mov    %esi,%edx
    19f9:	ec                   	in     (%dx),%al
    19fa:	0f b6 c0             	movzbl %al,%eax
    19fd:	09 c8                	or     %ecx,%eax
    19ff:	40 80 ff 0d          	cmp    $0xd,%dil
    1a03:	74 73                	je     1a78 <put_char+0xa8>
    1a05:	40 80 ff 0a          	cmp    $0xa,%dil
    1a09:	74 55                	je     1a60 <put_char+0x90>
    1a0b:	40 80 ff 08          	cmp    $0x8,%dil
    1a0f:	74 7f                	je     1a90 <put_char+0xc0>
    1a11:	0f b7 d0             	movzwl %ax,%edx
    1a14:	83 c0 01             	add    $0x1,%eax
    1a17:	48 8d 94 12 00 80 0b 	lea    0xb8000(%rdx,%rdx,1),%rdx
    1a1e:	00 
    1a1f:	40 88 3a             	mov    %dil,(%rdx)
    1a22:	c6 42 01 0f          	movb   $0xf,0x1(%rdx)
    1a26:	31 ff                	xor    %edi,%edi
    1a28:	31 db                	xor    %ebx,%ebx
    1a2a:	66 3d cf 07          	cmp    $0x7cf,%ax
    1a2e:	77 05                	ja     1a35 <put_char+0x65>
    1a30:	0f b6 dc             	movzbl %ah,%ebx
    1a33:	89 c7                	mov    %eax,%edi
    1a35:	be d4 03 00 00       	mov    $0x3d4,%esi
    1a3a:	b8 0e 00 00 00       	mov    $0xe,%eax
    1a3f:	89 f2                	mov    %esi,%edx
    1a41:	ee                   	out    %al,(%dx)
    1a42:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
    1a47:	89 d8                	mov    %ebx,%eax
    1a49:	89 ca                	mov    %ecx,%edx
    1a4b:	ee                   	out    %al,(%dx)
    1a4c:	b8 0f 00 00 00       	mov    $0xf,%eax
    1a51:	89 f2                	mov    %esi,%edx
    1a53:	ee                   	out    %al,(%dx)
    1a54:	89 f8                	mov    %edi,%eax
    1a56:	89 ca                	mov    %ecx,%edx
    1a58:	ee                   	out    %al,(%dx)
    1a59:	5b                   	pop    %rbx
    1a5a:	c3                   	ret    
    1a5b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    1a60:	0f b7 c0             	movzwl %ax,%eax
    1a63:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1a69:	c1 e8 16             	shr    $0x16,%eax
    1a6c:	8d 44 80 05          	lea    0x5(%rax,%rax,4),%eax
    1a70:	c1 e0 04             	shl    $0x4,%eax
    1a73:	eb b1                	jmp    1a26 <put_char+0x56>
    1a75:	0f 1f 00             	nopl   (%rax)
    1a78:	0f b7 c0             	movzwl %ax,%eax
    1a7b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
    1a81:	c1 e8 16             	shr    $0x16,%eax
    1a84:	8d 04 80             	lea    (%rax,%rax,4),%eax
    1a87:	c1 e0 04             	shl    $0x4,%eax
    1a8a:	eb 9a                	jmp    1a26 <put_char+0x56>
    1a8c:	0f 1f 40 00          	nopl   0x0(%rax)
    1a90:	66 85 c0             	test   %ax,%ax
    1a93:	75 1b                	jne    1ab0 <put_char+0xe0>
    1a95:	be 20 0f 00 00       	mov    $0xf20,%esi
    1a9a:	31 ff                	xor    %edi,%edi
    1a9c:	31 db                	xor    %ebx,%ebx
    1a9e:	66 89 34 25 00 80 0b 	mov    %si,0xb8000
    1aa5:	00 
    1aa6:	eb 8d                	jmp    1a35 <put_char+0x65>
    1aa8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1aaf:	00 
    1ab0:	83 e8 01             	sub    $0x1,%eax
    1ab3:	b9 20 0f 00 00       	mov    $0xf20,%ecx
    1ab8:	0f b7 d0             	movzwl %ax,%edx
    1abb:	66 89 8c 12 00 80 0b 	mov    %cx,0xb8000(%rdx,%rdx,1)
    1ac2:	00 
    1ac3:	e9 5e ff ff ff       	jmp    1a26 <put_char+0x56>
