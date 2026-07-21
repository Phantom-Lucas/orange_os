
kernel/kernel.elf：     文件格式 elf64-x86-64


Disassembly of section .text:

ffff800000001900 <kernel_main>:
ffff800000001900:	48 b8 c0 39 00 00 00 	movabs $0xffff8000000039c0,%rax
ffff800000001907:	80 ff ff 
ffff80000000190a:	41 54                	push   %r12
ffff80000000190c:	49 bc 40 37 00 00 00 	movabs $0xffff800000003740,%r12
ffff800000001913:	80 ff ff 
ffff800000001916:	55                   	push   %rbp
ffff800000001917:	53                   	push   %rbx
ffff800000001918:	48 81 ec 00 02 00 00 	sub    $0x200,%rsp
ffff80000000191f:	ff d0                	call   *%rax
ffff800000001921:	48 b8 50 34 00 00 00 	movabs $0xffff800000003450,%rax
ffff800000001928:	80 ff ff 
ffff80000000192b:	ff d0                	call   *%rax
ffff80000000192d:	48 bf c0 5a 00 00 00 	movabs $0xffff800000005ac0,%rdi
ffff800000001934:	80 ff ff 
ffff800000001937:	41 ff d4             	call   *%r12
ffff80000000193a:	48 b8 c0 26 00 00 00 	movabs $0xffff8000000026c0,%rax
ffff800000001941:	80 ff ff 
ffff800000001944:	ff d0                	call   *%rax
ffff800000001946:	48 b8 50 31 00 00 00 	movabs $0xffff800000003150,%rax
ffff80000000194d:	80 ff ff 
ffff800000001950:	ff d0                	call   *%rax
ffff800000001952:	48 b8 20 56 00 00 00 	movabs $0xffff800000005620,%rax
ffff800000001959:	80 ff ff 
ffff80000000195c:	ff d0                	call   *%rax
ffff80000000195e:	48 b8 c0 22 00 00 00 	movabs $0xffff8000000022c0,%rax
ffff800000001965:	80 ff ff 
ffff800000001968:	ff d0                	call   *%rax
ffff80000000196a:	31 ff                	xor    %edi,%edi
ffff80000000196c:	48 b8 20 2b 00 00 00 	movabs $0xffff800000002b20,%rax
ffff800000001973:	80 ff ff 
ffff800000001976:	ff d0                	call   *%rax
ffff800000001978:	48 b8 f0 28 00 00 00 	movabs $0xffff8000000028f0,%rax
ffff80000000197f:	80 ff ff 
ffff800000001982:	ff d0                	call   *%rax
ffff800000001984:	48 b8 c0 52 00 00 00 	movabs $0xffff8000000052c0,%rax
ffff80000000198b:	80 ff ff 
ffff80000000198e:	ff d0                	call   *%rax
ffff800000001990:	48 b8 b0 4a 00 00 00 	movabs $0xffff800000004ab0,%rax
ffff800000001997:	80 ff ff 
ffff80000000199a:	ff d0                	call   *%rax
ffff80000000199c:	fb                   	sti    
ffff80000000199d:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff8000000019a4:	80 ff ff 
ffff8000000019a7:	48 bf e8 5a 00 00 00 	movabs $0xffff800000005ae8,%rdi
ffff8000000019ae:	80 ff ff 
ffff8000000019b1:	48 bd 80 35 00 00 00 	movabs $0xffff800000003580,%rbp
ffff8000000019b8:	80 ff ff 
ffff8000000019bb:	ff d3                	call   *%rbx
ffff8000000019bd:	48 b8 d0 1a 00 00 00 	movabs $0xffff800000001ad0,%rax
ffff8000000019c4:	80 ff ff 
ffff8000000019c7:	ff d0                	call   *%rax
ffff8000000019c9:	31 c0                	xor    %eax,%eax
ffff8000000019cb:	48 8d 7c 24 08       	lea    0x8(%rsp),%rdi
ffff8000000019d0:	b9 3f 00 00 00       	mov    $0x3f,%ecx
ffff8000000019d5:	f3 48 ab             	rep stos %rax,%es:(%rdi)
ffff8000000019d8:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
ffff8000000019df:	00 
ffff8000000019e0:	48 bf 18 5b 00 00 00 	movabs $0xffff800000005b18,%rdi
ffff8000000019e7:	80 ff ff 
ffff8000000019ea:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff8000000019f1:	80 ff ff 
ffff8000000019f4:	ff d0                	call   *%rax
ffff8000000019f6:	ba 01 00 00 00       	mov    $0x1,%edx
ffff8000000019fb:	48 89 e6             	mov    %rsp,%rsi
ffff8000000019fe:	31 ff                	xor    %edi,%edi
ffff800000001a00:	48 b8 f0 1a 00 00 00 	movabs $0xffff800000001af0,%rax
ffff800000001a07:	80 ff ff 
ffff800000001a0a:	ff d0                	call   *%rax
ffff800000001a0c:	48 bf a7 5b 00 00 00 	movabs $0xffff800000005ba7,%rdi
ffff800000001a13:	80 ff ff 
ffff800000001a16:	ff d3                	call   *%rbx
ffff800000001a18:	0f b6 bc 24 fe 01 00 	movzbl 0x1fe(%rsp),%edi
ffff800000001a1f:	00 
ffff800000001a20:	ff d5                	call   *%rbp
ffff800000001a22:	48 bf c6 64 00 00 00 	movabs $0xffff8000000064c6,%rdi
ffff800000001a29:	80 ff ff 
ffff800000001a2c:	ff d3                	call   *%rbx
ffff800000001a2e:	0f b6 bc 24 ff 01 00 	movzbl 0x1ff(%rsp),%edi
ffff800000001a35:	00 
ffff800000001a36:	ff d5                	call   *%rbp
ffff800000001a38:	48 bf 52 64 00 00 00 	movabs $0xffff800000006452,%rdi
ffff800000001a3f:	80 ff ff 
ffff800000001a42:	ff d3                	call   *%rbx
ffff800000001a44:	80 bc 24 fe 01 00 00 	cmpb   $0x55,0x1fe(%rsp)
ffff800000001a4b:	55 
ffff800000001a4c:	75 0a                	jne    ffff800000001a58 <kernel_main+0x158>
ffff800000001a4e:	80 bc 24 ff 01 00 00 	cmpb   $0xaa,0x1ff(%rsp)
ffff800000001a55:	aa 
ffff800000001a56:	74 5b                	je     ffff800000001ab3 <kernel_main+0x1b3>
ffff800000001a58:	48 bf 78 5b 00 00 00 	movabs $0xffff800000005b78,%rdi
ffff800000001a5f:	80 ff ff 
ffff800000001a62:	48 bb d0 36 00 00 00 	movabs $0xffff8000000036d0,%rbx
ffff800000001a69:	80 ff ff 
ffff800000001a6c:	ff d3                	call   *%rbx
ffff800000001a6e:	48 b8 60 1f 00 00 00 	movabs $0xffff800000001f60,%rax
ffff800000001a75:	80 ff ff 
ffff800000001a78:	ff d0                	call   *%rax
ffff800000001a7a:	48 b8 f0 1b 00 00 00 	movabs $0xffff800000001bf0,%rax
ffff800000001a81:	80 ff ff 
ffff800000001a84:	48 bf c0 5b 00 00 00 	movabs $0xffff800000005bc0,%rdi
ffff800000001a8b:	80 ff ff 
ffff800000001a8e:	ff d0                	call   *%rax
ffff800000001a90:	48 bf ca 5b 00 00 00 	movabs $0xffff800000005bca,%rdi
ffff800000001a97:	80 ff ff 
ffff800000001a9a:	ff d3                	call   *%rbx
ffff800000001a9c:	48 b8 30 3a 00 00 00 	movabs $0xffff800000003a30,%rax
ffff800000001aa3:	80 ff ff 
ffff800000001aa6:	ff d0                	call   *%rax
ffff800000001aa8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000001aaf:	00 
ffff800000001ab0:	f4                   	hlt    
ffff800000001ab1:	eb fd                	jmp    ffff800000001ab0 <kernel_main+0x1b0>
ffff800000001ab3:	48 bf 48 5b 00 00 00 	movabs $0xffff800000005b48,%rdi
ffff800000001aba:	80 ff ff 
ffff800000001abd:	48 bb d0 36 00 00 00 	movabs $0xffff8000000036d0,%rbx
ffff800000001ac4:	80 ff ff 
ffff800000001ac7:	41 ff d4             	call   *%r12
ffff800000001aca:	eb a2                	jmp    ffff800000001a6e <kernel_main+0x16e>
ffff800000001acc:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000001ad0 <disk_init>:
ffff800000001ad0:	48 bf e0 56 00 00 00 	movabs $0xffff8000000056e0,%rdi
ffff800000001ad7:	80 ff ff 
ffff800000001ada:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000001ae1:	80 ff ff 
ffff800000001ae4:	ff e0                	jmp    *%rax
ffff800000001ae6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff800000001aed:	00 00 00 

ffff800000001af0 <disk_read_sector>:
ffff800000001af0:	49 89 f0             	mov    %rsi,%r8
ffff800000001af3:	b9 f7 01 00 00       	mov    $0x1f7,%ecx
ffff800000001af8:	89 d6                	mov    %edx,%esi
ffff800000001afa:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000001b00:	89 ca                	mov    %ecx,%edx
ffff800000001b02:	ec                   	in     (%dx),%al
ffff800000001b03:	84 c0                	test   %al,%al
ffff800000001b05:	78 f9                	js     ffff800000001b00 <disk_read_sector+0x10>
ffff800000001b07:	89 f8                	mov    %edi,%eax
ffff800000001b09:	ba f6 01 00 00       	mov    $0x1f6,%edx
ffff800000001b0e:	c1 e8 18             	shr    $0x18,%eax
ffff800000001b11:	83 e0 0f             	and    $0xf,%eax
ffff800000001b14:	83 c8 e0             	or     $0xffffffe0,%eax
ffff800000001b17:	ee                   	out    %al,(%dx)
ffff800000001b18:	ba f2 01 00 00       	mov    $0x1f2,%edx
ffff800000001b1d:	89 f0                	mov    %esi,%eax
ffff800000001b1f:	ee                   	out    %al,(%dx)
ffff800000001b20:	ba f3 01 00 00       	mov    $0x1f3,%edx
ffff800000001b25:	89 f8                	mov    %edi,%eax
ffff800000001b27:	ee                   	out    %al,(%dx)
ffff800000001b28:	89 f8                	mov    %edi,%eax
ffff800000001b2a:	ba f4 01 00 00       	mov    $0x1f4,%edx
ffff800000001b2f:	c1 e8 08             	shr    $0x8,%eax
ffff800000001b32:	ee                   	out    %al,(%dx)
ffff800000001b33:	89 f8                	mov    %edi,%eax
ffff800000001b35:	ba f5 01 00 00       	mov    $0x1f5,%edx
ffff800000001b3a:	c1 e8 10             	shr    $0x10,%eax
ffff800000001b3d:	ee                   	out    %al,(%dx)
ffff800000001b3e:	b8 20 00 00 00       	mov    $0x20,%eax
ffff800000001b43:	89 ca                	mov    %ecx,%edx
ffff800000001b45:	ee                   	out    %al,(%dx)
ffff800000001b46:	85 f6                	test   %esi,%esi
ffff800000001b48:	0f 84 9f 00 00 00    	je     ffff800000001bed <disk_read_sector+0xfd>
ffff800000001b4e:	41 57                	push   %r15
ffff800000001b50:	8d 46 ff             	lea    -0x1(%rsi),%eax
ffff800000001b53:	41 bf f7 01 00 00    	mov    $0x1f7,%r15d
ffff800000001b59:	41 56                	push   %r14
ffff800000001b5b:	48 c1 e0 09          	shl    $0x9,%rax
ffff800000001b5f:	49 be 09 57 00 00 00 	movabs $0xffff800000005709,%r14
ffff800000001b66:	80 ff ff 
ffff800000001b69:	41 55                	push   %r13
ffff800000001b6b:	4d 8d ac 00 00 04 00 	lea    0x400(%r8,%rax,1),%r13
ffff800000001b72:	00 
ffff800000001b73:	41 54                	push   %r12
ffff800000001b75:	41 bc f0 01 00 00    	mov    $0x1f0,%r12d
ffff800000001b7b:	55                   	push   %rbp
ffff800000001b7c:	49 8d a8 00 02 00 00 	lea    0x200(%r8),%rbp
ffff800000001b83:	53                   	push   %rbx
ffff800000001b84:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000001b88:	48 8d 9d 00 fe ff ff 	lea    -0x200(%rbp),%rbx
ffff800000001b8f:	90                   	nop
ffff800000001b90:	44 89 fa             	mov    %r15d,%edx
ffff800000001b93:	ec                   	in     (%dx),%al
ffff800000001b94:	84 c0                	test   %al,%al
ffff800000001b96:	78 f8                	js     ffff800000001b90 <disk_read_sector+0xa0>
ffff800000001b98:	eb 0e                	jmp    ffff800000001ba8 <disk_read_sector+0xb8>
ffff800000001b9a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000001ba0:	44 89 fa             	mov    %r15d,%edx
ffff800000001ba3:	ec                   	in     (%dx),%al
ffff800000001ba4:	a8 01                	test   $0x1,%al
ffff800000001ba6:	75 34                	jne    ffff800000001bdc <disk_read_sector+0xec>
ffff800000001ba8:	44 89 fa             	mov    %r15d,%edx
ffff800000001bab:	ec                   	in     (%dx),%al
ffff800000001bac:	a8 08                	test   $0x8,%al
ffff800000001bae:	74 f0                	je     ffff800000001ba0 <disk_read_sector+0xb0>
ffff800000001bb0:	44 89 e2             	mov    %r12d,%edx
ffff800000001bb3:	66 ed                	in     (%dx),%ax
ffff800000001bb5:	66 89 03             	mov    %ax,(%rbx)
ffff800000001bb8:	48 83 c3 02          	add    $0x2,%rbx
ffff800000001bbc:	48 39 eb             	cmp    %rbp,%rbx
ffff800000001bbf:	75 ef                	jne    ffff800000001bb0 <disk_read_sector+0xc0>
ffff800000001bc1:	48 81 c5 00 02 00 00 	add    $0x200,%rbp
ffff800000001bc8:	4c 39 ed             	cmp    %r13,%rbp
ffff800000001bcb:	75 bb                	jne    ffff800000001b88 <disk_read_sector+0x98>
ffff800000001bcd:	48 83 c4 08          	add    $0x8,%rsp
ffff800000001bd1:	5b                   	pop    %rbx
ffff800000001bd2:	5d                   	pop    %rbp
ffff800000001bd3:	41 5c                	pop    %r12
ffff800000001bd5:	41 5d                	pop    %r13
ffff800000001bd7:	41 5e                	pop    %r14
ffff800000001bd9:	41 5f                	pop    %r15
ffff800000001bdb:	c3                   	ret    
ffff800000001bdc:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000001be3:	80 ff ff 
ffff800000001be6:	4c 89 f7             	mov    %r14,%rdi
ffff800000001be9:	ff d0                	call   *%rax
ffff800000001beb:	eb c3                	jmp    ffff800000001bb0 <disk_read_sector+0xc0>
ffff800000001bed:	c3                   	ret    
ffff800000001bee:	66 90                	xchg   %ax,%ax

ffff800000001bf0 <execute_elf>:
ffff800000001bf0:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000001bf7:	80 ff ff 
ffff800000001bfa:	41 57                	push   %r15
ffff800000001bfc:	41 56                	push   %r14
ffff800000001bfe:	41 55                	push   %r13
ffff800000001c00:	41 54                	push   %r12
ffff800000001c02:	55                   	push   %rbp
ffff800000001c03:	48 89 fd             	mov    %rdi,%rbp
ffff800000001c06:	48 bf 21 57 00 00 00 	movabs $0xffff800000005721,%rdi
ffff800000001c0d:	80 ff ff 
ffff800000001c10:	53                   	push   %rbx
ffff800000001c11:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000001c18:	80 ff ff 
ffff800000001c1b:	48 81 ec a8 00 00 00 	sub    $0xa8,%rsp
ffff800000001c22:	ff d0                	call   *%rax
ffff800000001c24:	48 89 ef             	mov    %rbp,%rdi
ffff800000001c27:	ff d3                	call   *%rbx
ffff800000001c29:	48 bf 52 64 00 00 00 	movabs $0xffff800000006452,%rdi
ffff800000001c30:	80 ff ff 
ffff800000001c33:	ff d3                	call   *%rbx
ffff800000001c35:	48 8d 74 24 5c       	lea    0x5c(%rsp),%rsi
ffff800000001c3a:	48 89 ef             	mov    %rbp,%rdi
ffff800000001c3d:	48 b8 80 20 00 00 00 	movabs $0xffff800000002080,%rax
ffff800000001c44:	80 ff ff 
ffff800000001c47:	ff d0                	call   *%rax
ffff800000001c49:	85 c0                	test   %eax,%eax
ffff800000001c4b:	75 27                	jne    ffff800000001c74 <execute_elf+0x84>
ffff800000001c4d:	48 81 c4 a8 00 00 00 	add    $0xa8,%rsp
ffff800000001c54:	48 bf 3f 57 00 00 00 	movabs $0xffff80000000573f,%rdi
ffff800000001c5b:	80 ff ff 
ffff800000001c5e:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000001c65:	80 ff ff 
ffff800000001c68:	5b                   	pop    %rbx
ffff800000001c69:	5d                   	pop    %rbp
ffff800000001c6a:	41 5c                	pop    %r12
ffff800000001c6c:	41 5d                	pop    %r13
ffff800000001c6e:	41 5e                	pop    %r14
ffff800000001c70:	41 5f                	pop    %r15
ffff800000001c72:	ff e0                	jmp    *%rax
ffff800000001c74:	8b 44 24 5c          	mov    0x5c(%rsp),%eax
ffff800000001c78:	8d b8 00 02 00 00    	lea    0x200(%rax),%edi
ffff800000001c7e:	48 b8 70 29 00 00 00 	movabs $0xffff800000002970,%rax
ffff800000001c85:	80 ff ff 
ffff800000001c88:	ff d0                	call   *%rax
ffff800000001c8a:	48 89 c5             	mov    %rax,%rbp
ffff800000001c8d:	8b 44 24 5c          	mov    0x5c(%rsp),%eax
ffff800000001c91:	48 89 ee             	mov    %rbp,%rsi
ffff800000001c94:	8d 90 ff 01 00 00    	lea    0x1ff(%rax),%edx
ffff800000001c9a:	8b 44 24 64          	mov    0x64(%rsp),%eax
ffff800000001c9e:	c1 ea 09             	shr    $0x9,%edx
ffff800000001ca1:	8d 3c c5 e8 03 00 00 	lea    0x3e8(,%rax,8),%edi
ffff800000001ca8:	48 b8 f0 1a 00 00 00 	movabs $0xffff800000001af0,%rax
ffff800000001caf:	80 ff ff 
ffff800000001cb2:	ff d0                	call   *%rax
ffff800000001cb4:	81 7d 00 7f 45 4c 46 	cmpl   $0x464c457f,0x0(%rbp)
ffff800000001cbb:	74 14                	je     ffff800000001cd1 <execute_elf+0xe1>
ffff800000001cbd:	48 b8 90 2a 00 00 00 	movabs $0xffff800000002a90,%rax
ffff800000001cc4:	80 ff ff 
ffff800000001cc7:	48 89 ef             	mov    %rbp,%rdi
ffff800000001cca:	ff d0                	call   *%rax
ffff800000001ccc:	e9 7c ff ff ff       	jmp    ffff800000001c4d <execute_elf+0x5d>
ffff800000001cd1:	48 8b 45 18          	mov    0x18(%rbp),%rax
ffff800000001cd5:	48 89 44 24 18       	mov    %rax,0x18(%rsp)
ffff800000001cda:	48 b8 d0 2e 00 00 00 	movabs $0xffff800000002ed0,%rax
ffff800000001ce1:	80 ff ff 
ffff800000001ce4:	ff d0                	call   *%rax
ffff800000001ce6:	66 83 7d 38 00       	cmpw   $0x0,0x38(%rbp)
ffff800000001ceb:	4c 8b 55 20          	mov    0x20(%rbp),%r10
ffff800000001cef:	49 89 c4             	mov    %rax,%r12
ffff800000001cf2:	0f 84 28 02 00 00    	je     ffff800000001f20 <execute_elf+0x330>
ffff800000001cf8:	48 b8 50 2e 00 00 00 	movabs $0xffff800000002e50,%rax
ffff800000001cff:	80 ff ff 
ffff800000001d02:	4e 8d 6c 15 00       	lea    0x0(%rbp,%r10,1),%r13
ffff800000001d07:	31 db                	xor    %ebx,%ebx
ffff800000001d09:	48 89 04 24          	mov    %rax,(%rsp)
ffff800000001d0d:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000001d14:	80 ff ff 
ffff800000001d17:	48 89 44 24 10       	mov    %rax,0x10(%rsp)
ffff800000001d1c:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff800000001d23:	80 ff ff 
ffff800000001d26:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
ffff800000001d2b:	eb 16                	jmp    ffff800000001d43 <execute_elf+0x153>
ffff800000001d2d:	0f 1f 00             	nopl   (%rax)
ffff800000001d30:	0f b7 45 38          	movzwl 0x38(%rbp),%eax
ffff800000001d34:	83 c3 01             	add    $0x1,%ebx
ffff800000001d37:	49 83 c5 38          	add    $0x38,%r13
ffff800000001d3b:	39 c3                	cmp    %eax,%ebx
ffff800000001d3d:	0f 8d 06 01 00 00    	jge    ffff800000001e49 <execute_elf+0x259>
ffff800000001d43:	41 83 7d 00 01       	cmpl   $0x1,0x0(%r13)
ffff800000001d48:	75 e6                	jne    ffff800000001d30 <execute_elf+0x140>
ffff800000001d4a:	49 8b 45 10          	mov    0x10(%r13),%rax
ffff800000001d4e:	49 8b 55 20          	mov    0x20(%r13),%rdx
ffff800000001d52:	49 89 c7             	mov    %rax,%r15
ffff800000001d55:	48 89 44 24 20       	mov    %rax,0x20(%rsp)
ffff800000001d5a:	49 03 45 28          	add    0x28(%r13),%rax
ffff800000001d5e:	48 05 ff 0f 00 00    	add    $0xfff,%rax
ffff800000001d64:	49 81 e7 00 f0 ff ff 	and    $0xfffffffffffff000,%r15
ffff800000001d6b:	48 89 54 24 28       	mov    %rdx,0x28(%rsp)
ffff800000001d70:	49 8b 55 08          	mov    0x8(%r13),%rdx
ffff800000001d74:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffff800000001d7a:	4c 29 f8             	sub    %r15,%rax
ffff800000001d7d:	48 89 54 24 30       	mov    %rdx,0x30(%rsp)
ffff800000001d82:	48 c1 e8 0c          	shr    $0xc,%rax
ffff800000001d86:	74 75                	je     ffff800000001dfd <execute_elf+0x20d>
ffff800000001d88:	48 c1 e0 0c          	shl    $0xc,%rax
ffff800000001d8c:	48 89 6c 24 38       	mov    %rbp,0x38(%rsp)
ffff800000001d91:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
ffff800000001d96:	4c 01 f8             	add    %r15,%rax
ffff800000001d99:	4c 89 6c 24 48       	mov    %r13,0x48(%rsp)
ffff800000001d9e:	4d 89 fd             	mov    %r15,%r13
ffff800000001da1:	4c 8b 7c 24 10       	mov    0x10(%rsp),%r15
ffff800000001da6:	89 5c 24 44          	mov    %ebx,0x44(%rsp)
ffff800000001daa:	48 89 c3             	mov    %rax,%rbx
ffff800000001dad:	0f 1f 00             	nopl   (%rax)
ffff800000001db0:	48 8b 0c 24          	mov    (%rsp),%rcx
ffff800000001db4:	31 c0                	xor    %eax,%eax
ffff800000001db6:	ff d1                	call   *%rcx
ffff800000001db8:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000001dbd:	31 f6                	xor    %esi,%esi
ffff800000001dbf:	49 89 c6             	mov    %rax,%r14
ffff800000001dc2:	48 b8 00 00 00 00 00 	movabs $0xffff800000000000,%rax
ffff800000001dc9:	80 ff ff 
ffff800000001dcc:	49 8d 3c 06          	lea    (%r14,%rax,1),%rdi
ffff800000001dd0:	41 ff d7             	call   *%r15
ffff800000001dd3:	4c 89 ee             	mov    %r13,%rsi
ffff800000001dd6:	49 81 c5 00 10 00 00 	add    $0x1000,%r13
ffff800000001ddd:	4c 89 f2             	mov    %r14,%rdx
ffff800000001de0:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff800000001de5:	4c 89 e7             	mov    %r12,%rdi
ffff800000001de8:	ff d5                	call   *%rbp
ffff800000001dea:	49 39 dd             	cmp    %rbx,%r13
ffff800000001ded:	75 c1                	jne    ffff800000001db0 <execute_elf+0x1c0>
ffff800000001def:	48 8b 6c 24 38       	mov    0x38(%rsp),%rbp
ffff800000001df4:	8b 5c 24 44          	mov    0x44(%rsp),%ebx
ffff800000001df8:	4c 8b 6c 24 48       	mov    0x48(%rsp),%r13
ffff800000001dfd:	9c                   	pushf  
ffff800000001dfe:	41 5e                	pop    %r14
ffff800000001e00:	fa                   	cli    
ffff800000001e01:	0f 20 d9             	mov    %cr3,%rcx
ffff800000001e04:	48 89 4c 24 38       	mov    %rcx,0x38(%rsp)
ffff800000001e09:	41 0f 22 dc          	mov    %r12,%cr3
ffff800000001e0d:	48 8b 74 24 30       	mov    0x30(%rsp),%rsi
ffff800000001e12:	48 8b 54 24 28       	mov    0x28(%rsp),%rdx
ffff800000001e17:	48 b8 10 48 00 00 00 	movabs $0xffff800000004810,%rax
ffff800000001e1e:	80 ff ff 
ffff800000001e21:	48 8b 7c 24 20       	mov    0x20(%rsp),%rdi
ffff800000001e26:	48 01 ee             	add    %rbp,%rsi
ffff800000001e29:	ff d0                	call   *%rax
ffff800000001e2b:	48 8b 4c 24 38       	mov    0x38(%rsp),%rcx
ffff800000001e30:	0f 22 d9             	mov    %rcx,%cr3
ffff800000001e33:	41 56                	push   %r14
ffff800000001e35:	9d                   	popf   
ffff800000001e36:	0f b7 45 38          	movzwl 0x38(%rbp),%eax
ffff800000001e3a:	83 c3 01             	add    $0x1,%ebx
ffff800000001e3d:	49 83 c5 38          	add    $0x38,%r13
ffff800000001e41:	39 c3                	cmp    %eax,%ebx
ffff800000001e43:	0f 8c fa fe ff ff    	jl     ffff800000001d43 <execute_elf+0x153>
ffff800000001e49:	48 8b 14 24          	mov    (%rsp),%rdx
ffff800000001e4d:	31 c0                	xor    %eax,%eax
ffff800000001e4f:	ff d2                	call   *%rdx
ffff800000001e51:	31 f6                	xor    %esi,%esi
ffff800000001e53:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000001e58:	48 bf 00 00 00 00 00 	movabs $0xffff800000000000,%rdi
ffff800000001e5f:	80 ff ff 
ffff800000001e62:	49 89 c5             	mov    %rax,%r13
ffff800000001e65:	48 01 c7             	add    %rax,%rdi
ffff800000001e68:	48 8b 44 24 10       	mov    0x10(%rsp),%rax
ffff800000001e6d:	ff d0                	call   *%rax
ffff800000001e6f:	4c 89 ea             	mov    %r13,%rdx
ffff800000001e72:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
ffff800000001e77:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff800000001e7c:	48 be 00 e0 ff ff ff 	movabs $0x7fffffffe000,%rsi
ffff800000001e83:	7f 00 00 
ffff800000001e86:	4c 89 e7             	mov    %r12,%rdi
ffff800000001e89:	49 bd e0 77 00 00 00 	movabs $0xffff8000000077e0,%r13
ffff800000001e90:	80 ff ff 
ffff800000001e93:	ff d0                	call   *%rax
ffff800000001e95:	48 89 ef             	mov    %rbp,%rdi
ffff800000001e98:	48 b8 90 2a 00 00 00 	movabs $0xffff800000002a90,%rax
ffff800000001e9f:	80 ff ff 
ffff800000001ea2:	ff d0                	call   *%rax
ffff800000001ea4:	48 8b 4c 24 18       	mov    0x18(%rsp),%rcx
ffff800000001ea9:	48 b8 ff ff ff ff ff 	movabs $0x7fffffffffff,%rax
ffff800000001eb0:	7f 00 00 
ffff800000001eb3:	48 bf 58 57 00 00 00 	movabs $0xffff800000005758,%rdi
ffff800000001eba:	80 ff ff 
ffff800000001ebd:	48 39 c1             	cmp    %rax,%rcx
ffff800000001ec0:	b8 00 00 40 00       	mov    $0x400000,%eax
ffff800000001ec5:	48 0f 46 c1          	cmovbe %rcx,%rax
ffff800000001ec9:	48 89 c3             	mov    %rax,%rbx
ffff800000001ecc:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff800000001ed3:	80 ff ff 
ffff800000001ed6:	ff d0                	call   *%rax
ffff800000001ed8:	4c 89 ef             	mov    %r13,%rdi
ffff800000001edb:	48 b8 f0 23 00 00 00 	movabs $0xffff8000000023f0,%rax
ffff800000001ee2:	80 ff ff 
ffff800000001ee5:	ff d0                	call   *%rax
ffff800000001ee7:	4c 89 e8             	mov    %r13,%rax
ffff800000001eea:	48 a3 c0 8a 00 00 00 	movabs %rax,0xffff800000008ac0
ffff800000001ef1:	80 ff ff 
ffff800000001ef4:	fa                   	cli    
ffff800000001ef5:	48 ba 00 f0 ff ff ff 	movabs $0x7ffffffff000,%rdx
ffff800000001efc:	7f 00 00 
ffff800000001eff:	41 0f 22 dc          	mov    %r12,%cr3
ffff800000001f03:	66 b8 1b 00          	mov    $0x1b,%ax
ffff800000001f07:	8e d8                	mov    %eax,%ds
ffff800000001f09:	8e c0                	mov    %eax,%es
ffff800000001f0b:	8e e0                	mov    %eax,%fs
ffff800000001f0d:	8e e8                	mov    %eax,%gs
ffff800000001f0f:	6a 1b                	push   $0x1b
ffff800000001f11:	52                   	push   %rdx
ffff800000001f12:	68 02 02 00 00       	push   $0x202
ffff800000001f17:	6a 23                	push   $0x23
ffff800000001f19:	53                   	push   %rbx
ffff800000001f1a:	48 cf                	iretq  
ffff800000001f1c:	eb fe                	jmp    ffff800000001f1c <execute_elf+0x32c>
ffff800000001f1e:	66 90                	xchg   %ax,%ax
ffff800000001f20:	48 b8 50 2e 00 00 00 	movabs $0xffff800000002e50,%rax
ffff800000001f27:	80 ff ff 
ffff800000001f2a:	48 89 04 24          	mov    %rax,(%rsp)
ffff800000001f2e:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000001f35:	80 ff ff 
ffff800000001f38:	48 89 44 24 10       	mov    %rax,0x10(%rsp)
ffff800000001f3d:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff800000001f44:	80 ff ff 
ffff800000001f47:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
ffff800000001f4c:	e9 f8 fe ff ff       	jmp    ffff800000001e49 <execute_elf+0x259>
ffff800000001f51:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff800000001f58:	00 00 00 
ffff800000001f5b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff800000001f60 <fs_init>:
ffff800000001f60:	48 bf 88 57 00 00 00 	movabs $0xffff800000005788,%rdi
ffff800000001f67:	80 ff ff 
ffff800000001f6a:	55                   	push   %rbp
ffff800000001f6b:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000001f72:	80 ff ff 
ffff800000001f75:	53                   	push   %rbx
ffff800000001f76:	48 81 ec 08 02 00 00 	sub    $0x208,%rsp
ffff800000001f7d:	ff d0                	call   *%rax
ffff800000001f7f:	31 c0                	xor    %eax,%eax
ffff800000001f81:	48 8d 7c 24 08       	lea    0x8(%rsp),%rdi
ffff800000001f86:	b9 3f 00 00 00       	mov    $0x3f,%ecx
ffff800000001f8b:	f3 48 ab             	rep stos %rax,%es:(%rdi)
ffff800000001f8e:	ba 01 00 00 00       	mov    $0x1,%edx
ffff800000001f93:	48 89 e6             	mov    %rsp,%rsi
ffff800000001f96:	bf f0 03 00 00       	mov    $0x3f0,%edi
ffff800000001f9b:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
ffff800000001fa2:	00 
ffff800000001fa3:	48 b8 f0 1a 00 00 00 	movabs $0xffff800000001af0,%rax
ffff800000001faa:	80 ff ff 
ffff800000001fad:	ff d0                	call   *%rax
ffff800000001faf:	81 3c 24 11 08 98 19 	cmpl   $0x19980811,(%rsp)
ffff800000001fb6:	74 28                	je     ffff800000001fe0 <fs_init+0x80>
ffff800000001fb8:	48 bf fa 57 00 00 00 	movabs $0xffff8000000057fa,%rdi
ffff800000001fbf:	80 ff ff 
ffff800000001fc2:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000001fc9:	80 ff ff 
ffff800000001fcc:	ff d0                	call   *%rax
ffff800000001fce:	48 81 c4 08 02 00 00 	add    $0x208,%rsp
ffff800000001fd5:	5b                   	pop    %rbx
ffff800000001fd6:	5d                   	pop    %rbp
ffff800000001fd7:	c3                   	ret    
ffff800000001fd8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000001fdf:	00 
ffff800000001fe0:	48 bd 00 78 00 00 00 	movabs $0xffff800000007800,%rbp
ffff800000001fe7:	80 ff ff 
ffff800000001fea:	48 8b 04 24          	mov    (%rsp),%rax
ffff800000001fee:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000001ff5:	80 ff ff 
ffff800000001ff8:	48 bf b0 57 00 00 00 	movabs $0xffff8000000057b0,%rdi
ffff800000001fff:	80 ff ff 
ffff800000002002:	48 89 45 00          	mov    %rax,0x0(%rbp)
ffff800000002006:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
ffff80000000200b:	48 a3 08 78 00 00 00 	movabs %rax,0xffff800000007808
ffff800000002012:	80 ff ff 
ffff800000002015:	48 8b 44 24 10       	mov    0x10(%rsp),%rax
ffff80000000201a:	48 a3 10 78 00 00 00 	movabs %rax,0xffff800000007810
ffff800000002021:	80 ff ff 
ffff800000002024:	48 8b 44 24 18       	mov    0x18(%rsp),%rax
ffff800000002029:	48 a3 18 78 00 00 00 	movabs %rax,0xffff800000007818
ffff800000002030:	80 ff ff 
ffff800000002033:	48 b8 e0 77 00 00 00 	movabs $0xffff8000000077e0,%rax
ffff80000000203a:	80 ff ff 
ffff80000000203d:	c7 00 01 00 00 00    	movl   $0x1,(%rax)
ffff800000002043:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff80000000204a:	80 ff ff 
ffff80000000204d:	ff d0                	call   *%rax
ffff80000000204f:	48 bf e1 57 00 00 00 	movabs $0xffff8000000057e1,%rdi
ffff800000002056:	80 ff ff 
ffff800000002059:	ff d3                	call   *%rbx
ffff80000000205b:	8b 7d 00             	mov    0x0(%rbp),%edi
ffff80000000205e:	48 b8 80 35 00 00 00 	movabs $0xffff800000003580,%rax
ffff800000002065:	80 ff ff 
ffff800000002068:	ff d0                	call   *%rax
ffff80000000206a:	48 bf 52 64 00 00 00 	movabs $0xffff800000006452,%rdi
ffff800000002071:	80 ff ff 
ffff800000002074:	ff d3                	call   *%rbx
ffff800000002076:	48 81 c4 08 02 00 00 	add    $0x208,%rsp
ffff80000000207d:	5b                   	pop    %rbx
ffff80000000207e:	5d                   	pop    %rbp
ffff80000000207f:	c3                   	ret    

ffff800000002080 <fs_find_file>:
ffff800000002080:	48 b8 e0 77 00 00 00 	movabs $0xffff8000000077e0,%rax
ffff800000002087:	80 ff ff 
ffff80000000208a:	8b 00                	mov    (%rax),%eax
ffff80000000208c:	85 c0                	test   %eax,%eax
ffff80000000208e:	75 08                	jne    ffff800000002098 <fs_find_file+0x18>
ffff800000002090:	31 c0                	xor    %eax,%eax
ffff800000002092:	c3                   	ret    
ffff800000002093:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000002098:	41 56                	push   %r14
ffff80000000209a:	ba 01 00 00 00       	mov    $0x1,%edx
ffff80000000209f:	49 be f0 1a 00 00 00 	movabs $0xffff800000001af0,%r14
ffff8000000020a6:	80 ff ff 
ffff8000000020a9:	41 55                	push   %r13
ffff8000000020ab:	41 54                	push   %r12
ffff8000000020ad:	49 89 f4             	mov    %rsi,%r12
ffff8000000020b0:	55                   	push   %rbp
ffff8000000020b1:	53                   	push   %rbx
ffff8000000020b2:	48 89 fb             	mov    %rdi,%rbx
ffff8000000020b5:	bf 08 04 00 00       	mov    $0x408,%edi
ffff8000000020ba:	48 81 ec 00 04 00 00 	sub    $0x400,%rsp
ffff8000000020c1:	4c 8d ac 24 00 02 00 	lea    0x200(%rsp),%r13
ffff8000000020c8:	00 
ffff8000000020c9:	4c 89 ee             	mov    %r13,%rsi
ffff8000000020cc:	41 ff d6             	call   *%r14
ffff8000000020cf:	8b 84 24 4c 02 00 00 	mov    0x24c(%rsp),%eax
ffff8000000020d6:	66 83 bc 24 48 02 00 	cmpw   $0x1,0x248(%rsp)
ffff8000000020dd:	00 01 
ffff8000000020df:	74 17                	je     ffff8000000020f8 <fs_find_file+0x78>
ffff8000000020e1:	48 81 c4 00 04 00 00 	add    $0x400,%rsp
ffff8000000020e8:	31 c0                	xor    %eax,%eax
ffff8000000020ea:	5b                   	pop    %rbx
ffff8000000020eb:	5d                   	pop    %rbp
ffff8000000020ec:	41 5c                	pop    %r12
ffff8000000020ee:	41 5d                	pop    %r13
ffff8000000020f0:	41 5e                	pop    %r14
ffff8000000020f2:	c3                   	ret    
ffff8000000020f3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff8000000020f8:	8d 3c c5 e8 03 00 00 	lea    0x3e8(,%rax,8),%edi
ffff8000000020ff:	ba 01 00 00 00       	mov    $0x1,%edx
ffff800000002104:	48 89 e6             	mov    %rsp,%rsi
ffff800000002107:	41 ff d6             	call   *%r14
ffff80000000210a:	48 89 e1             	mov    %rsp,%rcx
ffff80000000210d:	eb 0a                	jmp    ffff800000002119 <fs_find_file+0x99>
ffff80000000210f:	90                   	nop
ffff800000002110:	48 83 c1 40          	add    $0x40,%rcx
ffff800000002114:	49 39 cd             	cmp    %rcx,%r13
ffff800000002117:	74 c8                	je     ffff8000000020e1 <fs_find_file+0x61>
ffff800000002119:	8b 29                	mov    (%rcx),%ebp
ffff80000000211b:	85 ed                	test   %ebp,%ebp
ffff80000000211d:	74 f1                	je     ffff800000002110 <fs_find_file+0x90>
ffff80000000211f:	31 c0                	xor    %eax,%eax
ffff800000002121:	eb 0f                	jmp    ffff800000002132 <fs_find_file+0xb2>
ffff800000002123:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000002128:	48 83 c0 01          	add    $0x1,%rax
ffff80000000212c:	48 83 f8 3c          	cmp    $0x3c,%rax
ffff800000002130:	74 0e                	je     ffff800000002140 <fs_find_file+0xc0>
ffff800000002132:	0f b6 14 03          	movzbl (%rbx,%rax,1),%edx
ffff800000002136:	38 54 01 04          	cmp    %dl,0x4(%rcx,%rax,1)
ffff80000000213a:	75 d4                	jne    ffff800000002110 <fs_find_file+0x90>
ffff80000000213c:	84 d2                	test   %dl,%dl
ffff80000000213e:	75 e8                	jne    ffff800000002128 <fs_find_file+0xa8>
ffff800000002140:	89 ef                	mov    %ebp,%edi
ffff800000002142:	83 e5 07             	and    $0x7,%ebp
ffff800000002145:	ba 01 00 00 00       	mov    $0x1,%edx
ffff80000000214a:	4c 89 ee             	mov    %r13,%rsi
ffff80000000214d:	c1 ef 03             	shr    $0x3,%edi
ffff800000002150:	81 c7 08 04 00 00    	add    $0x408,%edi
ffff800000002156:	41 ff d6             	call   *%r14
ffff800000002159:	6b c5 44             	imul   $0x44,%ebp,%eax
ffff80000000215c:	48 8b 94 04 00 02 00 	mov    0x200(%rsp,%rax,1),%rdx
ffff800000002163:	00 
ffff800000002164:	49 89 14 24          	mov    %rdx,(%r12)
ffff800000002168:	48 8b 94 04 08 02 00 	mov    0x208(%rsp,%rax,1),%rdx
ffff80000000216f:	00 
ffff800000002170:	49 89 54 24 08       	mov    %rdx,0x8(%r12)
ffff800000002175:	48 8b 94 04 10 02 00 	mov    0x210(%rsp,%rax,1),%rdx
ffff80000000217c:	00 
ffff80000000217d:	49 89 54 24 10       	mov    %rdx,0x10(%r12)
ffff800000002182:	48 8b 94 04 18 02 00 	mov    0x218(%rsp,%rax,1),%rdx
ffff800000002189:	00 
ffff80000000218a:	49 89 54 24 18       	mov    %rdx,0x18(%r12)
ffff80000000218f:	48 8b 94 04 20 02 00 	mov    0x220(%rsp,%rax,1),%rdx
ffff800000002196:	00 
ffff800000002197:	49 89 54 24 20       	mov    %rdx,0x20(%r12)
ffff80000000219c:	48 8b 94 04 28 02 00 	mov    0x228(%rsp,%rax,1),%rdx
ffff8000000021a3:	00 
ffff8000000021a4:	49 89 54 24 28       	mov    %rdx,0x28(%r12)
ffff8000000021a9:	48 8b 94 04 30 02 00 	mov    0x230(%rsp,%rax,1),%rdx
ffff8000000021b0:	00 
ffff8000000021b1:	49 89 54 24 30       	mov    %rdx,0x30(%r12)
ffff8000000021b6:	48 8b 94 04 38 02 00 	mov    0x238(%rsp,%rax,1),%rdx
ffff8000000021bd:	00 
ffff8000000021be:	8b 84 04 40 02 00 00 	mov    0x240(%rsp,%rax,1),%eax
ffff8000000021c5:	49 89 54 24 38       	mov    %rdx,0x38(%r12)
ffff8000000021ca:	41 89 44 24 40       	mov    %eax,0x40(%r12)
ffff8000000021cf:	48 81 c4 00 04 00 00 	add    $0x400,%rsp
ffff8000000021d6:	b8 01 00 00 00       	mov    $0x1,%eax
ffff8000000021db:	5b                   	pop    %rbx
ffff8000000021dc:	5d                   	pop    %rbp
ffff8000000021dd:	41 5c                	pop    %r12
ffff8000000021df:	41 5d                	pop    %r13
ffff8000000021e1:	41 5e                	pop    %r14
ffff8000000021e3:	c3                   	ret    

ffff8000000021e4 <gdt_flush>:
ffff8000000021e4:	0f 01 17             	lgdt   (%rdi)
ffff8000000021e7:	66 b8 10 00          	mov    $0x10,%ax
ffff8000000021eb:	8e d8                	mov    %eax,%ds
ffff8000000021ed:	8e c0                	mov    %eax,%es
ffff8000000021ef:	8e e0                	mov    %eax,%fs
ffff8000000021f1:	8e e8                	mov    %eax,%gs
ffff8000000021f3:	8e d0                	mov    %eax,%ss
ffff8000000021f5:	6a 08                	push   $0x8
ffff8000000021f7:	48 8d 05 03 00 00 00 	lea    0x3(%rip),%rax        # ffff800000002201 <.flush_cs>
ffff8000000021fe:	50                   	push   %rax
ffff8000000021ff:	48 cb                	lretq  

ffff800000002201 <.flush_cs>:
ffff800000002201:	c3                   	ret    

ffff800000002202 <tss_flush>:
ffff800000002202:	66 b8 28 00          	mov    $0x28,%ax
ffff800000002206:	0f 00 d8             	ltr    %ax
ffff800000002209:	c3                   	ret    
ffff80000000220a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff800000002210 <set_gdt_entry>:
ffff800000002210:	48 b8 a0 78 00 00 00 	movabs $0xffff8000000078a0,%rax
ffff800000002217:	80 ff ff 
ffff80000000221a:	48 63 ff             	movslq %edi,%rdi
ffff80000000221d:	48 89 34 f8          	mov    %rsi,(%rax,%rdi,8)
ffff800000002221:	c3                   	ret    
ffff800000002222:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000002229:	00 00 00 00 
ffff80000000222d:	0f 1f 00             	nopl   (%rax)

ffff800000002230 <write_tss>:
ffff800000002230:	48 b9 20 78 00 00 00 	movabs $0xffff800000007820,%rcx
ffff800000002237:	80 ff ff 
ffff80000000223a:	48 8d 51 68          	lea    0x68(%rcx),%rdx
ffff80000000223e:	48 89 c8             	mov    %rcx,%rax
ffff800000002241:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000002248:	c6 00 00             	movb   $0x0,(%rax)
ffff80000000224b:	48 83 c0 01          	add    $0x1,%rax
ffff80000000224f:	48 39 d0             	cmp    %rdx,%rax
ffff800000002252:	75 f4                	jne    ffff800000002248 <write_tss+0x18>
ffff800000002254:	48 b8 86 78 00 00 00 	movabs $0xffff800000007886,%rax
ffff80000000225b:	80 ff ff 
ffff80000000225e:	ba 68 00 00 00       	mov    $0x68,%edx
ffff800000002263:	4c 63 c7             	movslq %edi,%r8
ffff800000002266:	48 be a0 78 00 00 00 	movabs $0xffff8000000078a0,%rsi
ffff80000000226d:	80 ff ff 
ffff800000002270:	66 89 10             	mov    %dx,(%rax)
ffff800000002273:	48 89 c8             	mov    %rcx,%rax
ffff800000002276:	48 ba 00 00 ff ff ff 	movabs $0xffffff0000,%rdx
ffff80000000227d:	00 00 00 
ffff800000002280:	48 c1 e0 10          	shl    $0x10,%rax
ffff800000002284:	48 21 d0             	and    %rdx,%rax
ffff800000002287:	89 ca                	mov    %ecx,%edx
ffff800000002289:	48 c1 e9 20          	shr    $0x20,%rcx
ffff80000000228d:	c1 ea 18             	shr    $0x18,%edx
ffff800000002290:	48 c1 e2 38          	shl    $0x38,%rdx
ffff800000002294:	48 09 d0             	or     %rdx,%rax
ffff800000002297:	48 ba 67 00 00 00 00 	movabs $0x890000000067,%rdx
ffff80000000229e:	89 00 00 
ffff8000000022a1:	48 09 d0             	or     %rdx,%rax
ffff8000000022a4:	4a 89 04 c6          	mov    %rax,(%rsi,%r8,8)
ffff8000000022a8:	8d 47 01             	lea    0x1(%rdi),%eax
ffff8000000022ab:	48 98                	cltq   
ffff8000000022ad:	48 89 0c c6          	mov    %rcx,(%rsi,%rax,8)
ffff8000000022b1:	c3                   	ret    
ffff8000000022b2:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000022b9:	00 00 00 00 
ffff8000000022bd:	0f 1f 00             	nopl   (%rax)

ffff8000000022c0 <gdt_init>:
ffff8000000022c0:	48 b8 88 78 00 00 00 	movabs $0xffff800000007888,%rax
ffff8000000022c7:	80 ff ff 
ffff8000000022ca:	b9 37 00 00 00       	mov    $0x37,%ecx
ffff8000000022cf:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000022d3:	48 be 20 78 00 00 00 	movabs $0xffff800000007820,%rsi
ffff8000000022da:	80 ff ff 
ffff8000000022dd:	66 89 08             	mov    %cx,(%rax)
ffff8000000022e0:	48 89 f2             	mov    %rsi,%rdx
ffff8000000022e3:	48 8d 4e 68          	lea    0x68(%rsi),%rcx
ffff8000000022e7:	48 b8 a0 78 00 00 00 	movabs $0xffff8000000078a0,%rax
ffff8000000022ee:	80 ff ff 
ffff8000000022f1:	48 a3 8a 78 00 00 00 	movabs %rax,0xffff80000000788a
ffff8000000022f8:	80 ff ff 
ffff8000000022fb:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
ffff800000002302:	48 b8 ff ff 00 00 00 	movabs $0xaf98000000ffff,%rax
ffff800000002309:	98 af 00 
ffff80000000230c:	48 a3 a8 78 00 00 00 	movabs %rax,0xffff8000000078a8
ffff800000002313:	80 ff ff 
ffff800000002316:	48 b8 ff ff 00 00 00 	movabs $0xcf92000000ffff,%rax
ffff80000000231d:	92 cf 00 
ffff800000002320:	48 a3 b0 78 00 00 00 	movabs %rax,0xffff8000000078b0
ffff800000002327:	80 ff ff 
ffff80000000232a:	48 b8 ff ff 00 00 00 	movabs $0xcff2000000ffff,%rax
ffff800000002331:	f2 cf 00 
ffff800000002334:	48 a3 b8 78 00 00 00 	movabs %rax,0xffff8000000078b8
ffff80000000233b:	80 ff ff 
ffff80000000233e:	48 b8 ff ff 00 00 00 	movabs $0xaffa000000ffff,%rax
ffff800000002345:	fa af 00 
ffff800000002348:	48 a3 c0 78 00 00 00 	movabs %rax,0xffff8000000078c0
ffff80000000234f:	80 ff ff 
ffff800000002352:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000002358:	c6 02 00             	movb   $0x0,(%rdx)
ffff80000000235b:	48 83 c2 01          	add    $0x1,%rdx
ffff80000000235f:	48 39 ca             	cmp    %rcx,%rdx
ffff800000002362:	75 f4                	jne    ffff800000002358 <gdt_init+0x98>
ffff800000002364:	48 b8 86 78 00 00 00 	movabs $0xffff800000007886,%rax
ffff80000000236b:	80 ff ff 
ffff80000000236e:	ba 68 00 00 00       	mov    $0x68,%edx
ffff800000002373:	48 bf 88 78 00 00 00 	movabs $0xffff800000007888,%rdi
ffff80000000237a:	80 ff ff 
ffff80000000237d:	66 89 10             	mov    %dx,(%rax)
ffff800000002380:	48 89 f0             	mov    %rsi,%rax
ffff800000002383:	48 ba 00 00 ff ff ff 	movabs $0xffffff0000,%rdx
ffff80000000238a:	00 00 00 
ffff80000000238d:	48 c1 e0 10          	shl    $0x10,%rax
ffff800000002391:	48 21 d0             	and    %rdx,%rax
ffff800000002394:	89 f2                	mov    %esi,%edx
ffff800000002396:	c1 ea 18             	shr    $0x18,%edx
ffff800000002399:	48 c1 e2 38          	shl    $0x38,%rdx
ffff80000000239d:	48 09 d0             	or     %rdx,%rax
ffff8000000023a0:	48 ba 67 00 00 00 00 	movabs $0x890000000067,%rdx
ffff8000000023a7:	89 00 00 
ffff8000000023aa:	48 09 d0             	or     %rdx,%rax
ffff8000000023ad:	48 a3 c8 78 00 00 00 	movabs %rax,0xffff8000000078c8
ffff8000000023b4:	80 ff ff 
ffff8000000023b7:	48 89 f0             	mov    %rsi,%rax
ffff8000000023ba:	48 c1 e8 20          	shr    $0x20,%rax
ffff8000000023be:	48 a3 d0 78 00 00 00 	movabs %rax,0xffff8000000078d0
ffff8000000023c5:	80 ff ff 
ffff8000000023c8:	48 b8 e4 21 00 00 00 	movabs $0xffff8000000021e4,%rax
ffff8000000023cf:	80 ff ff 
ffff8000000023d2:	ff d0                	call   *%rax
ffff8000000023d4:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000023d8:	48 b8 02 22 00 00 00 	movabs $0xffff800000002202,%rax
ffff8000000023df:	80 ff ff 
ffff8000000023e2:	ff e0                	jmp    *%rax
ffff8000000023e4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000023eb:	00 00 00 00 
ffff8000000023ef:	90                   	nop

ffff8000000023f0 <set_tss_rsp0>:
ffff8000000023f0:	48 89 f8             	mov    %rdi,%rax
ffff8000000023f3:	48 a3 24 78 00 00 00 	movabs %rax,0xffff800000007824
ffff8000000023fa:	80 ff ff 
ffff8000000023fd:	c3                   	ret    
ffff8000000023fe:	66 90                	xchg   %ax,%ax

ffff800000002400 <isr0_divide_by_zero>:
ffff800000002400:	41 54                	push   %r12
ffff800000002402:	41 53                	push   %r11
ffff800000002404:	41 52                	push   %r10
ffff800000002406:	41 51                	push   %r9
ffff800000002408:	41 50                	push   %r8
ffff80000000240a:	55                   	push   %rbp
ffff80000000240b:	48 bd 18 58 00 00 00 	movabs $0xffff800000005818,%rbp
ffff800000002412:	80 ff ff 
ffff800000002415:	57                   	push   %rdi
ffff800000002416:	48 89 ef             	mov    %rbp,%rdi
ffff800000002419:	56                   	push   %rsi
ffff80000000241a:	53                   	push   %rbx
ffff80000000241b:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000002422:	80 ff ff 
ffff800000002425:	51                   	push   %rcx
ffff800000002426:	52                   	push   %rdx
ffff800000002427:	50                   	push   %rax
ffff800000002428:	48 83 ec 08          	sub    $0x8,%rsp
ffff80000000242c:	fc                   	cld    
ffff80000000242d:	49 bc e0 38 00 00 00 	movabs $0xffff8000000038e0,%r12
ffff800000002434:	80 ff ff 
ffff800000002437:	ff d3                	call   *%rbx
ffff800000002439:	48 bf 50 58 00 00 00 	movabs $0xffff800000005850,%rdi
ffff800000002440:	80 ff ff 
ffff800000002443:	ff d3                	call   *%rbx
ffff800000002445:	48 bf 80 58 00 00 00 	movabs $0xffff800000005880,%rdi
ffff80000000244c:	80 ff ff 
ffff80000000244f:	ff d3                	call   *%rbx
ffff800000002451:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
ffff800000002456:	41 ff d4             	call   *%r12
ffff800000002459:	48 89 ef             	mov    %rbp,%rdi
ffff80000000245c:	ff d3                	call   *%rbx
ffff80000000245e:	48 bf 68 59 00 00 00 	movabs $0xffff800000005968,%rdi
ffff800000002465:	80 ff ff 
ffff800000002468:	ff d3                	call   *%rbx
ffff80000000246a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000002470:	f4                   	hlt    
ffff800000002471:	eb fd                	jmp    ffff800000002470 <isr0_divide_by_zero+0x70>
ffff800000002473:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff80000000247a:	00 00 00 00 
ffff80000000247e:	66 90                	xchg   %ax,%ax

ffff800000002480 <isr13_gpf>:
ffff800000002480:	41 54                	push   %r12
ffff800000002482:	41 53                	push   %r11
ffff800000002484:	41 52                	push   %r10
ffff800000002486:	41 51                	push   %r9
ffff800000002488:	41 50                	push   %r8
ffff80000000248a:	55                   	push   %rbp
ffff80000000248b:	57                   	push   %rdi
ffff80000000248c:	48 bf 18 58 00 00 00 	movabs $0xffff800000005818,%rdi
ffff800000002493:	80 ff ff 
ffff800000002496:	56                   	push   %rsi
ffff800000002497:	53                   	push   %rbx
ffff800000002498:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff80000000249f:	80 ff ff 
ffff8000000024a2:	51                   	push   %rcx
ffff8000000024a3:	52                   	push   %rdx
ffff8000000024a4:	50                   	push   %rax
ffff8000000024a5:	48 8b 6c 24 60       	mov    0x60(%rsp),%rbp
ffff8000000024aa:	fc                   	cld    
ffff8000000024ab:	49 bc e0 38 00 00 00 	movabs $0xffff8000000038e0,%r12
ffff8000000024b2:	80 ff ff 
ffff8000000024b5:	ff d3                	call   *%rbx
ffff8000000024b7:	48 bf a8 58 00 00 00 	movabs $0xffff8000000058a8,%rdi
ffff8000000024be:	80 ff ff 
ffff8000000024c1:	ff d3                	call   *%rbx
ffff8000000024c3:	48 bf 78 59 00 00 00 	movabs $0xffff800000005978,%rdi
ffff8000000024ca:	80 ff ff 
ffff8000000024cd:	ff d3                	call   *%rbx
ffff8000000024cf:	48 89 ef             	mov    %rbp,%rdi
ffff8000000024d2:	48 bd 52 64 00 00 00 	movabs $0xffff800000006452,%rbp
ffff8000000024d9:	80 ff ff 
ffff8000000024dc:	41 ff d4             	call   *%r12
ffff8000000024df:	48 89 ef             	mov    %rbp,%rdi
ffff8000000024e2:	ff d3                	call   *%rbx
ffff8000000024e4:	48 bf 85 59 00 00 00 	movabs $0xffff800000005985,%rdi
ffff8000000024eb:	80 ff ff 
ffff8000000024ee:	ff d3                	call   *%rbx
ffff8000000024f0:	48 8b 7c 24 68       	mov    0x68(%rsp),%rdi
ffff8000000024f5:	41 ff d4             	call   *%r12
ffff8000000024f8:	48 89 ef             	mov    %rbp,%rdi
ffff8000000024fb:	ff d3                	call   *%rbx
ffff8000000024fd:	48 bf e0 58 00 00 00 	movabs $0xffff8000000058e0,%rdi
ffff800000002504:	80 ff ff 
ffff800000002507:	ff d3                	call   *%rbx
ffff800000002509:	48 bf 68 59 00 00 00 	movabs $0xffff800000005968,%rdi
ffff800000002510:	80 ff ff 
ffff800000002513:	ff d3                	call   *%rbx
ffff800000002515:	0f 1f 00             	nopl   (%rax)
ffff800000002518:	f4                   	hlt    
ffff800000002519:	eb fd                	jmp    ffff800000002518 <isr13_gpf+0x98>
ffff80000000251b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff800000002520 <isr14_page_fault>:
ffff800000002520:	41 55                	push   %r13
ffff800000002522:	41 54                	push   %r12
ffff800000002524:	41 53                	push   %r11
ffff800000002526:	41 52                	push   %r10
ffff800000002528:	41 51                	push   %r9
ffff80000000252a:	41 50                	push   %r8
ffff80000000252c:	55                   	push   %rbp
ffff80000000252d:	57                   	push   %rdi
ffff80000000252e:	56                   	push   %rsi
ffff80000000252f:	53                   	push   %rbx
ffff800000002530:	51                   	push   %rcx
ffff800000002531:	52                   	push   %rdx
ffff800000002532:	50                   	push   %rax
ffff800000002533:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000002537:	4c 8b 6c 24 70       	mov    0x70(%rsp),%r13
ffff80000000253c:	0f 20 d5             	mov    %cr2,%rbp
ffff80000000253f:	48 bf 18 58 00 00 00 	movabs $0xffff800000005818,%rdi
ffff800000002546:	80 ff ff 
ffff800000002549:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000002550:	80 ff ff 
ffff800000002553:	fc                   	cld    
ffff800000002554:	49 bc e0 38 00 00 00 	movabs $0xffff8000000038e0,%r12
ffff80000000255b:	80 ff ff 
ffff80000000255e:	ff d3                	call   *%rbx
ffff800000002560:	48 bf 18 59 00 00 00 	movabs $0xffff800000005918,%rdi
ffff800000002567:	80 ff ff 
ffff80000000256a:	ff d3                	call   *%rbx
ffff80000000256c:	48 bf 48 59 00 00 00 	movabs $0xffff800000005948,%rdi
ffff800000002573:	80 ff ff 
ffff800000002576:	ff d3                	call   *%rbx
ffff800000002578:	48 89 ef             	mov    %rbp,%rdi
ffff80000000257b:	48 bd 52 64 00 00 00 	movabs $0xffff800000006452,%rbp
ffff800000002582:	80 ff ff 
ffff800000002585:	41 ff d4             	call   *%r12
ffff800000002588:	48 89 ef             	mov    %rbp,%rdi
ffff80000000258b:	ff d3                	call   *%rbx
ffff80000000258d:	48 bf 78 59 00 00 00 	movabs $0xffff800000005978,%rdi
ffff800000002594:	80 ff ff 
ffff800000002597:	ff d3                	call   *%rbx
ffff800000002599:	4c 89 ef             	mov    %r13,%rdi
ffff80000000259c:	41 ff d4             	call   *%r12
ffff80000000259f:	48 89 ef             	mov    %rbp,%rdi
ffff8000000025a2:	ff d3                	call   *%rbx
ffff8000000025a4:	48 bf 85 59 00 00 00 	movabs $0xffff800000005985,%rdi
ffff8000000025ab:	80 ff ff 
ffff8000000025ae:	ff d3                	call   *%rbx
ffff8000000025b0:	48 8b 7c 24 78       	mov    0x78(%rsp),%rdi
ffff8000000025b5:	41 ff d4             	call   *%r12
ffff8000000025b8:	48 89 ef             	mov    %rbp,%rdi
ffff8000000025bb:	ff d3                	call   *%rbx
ffff8000000025bd:	48 bf e0 58 00 00 00 	movabs $0xffff8000000058e0,%rdi
ffff8000000025c4:	80 ff ff 
ffff8000000025c7:	ff d3                	call   *%rbx
ffff8000000025c9:	48 bf 68 59 00 00 00 	movabs $0xffff800000005968,%rdi
ffff8000000025d0:	80 ff ff 
ffff8000000025d3:	ff d3                	call   *%rbx
ffff8000000025d5:	0f 1f 00             	nopl   (%rax)
ffff8000000025d8:	f4                   	hlt    
ffff8000000025d9:	eb fd                	jmp    ffff8000000025d8 <isr14_page_fault+0xb8>
ffff8000000025db:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff8000000025e0 <isr32_timer>:
ffff8000000025e0:	41 53                	push   %r11
ffff8000000025e2:	41 52                	push   %r10
ffff8000000025e4:	41 51                	push   %r9
ffff8000000025e6:	41 50                	push   %r8
ffff8000000025e8:	57                   	push   %rdi
ffff8000000025e9:	56                   	push   %rsi
ffff8000000025ea:	53                   	push   %rbx
ffff8000000025eb:	51                   	push   %rcx
ffff8000000025ec:	52                   	push   %rdx
ffff8000000025ed:	50                   	push   %rax
ffff8000000025ee:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000025f2:	fc                   	cld    
ffff8000000025f3:	48 bb 50 56 00 00 00 	movabs $0xffff800000005650,%rbx
ffff8000000025fa:	80 ff ff 
ffff8000000025fd:	ff d3                	call   *%rbx
ffff8000000025ff:	48 83 c4 08          	add    $0x8,%rsp
ffff800000002603:	58                   	pop    %rax
ffff800000002604:	5a                   	pop    %rdx
ffff800000002605:	59                   	pop    %rcx
ffff800000002606:	5b                   	pop    %rbx
ffff800000002607:	5e                   	pop    %rsi
ffff800000002608:	5f                   	pop    %rdi
ffff800000002609:	41 58                	pop    %r8
ffff80000000260b:	41 59                	pop    %r9
ffff80000000260d:	41 5a                	pop    %r10
ffff80000000260f:	41 5b                	pop    %r11
ffff800000002611:	48 cf                	iretq  
ffff800000002613:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff80000000261a:	00 00 00 00 
ffff80000000261e:	66 90                	xchg   %ax,%ax

ffff800000002620 <isr33_keyboard>:
ffff800000002620:	41 53                	push   %r11
ffff800000002622:	41 52                	push   %r10
ffff800000002624:	41 51                	push   %r9
ffff800000002626:	41 50                	push   %r8
ffff800000002628:	57                   	push   %rdi
ffff800000002629:	56                   	push   %rsi
ffff80000000262a:	53                   	push   %rbx
ffff80000000262b:	51                   	push   %rcx
ffff80000000262c:	52                   	push   %rdx
ffff80000000262d:	50                   	push   %rax
ffff80000000262e:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000002632:	e4 60                	in     $0x60,%al
ffff800000002634:	84 c0                	test   %al,%al
ffff800000002636:	78 16                	js     ffff80000000264e <isr33_keyboard+0x2e>
ffff800000002638:	48 ba a0 59 00 00 00 	movabs $0xffff8000000059a0,%rdx
ffff80000000263f:	80 ff ff 
ffff800000002642:	0f b6 c0             	movzbl %al,%eax
ffff800000002645:	0f be 3c 02          	movsbl (%rdx,%rax,1),%edi
ffff800000002649:	40 84 ff             	test   %dil,%dil
ffff80000000264c:	75 22                	jne    ffff800000002670 <isr33_keyboard+0x50>
ffff80000000264e:	b8 20 00 00 00       	mov    $0x20,%eax
ffff800000002653:	e6 20                	out    %al,$0x20
ffff800000002655:	48 83 c4 08          	add    $0x8,%rsp
ffff800000002659:	58                   	pop    %rax
ffff80000000265a:	5a                   	pop    %rdx
ffff80000000265b:	59                   	pop    %rcx
ffff80000000265c:	5b                   	pop    %rbx
ffff80000000265d:	5e                   	pop    %rsi
ffff80000000265e:	5f                   	pop    %rdi
ffff80000000265f:	41 58                	pop    %r8
ffff800000002661:	41 59                	pop    %r9
ffff800000002663:	41 5a                	pop    %r10
ffff800000002665:	41 5b                	pop    %r11
ffff800000002667:	48 cf                	iretq  
ffff800000002669:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000002670:	fc                   	cld    
ffff800000002671:	48 bb 20 46 00 00 00 	movabs $0xffff800000004620,%rbx
ffff800000002678:	80 ff ff 
ffff80000000267b:	ff d3                	call   *%rbx
ffff80000000267d:	eb cf                	jmp    ffff80000000264e <isr33_keyboard+0x2e>
ffff80000000267f:	90                   	nop

ffff800000002680 <set_idt_gate>:
ffff800000002680:	48 63 c7             	movslq %edi,%rax
ffff800000002683:	48 bf 00 79 00 00 00 	movabs $0xffff800000007900,%rdi
ffff80000000268a:	80 ff ff 
ffff80000000268d:	48 c1 e0 04          	shl    $0x4,%rax
ffff800000002691:	48 01 c7             	add    %rax,%rdi
ffff800000002694:	48 89 f0             	mov    %rsi,%rax
ffff800000002697:	66 89 37             	mov    %si,(%rdi)
ffff80000000269a:	48 c1 e8 10          	shr    $0x10,%rax
ffff80000000269e:	48 c1 ee 20          	shr    $0x20,%rsi
ffff8000000026a2:	c7 47 02 08 00 00 8e 	movl   $0x8e000008,0x2(%rdi)
ffff8000000026a9:	66 89 47 06          	mov    %ax,0x6(%rdi)
ffff8000000026ad:	89 77 08             	mov    %esi,0x8(%rdi)
ffff8000000026b0:	c7 47 0c 00 00 00 00 	movl   $0x0,0xc(%rdi)
ffff8000000026b7:	c3                   	ret    
ffff8000000026b8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff8000000026bf:	00 

ffff8000000026c0 <idt_init>:
ffff8000000026c0:	48 b9 00 79 00 00 00 	movabs $0xffff800000007900,%rcx
ffff8000000026c7:	80 ff ff 
ffff8000000026ca:	48 8d 91 00 10 00 00 	lea    0x1000(%rcx),%rdx
ffff8000000026d1:	48 89 c8             	mov    %rcx,%rax
ffff8000000026d4:	0f 1f 40 00          	nopl   0x0(%rax)
ffff8000000026d8:	31 f6                	xor    %esi,%esi
ffff8000000026da:	bf 08 00 00 00       	mov    $0x8,%edi
ffff8000000026df:	45 31 c0             	xor    %r8d,%r8d
ffff8000000026e2:	c6 40 04 00          	movb   $0x0,0x4(%rax)
ffff8000000026e6:	66 89 30             	mov    %si,(%rax)
ffff8000000026e9:	48 83 c0 10          	add    $0x10,%rax
ffff8000000026ed:	66 89 78 f2          	mov    %di,-0xe(%rax)
ffff8000000026f1:	c6 40 f5 8e          	movb   $0x8e,-0xb(%rax)
ffff8000000026f5:	66 44 89 40 f6       	mov    %r8w,-0xa(%rax)
ffff8000000026fa:	c7 40 f8 00 00 00 00 	movl   $0x0,-0x8(%rax)
ffff800000002701:	c7 40 fc 00 00 00 00 	movl   $0x0,-0x4(%rax)
ffff800000002708:	48 39 d0             	cmp    %rdx,%rax
ffff80000000270b:	75 cb                	jne    ffff8000000026d8 <idt_init+0x18>
ffff80000000270d:	48 ba 00 24 00 00 00 	movabs $0xffff800000002400,%rdx
ffff800000002714:	80 ff ff 
ffff800000002717:	48 b8 02 79 00 00 00 	movabs $0xffff800000007902,%rax
ffff80000000271e:	80 ff ff 
ffff800000002721:	c7 00 08 00 00 8e    	movl   $0x8e000008,(%rax)
ffff800000002727:	48 89 d0             	mov    %rdx,%rax
ffff80000000272a:	48 c1 e8 10          	shr    $0x10,%rax
ffff80000000272e:	66 89 11             	mov    %dx,(%rcx)
ffff800000002731:	66 a3 06 79 00 00 00 	movabs %ax,0xffff800000007906
ffff800000002738:	80 ff ff 
ffff80000000273b:	48 89 d0             	mov    %rdx,%rax
ffff80000000273e:	48 ba 80 24 00 00 00 	movabs $0xffff800000002480,%rdx
ffff800000002745:	80 ff ff 
ffff800000002748:	48 c1 e8 20          	shr    $0x20,%rax
ffff80000000274c:	a3 08 79 00 00 00 80 	movabs %eax,0xffff800000007908
ffff800000002753:	ff ff 
ffff800000002755:	48 b8 0c 79 00 00 00 	movabs $0xffff80000000790c,%rax
ffff80000000275c:	80 ff ff 
ffff80000000275f:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff800000002765:	89 d0                	mov    %edx,%eax
ffff800000002767:	66 a3 d0 79 00 00 00 	movabs %ax,0xffff8000000079d0
ffff80000000276e:	80 ff ff 
ffff800000002771:	48 b8 d2 79 00 00 00 	movabs $0xffff8000000079d2,%rax
ffff800000002778:	80 ff ff 
ffff80000000277b:	c7 00 08 00 00 8e    	movl   $0x8e000008,(%rax)
ffff800000002781:	48 89 d0             	mov    %rdx,%rax
ffff800000002784:	48 c1 e8 10          	shr    $0x10,%rax
ffff800000002788:	66 a3 d6 79 00 00 00 	movabs %ax,0xffff8000000079d6
ffff80000000278f:	80 ff ff 
ffff800000002792:	48 89 d0             	mov    %rdx,%rax
ffff800000002795:	48 ba 20 25 00 00 00 	movabs $0xffff800000002520,%rdx
ffff80000000279c:	80 ff ff 
ffff80000000279f:	48 c1 e8 20          	shr    $0x20,%rax
ffff8000000027a3:	a3 d8 79 00 00 00 80 	movabs %eax,0xffff8000000079d8
ffff8000000027aa:	ff ff 
ffff8000000027ac:	48 b8 dc 79 00 00 00 	movabs $0xffff8000000079dc,%rax
ffff8000000027b3:	80 ff ff 
ffff8000000027b6:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff8000000027bc:	89 d0                	mov    %edx,%eax
ffff8000000027be:	66 a3 e0 79 00 00 00 	movabs %ax,0xffff8000000079e0
ffff8000000027c5:	80 ff ff 
ffff8000000027c8:	48 b8 e2 79 00 00 00 	movabs $0xffff8000000079e2,%rax
ffff8000000027cf:	80 ff ff 
ffff8000000027d2:	c7 00 08 00 00 8e    	movl   $0x8e000008,(%rax)
ffff8000000027d8:	48 89 d0             	mov    %rdx,%rax
ffff8000000027db:	48 c1 e8 10          	shr    $0x10,%rax
ffff8000000027df:	66 a3 e6 79 00 00 00 	movabs %ax,0xffff8000000079e6
ffff8000000027e6:	80 ff ff 
ffff8000000027e9:	48 89 d0             	mov    %rdx,%rax
ffff8000000027ec:	48 ba e0 25 00 00 00 	movabs $0xffff8000000025e0,%rdx
ffff8000000027f3:	80 ff ff 
ffff8000000027f6:	48 c1 e8 20          	shr    $0x20,%rax
ffff8000000027fa:	a3 e8 79 00 00 00 80 	movabs %eax,0xffff8000000079e8
ffff800000002801:	ff ff 
ffff800000002803:	48 b8 ec 79 00 00 00 	movabs $0xffff8000000079ec,%rax
ffff80000000280a:	80 ff ff 
ffff80000000280d:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff800000002813:	89 d0                	mov    %edx,%eax
ffff800000002815:	66 a3 00 7b 00 00 00 	movabs %ax,0xffff800000007b00
ffff80000000281c:	80 ff ff 
ffff80000000281f:	48 b8 02 7b 00 00 00 	movabs $0xffff800000007b02,%rax
ffff800000002826:	80 ff ff 
ffff800000002829:	c7 00 08 00 00 8e    	movl   $0x8e000008,(%rax)
ffff80000000282f:	48 89 d0             	mov    %rdx,%rax
ffff800000002832:	48 c1 e8 10          	shr    $0x10,%rax
ffff800000002836:	66 a3 06 7b 00 00 00 	movabs %ax,0xffff800000007b06
ffff80000000283d:	80 ff ff 
ffff800000002840:	48 89 d0             	mov    %rdx,%rax
ffff800000002843:	48 ba 20 26 00 00 00 	movabs $0xffff800000002620,%rdx
ffff80000000284a:	80 ff ff 
ffff80000000284d:	48 c1 e8 20          	shr    $0x20,%rax
ffff800000002851:	a3 08 7b 00 00 00 80 	movabs %eax,0xffff800000007b08
ffff800000002858:	ff ff 
ffff80000000285a:	48 b8 0c 7b 00 00 00 	movabs $0xffff800000007b0c,%rax
ffff800000002861:	80 ff ff 
ffff800000002864:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff80000000286a:	89 d0                	mov    %edx,%eax
ffff80000000286c:	66 a3 10 7b 00 00 00 	movabs %ax,0xffff800000007b10
ffff800000002873:	80 ff ff 
ffff800000002876:	48 b8 12 7b 00 00 00 	movabs $0xffff800000007b12,%rax
ffff80000000287d:	80 ff ff 
ffff800000002880:	c7 00 08 00 00 8e    	movl   $0x8e000008,(%rax)
ffff800000002886:	48 89 d0             	mov    %rdx,%rax
ffff800000002889:	48 c1 e8 10          	shr    $0x10,%rax
ffff80000000288d:	66 a3 16 7b 00 00 00 	movabs %ax,0xffff800000007b16
ffff800000002894:	80 ff ff 
ffff800000002897:	48 89 d0             	mov    %rdx,%rax
ffff80000000289a:	ba ff 0f 00 00       	mov    $0xfff,%edx
ffff80000000289f:	48 c1 e8 20          	shr    $0x20,%rax
ffff8000000028a3:	a3 18 7b 00 00 00 80 	movabs %eax,0xffff800000007b18
ffff8000000028aa:	ff ff 
ffff8000000028ac:	48 b8 1c 7b 00 00 00 	movabs $0xffff800000007b1c,%rax
ffff8000000028b3:	80 ff ff 
ffff8000000028b6:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff8000000028bc:	48 b8 e0 78 00 00 00 	movabs $0xffff8000000078e0,%rax
ffff8000000028c3:	80 ff ff 
ffff8000000028c6:	66 89 10             	mov    %dx,(%rax)
ffff8000000028c9:	48 89 c8             	mov    %rcx,%rax
ffff8000000028cc:	48 a3 e2 78 00 00 00 	movabs %rax,0xffff8000000078e2
ffff8000000028d3:	80 ff ff 
ffff8000000028d6:	48 b8 e0 78 00 00 00 	movabs $0xffff8000000078e0,%rax
ffff8000000028dd:	80 ff ff 
ffff8000000028e0:	0f 01 18             	lidt   (%rax)
ffff8000000028e3:	c3                   	ret    
ffff8000000028e4:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000028eb:	00 00 00 
ffff8000000028ee:	66 90                	xchg   %ax,%ax

ffff8000000028f0 <kmalloc_init>:
ffff8000000028f0:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff8000000028f7:	80 ff ff 
ffff8000000028fa:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000028fe:	31 c0                	xor    %eax,%eax
ffff800000002900:	ff d2                	call   *%rdx
ffff800000002902:	48 85 c0             	test   %rax,%rax
ffff800000002905:	74 49                	je     ffff800000002950 <kmalloc_init+0x60>
ffff800000002907:	48 ba 00 00 00 00 00 	movabs $0xffff800000000000,%rdx
ffff80000000290e:	80 ff ff 
ffff800000002911:	48 bf 58 5a 00 00 00 	movabs $0xffff800000005a58,%rdi
ffff800000002918:	80 ff ff 
ffff80000000291b:	48 01 d0             	add    %rdx,%rax
ffff80000000291e:	48 a3 00 89 00 00 00 	movabs %rax,0xffff800000008900
ffff800000002925:	80 ff ff 
ffff800000002928:	48 c7 40 10 e8 0f 00 	movq   $0xfe8,0x10(%rax)
ffff80000000292f:	00 
ffff800000002930:	c6 40 08 01          	movb   $0x1,0x8(%rax)
ffff800000002934:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
ffff80000000293b:	48 83 c4 08          	add    $0x8,%rsp
ffff80000000293f:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000002946:	80 ff ff 
ffff800000002949:	ff e0                	jmp    *%rax
ffff80000000294b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000002950:	48 bf 20 5a 00 00 00 	movabs $0xffff800000005a20,%rdi
ffff800000002957:	80 ff ff 
ffff80000000295a:	48 83 c4 08          	add    $0x8,%rsp
ffff80000000295e:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000002965:	80 ff ff 
ffff800000002968:	ff e0                	jmp    *%rax
ffff80000000296a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff800000002970 <kmalloc>:
ffff800000002970:	48 85 ff             	test   %rdi,%rdi
ffff800000002973:	0f 84 0c 01 00 00    	je     ffff800000002a85 <kmalloc+0x115>
ffff800000002979:	41 57                	push   %r15
ffff80000000297b:	49 bf 00 89 00 00 00 	movabs $0xffff800000008900,%r15
ffff800000002982:	80 ff ff 
ffff800000002985:	41 56                	push   %r14
ffff800000002987:	41 55                	push   %r13
ffff800000002989:	4c 8d 6f 07          	lea    0x7(%rdi),%r13
ffff80000000298d:	49 83 e5 f8          	and    $0xfffffffffffffff8,%r13
ffff800000002991:	41 54                	push   %r12
ffff800000002993:	49 bc 00 00 00 00 00 	movabs $0xffff800000000000,%r12
ffff80000000299a:	80 ff ff 
ffff80000000299d:	55                   	push   %rbp
ffff80000000299e:	48 bd 50 2d 00 00 00 	movabs $0xffff800000002d50,%rbp
ffff8000000029a5:	80 ff ff 
ffff8000000029a8:	53                   	push   %rbx
ffff8000000029a9:	49 8d 9d 17 10 00 00 	lea    0x1017(%r13),%rbx
ffff8000000029b0:	48 c1 eb 0c          	shr    $0xc,%rbx
ffff8000000029b4:	41 89 de             	mov    %ebx,%r14d
ffff8000000029b7:	c1 e3 0c             	shl    $0xc,%ebx
ffff8000000029ba:	48 83 ec 18          	sub    $0x18,%rsp
ffff8000000029be:	48 83 eb 18          	sub    $0x18,%rbx
ffff8000000029c2:	49 8b 07             	mov    (%r15),%rax
ffff8000000029c5:	48 85 c0             	test   %rax,%rax
ffff8000000029c8:	74 1d                	je     ffff8000000029e7 <kmalloc+0x77>
ffff8000000029ca:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff8000000029d0:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
ffff8000000029d4:	74 09                	je     ffff8000000029df <kmalloc+0x6f>
ffff8000000029d6:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffff8000000029da:	4c 39 ea             	cmp    %r13,%rdx
ffff8000000029dd:	73 41                	jae    ffff800000002a20 <kmalloc+0xb0>
ffff8000000029df:	48 8b 00             	mov    (%rax),%rax
ffff8000000029e2:	48 85 c0             	test   %rax,%rax
ffff8000000029e5:	75 e9                	jne    ffff8000000029d0 <kmalloc+0x60>
ffff8000000029e7:	44 89 f7             	mov    %r14d,%edi
ffff8000000029ea:	ff d5                	call   *%rbp
ffff8000000029ec:	48 85 c0             	test   %rax,%rax
ffff8000000029ef:	74 72                	je     ffff800000002a63 <kmalloc+0xf3>
ffff8000000029f1:	49 8b 17             	mov    (%r15),%rdx
ffff8000000029f4:	4c 01 e0             	add    %r12,%rax
ffff8000000029f7:	48 89 58 10          	mov    %rbx,0x10(%rax)
ffff8000000029fb:	c6 40 08 01          	movb   $0x1,0x8(%rax)
ffff8000000029ff:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
ffff800000002a06:	48 85 d2             	test   %rdx,%rdx
ffff800000002a09:	75 05                	jne    ffff800000002a10 <kmalloc+0xa0>
ffff800000002a0b:	49 89 07             	mov    %rax,(%r15)
ffff800000002a0e:	eb b2                	jmp    ffff8000000029c2 <kmalloc+0x52>
ffff800000002a10:	48 89 d1             	mov    %rdx,%rcx
ffff800000002a13:	48 8b 12             	mov    (%rdx),%rdx
ffff800000002a16:	48 85 d2             	test   %rdx,%rdx
ffff800000002a19:	75 f5                	jne    ffff800000002a10 <kmalloc+0xa0>
ffff800000002a1b:	48 89 01             	mov    %rax,(%rcx)
ffff800000002a1e:	eb a2                	jmp    ffff8000000029c2 <kmalloc+0x52>
ffff800000002a20:	49 8d 4d 20          	lea    0x20(%r13),%rcx
ffff800000002a24:	48 39 ca             	cmp    %rcx,%rdx
ffff800000002a27:	73 17                	jae    ffff800000002a40 <kmalloc+0xd0>
ffff800000002a29:	c6 40 08 00          	movb   $0x0,0x8(%rax)
ffff800000002a2d:	48 83 c0 18          	add    $0x18,%rax
ffff800000002a31:	48 83 c4 18          	add    $0x18,%rsp
ffff800000002a35:	5b                   	pop    %rbx
ffff800000002a36:	5d                   	pop    %rbp
ffff800000002a37:	41 5c                	pop    %r12
ffff800000002a39:	41 5d                	pop    %r13
ffff800000002a3b:	41 5e                	pop    %r14
ffff800000002a3d:	41 5f                	pop    %r15
ffff800000002a3f:	c3                   	ret    
ffff800000002a40:	4c 29 ea             	sub    %r13,%rdx
ffff800000002a43:	4a 8d 4c 28 18       	lea    0x18(%rax,%r13,1),%rcx
ffff800000002a48:	48 83 ea 18          	sub    $0x18,%rdx
ffff800000002a4c:	c6 41 08 01          	movb   $0x1,0x8(%rcx)
ffff800000002a50:	48 89 51 10          	mov    %rdx,0x10(%rcx)
ffff800000002a54:	48 8b 10             	mov    (%rax),%rdx
ffff800000002a57:	48 89 11             	mov    %rdx,(%rcx)
ffff800000002a5a:	4c 89 68 10          	mov    %r13,0x10(%rax)
ffff800000002a5e:	48 89 08             	mov    %rcx,(%rax)
ffff800000002a61:	eb c6                	jmp    ffff800000002a29 <kmalloc+0xb9>
ffff800000002a63:	48 bf 90 5a 00 00 00 	movabs $0xffff800000005a90,%rdi
ffff800000002a6a:	80 ff ff 
ffff800000002a6d:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
ffff800000002a72:	48 ba 20 35 00 00 00 	movabs $0xffff800000003520,%rdx
ffff800000002a79:	80 ff ff 
ffff800000002a7c:	ff d2                	call   *%rdx
ffff800000002a7e:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
ffff800000002a83:	eb ac                	jmp    ffff800000002a31 <kmalloc+0xc1>
ffff800000002a85:	31 c0                	xor    %eax,%eax
ffff800000002a87:	c3                   	ret    
ffff800000002a88:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000002a8f:	00 

ffff800000002a90 <kfree>:
ffff800000002a90:	48 85 ff             	test   %rdi,%rdi
ffff800000002a93:	74 3b                	je     ffff800000002ad0 <kfree+0x40>
ffff800000002a95:	48 8b 47 e8          	mov    -0x18(%rdi),%rax
ffff800000002a99:	c6 47 f0 01          	movb   $0x1,-0x10(%rdi)
ffff800000002a9d:	48 8d 4f e8          	lea    -0x18(%rdi),%rcx
ffff800000002aa1:	48 85 c0             	test   %rax,%rax
ffff800000002aa4:	74 06                	je     ffff800000002aac <kfree+0x1c>
ffff800000002aa6:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
ffff800000002aaa:	75 2c                	jne    ffff800000002ad8 <kfree+0x48>
ffff800000002aac:	48 a1 00 89 00 00 00 	movabs 0xffff800000008900,%rax
ffff800000002ab3:	80 ff ff 
ffff800000002ab6:	eb 13                	jmp    ffff800000002acb <kfree+0x3b>
ffff800000002ab8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000002abf:	00 
ffff800000002ac0:	48 8b 10             	mov    (%rax),%rdx
ffff800000002ac3:	48 39 ca             	cmp    %rcx,%rdx
ffff800000002ac6:	74 30                	je     ffff800000002af8 <kfree+0x68>
ffff800000002ac8:	48 89 d0             	mov    %rdx,%rax
ffff800000002acb:	48 85 c0             	test   %rax,%rax
ffff800000002ace:	75 f0                	jne    ffff800000002ac0 <kfree+0x30>
ffff800000002ad0:	c3                   	ret    
ffff800000002ad1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000002ad8:	48 8b 50 10          	mov    0x10(%rax),%rdx
ffff800000002adc:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
ffff800000002ae0:	48 8b 00             	mov    (%rax),%rax
ffff800000002ae3:	48 8d 54 16 18       	lea    0x18(%rsi,%rdx,1),%rdx
ffff800000002ae8:	48 89 57 f8          	mov    %rdx,-0x8(%rdi)
ffff800000002aec:	48 89 47 e8          	mov    %rax,-0x18(%rdi)
ffff800000002af0:	eb ba                	jmp    ffff800000002aac <kfree+0x1c>
ffff800000002af2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000002af8:	80 78 08 00          	cmpb   $0x0,0x8(%rax)
ffff800000002afc:	74 d2                	je     ffff800000002ad0 <kfree+0x40>
ffff800000002afe:	48 8b 77 f8          	mov    -0x8(%rdi),%rsi
ffff800000002b02:	48 8d 56 18          	lea    0x18(%rsi),%rdx
ffff800000002b06:	48 01 50 10          	add    %rdx,0x10(%rax)
ffff800000002b0a:	48 8b 57 e8          	mov    -0x18(%rdi),%rdx
ffff800000002b0e:	48 89 10             	mov    %rdx,(%rax)
ffff800000002b11:	c3                   	ret    
ffff800000002b12:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff800000002b19:	00 00 00 
ffff800000002b1c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000002b20 <init_phy_mem_map>:
ffff800000002b20:	55                   	push   %rbp
ffff800000002b21:	53                   	push   %rbx
ffff800000002b22:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000002b26:	a1 00 05 00 00 00 80 	movabs 0xffff800000000500,%eax
ffff800000002b2d:	ff ff 
ffff800000002b2f:	85 c0                	test   %eax,%eax
ffff800000002b31:	0f 84 64 01 00 00    	je     ffff800000002c9b <init_phy_mem_map+0x17b>
ffff800000002b37:	83 e8 01             	sub    $0x1,%eax
ffff800000002b3a:	48 8d 14 80          	lea    (%rax,%rax,4),%rdx
ffff800000002b3e:	48 b8 18 05 00 00 00 	movabs $0xffff800000000518,%rax
ffff800000002b45:	80 ff ff 
ffff800000002b48:	48 8d 2c 90          	lea    (%rax,%rdx,4),%rbp
ffff800000002b4c:	48 83 e8 14          	sub    $0x14,%rax
ffff800000002b50:	31 d2                	xor    %edx,%edx
ffff800000002b52:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000002b58:	83 78 10 01          	cmpl   $0x1,0x10(%rax)
ffff800000002b5c:	75 0e                	jne    ffff800000002b6c <init_phy_mem_map+0x4c>
ffff800000002b5e:	48 8b 48 08          	mov    0x8(%rax),%rcx
ffff800000002b62:	48 03 08             	add    (%rax),%rcx
ffff800000002b65:	48 39 ca             	cmp    %rcx,%rdx
ffff800000002b68:	48 0f 42 d1          	cmovb  %rcx,%rdx
ffff800000002b6c:	48 83 c0 14          	add    $0x14,%rax
ffff800000002b70:	48 39 c5             	cmp    %rax,%rbp
ffff800000002b73:	75 e3                	jne    ffff800000002b58 <init_phy_mem_map+0x38>
ffff800000002b75:	48 c1 ea 0c          	shr    $0xc,%rdx
ffff800000002b79:	be ff 00 00 00       	mov    $0xff,%esi
ffff800000002b7e:	48 bf 00 00 20 00 00 	movabs $0xffff800000200000,%rdi
ffff800000002b85:	80 ff ff 
ffff800000002b88:	48 bb 60 89 00 00 00 	movabs $0xffff800000008960,%rbx
ffff800000002b8f:	80 ff ff 
ffff800000002b92:	48 83 c2 07          	add    $0x7,%rdx
ffff800000002b96:	48 89 3b             	mov    %rdi,(%rbx)
ffff800000002b99:	48 c1 ea 03          	shr    $0x3,%rdx
ffff800000002b9d:	48 89 d0             	mov    %rdx,%rax
ffff800000002ba0:	48 a3 68 89 00 00 00 	movabs %rax,0xffff800000008968
ffff800000002ba7:	80 ff ff 
ffff800000002baa:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000002bb1:	80 ff ff 
ffff800000002bb4:	ff d0                	call   *%rax
ffff800000002bb6:	41 b8 01 00 00 00    	mov    $0x1,%r8d
ffff800000002bbc:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002bc3:	80 ff ff 
ffff800000002bc6:	48 be 04 05 00 00 00 	movabs $0xffff800000000504,%rsi
ffff800000002bcd:	80 ff ff 
ffff800000002bd0:	eb 0f                	jmp    ffff800000002be1 <init_phy_mem_map+0xc1>
ffff800000002bd2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000002bd8:	48 83 c6 14          	add    $0x14,%rsi
ffff800000002bdc:	48 39 f5             	cmp    %rsi,%rbp
ffff800000002bdf:	74 67                	je     ffff800000002c48 <init_phy_mem_map+0x128>
ffff800000002be1:	83 7e 10 01          	cmpl   $0x1,0x10(%rsi)
ffff800000002be5:	75 f1                	jne    ffff800000002bd8 <init_phy_mem_map+0xb8>
ffff800000002be7:	48 8b 3e             	mov    (%rsi),%rdi
ffff800000002bea:	48 89 fa             	mov    %rdi,%rdx
ffff800000002bed:	48 03 7e 08          	add    0x8(%rsi),%rdi
ffff800000002bf1:	48 c1 ea 0c          	shr    $0xc,%rdx
ffff800000002bf5:	48 c1 ef 0c          	shr    $0xc,%rdi
ffff800000002bf9:	48 39 fa             	cmp    %rdi,%rdx
ffff800000002bfc:	73 da                	jae    ffff800000002bd8 <init_phy_mem_map+0xb8>
ffff800000002bfe:	66 90                	xchg   %ax,%ax
ffff800000002c00:	48 8d 0c c5 00 00 00 	lea    0x0(,%rax,8),%rcx
ffff800000002c07:	00 
ffff800000002c08:	48 39 d1             	cmp    %rdx,%rcx
ffff800000002c0b:	76 26                	jbe    ffff800000002c33 <init_phy_mem_map+0x113>
ffff800000002c0d:	89 d1                	mov    %edx,%ecx
ffff800000002c0f:	45 89 c1             	mov    %r8d,%r9d
ffff800000002c12:	48 89 d0             	mov    %rdx,%rax
ffff800000002c15:	83 e1 07             	and    $0x7,%ecx
ffff800000002c18:	48 c1 e8 03          	shr    $0x3,%rax
ffff800000002c1c:	48 03 03             	add    (%rbx),%rax
ffff800000002c1f:	41 d3 e1             	shl    %cl,%r9d
ffff800000002c22:	44 89 c9             	mov    %r9d,%ecx
ffff800000002c25:	f7 d1                	not    %ecx
ffff800000002c27:	20 08                	and    %cl,(%rax)
ffff800000002c29:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002c30:	80 ff ff 
ffff800000002c33:	48 83 c2 01          	add    $0x1,%rdx
ffff800000002c37:	48 39 d7             	cmp    %rdx,%rdi
ffff800000002c3a:	75 c4                	jne    ffff800000002c00 <init_phy_mem_map+0xe0>
ffff800000002c3c:	48 83 c6 14          	add    $0x14,%rsi
ffff800000002c40:	48 39 f5             	cmp    %rsi,%rbp
ffff800000002c43:	75 9c                	jne    ffff800000002be1 <init_phy_mem_map+0xc1>
ffff800000002c45:	0f 1f 00             	nopl   (%rax)
ffff800000002c48:	48 8d b0 ff 0f 20 00 	lea    0x200fff(%rax),%rsi
ffff800000002c4f:	48 c1 ee 0c          	shr    $0xc,%rsi
ffff800000002c53:	74 3f                	je     ffff800000002c94 <init_phy_mem_map+0x174>
ffff800000002c55:	31 d2                	xor    %edx,%edx
ffff800000002c57:	bf 01 00 00 00       	mov    $0x1,%edi
ffff800000002c5c:	eb 0c                	jmp    ffff800000002c6a <init_phy_mem_map+0x14a>
ffff800000002c5e:	66 90                	xchg   %ax,%ax
ffff800000002c60:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002c67:	80 ff ff 
ffff800000002c6a:	48 c1 e0 03          	shl    $0x3,%rax
ffff800000002c6e:	48 39 d0             	cmp    %rdx,%rax
ffff800000002c71:	76 18                	jbe    ffff800000002c8b <init_phy_mem_map+0x16b>
ffff800000002c73:	48 89 d0             	mov    %rdx,%rax
ffff800000002c76:	89 d1                	mov    %edx,%ecx
ffff800000002c78:	41 89 fa             	mov    %edi,%r10d
ffff800000002c7b:	48 c1 e8 03          	shr    $0x3,%rax
ffff800000002c7f:	83 e1 07             	and    $0x7,%ecx
ffff800000002c82:	48 03 03             	add    (%rbx),%rax
ffff800000002c85:	41 d3 e2             	shl    %cl,%r10d
ffff800000002c88:	44 08 10             	or     %r10b,(%rax)
ffff800000002c8b:	48 83 c2 01          	add    $0x1,%rdx
ffff800000002c8f:	48 39 d6             	cmp    %rdx,%rsi
ffff800000002c92:	75 cc                	jne    ffff800000002c60 <init_phy_mem_map+0x140>
ffff800000002c94:	48 83 c4 08          	add    $0x8,%rsp
ffff800000002c98:	5b                   	pop    %rbx
ffff800000002c99:	5d                   	pop    %rbp
ffff800000002c9a:	c3                   	ret    
ffff800000002c9b:	48 bb 60 89 00 00 00 	movabs $0xffff800000008960,%rbx
ffff800000002ca2:	80 ff ff 
ffff800000002ca5:	31 d2                	xor    %edx,%edx
ffff800000002ca7:	be ff 00 00 00       	mov    $0xff,%esi
ffff800000002cac:	48 bf 00 00 20 00 00 	movabs $0xffff800000200000,%rdi
ffff800000002cb3:	80 ff ff 
ffff800000002cb6:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000002cbd:	80 ff ff 
ffff800000002cc0:	48 89 3b             	mov    %rdi,(%rbx)
ffff800000002cc3:	48 c7 43 08 00 00 00 	movq   $0x0,0x8(%rbx)
ffff800000002cca:	00 
ffff800000002ccb:	ff d0                	call   *%rax
ffff800000002ccd:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002cd4:	80 ff ff 
ffff800000002cd7:	e9 6c ff ff ff       	jmp    ffff800000002c48 <init_phy_mem_map+0x128>
ffff800000002cdc:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000002ce0 <set_bit>:
ffff800000002ce0:	48 8b 47 08          	mov    0x8(%rdi),%rax
ffff800000002ce4:	48 89 f1             	mov    %rsi,%rcx
ffff800000002ce7:	48 c1 e0 03          	shl    $0x3,%rax
ffff800000002ceb:	48 39 f0             	cmp    %rsi,%rax
ffff800000002cee:	76 20                	jbe    ffff800000002d10 <set_bit+0x30>
ffff800000002cf0:	83 e1 07             	and    $0x7,%ecx
ffff800000002cf3:	b8 01 00 00 00       	mov    $0x1,%eax
ffff800000002cf8:	48 c1 ee 03          	shr    $0x3,%rsi
ffff800000002cfc:	48 03 37             	add    (%rdi),%rsi
ffff800000002cff:	d3 e0                	shl    %cl,%eax
ffff800000002d01:	89 c1                	mov    %eax,%ecx
ffff800000002d03:	0a 06                	or     (%rsi),%al
ffff800000002d05:	f7 d1                	not    %ecx
ffff800000002d07:	22 0e                	and    (%rsi),%cl
ffff800000002d09:	84 d2                	test   %dl,%dl
ffff800000002d0b:	0f 44 c1             	cmove  %ecx,%eax
ffff800000002d0e:	88 06                	mov    %al,(%rsi)
ffff800000002d10:	c3                   	ret    
ffff800000002d11:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000002d18:	00 00 00 00 
ffff800000002d1c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000002d20 <get_bit>:
ffff800000002d20:	48 8b 47 08          	mov    0x8(%rdi),%rax
ffff800000002d24:	48 89 f1             	mov    %rsi,%rcx
ffff800000002d27:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
ffff800000002d2e:	00 
ffff800000002d2f:	31 c0                	xor    %eax,%eax
ffff800000002d31:	48 39 f2             	cmp    %rsi,%rdx
ffff800000002d34:	76 16                	jbe    ffff800000002d4c <get_bit+0x2c>
ffff800000002d36:	48 8b 17             	mov    (%rdi),%rdx
ffff800000002d39:	48 89 f0             	mov    %rsi,%rax
ffff800000002d3c:	83 e1 07             	and    $0x7,%ecx
ffff800000002d3f:	48 c1 e8 03          	shr    $0x3,%rax
ffff800000002d43:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
ffff800000002d47:	d3 f8                	sar    %cl,%eax
ffff800000002d49:	83 e0 01             	and    $0x1,%eax
ffff800000002d4c:	c3                   	ret    
ffff800000002d4d:	0f 1f 00             	nopl   (%rax)

ffff800000002d50 <alloc_pages>:
ffff800000002d50:	85 ff                	test   %edi,%edi
ffff800000002d52:	0f 84 e8 00 00 00    	je     ffff800000002e40 <alloc_pages+0xf0>
ffff800000002d58:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002d5f:	80 ff ff 
ffff800000002d62:	41 54                	push   %r12
ffff800000002d64:	55                   	push   %rbp
ffff800000002d65:	41 89 c3             	mov    %eax,%r11d
ffff800000002d68:	53                   	push   %rbx
ffff800000002d69:	48 bb 60 89 00 00 00 	movabs $0xffff800000008960,%rbx
ffff800000002d70:	80 ff ff 
ffff800000002d73:	41 c1 e3 03          	shl    $0x3,%r11d
ffff800000002d77:	0f 84 b3 00 00 00    	je     ffff800000002e30 <alloc_pages+0xe0>
ffff800000002d7d:	4c 8b 23             	mov    (%rbx),%r12
ffff800000002d80:	48 8d 2c c5 00 00 00 	lea    0x0(,%rax,8),%rbp
ffff800000002d87:	00 
ffff800000002d88:	45 89 db             	mov    %r11d,%r11d
ffff800000002d8b:	31 d2                	xor    %edx,%edx
ffff800000002d8d:	45 31 c0             	xor    %r8d,%r8d
ffff800000002d90:	31 f6                	xor    %esi,%esi
ffff800000002d92:	eb 28                	jmp    ffff800000002dbc <alloc_pages+0x6c>
ffff800000002d94:	0f 1f 40 00          	nopl   0x0(%rax)
ffff800000002d98:	49 89 d1             	mov    %rdx,%r9
ffff800000002d9b:	49 c1 e9 03          	shr    $0x3,%r9
ffff800000002d9f:	47 0f b6 14 0c       	movzbl (%r12,%r9,1),%r10d
ffff800000002da4:	41 89 d1             	mov    %edx,%r9d
ffff800000002da7:	41 83 e1 07          	and    $0x7,%r9d
ffff800000002dab:	45 0f a3 ca          	bt     %r9d,%r10d
ffff800000002daf:	73 12                	jae    ffff800000002dc3 <alloc_pages+0x73>
ffff800000002db1:	31 f6                	xor    %esi,%esi
ffff800000002db3:	48 83 c2 01          	add    $0x1,%rdx
ffff800000002db7:	49 39 d3             	cmp    %rdx,%r11
ffff800000002dba:	74 74                	je     ffff800000002e30 <alloc_pages+0xe0>
ffff800000002dbc:	89 d1                	mov    %edx,%ecx
ffff800000002dbe:	48 39 d5             	cmp    %rdx,%rbp
ffff800000002dc1:	77 d5                	ja     ffff800000002d98 <alloc_pages+0x48>
ffff800000002dc3:	85 f6                	test   %esi,%esi
ffff800000002dc5:	44 0f 44 c1          	cmove  %ecx,%r8d
ffff800000002dc9:	83 c6 01             	add    $0x1,%esi
ffff800000002dcc:	39 f7                	cmp    %esi,%edi
ffff800000002dce:	75 e3                	jne    ffff800000002db3 <alloc_pages+0x63>
ffff800000002dd0:	41 ba 01 00 00 00    	mov    $0x1,%r10d
ffff800000002dd6:	44 89 c7             	mov    %r8d,%edi
ffff800000002dd9:	45 89 d1             	mov    %r10d,%r9d
ffff800000002ddc:	45 29 c1             	sub    %r8d,%r9d
ffff800000002ddf:	eb 14                	jmp    ffff800000002df5 <alloc_pages+0xa5>
ffff800000002de1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000002de8:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002def:	80 ff ff 
ffff800000002df2:	83 c7 01             	add    $0x1,%edi
ffff800000002df5:	89 fa                	mov    %edi,%edx
ffff800000002df7:	48 c1 e0 03          	shl    $0x3,%rax
ffff800000002dfb:	48 39 c2             	cmp    %rax,%rdx
ffff800000002dfe:	73 13                	jae    ffff800000002e13 <alloc_pages+0xc3>
ffff800000002e00:	89 f9                	mov    %edi,%ecx
ffff800000002e02:	48 c1 ea 03          	shr    $0x3,%rdx
ffff800000002e06:	44 89 d0             	mov    %r10d,%eax
ffff800000002e09:	48 03 13             	add    (%rbx),%rdx
ffff800000002e0c:	83 e1 07             	and    $0x7,%ecx
ffff800000002e0f:	d3 e0                	shl    %cl,%eax
ffff800000002e11:	08 02                	or     %al,(%rdx)
ffff800000002e13:	41 8d 04 39          	lea    (%r9,%rdi,1),%eax
ffff800000002e17:	39 f0                	cmp    %esi,%eax
ffff800000002e19:	72 cd                	jb     ffff800000002de8 <alloc_pages+0x98>
ffff800000002e1b:	44 89 c0             	mov    %r8d,%eax
ffff800000002e1e:	5b                   	pop    %rbx
ffff800000002e1f:	5d                   	pop    %rbp
ffff800000002e20:	48 c1 e0 0c          	shl    $0xc,%rax
ffff800000002e24:	41 5c                	pop    %r12
ffff800000002e26:	c3                   	ret    
ffff800000002e27:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff800000002e2e:	00 00 
ffff800000002e30:	5b                   	pop    %rbx
ffff800000002e31:	31 c0                	xor    %eax,%eax
ffff800000002e33:	5d                   	pop    %rbp
ffff800000002e34:	41 5c                	pop    %r12
ffff800000002e36:	c3                   	ret    
ffff800000002e37:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff800000002e3e:	00 00 
ffff800000002e40:	31 c0                	xor    %eax,%eax
ffff800000002e42:	c3                   	ret    
ffff800000002e43:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000002e4a:	00 00 00 00 
ffff800000002e4e:	66 90                	xchg   %ax,%ax

ffff800000002e50 <alloc_page>:
ffff800000002e50:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff800000002e57:	80 ff ff 
ffff800000002e5a:	bf 01 00 00 00       	mov    $0x1,%edi
ffff800000002e5f:	ff e0                	jmp    *%rax
ffff800000002e61:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000002e68:	00 00 00 00 
ffff800000002e6c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000002e70 <free_page>:
ffff800000002e70:	55                   	push   %rbp
ffff800000002e71:	31 f6                	xor    %esi,%esi
ffff800000002e73:	48 89 fd             	mov    %rdi,%rbp
ffff800000002e76:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000002e7b:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000002e82:	80 ff ff 
ffff800000002e85:	53                   	push   %rbx
ffff800000002e86:	48 89 fb             	mov    %rdi,%rbx
ffff800000002e89:	48 c1 ed 0c          	shr    $0xc,%rbp
ffff800000002e8d:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000002e91:	ff d0                	call   *%rax
ffff800000002e93:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff800000002e9a:	80 ff ff 
ffff800000002e9d:	48 c1 e0 03          	shl    $0x3,%rax
ffff800000002ea1:	48 39 c5             	cmp    %rax,%rbp
ffff800000002ea4:	73 1c                	jae    ffff800000002ec2 <free_page+0x52>
ffff800000002ea6:	48 b8 60 89 00 00 00 	movabs $0xffff800000008960,%rax
ffff800000002ead:	80 ff ff 
ffff800000002eb0:	48 c1 eb 0f          	shr    $0xf,%rbx
ffff800000002eb4:	83 e5 07             	and    $0x7,%ebp
ffff800000002eb7:	48 03 18             	add    (%rax),%rbx
ffff800000002eba:	0f b6 03             	movzbl (%rbx),%eax
ffff800000002ebd:	0f b3 e8             	btr    %ebp,%eax
ffff800000002ec0:	88 03                	mov    %al,(%rbx)
ffff800000002ec2:	48 83 c4 08          	add    $0x8,%rsp
ffff800000002ec6:	5b                   	pop    %rbx
ffff800000002ec7:	5d                   	pop    %rbp
ffff800000002ec8:	c3                   	ret    
ffff800000002ec9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

ffff800000002ed0 <create_page_dir>:
ffff800000002ed0:	41 54                	push   %r12
ffff800000002ed2:	bf 01 00 00 00       	mov    $0x1,%edi
ffff800000002ed7:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff800000002ede:	80 ff ff 
ffff800000002ee1:	ff d0                	call   *%rax
ffff800000002ee3:	49 89 c4             	mov    %rax,%r12
ffff800000002ee6:	48 85 c0             	test   %rax,%rax
ffff800000002ee9:	74 49                	je     ffff800000002f34 <create_page_dir+0x64>
ffff800000002eeb:	48 bf 00 00 00 00 00 	movabs $0xffff800000000000,%rdi
ffff800000002ef2:	80 ff ff 
ffff800000002ef5:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000002efa:	31 f6                	xor    %esi,%esi
ffff800000002efc:	48 01 c7             	add    %rax,%rdi
ffff800000002eff:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000002f06:	80 ff ff 
ffff800000002f09:	ff d0                	call   *%rax
ffff800000002f0b:	48 b8 00 08 07 00 00 	movabs $0xffff800000070800,%rax
ffff800000002f12:	80 ff ff 
ffff800000002f15:	48 b9 00 10 07 00 00 	movabs $0xffff800000071000,%rcx
ffff800000002f1c:	80 ff ff 
ffff800000002f1f:	90                   	nop
ffff800000002f20:	48 8b 10             	mov    (%rax),%rdx
ffff800000002f23:	49 89 94 04 00 00 f9 	mov    %rdx,-0x70000(%r12,%rax,1)
ffff800000002f2a:	ff 
ffff800000002f2b:	48 83 c0 08          	add    $0x8,%rax
ffff800000002f2f:	48 39 c8             	cmp    %rcx,%rax
ffff800000002f32:	75 ec                	jne    ffff800000002f20 <create_page_dir+0x50>
ffff800000002f34:	4c 89 e0             	mov    %r12,%rax
ffff800000002f37:	41 5c                	pop    %r12
ffff800000002f39:	c3                   	ret    
ffff800000002f3a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff800000002f40 <map_page>:
ffff800000002f40:	48 89 f0             	mov    %rsi,%rax
ffff800000002f43:	41 57                	push   %r15
ffff800000002f45:	49 bf 00 00 00 00 00 	movabs $0xffff800000000000,%r15
ffff800000002f4c:	80 ff ff 
ffff800000002f4f:	41 56                	push   %r14
ffff800000002f51:	48 c1 e8 24          	shr    $0x24,%rax
ffff800000002f55:	4c 01 ff             	add    %r15,%rdi
ffff800000002f58:	41 55                	push   %r13
ffff800000002f5a:	25 f8 0f 00 00       	and    $0xff8,%eax
ffff800000002f5f:	49 89 cd             	mov    %rcx,%r13
ffff800000002f62:	41 54                	push   %r12
ffff800000002f64:	4c 8d 34 07          	lea    (%rdi,%rax,1),%r14
ffff800000002f68:	49 89 d4             	mov    %rdx,%r12
ffff800000002f6b:	55                   	push   %rbp
ffff800000002f6c:	53                   	push   %rbx
ffff800000002f6d:	48 89 f3             	mov    %rsi,%rbx
ffff800000002f70:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000002f74:	49 8b 06             	mov    (%r14),%rax
ffff800000002f77:	a8 01                	test   $0x1,%al
ffff800000002f79:	0f 84 a1 00 00 00    	je     ffff800000003020 <map_page+0xe0>
ffff800000002f7f:	49 bf 00 00 00 00 00 	movabs $0xffff800000000000,%r15
ffff800000002f86:	80 ff ff 
ffff800000002f89:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffff800000002f8f:	4e 8d 34 38          	lea    (%rax,%r15,1),%r14
ffff800000002f93:	48 89 d8             	mov    %rbx,%rax
ffff800000002f96:	48 c1 e8 1b          	shr    $0x1b,%rax
ffff800000002f9a:	25 f8 0f 00 00       	and    $0xff8,%eax
ffff800000002f9f:	49 01 c6             	add    %rax,%r14
ffff800000002fa2:	49 8b 06             	mov    (%r14),%rax
ffff800000002fa5:	a8 01                	test   $0x1,%al
ffff800000002fa7:	0f 84 f3 00 00 00    	je     ffff8000000030a0 <map_page+0x160>
ffff800000002fad:	49 bf 00 00 00 00 00 	movabs $0xffff800000000000,%r15
ffff800000002fb4:	80 ff ff 
ffff800000002fb7:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffff800000002fbd:	4a 8d 2c 38          	lea    (%rax,%r15,1),%rbp
ffff800000002fc1:	48 89 d8             	mov    %rbx,%rax
ffff800000002fc4:	48 c1 e8 12          	shr    $0x12,%rax
ffff800000002fc8:	25 f8 0f 00 00       	and    $0xff8,%eax
ffff800000002fcd:	48 01 c5             	add    %rax,%rbp
ffff800000002fd0:	48 8b 45 00          	mov    0x0(%rbp),%rax
ffff800000002fd4:	a8 01                	test   $0x1,%al
ffff800000002fd6:	0f 84 84 00 00 00    	je     ffff800000003060 <map_page+0x120>
ffff800000002fdc:	48 c1 eb 09          	shr    $0x9,%rbx
ffff800000002fe0:	48 25 00 f0 ff ff    	and    $0xfffffffffffff000,%rax
ffff800000002fe6:	49 81 e4 00 f0 ff ff 	and    $0xfffffffffffff000,%r12
ffff800000002fed:	81 e3 f8 0f 00 00    	and    $0xff8,%ebx
ffff800000002ff3:	4d 09 ec             	or     %r13,%r12
ffff800000002ff6:	48 01 c3             	add    %rax,%rbx
ffff800000002ff9:	48 b8 00 00 00 00 00 	movabs $0xffff800000000000,%rax
ffff800000003000:	80 ff ff 
ffff800000003003:	4c 89 24 03          	mov    %r12,(%rbx,%rax,1)
ffff800000003007:	48 83 c4 08          	add    $0x8,%rsp
ffff80000000300b:	5b                   	pop    %rbx
ffff80000000300c:	5d                   	pop    %rbp
ffff80000000300d:	41 5c                	pop    %r12
ffff80000000300f:	41 5d                	pop    %r13
ffff800000003011:	41 5e                	pop    %r14
ffff800000003013:	41 5f                	pop    %r15
ffff800000003015:	c3                   	ret    
ffff800000003016:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff80000000301d:	00 00 00 
ffff800000003020:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff800000003027:	80 ff ff 
ffff80000000302a:	bf 01 00 00 00       	mov    $0x1,%edi
ffff80000000302f:	ff d0                	call   *%rax
ffff800000003031:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000003036:	31 f6                	xor    %esi,%esi
ffff800000003038:	48 89 c5             	mov    %rax,%rbp
ffff80000000303b:	4a 8d 3c 38          	lea    (%rax,%r15,1),%rdi
ffff80000000303f:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000003046:	80 ff ff 
ffff800000003049:	ff d0                	call   *%rax
ffff80000000304b:	48 89 e8             	mov    %rbp,%rax
ffff80000000304e:	48 83 c8 07          	or     $0x7,%rax
ffff800000003052:	49 89 06             	mov    %rax,(%r14)
ffff800000003055:	e9 25 ff ff ff       	jmp    ffff800000002f7f <map_page+0x3f>
ffff80000000305a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000003060:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff800000003067:	80 ff ff 
ffff80000000306a:	bf 01 00 00 00       	mov    $0x1,%edi
ffff80000000306f:	ff d0                	call   *%rax
ffff800000003071:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff800000003076:	31 f6                	xor    %esi,%esi
ffff800000003078:	49 89 c6             	mov    %rax,%r14
ffff80000000307b:	4a 8d 3c 38          	lea    (%rax,%r15,1),%rdi
ffff80000000307f:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000003086:	80 ff ff 
ffff800000003089:	ff d0                	call   *%rax
ffff80000000308b:	4c 89 f0             	mov    %r14,%rax
ffff80000000308e:	48 83 c8 07          	or     $0x7,%rax
ffff800000003092:	48 89 45 00          	mov    %rax,0x0(%rbp)
ffff800000003096:	e9 41 ff ff ff       	jmp    ffff800000002fdc <map_page+0x9c>
ffff80000000309b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff8000000030a0:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff8000000030a7:	80 ff ff 
ffff8000000030aa:	bf 01 00 00 00       	mov    $0x1,%edi
ffff8000000030af:	ff d0                	call   *%rax
ffff8000000030b1:	ba 00 10 00 00       	mov    $0x1000,%edx
ffff8000000030b6:	31 f6                	xor    %esi,%esi
ffff8000000030b8:	48 89 c5             	mov    %rax,%rbp
ffff8000000030bb:	4a 8d 3c 38          	lea    (%rax,%r15,1),%rdi
ffff8000000030bf:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff8000000030c6:	80 ff ff 
ffff8000000030c9:	ff d0                	call   *%rax
ffff8000000030cb:	48 89 e8             	mov    %rbp,%rax
ffff8000000030ce:	48 83 c8 07          	or     $0x7,%rax
ffff8000000030d2:	49 89 06             	mov    %rax,(%r14)
ffff8000000030d5:	e9 d3 fe ff ff       	jmp    ffff800000002fad <map_page+0x6d>
ffff8000000030da:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff8000000030e0 <get_free_page_count>:
ffff8000000030e0:	48 a1 68 89 00 00 00 	movabs 0xffff800000008968,%rax
ffff8000000030e7:	80 ff ff 
ffff8000000030ea:	41 89 c0             	mov    %eax,%r8d
ffff8000000030ed:	41 c1 e0 03          	shl    $0x3,%r8d
ffff8000000030f1:	74 4d                	je     ffff800000003140 <get_free_page_count+0x60>
ffff8000000030f3:	48 8d 0c c5 00 00 00 	lea    0x0(,%rax,8),%rcx
ffff8000000030fa:	00 
ffff8000000030fb:	45 89 c1             	mov    %r8d,%r9d
ffff8000000030fe:	31 d2                	xor    %edx,%edx
ffff800000003100:	45 31 c0             	xor    %r8d,%r8d
ffff800000003103:	48 a1 60 89 00 00 00 	movabs 0xffff800000008960,%rax
ffff80000000310a:	80 ff ff 
ffff80000000310d:	eb 1f                	jmp    ffff80000000312e <get_free_page_count+0x4e>
ffff80000000310f:	90                   	nop
ffff800000003110:	48 89 d6             	mov    %rdx,%rsi
ffff800000003113:	48 c1 ee 03          	shr    $0x3,%rsi
ffff800000003117:	0f b6 3c 30          	movzbl (%rax,%rsi,1),%edi
ffff80000000311b:	89 d6                	mov    %edx,%esi
ffff80000000311d:	83 e6 07             	and    $0x7,%esi
ffff800000003120:	0f a3 f7             	bt     %esi,%edi
ffff800000003123:	73 0e                	jae    ffff800000003133 <get_free_page_count+0x53>
ffff800000003125:	48 83 c2 01          	add    $0x1,%rdx
ffff800000003129:	4c 39 ca             	cmp    %r9,%rdx
ffff80000000312c:	74 12                	je     ffff800000003140 <get_free_page_count+0x60>
ffff80000000312e:	48 39 ca             	cmp    %rcx,%rdx
ffff800000003131:	72 dd                	jb     ffff800000003110 <get_free_page_count+0x30>
ffff800000003133:	48 83 c2 01          	add    $0x1,%rdx
ffff800000003137:	41 83 c0 01          	add    $0x1,%r8d
ffff80000000313b:	4c 39 ca             	cmp    %r9,%rdx
ffff80000000313e:	75 ee                	jne    ffff80000000312e <get_free_page_count+0x4e>
ffff800000003140:	44 89 c0             	mov    %r8d,%eax
ffff800000003143:	c3                   	ret    
ffff800000003144:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff80000000314b:	00 00 00 
ffff80000000314e:	66 90                	xchg   %ax,%ax

ffff800000003150 <pic_init>:
ffff800000003150:	b8 11 00 00 00       	mov    $0x11,%eax
ffff800000003155:	e6 20                	out    %al,$0x20
ffff800000003157:	e6 a0                	out    %al,$0xa0
ffff800000003159:	b8 20 00 00 00       	mov    $0x20,%eax
ffff80000000315e:	e6 21                	out    %al,$0x21
ffff800000003160:	b8 28 00 00 00       	mov    $0x28,%eax
ffff800000003165:	e6 a1                	out    %al,$0xa1
ffff800000003167:	b8 04 00 00 00       	mov    $0x4,%eax
ffff80000000316c:	e6 21                	out    %al,$0x21
ffff80000000316e:	b8 02 00 00 00       	mov    $0x2,%eax
ffff800000003173:	e6 a1                	out    %al,$0xa1
ffff800000003175:	b8 01 00 00 00       	mov    $0x1,%eax
ffff80000000317a:	e6 21                	out    %al,$0x21
ffff80000000317c:	e6 a1                	out    %al,$0xa1
ffff80000000317e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
ffff800000003183:	e6 21                	out    %al,$0x21
ffff800000003185:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
ffff80000000318a:	e6 a1                	out    %al,$0xa1
ffff80000000318c:	48 bf e8 5b 00 00 00 	movabs $0xffff800000005be8,%rdi
ffff800000003193:	80 ff ff 
ffff800000003196:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff80000000319d:	80 ff ff 
ffff8000000031a0:	ff e0                	jmp    *%rax
ffff8000000031a2:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000031a9:	00 00 00 
ffff8000000031ac:	0f 1f 40 00          	nopl   0x0(%rax)

ffff8000000031b0 <_put_char>:
ffff8000000031b0:	41 b8 d4 03 00 00    	mov    $0x3d4,%r8d
ffff8000000031b6:	53                   	push   %rbx
ffff8000000031b7:	89 fe                	mov    %edi,%esi
ffff8000000031b9:	b8 0e 00 00 00       	mov    $0xe,%eax
ffff8000000031be:	44 89 c2             	mov    %r8d,%edx
ffff8000000031c1:	ee                   	out    %al,(%dx)
ffff8000000031c2:	bf d5 03 00 00       	mov    $0x3d5,%edi
ffff8000000031c7:	89 fa                	mov    %edi,%edx
ffff8000000031c9:	ec                   	in     (%dx),%al
ffff8000000031ca:	0f b6 c8             	movzbl %al,%ecx
ffff8000000031cd:	44 89 c2             	mov    %r8d,%edx
ffff8000000031d0:	b8 0f 00 00 00       	mov    $0xf,%eax
ffff8000000031d5:	c1 e1 08             	shl    $0x8,%ecx
ffff8000000031d8:	ee                   	out    %al,(%dx)
ffff8000000031d9:	89 fa                	mov    %edi,%edx
ffff8000000031db:	ec                   	in     (%dx),%al
ffff8000000031dc:	0f b6 d0             	movzbl %al,%edx
ffff8000000031df:	09 ca                	or     %ecx,%edx
ffff8000000031e1:	40 80 fe 0d          	cmp    $0xd,%sil
ffff8000000031e5:	0f 84 f5 00 00 00    	je     ffff8000000032e0 <_put_char+0x130>
ffff8000000031eb:	40 80 fe 0a          	cmp    $0xa,%sil
ffff8000000031ef:	74 6d                	je     ffff80000000325e <_put_char+0xae>
ffff8000000031f1:	40 80 fe 08          	cmp    $0x8,%sil
ffff8000000031f5:	0f 84 fc 00 00 00    	je     ffff8000000032f7 <_put_char+0x147>
ffff8000000031fb:	48 b8 00 80 0b 00 00 	movabs $0xffff8000000b8000,%rax
ffff800000003202:	80 ff ff 
ffff800000003205:	48 8d 0c 12          	lea    (%rdx,%rdx,1),%rcx
ffff800000003209:	83 c2 01             	add    $0x1,%edx
ffff80000000320c:	81 e1 fe ff 01 00    	and    $0x1fffe,%ecx
ffff800000003212:	40 88 34 01          	mov    %sil,(%rcx,%rax,1)
ffff800000003216:	a0 bd 67 00 00 00 80 	movabs 0xffff8000000067bd,%al
ffff80000000321d:	ff ff 
ffff80000000321f:	48 be 01 80 0b 00 00 	movabs $0xffff8000000b8001,%rsi
ffff800000003226:	80 ff ff 
ffff800000003229:	88 04 31             	mov    %al,(%rcx,%rsi,1)
ffff80000000322c:	66 81 fa cf 07       	cmp    $0x7cf,%dx
ffff800000003231:	77 45                	ja     ffff800000003278 <_put_char+0xc8>
ffff800000003233:	0f b6 de             	movzbl %dh,%ebx
ffff800000003236:	89 d1                	mov    %edx,%ecx
ffff800000003238:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffff80000000323d:	b8 0e 00 00 00       	mov    $0xe,%eax
ffff800000003242:	89 fa                	mov    %edi,%edx
ffff800000003244:	ee                   	out    %al,(%dx)
ffff800000003245:	be d5 03 00 00       	mov    $0x3d5,%esi
ffff80000000324a:	89 d8                	mov    %ebx,%eax
ffff80000000324c:	89 f2                	mov    %esi,%edx
ffff80000000324e:	ee                   	out    %al,(%dx)
ffff80000000324f:	b8 0f 00 00 00       	mov    $0xf,%eax
ffff800000003254:	89 fa                	mov    %edi,%edx
ffff800000003256:	ee                   	out    %al,(%dx)
ffff800000003257:	89 c8                	mov    %ecx,%eax
ffff800000003259:	89 f2                	mov    %esi,%edx
ffff80000000325b:	ee                   	out    %al,(%dx)
ffff80000000325c:	5b                   	pop    %rbx
ffff80000000325d:	c3                   	ret    
ffff80000000325e:	0f b7 d2             	movzwl %dx,%edx
ffff800000003261:	69 d2 cd cc 00 00    	imul   $0xcccd,%edx,%edx
ffff800000003267:	c1 ea 16             	shr    $0x16,%edx
ffff80000000326a:	8d 54 92 05          	lea    0x5(%rdx,%rdx,4),%edx
ffff80000000326e:	c1 e2 04             	shl    $0x4,%edx
ffff800000003271:	66 81 fa cf 07       	cmp    $0x7cf,%dx
ffff800000003276:	76 bb                	jbe    ffff800000003233 <_put_char+0x83>
ffff800000003278:	48 be a0 80 0b 00 00 	movabs $0xffff8000000b80a0,%rsi
ffff80000000327f:	80 ff ff 
ffff800000003282:	ba 00 0f 00 00       	mov    $0xf00,%edx
ffff800000003287:	48 bf 00 80 0b 00 00 	movabs $0xffff8000000b8000,%rdi
ffff80000000328e:	80 ff ff 
ffff800000003291:	48 b8 10 48 00 00 00 	movabs $0xffff800000004810,%rax
ffff800000003298:	80 ff ff 
ffff80000000329b:	ff d0                	call   *%rax
ffff80000000329d:	48 b8 00 8f 0b 00 00 	movabs $0xffff8000000b8f00,%rax
ffff8000000032a4:	80 ff ff 
ffff8000000032a7:	48 ba a0 8f 0b 00 00 	movabs $0xffff8000000b8fa0,%rdx
ffff8000000032ae:	80 ff ff 
ffff8000000032b1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff8000000032b8:	c6 00 20             	movb   $0x20,(%rax)
ffff8000000032bb:	48 83 c0 02          	add    $0x2,%rax
ffff8000000032bf:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
ffff8000000032c3:	48 39 d0             	cmp    %rdx,%rax
ffff8000000032c6:	75 f0                	jne    ffff8000000032b8 <_put_char+0x108>
ffff8000000032c8:	b9 80 ff ff ff       	mov    $0xffffff80,%ecx
ffff8000000032cd:	bb 07 00 00 00       	mov    $0x7,%ebx
ffff8000000032d2:	e9 61 ff ff ff       	jmp    ffff800000003238 <_put_char+0x88>
ffff8000000032d7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff8000000032de:	00 00 
ffff8000000032e0:	0f b7 d2             	movzwl %dx,%edx
ffff8000000032e3:	69 d2 cd cc 00 00    	imul   $0xcccd,%edx,%edx
ffff8000000032e9:	c1 ea 16             	shr    $0x16,%edx
ffff8000000032ec:	8d 14 92             	lea    (%rdx,%rdx,4),%edx
ffff8000000032ef:	c1 e2 04             	shl    $0x4,%edx
ffff8000000032f2:	e9 35 ff ff ff       	jmp    ffff80000000322c <_put_char+0x7c>
ffff8000000032f7:	66 85 d2             	test   %dx,%dx
ffff8000000032fa:	74 36                	je     ffff800000003332 <_put_char+0x182>
ffff8000000032fc:	48 b8 00 80 0b 00 00 	movabs $0xffff8000000b8000,%rax
ffff800000003303:	80 ff ff 
ffff800000003306:	83 ea 01             	sub    $0x1,%edx
ffff800000003309:	48 be 01 80 0b 00 00 	movabs $0xffff8000000b8001,%rsi
ffff800000003310:	80 ff ff 
ffff800000003313:	48 8d 0c 12          	lea    (%rdx,%rdx,1),%rcx
ffff800000003317:	81 e1 fe ff 01 00    	and    $0x1fffe,%ecx
ffff80000000331d:	c6 04 01 20          	movb   $0x20,(%rcx,%rax,1)
ffff800000003321:	a0 bd 67 00 00 00 80 	movabs 0xffff8000000067bd,%al
ffff800000003328:	ff ff 
ffff80000000332a:	88 04 31             	mov    %al,(%rcx,%rsi,1)
ffff80000000332d:	e9 fa fe ff ff       	jmp    ffff80000000322c <_put_char+0x7c>
ffff800000003332:	31 c9                	xor    %ecx,%ecx
ffff800000003334:	31 db                	xor    %ebx,%ebx
ffff800000003336:	e9 fd fe ff ff       	jmp    ffff800000003238 <_put_char+0x88>
ffff80000000333b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff800000003340 <_print_int>:
ffff800000003340:	55                   	push   %rbp
ffff800000003341:	53                   	push   %rbx
ffff800000003342:	48 83 ec 28          	sub    $0x28,%rsp
ffff800000003346:	48 85 ff             	test   %rdi,%rdi
ffff800000003349:	0f 84 81 00 00 00    	je     ffff8000000033d0 <_print_int+0x90>
ffff80000000334f:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff800000003356:	80 ff ff 
ffff800000003359:	48 89 fb             	mov    %rdi,%rbx
ffff80000000335c:	78 62                	js     ffff8000000033c0 <_print_int+0x80>
ffff80000000335e:	49 b8 cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r8
ffff800000003365:	cc cc cc 
ffff800000003368:	be 01 00 00 00       	mov    $0x1,%esi
ffff80000000336d:	0f 1f 00             	nopl   (%rax)
ffff800000003370:	48 89 d8             	mov    %rbx,%rax
ffff800000003373:	89 f1                	mov    %esi,%ecx
ffff800000003375:	49 f7 e0             	mul    %r8
ffff800000003378:	48 c1 ea 03          	shr    $0x3,%rdx
ffff80000000337c:	48 8d 04 92          	lea    (%rdx,%rdx,4),%rax
ffff800000003380:	48 01 c0             	add    %rax,%rax
ffff800000003383:	48 29 c3             	sub    %rax,%rbx
ffff800000003386:	8d 7b 30             	lea    0x30(%rbx),%edi
ffff800000003389:	48 89 d3             	mov    %rdx,%rbx
ffff80000000338c:	40 88 7c 34 0b       	mov    %dil,0xb(%rsp,%rsi,1)
ffff800000003391:	48 83 c6 01          	add    $0x1,%rsi
ffff800000003395:	48 85 d2             	test   %rdx,%rdx
ffff800000003398:	75 d6                	jne    ffff800000003370 <_print_int+0x30>
ffff80000000339a:	48 63 d9             	movslq %ecx,%rbx
ffff80000000339d:	eb 06                	jmp    ffff8000000033a5 <_print_int+0x65>
ffff80000000339f:	90                   	nop
ffff8000000033a0:	0f b6 7c 1c 0b       	movzbl 0xb(%rsp,%rbx,1),%edi
ffff8000000033a5:	48 83 eb 01          	sub    $0x1,%rbx
ffff8000000033a9:	40 0f be ff          	movsbl %dil,%edi
ffff8000000033ad:	ff d5                	call   *%rbp
ffff8000000033af:	85 db                	test   %ebx,%ebx
ffff8000000033b1:	75 ed                	jne    ffff8000000033a0 <_print_int+0x60>
ffff8000000033b3:	48 83 c4 28          	add    $0x28,%rsp
ffff8000000033b7:	5b                   	pop    %rbx
ffff8000000033b8:	5d                   	pop    %rbp
ffff8000000033b9:	c3                   	ret    
ffff8000000033ba:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff8000000033c0:	bf 2d 00 00 00       	mov    $0x2d,%edi
ffff8000000033c5:	48 f7 db             	neg    %rbx
ffff8000000033c8:	ff d5                	call   *%rbp
ffff8000000033ca:	eb 92                	jmp    ffff80000000335e <_print_int+0x1e>
ffff8000000033cc:	0f 1f 40 00          	nopl   0x0(%rax)
ffff8000000033d0:	48 83 c4 28          	add    $0x28,%rsp
ffff8000000033d4:	bf 30 00 00 00       	mov    $0x30,%edi
ffff8000000033d9:	48 b8 b0 31 00 00 00 	movabs $0xffff8000000031b0,%rax
ffff8000000033e0:	80 ff ff 
ffff8000000033e3:	5b                   	pop    %rbx
ffff8000000033e4:	5d                   	pop    %rbp
ffff8000000033e5:	ff e0                	jmp    *%rax
ffff8000000033e7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff8000000033ee:	00 00 

ffff8000000033f0 <_get_cursor>:
ffff8000000033f0:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffff8000000033f5:	b8 0e 00 00 00       	mov    $0xe,%eax
ffff8000000033fa:	89 fa                	mov    %edi,%edx
ffff8000000033fc:	ee                   	out    %al,(%dx)
ffff8000000033fd:	be d5 03 00 00       	mov    $0x3d5,%esi
ffff800000003402:	89 f2                	mov    %esi,%edx
ffff800000003404:	ec                   	in     (%dx),%al
ffff800000003405:	0f b6 c8             	movzbl %al,%ecx
ffff800000003408:	89 fa                	mov    %edi,%edx
ffff80000000340a:	b8 0f 00 00 00       	mov    $0xf,%eax
ffff80000000340f:	c1 e1 08             	shl    $0x8,%ecx
ffff800000003412:	ee                   	out    %al,(%dx)
ffff800000003413:	89 f2                	mov    %esi,%edx
ffff800000003415:	ec                   	in     (%dx),%al
ffff800000003416:	0f b6 c0             	movzbl %al,%eax
ffff800000003419:	09 c8                	or     %ecx,%eax
ffff80000000341b:	c3                   	ret    
ffff80000000341c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000003420 <_set_cursor>:
ffff800000003420:	be d4 03 00 00       	mov    $0x3d4,%esi
ffff800000003425:	41 89 f8             	mov    %edi,%r8d
ffff800000003428:	b8 0e 00 00 00       	mov    $0xe,%eax
ffff80000000342d:	89 f2                	mov    %esi,%edx
ffff80000000342f:	ee                   	out    %al,(%dx)
ffff800000003430:	b9 d5 03 00 00       	mov    $0x3d5,%ecx
ffff800000003435:	66 c1 ef 08          	shr    $0x8,%di
ffff800000003439:	89 f8                	mov    %edi,%eax
ffff80000000343b:	89 ca                	mov    %ecx,%edx
ffff80000000343d:	ee                   	out    %al,(%dx)
ffff80000000343e:	b8 0f 00 00 00       	mov    $0xf,%eax
ffff800000003443:	89 f2                	mov    %esi,%edx
ffff800000003445:	ee                   	out    %al,(%dx)
ffff800000003446:	44 89 c0             	mov    %r8d,%eax
ffff800000003449:	89 ca                	mov    %ecx,%edx
ffff80000000344b:	ee                   	out    %al,(%dx)
ffff80000000344c:	c3                   	ret    
ffff80000000344d:	0f 1f 00             	nopl   (%rax)

ffff800000003450 <clear_screen>:
ffff800000003450:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003457:	80 ff ff 
ffff80000000345a:	55                   	push   %rbp
ffff80000000345b:	48 bd 70 89 00 00 00 	movabs $0xffff800000008970,%rbp
ffff800000003462:	80 ff ff 
ffff800000003465:	48 89 ef             	mov    %rbp,%rdi
ffff800000003468:	ff d0                	call   *%rax
ffff80000000346a:	48 b8 00 80 0b 00 00 	movabs $0xffff8000000b8000,%rax
ffff800000003471:	80 ff ff 
ffff800000003474:	48 ba a0 8f 0b 00 00 	movabs $0xffff8000000b8fa0,%rdx
ffff80000000347b:	80 ff ff 
ffff80000000347e:	66 90                	xchg   %ax,%ax
ffff800000003480:	c6 00 20             	movb   $0x20,(%rax)
ffff800000003483:	48 83 c0 02          	add    $0x2,%rax
ffff800000003487:	c6 40 ff 0f          	movb   $0xf,-0x1(%rax)
ffff80000000348b:	48 39 d0             	cmp    %rdx,%rax
ffff80000000348e:	75 f0                	jne    ffff800000003480 <clear_screen+0x30>
ffff800000003490:	bf d4 03 00 00       	mov    $0x3d4,%edi
ffff800000003495:	b8 0e 00 00 00       	mov    $0xe,%eax
ffff80000000349a:	89 fa                	mov    %edi,%edx
ffff80000000349c:	ee                   	out    %al,(%dx)
ffff80000000349d:	31 c9                	xor    %ecx,%ecx
ffff80000000349f:	be d5 03 00 00       	mov    $0x3d5,%esi
ffff8000000034a4:	89 c8                	mov    %ecx,%eax
ffff8000000034a6:	89 f2                	mov    %esi,%edx
ffff8000000034a8:	ee                   	out    %al,(%dx)
ffff8000000034a9:	b8 0f 00 00 00       	mov    $0xf,%eax
ffff8000000034ae:	89 fa                	mov    %edi,%edx
ffff8000000034b0:	ee                   	out    %al,(%dx)
ffff8000000034b1:	89 c8                	mov    %ecx,%eax
ffff8000000034b3:	89 f2                	mov    %esi,%edx
ffff8000000034b5:	ee                   	out    %al,(%dx)
ffff8000000034b6:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff8000000034bd:	80 ff ff 
ffff8000000034c0:	48 89 ef             	mov    %rbp,%rdi
ffff8000000034c3:	5d                   	pop    %rbp
ffff8000000034c4:	ff e0                	jmp    *%rax
ffff8000000034c6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000034cd:	00 00 00 

ffff8000000034d0 <put_char>:
ffff8000000034d0:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff8000000034d7:	80 ff ff 
ffff8000000034da:	55                   	push   %rbp
ffff8000000034db:	48 bd 70 89 00 00 00 	movabs $0xffff800000008970,%rbp
ffff8000000034e2:	80 ff ff 
ffff8000000034e5:	53                   	push   %rbx
ffff8000000034e6:	89 fb                	mov    %edi,%ebx
ffff8000000034e8:	48 89 ef             	mov    %rbp,%rdi
ffff8000000034eb:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000034ef:	ff d0                	call   *%rax
ffff8000000034f1:	0f be fb             	movsbl %bl,%edi
ffff8000000034f4:	48 b8 b0 31 00 00 00 	movabs $0xffff8000000031b0,%rax
ffff8000000034fb:	80 ff ff 
ffff8000000034fe:	ff d0                	call   *%rax
ffff800000003500:	48 83 c4 08          	add    $0x8,%rsp
ffff800000003504:	48 89 ef             	mov    %rbp,%rdi
ffff800000003507:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff80000000350e:	80 ff ff 
ffff800000003511:	5b                   	pop    %rbx
ffff800000003512:	5d                   	pop    %rbp
ffff800000003513:	ff e0                	jmp    *%rax
ffff800000003515:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff80000000351c:	00 00 00 00 

ffff800000003520 <print_string>:
ffff800000003520:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003527:	80 ff ff 
ffff80000000352a:	41 54                	push   %r12
ffff80000000352c:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff800000003533:	80 ff ff 
ffff800000003536:	55                   	push   %rbp
ffff800000003537:	53                   	push   %rbx
ffff800000003538:	48 89 fb             	mov    %rdi,%rbx
ffff80000000353b:	4c 89 e7             	mov    %r12,%rdi
ffff80000000353e:	ff d0                	call   *%rax
ffff800000003540:	0f be 3b             	movsbl (%rbx),%edi
ffff800000003543:	40 84 ff             	test   %dil,%dil
ffff800000003546:	74 1f                	je     ffff800000003567 <print_string+0x47>
ffff800000003548:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff80000000354f:	80 ff ff 
ffff800000003552:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000003558:	ff d5                	call   *%rbp
ffff80000000355a:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff80000000355e:	48 83 c3 01          	add    $0x1,%rbx
ffff800000003562:	40 84 ff             	test   %dil,%dil
ffff800000003565:	75 f1                	jne    ffff800000003558 <print_string+0x38>
ffff800000003567:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff80000000356e:	80 ff ff 
ffff800000003571:	5b                   	pop    %rbx
ffff800000003572:	4c 89 e7             	mov    %r12,%rdi
ffff800000003575:	5d                   	pop    %rbp
ffff800000003576:	41 5c                	pop    %r12
ffff800000003578:	ff e0                	jmp    *%rax
ffff80000000357a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff800000003580 <print_hex>:
ffff800000003580:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003587:	80 ff ff 
ffff80000000358a:	41 55                	push   %r13
ffff80000000358c:	49 bd f7 57 00 00 00 	movabs $0xffff8000000057f7,%r13
ffff800000003593:	80 ff ff 
ffff800000003596:	41 54                	push   %r12
ffff800000003598:	49 89 fc             	mov    %rdi,%r12
ffff80000000359b:	55                   	push   %rbp
ffff80000000359c:	48 bd 70 89 00 00 00 	movabs $0xffff800000008970,%rbp
ffff8000000035a3:	80 ff ff 
ffff8000000035a6:	53                   	push   %rbx
ffff8000000035a7:	48 89 ef             	mov    %rbp,%rdi
ffff8000000035aa:	48 bb b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbx
ffff8000000035b1:	80 ff ff 
ffff8000000035b4:	48 83 ec 18          	sub    $0x18,%rsp
ffff8000000035b8:	ff d0                	call   *%rax
ffff8000000035ba:	bf 30 00 00 00       	mov    $0x30,%edi
ffff8000000035bf:	90                   	nop
ffff8000000035c0:	ff d3                	call   *%rbx
ffff8000000035c2:	41 0f be 7d 01       	movsbl 0x1(%r13),%edi
ffff8000000035c7:	49 83 c5 01          	add    $0x1,%r13
ffff8000000035cb:	40 84 ff             	test   %dil,%dil
ffff8000000035ce:	75 f0                	jne    ffff8000000035c0 <print_hex+0x40>
ffff8000000035d0:	48 be 14 5c 00 00 00 	movabs $0xffff800000005c14,%rsi
ffff8000000035d7:	80 ff ff 
ffff8000000035da:	ba 01 00 00 00       	mov    $0x1,%edx
ffff8000000035df:	4d 85 e4             	test   %r12,%r12
ffff8000000035e2:	74 5c                	je     ffff800000003640 <print_hex+0xc0>
ffff8000000035e4:	0f 1f 40 00          	nopl   0x0(%rax)
ffff8000000035e8:	4c 89 e1             	mov    %r12,%rcx
ffff8000000035eb:	89 d0                	mov    %edx,%eax
ffff8000000035ed:	83 e1 0f             	and    $0xf,%ecx
ffff8000000035f0:	0f be 3c 0e          	movsbl (%rsi,%rcx,1),%edi
ffff8000000035f4:	40 88 7c 14 ff       	mov    %dil,-0x1(%rsp,%rdx,1)
ffff8000000035f9:	48 83 c2 01          	add    $0x1,%rdx
ffff8000000035fd:	49 c1 ec 04          	shr    $0x4,%r12
ffff800000003601:	75 e5                	jne    ffff8000000035e8 <print_hex+0x68>
ffff800000003603:	44 8d 60 ff          	lea    -0x1(%rax),%r12d
ffff800000003607:	4d 63 e4             	movslq %r12d,%r12
ffff80000000360a:	eb 0e                	jmp    ffff80000000361a <print_hex+0x9a>
ffff80000000360c:	0f 1f 40 00          	nopl   0x0(%rax)
ffff800000003610:	42 0f be 7c 24 ff    	movsbl -0x1(%rsp,%r12,1),%edi
ffff800000003616:	49 83 ec 01          	sub    $0x1,%r12
ffff80000000361a:	ff d3                	call   *%rbx
ffff80000000361c:	45 85 e4             	test   %r12d,%r12d
ffff80000000361f:	75 ef                	jne    ffff800000003610 <print_hex+0x90>
ffff800000003621:	48 83 c4 18          	add    $0x18,%rsp
ffff800000003625:	48 89 ef             	mov    %rbp,%rdi
ffff800000003628:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff80000000362f:	80 ff ff 
ffff800000003632:	5b                   	pop    %rbx
ffff800000003633:	5d                   	pop    %rbp
ffff800000003634:	41 5c                	pop    %r12
ffff800000003636:	41 5d                	pop    %r13
ffff800000003638:	ff e0                	jmp    *%rax
ffff80000000363a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000003640:	bf 30 00 00 00       	mov    $0x30,%edi
ffff800000003645:	ff d3                	call   *%rbx
ffff800000003647:	eb d8                	jmp    ffff800000003621 <print_hex+0xa1>
ffff800000003649:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

ffff800000003650 <print_int>:
ffff800000003650:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003657:	80 ff ff 
ffff80000000365a:	41 54                	push   %r12
ffff80000000365c:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff800000003663:	80 ff ff 
ffff800000003666:	55                   	push   %rbp
ffff800000003667:	48 89 fd             	mov    %rdi,%rbp
ffff80000000366a:	4c 89 e7             	mov    %r12,%rdi
ffff80000000366d:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000003671:	ff d0                	call   *%rax
ffff800000003673:	48 89 ef             	mov    %rbp,%rdi
ffff800000003676:	48 b8 40 33 00 00 00 	movabs $0xffff800000003340,%rax
ffff80000000367d:	80 ff ff 
ffff800000003680:	ff d0                	call   *%rax
ffff800000003682:	48 83 c4 08          	add    $0x8,%rsp
ffff800000003686:	4c 89 e7             	mov    %r12,%rdi
ffff800000003689:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff800000003690:	80 ff ff 
ffff800000003693:	5d                   	pop    %rbp
ffff800000003694:	41 5c                	pop    %r12
ffff800000003696:	ff e0                	jmp    *%rax
ffff800000003698:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff80000000369f:	00 

ffff8000000036a0 <set_print_color>:
ffff8000000036a0:	89 f0                	mov    %esi,%eax
ffff8000000036a2:	83 e7 0f             	and    $0xf,%edi
ffff8000000036a5:	c1 e0 04             	shl    $0x4,%eax
ffff8000000036a8:	09 f8                	or     %edi,%eax
ffff8000000036aa:	a2 bd 67 00 00 00 80 	movabs %al,0xffff8000000067bd
ffff8000000036b1:	ff ff 
ffff8000000036b3:	c3                   	ret    
ffff8000000036b4:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000036bb:	00 00 00 00 
ffff8000000036bf:	90                   	nop

ffff8000000036c0 <reset_print_color>:
ffff8000000036c0:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff8000000036c7:	80 ff ff 
ffff8000000036ca:	c6 00 0f             	movb   $0xf,(%rax)
ffff8000000036cd:	c3                   	ret    
ffff8000000036ce:	66 90                	xchg   %ax,%ax

ffff8000000036d0 <print_error>:
ffff8000000036d0:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff8000000036d7:	80 ff ff 
ffff8000000036da:	41 54                	push   %r12
ffff8000000036dc:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff8000000036e3:	80 ff ff 
ffff8000000036e6:	55                   	push   %rbp
ffff8000000036e7:	53                   	push   %rbx
ffff8000000036e8:	48 89 fb             	mov    %rdi,%rbx
ffff8000000036eb:	4c 89 e7             	mov    %r12,%rdi
ffff8000000036ee:	ff d0                	call   *%rax
ffff8000000036f0:	0f be 3b             	movsbl (%rbx),%edi
ffff8000000036f3:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff8000000036fa:	80 ff ff 
ffff8000000036fd:	c6 00 0c             	movb   $0xc,(%rax)
ffff800000003700:	40 84 ff             	test   %dil,%dil
ffff800000003703:	74 1a                	je     ffff80000000371f <print_error+0x4f>
ffff800000003705:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff80000000370c:	80 ff ff 
ffff80000000370f:	90                   	nop
ffff800000003710:	ff d5                	call   *%rbp
ffff800000003712:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff800000003716:	48 83 c3 01          	add    $0x1,%rbx
ffff80000000371a:	40 84 ff             	test   %dil,%dil
ffff80000000371d:	75 f1                	jne    ffff800000003710 <print_error+0x40>
ffff80000000371f:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff800000003726:	80 ff ff 
ffff800000003729:	4c 89 e7             	mov    %r12,%rdi
ffff80000000372c:	c6 00 0f             	movb   $0xf,(%rax)
ffff80000000372f:	5b                   	pop    %rbx
ffff800000003730:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff800000003737:	80 ff ff 
ffff80000000373a:	5d                   	pop    %rbp
ffff80000000373b:	41 5c                	pop    %r12
ffff80000000373d:	ff e0                	jmp    *%rax
ffff80000000373f:	90                   	nop

ffff800000003740 <print_success>:
ffff800000003740:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003747:	80 ff ff 
ffff80000000374a:	41 54                	push   %r12
ffff80000000374c:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff800000003753:	80 ff ff 
ffff800000003756:	55                   	push   %rbp
ffff800000003757:	53                   	push   %rbx
ffff800000003758:	48 89 fb             	mov    %rdi,%rbx
ffff80000000375b:	4c 89 e7             	mov    %r12,%rdi
ffff80000000375e:	ff d0                	call   *%rax
ffff800000003760:	0f be 3b             	movsbl (%rbx),%edi
ffff800000003763:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff80000000376a:	80 ff ff 
ffff80000000376d:	c6 00 0a             	movb   $0xa,(%rax)
ffff800000003770:	40 84 ff             	test   %dil,%dil
ffff800000003773:	74 1a                	je     ffff80000000378f <print_success+0x4f>
ffff800000003775:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff80000000377c:	80 ff ff 
ffff80000000377f:	90                   	nop
ffff800000003780:	ff d5                	call   *%rbp
ffff800000003782:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff800000003786:	48 83 c3 01          	add    $0x1,%rbx
ffff80000000378a:	40 84 ff             	test   %dil,%dil
ffff80000000378d:	75 f1                	jne    ffff800000003780 <print_success+0x40>
ffff80000000378f:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff800000003796:	80 ff ff 
ffff800000003799:	4c 89 e7             	mov    %r12,%rdi
ffff80000000379c:	c6 00 0f             	movb   $0xf,(%rax)
ffff80000000379f:	5b                   	pop    %rbx
ffff8000000037a0:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff8000000037a7:	80 ff ff 
ffff8000000037aa:	5d                   	pop    %rbp
ffff8000000037ab:	41 5c                	pop    %r12
ffff8000000037ad:	ff e0                	jmp    *%rax
ffff8000000037af:	90                   	nop

ffff8000000037b0 <print_info>:
ffff8000000037b0:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff8000000037b7:	80 ff ff 
ffff8000000037ba:	41 54                	push   %r12
ffff8000000037bc:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff8000000037c3:	80 ff ff 
ffff8000000037c6:	55                   	push   %rbp
ffff8000000037c7:	53                   	push   %rbx
ffff8000000037c8:	48 89 fb             	mov    %rdi,%rbx
ffff8000000037cb:	4c 89 e7             	mov    %r12,%rdi
ffff8000000037ce:	ff d0                	call   *%rax
ffff8000000037d0:	0f be 3b             	movsbl (%rbx),%edi
ffff8000000037d3:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff8000000037da:	80 ff ff 
ffff8000000037dd:	c6 00 0b             	movb   $0xb,(%rax)
ffff8000000037e0:	40 84 ff             	test   %dil,%dil
ffff8000000037e3:	74 1a                	je     ffff8000000037ff <print_info+0x4f>
ffff8000000037e5:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff8000000037ec:	80 ff ff 
ffff8000000037ef:	90                   	nop
ffff8000000037f0:	ff d5                	call   *%rbp
ffff8000000037f2:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff8000000037f6:	48 83 c3 01          	add    $0x1,%rbx
ffff8000000037fa:	40 84 ff             	test   %dil,%dil
ffff8000000037fd:	75 f1                	jne    ffff8000000037f0 <print_info+0x40>
ffff8000000037ff:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff800000003806:	80 ff ff 
ffff800000003809:	4c 89 e7             	mov    %r12,%rdi
ffff80000000380c:	c6 00 0f             	movb   $0xf,(%rax)
ffff80000000380f:	5b                   	pop    %rbx
ffff800000003810:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff800000003817:	80 ff ff 
ffff80000000381a:	5d                   	pop    %rbp
ffff80000000381b:	41 5c                	pop    %r12
ffff80000000381d:	ff e0                	jmp    *%rax
ffff80000000381f:	90                   	nop

ffff800000003820 <print_warning>:
ffff800000003820:	48 b8 10 49 00 00 00 	movabs $0xffff800000004910,%rax
ffff800000003827:	80 ff ff 
ffff80000000382a:	41 54                	push   %r12
ffff80000000382c:	49 bc 70 89 00 00 00 	movabs $0xffff800000008970,%r12
ffff800000003833:	80 ff ff 
ffff800000003836:	55                   	push   %rbp
ffff800000003837:	53                   	push   %rbx
ffff800000003838:	48 89 fb             	mov    %rdi,%rbx
ffff80000000383b:	4c 89 e7             	mov    %r12,%rdi
ffff80000000383e:	ff d0                	call   *%rax
ffff800000003840:	0f be 3b             	movsbl (%rbx),%edi
ffff800000003843:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff80000000384a:	80 ff ff 
ffff80000000384d:	c6 00 0e             	movb   $0xe,(%rax)
ffff800000003850:	40 84 ff             	test   %dil,%dil
ffff800000003853:	74 1a                	je     ffff80000000386f <print_warning+0x4f>
ffff800000003855:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff80000000385c:	80 ff ff 
ffff80000000385f:	90                   	nop
ffff800000003860:	ff d5                	call   *%rbp
ffff800000003862:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff800000003866:	48 83 c3 01          	add    $0x1,%rbx
ffff80000000386a:	40 84 ff             	test   %dil,%dil
ffff80000000386d:	75 f1                	jne    ffff800000003860 <print_warning+0x40>
ffff80000000386f:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff800000003876:	80 ff ff 
ffff800000003879:	4c 89 e7             	mov    %r12,%rdi
ffff80000000387c:	c6 00 0f             	movb   $0xf,(%rax)
ffff80000000387f:	5b                   	pop    %rbx
ffff800000003880:	48 b8 a0 49 00 00 00 	movabs $0xffff8000000049a0,%rax
ffff800000003887:	80 ff ff 
ffff80000000388a:	5d                   	pop    %rbp
ffff80000000388b:	41 5c                	pop    %r12
ffff80000000388d:	ff e0                	jmp    *%rax
ffff80000000388f:	90                   	nop

ffff800000003890 <panic_print>:
ffff800000003890:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff800000003897:	80 ff ff 
ffff80000000389a:	55                   	push   %rbp
ffff80000000389b:	53                   	push   %rbx
ffff80000000389c:	48 89 fb             	mov    %rdi,%rbx
ffff80000000389f:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000038a3:	0f be 3f             	movsbl (%rdi),%edi
ffff8000000038a6:	c6 00 4f             	movb   $0x4f,(%rax)
ffff8000000038a9:	40 84 ff             	test   %dil,%dil
ffff8000000038ac:	74 21                	je     ffff8000000038cf <panic_print+0x3f>
ffff8000000038ae:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff8000000038b5:	80 ff ff 
ffff8000000038b8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff8000000038bf:	00 
ffff8000000038c0:	ff d5                	call   *%rbp
ffff8000000038c2:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff8000000038c6:	48 83 c3 01          	add    $0x1,%rbx
ffff8000000038ca:	40 84 ff             	test   %dil,%dil
ffff8000000038cd:	75 f1                	jne    ffff8000000038c0 <panic_print+0x30>
ffff8000000038cf:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000038d3:	5b                   	pop    %rbx
ffff8000000038d4:	5d                   	pop    %rbp
ffff8000000038d5:	c3                   	ret    
ffff8000000038d6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000038dd:	00 00 00 

ffff8000000038e0 <panic_print_hex>:
ffff8000000038e0:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff8000000038e7:	80 ff ff 
ffff8000000038ea:	41 54                	push   %r12
ffff8000000038ec:	49 89 fc             	mov    %rdi,%r12
ffff8000000038ef:	bf 30 00 00 00       	mov    $0x30,%edi
ffff8000000038f4:	55                   	push   %rbp
ffff8000000038f5:	48 bd b0 31 00 00 00 	movabs $0xffff8000000031b0,%rbp
ffff8000000038fc:	80 ff ff 
ffff8000000038ff:	53                   	push   %rbx
ffff800000003900:	48 bb f7 57 00 00 00 	movabs $0xffff8000000057f7,%rbx
ffff800000003907:	80 ff ff 
ffff80000000390a:	48 83 ec 10          	sub    $0x10,%rsp
ffff80000000390e:	c6 00 4f             	movb   $0x4f,(%rax)
ffff800000003911:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000003918:	ff d5                	call   *%rbp
ffff80000000391a:	0f be 7b 01          	movsbl 0x1(%rbx),%edi
ffff80000000391e:	48 83 c3 01          	add    $0x1,%rbx
ffff800000003922:	40 84 ff             	test   %dil,%dil
ffff800000003925:	75 f1                	jne    ffff800000003918 <panic_print_hex+0x38>
ffff800000003927:	48 b9 14 5c 00 00 00 	movabs $0xffff800000005c14,%rcx
ffff80000000392e:	80 ff ff 
ffff800000003931:	b8 01 00 00 00       	mov    $0x1,%eax
ffff800000003936:	4d 85 e4             	test   %r12,%r12
ffff800000003939:	74 45                	je     ffff800000003980 <panic_print_hex+0xa0>
ffff80000000393b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000003940:	4c 89 e2             	mov    %r12,%rdx
ffff800000003943:	89 c3                	mov    %eax,%ebx
ffff800000003945:	83 e2 0f             	and    $0xf,%edx
ffff800000003948:	0f be 3c 11          	movsbl (%rcx,%rdx,1),%edi
ffff80000000394c:	40 88 7c 04 ff       	mov    %dil,-0x1(%rsp,%rax,1)
ffff800000003951:	48 83 c0 01          	add    $0x1,%rax
ffff800000003955:	49 c1 ec 04          	shr    $0x4,%r12
ffff800000003959:	75 e5                	jne    ffff800000003940 <panic_print_hex+0x60>
ffff80000000395b:	83 eb 01             	sub    $0x1,%ebx
ffff80000000395e:	48 63 db             	movslq %ebx,%rbx
ffff800000003961:	eb 0e                	jmp    ffff800000003971 <panic_print_hex+0x91>
ffff800000003963:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000003968:	0f be 7c 1c ff       	movsbl -0x1(%rsp,%rbx,1),%edi
ffff80000000396d:	48 83 eb 01          	sub    $0x1,%rbx
ffff800000003971:	ff d5                	call   *%rbp
ffff800000003973:	85 db                	test   %ebx,%ebx
ffff800000003975:	75 f1                	jne    ffff800000003968 <panic_print_hex+0x88>
ffff800000003977:	48 83 c4 10          	add    $0x10,%rsp
ffff80000000397b:	5b                   	pop    %rbx
ffff80000000397c:	5d                   	pop    %rbp
ffff80000000397d:	41 5c                	pop    %r12
ffff80000000397f:	c3                   	ret    
ffff800000003980:	48 83 c4 10          	add    $0x10,%rsp
ffff800000003984:	48 89 e8             	mov    %rbp,%rax
ffff800000003987:	bf 30 00 00 00       	mov    $0x30,%edi
ffff80000000398c:	5b                   	pop    %rbx
ffff80000000398d:	5d                   	pop    %rbp
ffff80000000398e:	41 5c                	pop    %r12
ffff800000003990:	ff e0                	jmp    *%rax
ffff800000003992:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000003999:	00 00 00 00 
ffff80000000399d:	0f 1f 00             	nopl   (%rax)

ffff8000000039a0 <panic_print_int>:
ffff8000000039a0:	48 b8 bd 67 00 00 00 	movabs $0xffff8000000067bd,%rax
ffff8000000039a7:	80 ff ff 
ffff8000000039aa:	c6 00 4f             	movb   $0x4f,(%rax)
ffff8000000039ad:	48 b8 40 33 00 00 00 	movabs $0xffff800000003340,%rax
ffff8000000039b4:	80 ff ff 
ffff8000000039b7:	ff e0                	jmp    *%rax
ffff8000000039b9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

ffff8000000039c0 <print_init>:
ffff8000000039c0:	48 bf 70 89 00 00 00 	movabs $0xffff800000008970,%rdi
ffff8000000039c7:	80 ff ff 
ffff8000000039ca:	48 b8 f0 48 00 00 00 	movabs $0xffff8000000048f0,%rax
ffff8000000039d1:	80 ff ff 
ffff8000000039d4:	ff e0                	jmp    *%rax
ffff8000000039d6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000039dd:	00 00 00 

ffff8000000039e0 <dummy_thread_task>:
ffff8000000039e0:	48 bf 28 5c 00 00 00 	movabs $0xffff800000005c28,%rdi
ffff8000000039e7:	80 ff ff 
ffff8000000039ea:	55                   	push   %rbp
ffff8000000039eb:	48 bd b0 37 00 00 00 	movabs $0xffff8000000037b0,%rbp
ffff8000000039f2:	80 ff ff 
ffff8000000039f5:	53                   	push   %rbx
ffff8000000039f6:	48 bb 90 54 00 00 00 	movabs $0xffff800000005490,%rbx
ffff8000000039fd:	80 ff ff 
ffff800000003a00:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000003a04:	ff d5                	call   *%rbp
ffff800000003a06:	48 bf 68 5c 00 00 00 	movabs $0xffff800000005c68,%rdi
ffff800000003a0d:	80 ff ff 
ffff800000003a10:	ff d5                	call   *%rbp
ffff800000003a12:	ff d3                	call   *%rbx
ffff800000003a14:	48 bf a0 5c 00 00 00 	movabs $0xffff800000005ca0,%rdi
ffff800000003a1b:	80 ff ff 
ffff800000003a1e:	ff d5                	call   *%rbp
ffff800000003a20:	ff d3                	call   *%rbx
ffff800000003a22:	ff d3                	call   *%rbx
ffff800000003a24:	eb fa                	jmp    ffff800000003a20 <dummy_thread_task+0x40>
ffff800000003a26:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff800000003a2d:	00 00 00 

ffff800000003a30 <shell_init>:
ffff800000003a30:	48 bf e7 62 00 00 00 	movabs $0xffff8000000062e7,%rdi
ffff800000003a37:	80 ff ff 
ffff800000003a3a:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000003a41:	80 ff ff 
ffff800000003a44:	ff e0                	jmp    *%rax
ffff800000003a46:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff800000003a4d:	00 00 00 

ffff800000003a50 <execute_command>:
ffff800000003a50:	a1 a0 89 00 00 00 80 	movabs 0xffff8000000089a0,%eax
ffff800000003a57:	ff ff 
ffff800000003a59:	85 c0                	test   %eax,%eax
ffff800000003a5b:	75 03                	jne    ffff800000003a60 <execute_command+0x10>
ffff800000003a5d:	c3                   	ret    
ffff800000003a5e:	66 90                	xchg   %ax,%ax
ffff800000003a60:	48 be ef 62 00 00 00 	movabs $0xffff8000000062ef,%rsi
ffff800000003a67:	80 ff ff 
ffff800000003a6a:	41 57                	push   %r15
ffff800000003a6c:	48 98                	cltq   
ffff800000003a6e:	41 56                	push   %r14
ffff800000003a70:	41 55                	push   %r13
ffff800000003a72:	41 54                	push   %r12
ffff800000003a74:	55                   	push   %rbp
ffff800000003a75:	48 89 fd             	mov    %rdi,%rbp
ffff800000003a78:	53                   	push   %rbx
ffff800000003a79:	48 bb 70 47 00 00 00 	movabs $0xffff800000004770,%rbx
ffff800000003a80:	80 ff ff 
ffff800000003a83:	48 83 ec 58          	sub    $0x58,%rsp
ffff800000003a87:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
ffff800000003a8b:	ff d3                	call   *%rbx
ffff800000003a8d:	85 c0                	test   %eax,%eax
ffff800000003a8f:	0f 85 9b 00 00 00    	jne    ffff800000003b30 <execute_command+0xe0>
ffff800000003a95:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000003a9c:	80 ff ff 
ffff800000003a9f:	48 bf d8 5c 00 00 00 	movabs $0xffff800000005cd8,%rdi
ffff800000003aa6:	80 ff ff 
ffff800000003aa9:	48 bd b0 37 00 00 00 	movabs $0xffff8000000037b0,%rbp
ffff800000003ab0:	80 ff ff 
ffff800000003ab3:	ff d5                	call   *%rbp
ffff800000003ab5:	48 bf 10 5d 00 00 00 	movabs $0xffff800000005d10,%rdi
ffff800000003abc:	80 ff ff 
ffff800000003abf:	ff d3                	call   *%rbx
ffff800000003ac1:	48 bf f4 62 00 00 00 	movabs $0xffff8000000062f4,%rdi
ffff800000003ac8:	80 ff ff 
ffff800000003acb:	ff d3                	call   *%rbx
ffff800000003acd:	48 bf 40 5d 00 00 00 	movabs $0xffff800000005d40,%rdi
ffff800000003ad4:	80 ff ff 
ffff800000003ad7:	ff d3                	call   *%rbx
ffff800000003ad9:	48 bf 70 5d 00 00 00 	movabs $0xffff800000005d70,%rdi
ffff800000003ae0:	80 ff ff 
ffff800000003ae3:	ff d3                	call   *%rbx
ffff800000003ae5:	48 bf 90 5d 00 00 00 	movabs $0xffff800000005d90,%rdi
ffff800000003aec:	80 ff ff 
ffff800000003aef:	ff d3                	call   *%rbx
ffff800000003af1:	48 bf c0 5d 00 00 00 	movabs $0xffff800000005dc0,%rdi
ffff800000003af8:	80 ff ff 
ffff800000003afb:	ff d3                	call   *%rbx
ffff800000003afd:	48 bf e0 5d 00 00 00 	movabs $0xffff800000005de0,%rdi
ffff800000003b04:	80 ff ff 
ffff800000003b07:	ff d5                	call   *%rbp
ffff800000003b09:	48 b8 a0 89 00 00 00 	movabs $0xffff8000000089a0,%rax
ffff800000003b10:	80 ff ff 
ffff800000003b13:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
ffff800000003b19:	48 83 c4 58          	add    $0x58,%rsp
ffff800000003b1d:	5b                   	pop    %rbx
ffff800000003b1e:	5d                   	pop    %rbp
ffff800000003b1f:	41 5c                	pop    %r12
ffff800000003b21:	41 5d                	pop    %r13
ffff800000003b23:	41 5e                	pop    %r14
ffff800000003b25:	41 5f                	pop    %r15
ffff800000003b27:	c3                   	ret    
ffff800000003b28:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000003b2f:	00 
ffff800000003b30:	48 be 11 63 00 00 00 	movabs $0xffff800000006311,%rsi
ffff800000003b37:	80 ff ff 
ffff800000003b3a:	48 89 ef             	mov    %rbp,%rdi
ffff800000003b3d:	ff d3                	call   *%rbx
ffff800000003b3f:	85 c0                	test   %eax,%eax
ffff800000003b41:	74 2d                	je     ffff800000003b70 <execute_command+0x120>
ffff800000003b43:	48 be 17 63 00 00 00 	movabs $0xffff800000006317,%rsi
ffff800000003b4a:	80 ff ff 
ffff800000003b4d:	48 89 ef             	mov    %rbp,%rdi
ffff800000003b50:	ff d3                	call   *%rbx
ffff800000003b52:	85 c0                	test   %eax,%eax
ffff800000003b54:	75 2a                	jne    ffff800000003b80 <execute_command+0x130>
ffff800000003b56:	48 bf 18 5e 00 00 00 	movabs $0xffff800000005e18,%rdi
ffff800000003b5d:	80 ff ff 
ffff800000003b60:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff800000003b67:	80 ff ff 
ffff800000003b6a:	ff d0                	call   *%rax
ffff800000003b6c:	eb 9b                	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003b6e:	66 90                	xchg   %ax,%ax
ffff800000003b70:	48 b8 50 34 00 00 00 	movabs $0xffff800000003450,%rax
ffff800000003b77:	80 ff ff 
ffff800000003b7a:	ff d0                	call   *%rax
ffff800000003b7c:	eb 8b                	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003b7e:	66 90                	xchg   %ax,%ax
ffff800000003b80:	ba 05 00 00 00       	mov    $0x5,%edx
ffff800000003b85:	48 89 ef             	mov    %rbp,%rdi
ffff800000003b88:	48 be 1d 63 00 00 00 	movabs $0xffff80000000631d,%rsi
ffff800000003b8f:	80 ff ff 
ffff800000003b92:	48 b8 a0 47 00 00 00 	movabs $0xffff8000000047a0,%rax
ffff800000003b99:	80 ff ff 
ffff800000003b9c:	ff d0                	call   *%rax
ffff800000003b9e:	85 c0                	test   %eax,%eax
ffff800000003ba0:	74 76                	je     ffff800000003c18 <execute_command+0x1c8>
ffff800000003ba2:	48 be 23 63 00 00 00 	movabs $0xffff800000006323,%rsi
ffff800000003ba9:	80 ff ff 
ffff800000003bac:	48 89 ef             	mov    %rbp,%rdi
ffff800000003baf:	ff d3                	call   *%rbx
ffff800000003bb1:	85 c0                	test   %eax,%eax
ffff800000003bb3:	0f 85 87 00 00 00    	jne    ffff800000003c40 <execute_command+0x1f0>
ffff800000003bb9:	48 b8 f8 8a 00 00 00 	movabs $0xffff800000008af8,%rax
ffff800000003bc0:	80 ff ff 
ffff800000003bc3:	48 8b 18             	mov    (%rax),%rbx
ffff800000003bc6:	48 bf 2a 63 00 00 00 	movabs $0xffff80000000632a,%rdi
ffff800000003bcd:	80 ff ff 
ffff800000003bd0:	48 bd 20 35 00 00 00 	movabs $0xffff800000003520,%rbp
ffff800000003bd7:	80 ff ff 
ffff800000003bda:	ff d5                	call   *%rbp
ffff800000003bdc:	48 ba c3 f5 28 5c 8f 	movabs $0x28f5c28f5c28f5c3,%rdx
ffff800000003be3:	c2 f5 28 
ffff800000003be6:	48 c1 eb 02          	shr    $0x2,%rbx
ffff800000003bea:	48 89 d8             	mov    %rbx,%rax
ffff800000003bed:	48 f7 e2             	mul    %rdx
ffff800000003bf0:	48 b8 50 36 00 00 00 	movabs $0xffff800000003650,%rax
ffff800000003bf7:	80 ff ff 
ffff800000003bfa:	48 c1 ea 02          	shr    $0x2,%rdx
ffff800000003bfe:	48 89 d7             	mov    %rdx,%rdi
ffff800000003c01:	ff d0                	call   *%rax
ffff800000003c03:	48 bf 3a 63 00 00 00 	movabs $0xffff80000000633a,%rdi
ffff800000003c0a:	80 ff ff 
ffff800000003c0d:	ff d5                	call   *%rbp
ffff800000003c0f:	e9 f5 fe ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003c14:	0f 1f 40 00          	nopl   0x0(%rax)
ffff800000003c18:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000003c1f:	80 ff ff 
ffff800000003c22:	48 8d 7d 05          	lea    0x5(%rbp),%rdi
ffff800000003c26:	ff d3                	call   *%rbx
ffff800000003c28:	48 bf 52 64 00 00 00 	movabs $0xffff800000006452,%rdi
ffff800000003c2f:	80 ff ff 
ffff800000003c32:	ff d3                	call   *%rbx
ffff800000003c34:	e9 d0 fe ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003c39:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000003c40:	48 be 45 63 00 00 00 	movabs $0xffff800000006345,%rsi
ffff800000003c47:	80 ff ff 
ffff800000003c4a:	48 89 ef             	mov    %rbp,%rdi
ffff800000003c4d:	ff d3                	call   *%rbx
ffff800000003c4f:	85 c0                	test   %eax,%eax
ffff800000003c51:	75 4b                	jne    ffff800000003c9e <execute_command+0x24e>
ffff800000003c53:	0f a2                	cpuid  
ffff800000003c55:	48 bf 4d 63 00 00 00 	movabs $0xffff80000000634d,%rdi
ffff800000003c5c:	80 ff ff 
ffff800000003c5f:	89 5c 24 3c          	mov    %ebx,0x3c(%rsp)
ffff800000003c63:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000003c6a:	80 ff ff 
ffff800000003c6d:	89 54 24 40          	mov    %edx,0x40(%rsp)
ffff800000003c71:	89 4c 24 44          	mov    %ecx,0x44(%rsp)
ffff800000003c75:	c6 44 24 48 00       	movb   $0x0,0x48(%rsp)
ffff800000003c7a:	ff d3                	call   *%rbx
ffff800000003c7c:	48 8d 7c 24 3c       	lea    0x3c(%rsp),%rdi
ffff800000003c81:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000003c88:	80 ff ff 
ffff800000003c8b:	ff d0                	call   *%rax
ffff800000003c8d:	48 bf 52 64 00 00 00 	movabs $0xffff800000006452,%rdi
ffff800000003c94:	80 ff ff 
ffff800000003c97:	ff d3                	call   *%rbx
ffff800000003c99:	e9 6b fe ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003c9e:	48 be 5a 63 00 00 00 	movabs $0xffff80000000635a,%rsi
ffff800000003ca5:	80 ff ff 
ffff800000003ca8:	48 89 ef             	mov    %rbp,%rdi
ffff800000003cab:	ff d3                	call   *%rbx
ffff800000003cad:	85 c0                	test   %eax,%eax
ffff800000003caf:	0f 85 1e 01 00 00    	jne    ffff800000003dd3 <execute_command+0x383>
ffff800000003cb5:	48 b8 00 05 00 00 00 	movabs $0xffff800000000500,%rax
ffff800000003cbc:	80 ff ff 
ffff800000003cbf:	8b 18                	mov    (%rax),%ebx
ffff800000003cc1:	48 bf 62 63 00 00 00 	movabs $0xffff800000006362,%rdi
ffff800000003cc8:	80 ff ff 
ffff800000003ccb:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000003cd2:	80 ff ff 
ffff800000003cd5:	ff d0                	call   *%rax
ffff800000003cd7:	85 db                	test   %ebx,%ebx
ffff800000003cd9:	0f 84 a7 03 00 00    	je     ffff800000004086 <execute_command+0x636>
ffff800000003cdf:	48 c7 44 24 18 00 00 	movq   $0x0,0x18(%rsp)
ffff800000003ce6:	00 00 
ffff800000003ce8:	8d 43 ff             	lea    -0x1(%rbx),%eax
ffff800000003ceb:	48 bd 20 35 00 00 00 	movabs $0xffff800000003520,%rbp
ffff800000003cf2:	80 ff ff 
ffff800000003cf5:	48 bb 04 05 00 00 00 	movabs $0xffff800000000504,%rbx
ffff800000003cfc:	80 ff ff 
ffff800000003cff:	49 bf 52 64 00 00 00 	movabs $0xffff800000006452,%r15
ffff800000003d06:	80 ff ff 
ffff800000003d09:	48 8d 14 80          	lea    (%rax,%rax,4),%rdx
ffff800000003d0d:	48 b8 18 05 00 00 00 	movabs $0xffff800000000518,%rax
ffff800000003d14:	80 ff ff 
ffff800000003d17:	49 be 7f 63 00 00 00 	movabs $0xffff80000000637f,%r14
ffff800000003d1e:	80 ff ff 
ffff800000003d21:	49 bc 80 35 00 00 00 	movabs $0xffff800000003580,%r12
ffff800000003d28:	80 ff ff 
ffff800000003d2b:	48 8d 04 90          	lea    (%rax,%rdx,4),%rax
ffff800000003d2f:	49 bd 88 63 00 00 00 	movabs $0xffff800000006388,%r13
ffff800000003d36:	80 ff ff 
ffff800000003d39:	48 89 44 24 10       	mov    %rax,0x10(%rsp)
ffff800000003d3e:	48 b8 50 36 00 00 00 	movabs $0xffff800000003650,%rax
ffff800000003d45:	80 ff ff 
ffff800000003d48:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
ffff800000003d4d:	0f 1f 00             	nopl   (%rax)
ffff800000003d50:	4c 89 f7             	mov    %r14,%rdi
ffff800000003d53:	ff d5                	call   *%rbp
ffff800000003d55:	48 8b 3b             	mov    (%rbx),%rdi
ffff800000003d58:	41 ff d4             	call   *%r12
ffff800000003d5b:	4c 89 ef             	mov    %r13,%rdi
ffff800000003d5e:	ff d5                	call   *%rbp
ffff800000003d60:	48 8b 7b 08          	mov    0x8(%rbx),%rdi
ffff800000003d64:	41 ff d4             	call   *%r12
ffff800000003d67:	48 bf 90 63 00 00 00 	movabs $0xffff800000006390,%rdi
ffff800000003d6e:	80 ff ff 
ffff800000003d71:	ff d5                	call   *%rbp
ffff800000003d73:	8b 7b 10             	mov    0x10(%rbx),%edi
ffff800000003d76:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
ffff800000003d7b:	ff d0                	call   *%rax
ffff800000003d7d:	4c 89 ff             	mov    %r15,%rdi
ffff800000003d80:	ff d5                	call   *%rbp
ffff800000003d82:	83 7b 10 01          	cmpl   $0x1,0x10(%rbx)
ffff800000003d86:	75 09                	jne    ffff800000003d91 <execute_command+0x341>
ffff800000003d88:	48 8b 4b 08          	mov    0x8(%rbx),%rcx
ffff800000003d8c:	48 01 4c 24 18       	add    %rcx,0x18(%rsp)
ffff800000003d91:	48 83 c3 14          	add    $0x14,%rbx
ffff800000003d95:	48 3b 5c 24 10       	cmp    0x10(%rsp),%rbx
ffff800000003d9a:	75 b4                	jne    ffff800000003d50 <execute_command+0x300>
ffff800000003d9c:	48 bf 50 5e 00 00 00 	movabs $0xffff800000005e50,%rdi
ffff800000003da3:	80 ff ff 
ffff800000003da6:	48 bb 40 37 00 00 00 	movabs $0xffff800000003740,%rbx
ffff800000003dad:	80 ff ff 
ffff800000003db0:	ff d3                	call   *%rbx
ffff800000003db2:	48 8b 7c 24 18       	mov    0x18(%rsp),%rdi
ffff800000003db7:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
ffff800000003dbc:	48 c1 ef 14          	shr    $0x14,%rdi
ffff800000003dc0:	ff d0                	call   *%rax
ffff800000003dc2:	48 bf 99 63 00 00 00 	movabs $0xffff800000006399,%rdi
ffff800000003dc9:	80 ff ff 
ffff800000003dcc:	ff d3                	call   *%rbx
ffff800000003dce:	e9 36 fd ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003dd3:	48 be 9e 63 00 00 00 	movabs $0xffff80000000639e,%rsi
ffff800000003dda:	80 ff ff 
ffff800000003ddd:	48 89 ef             	mov    %rbp,%rdi
ffff800000003de0:	ff d3                	call   *%rbx
ffff800000003de2:	85 c0                	test   %eax,%eax
ffff800000003de4:	0f 85 c1 00 00 00    	jne    ffff800000003eab <execute_command+0x45b>
ffff800000003dea:	48 bf 70 5e 00 00 00 	movabs $0xffff800000005e70,%rdi
ffff800000003df1:	80 ff ff 
ffff800000003df4:	48 bd 20 35 00 00 00 	movabs $0xffff800000003520,%rbp
ffff800000003dfb:	80 ff ff 
ffff800000003dfe:	ff d5                	call   *%rbp
ffff800000003e00:	31 c0                	xor    %eax,%eax
ffff800000003e02:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff800000003e09:	80 ff ff 
ffff800000003e0c:	ff d2                	call   *%rdx
ffff800000003e0e:	49 89 c4             	mov    %rax,%r12
ffff800000003e11:	48 85 c0             	test   %rax,%rax
ffff800000003e14:	0f 84 bb 01 00 00    	je     ffff800000003fd5 <execute_command+0x585>
ffff800000003e1a:	49 bd 52 64 00 00 00 	movabs $0xffff800000006452,%r13
ffff800000003e21:	80 ff ff 
ffff800000003e24:	48 bb 00 00 00 00 00 	movabs $0xffff800000000000,%rbx
ffff800000003e2b:	80 ff ff 
ffff800000003e2e:	49 be 80 35 00 00 00 	movabs $0xffff800000003580,%r14
ffff800000003e35:	80 ff ff 
ffff800000003e38:	48 bf a8 5e 00 00 00 	movabs $0xffff800000005ea8,%rdi
ffff800000003e3f:	80 ff ff 
ffff800000003e42:	ff d5                	call   *%rbp
ffff800000003e44:	4c 89 e7             	mov    %r12,%rdi
ffff800000003e47:	41 ff d6             	call   *%r14
ffff800000003e4a:	4c 89 ef             	mov    %r13,%rdi
ffff800000003e4d:	ff d5                	call   *%rbp
ffff800000003e4f:	48 bf a7 63 00 00 00 	movabs $0xffff8000000063a7,%rdi
ffff800000003e56:	80 ff ff 
ffff800000003e59:	ff d5                	call   *%rbp
ffff800000003e5b:	4a 8d 3c 23          	lea    (%rbx,%r12,1),%rdi
ffff800000003e5f:	41 ff d6             	call   *%r14
ffff800000003e62:	4c 89 ef             	mov    %r13,%rdi
ffff800000003e65:	ff d5                	call   *%rbp
ffff800000003e67:	48 b8 be ba fe ca ef 	movabs $0xdeadbeefcafebabe,%rax
ffff800000003e6e:	be ad de 
ffff800000003e71:	48 bf c4 63 00 00 00 	movabs $0xffff8000000063c4,%rdi
ffff800000003e78:	80 ff ff 
ffff800000003e7b:	4a 89 04 23          	mov    %rax,(%rbx,%r12,1)
ffff800000003e7f:	48 bb 40 37 00 00 00 	movabs $0xffff800000003740,%rbx
ffff800000003e86:	80 ff ff 
ffff800000003e89:	ff d3                	call   *%rbx
ffff800000003e8b:	4c 89 e7             	mov    %r12,%rdi
ffff800000003e8e:	48 b8 70 2e 00 00 00 	movabs $0xffff800000002e70,%rax
ffff800000003e95:	80 ff ff 
ffff800000003e98:	ff d0                	call   *%rax
ffff800000003e9a:	48 bf c8 5e 00 00 00 	movabs $0xffff800000005ec8,%rdi
ffff800000003ea1:	80 ff ff 
ffff800000003ea4:	ff d3                	call   *%rbx
ffff800000003ea6:	e9 5e fc ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003eab:	48 be fb 63 00 00 00 	movabs $0xffff8000000063fb,%rsi
ffff800000003eb2:	80 ff ff 
ffff800000003eb5:	48 89 ef             	mov    %rbp,%rdi
ffff800000003eb8:	ff d3                	call   *%rbx
ffff800000003eba:	85 c0                	test   %eax,%eax
ffff800000003ebc:	0f 85 d9 00 00 00    	jne    ffff800000003f9b <execute_command+0x54b>
ffff800000003ec2:	49 bc 70 29 00 00 00 	movabs $0xffff800000002970,%r12
ffff800000003ec9:	80 ff ff 
ffff800000003ecc:	48 bf e8 5e 00 00 00 	movabs $0xffff800000005ee8,%rdi
ffff800000003ed3:	80 ff ff 
ffff800000003ed6:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000003edd:	80 ff ff 
ffff800000003ee0:	ff d3                	call   *%rbx
ffff800000003ee2:	bf 64 00 00 00       	mov    $0x64,%edi
ffff800000003ee7:	41 ff d4             	call   *%r12
ffff800000003eea:	bf 00 10 00 00       	mov    $0x1000,%edi
ffff800000003eef:	48 89 c5             	mov    %rax,%rbp
ffff800000003ef2:	41 ff d4             	call   *%r12
ffff800000003ef5:	49 89 c4             	mov    %rax,%r12
ffff800000003ef8:	48 85 ed             	test   %rbp,%rbp
ffff800000003efb:	0f 84 ef 00 00 00    	je     ffff800000003ff0 <execute_command+0x5a0>
ffff800000003f01:	48 85 c0             	test   %rax,%rax
ffff800000003f04:	0f 84 e6 00 00 00    	je     ffff800000003ff0 <execute_command+0x5a0>
ffff800000003f0a:	49 be 52 64 00 00 00 	movabs $0xffff800000006452,%r14
ffff800000003f11:	80 ff ff 
ffff800000003f14:	48 89 ef             	mov    %rbp,%rdi
ffff800000003f17:	48 be 18 5f 00 00 00 	movabs $0xffff800000005f18,%rsi
ffff800000003f1e:	80 ff ff 
ffff800000003f21:	49 bf 80 35 00 00 00 	movabs $0xffff800000003580,%r15
ffff800000003f28:	80 ff ff 
ffff800000003f2b:	49 bd 40 37 00 00 00 	movabs $0xffff800000003740,%r13
ffff800000003f32:	80 ff ff 
ffff800000003f35:	48 b8 40 48 00 00 00 	movabs $0xffff800000004840,%rax
ffff800000003f3c:	80 ff ff 
ffff800000003f3f:	ff d0                	call   *%rax
ffff800000003f41:	48 89 ef             	mov    %rbp,%rdi
ffff800000003f44:	41 ff d5             	call   *%r13
ffff800000003f47:	4c 89 f7             	mov    %r14,%rdi
ffff800000003f4a:	ff d3                	call   *%rbx
ffff800000003f4c:	48 bf 06 64 00 00 00 	movabs $0xffff800000006406,%rdi
ffff800000003f53:	80 ff ff 
ffff800000003f56:	ff d3                	call   *%rbx
ffff800000003f58:	48 89 ef             	mov    %rbp,%rdi
ffff800000003f5b:	41 ff d7             	call   *%r15
ffff800000003f5e:	48 bf 1b 64 00 00 00 	movabs $0xffff80000000641b,%rdi
ffff800000003f65:	80 ff ff 
ffff800000003f68:	ff d3                	call   *%rbx
ffff800000003f6a:	4c 89 e7             	mov    %r12,%rdi
ffff800000003f6d:	41 ff d7             	call   *%r15
ffff800000003f70:	4c 89 f7             	mov    %r14,%rdi
ffff800000003f73:	ff d3                	call   *%rbx
ffff800000003f75:	48 89 ef             	mov    %rbp,%rdi
ffff800000003f78:	48 bb 90 2a 00 00 00 	movabs $0xffff800000002a90,%rbx
ffff800000003f7f:	80 ff ff 
ffff800000003f82:	ff d3                	call   *%rbx
ffff800000003f84:	4c 89 e7             	mov    %r12,%rdi
ffff800000003f87:	ff d3                	call   *%rbx
ffff800000003f89:	48 bf 23 64 00 00 00 	movabs $0xffff800000006423,%rdi
ffff800000003f90:	80 ff ff 
ffff800000003f93:	41 ff d5             	call   *%r13
ffff800000003f96:	e9 6e fb ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003f9b:	48 be 54 64 00 00 00 	movabs $0xffff800000006454,%rsi
ffff800000003fa2:	80 ff ff 
ffff800000003fa5:	48 89 ef             	mov    %rbp,%rdi
ffff800000003fa8:	ff d3                	call   *%rbx
ffff800000003faa:	85 c0                	test   %eax,%eax
ffff800000003fac:	75 5d                	jne    ffff80000000400b <execute_command+0x5bb>
ffff800000003fae:	48 bf 38 5f 00 00 00 	movabs $0xffff800000005f38,%rdi
ffff800000003fb5:	80 ff ff 
ffff800000003fb8:	48 b8 20 38 00 00 00 	movabs $0xffff800000003820,%rax
ffff800000003fbf:	80 ff ff 
ffff800000003fc2:	ff d0                	call   *%rax
ffff800000003fc4:	48 b8 90 54 00 00 00 	movabs $0xffff800000005490,%rax
ffff800000003fcb:	80 ff ff 
ffff800000003fce:	ff d0                	call   *%rax
ffff800000003fd0:	e9 34 fb ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003fd5:	48 bf e2 63 00 00 00 	movabs $0xffff8000000063e2,%rdi
ffff800000003fdc:	80 ff ff 
ffff800000003fdf:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000003fe6:	80 ff ff 
ffff800000003fe9:	ff d0                	call   *%rax
ffff800000003feb:	e9 19 fb ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000003ff0:	48 bf 3e 64 00 00 00 	movabs $0xffff80000000643e,%rdi
ffff800000003ff7:	80 ff ff 
ffff800000003ffa:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000004001:	80 ff ff 
ffff800000004004:	ff d0                	call   *%rax
ffff800000004006:	e9 fe fa ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff80000000400b:	48 be 5a 64 00 00 00 	movabs $0xffff80000000645a,%rsi
ffff800000004012:	80 ff ff 
ffff800000004015:	48 89 ef             	mov    %rbp,%rdi
ffff800000004018:	ff d3                	call   *%rbx
ffff80000000401a:	85 c0                	test   %eax,%eax
ffff80000000401c:	0f 85 81 00 00 00    	jne    ffff8000000040a3 <execute_command+0x653>
ffff800000004022:	48 bf 58 5f 00 00 00 	movabs $0xffff800000005f58,%rdi
ffff800000004029:	80 ff ff 
ffff80000000402c:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000004033:	80 ff ff 
ffff800000004036:	ff d0                	call   *%rax
ffff800000004038:	be 05 00 00 00       	mov    $0x5,%esi
ffff80000000403d:	48 bf e0 39 00 00 00 	movabs $0xffff8000000039e0,%rdi
ffff800000004044:	80 ff ff 
ffff800000004047:	48 b8 10 53 00 00 00 	movabs $0xffff800000005310,%rax
ffff80000000404e:	80 ff ff 
ffff800000004051:	ff d0                	call   *%rax
ffff800000004053:	48 89 c7             	mov    %rax,%rdi
ffff800000004056:	48 85 c0             	test   %rax,%rax
ffff800000004059:	0f 84 12 01 00 00    	je     ffff800000004171 <execute_command+0x721>
ffff80000000405f:	48 b8 b0 53 00 00 00 	movabs $0xffff8000000053b0,%rax
ffff800000004066:	80 ff ff 
ffff800000004069:	ff d0                	call   *%rax
ffff80000000406b:	48 bf 80 5f 00 00 00 	movabs $0xffff800000005f80,%rdi
ffff800000004072:	80 ff ff 
ffff800000004075:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff80000000407c:	80 ff ff 
ffff80000000407f:	ff d0                	call   *%rax
ffff800000004081:	e9 83 fa ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000004086:	48 b8 50 36 00 00 00 	movabs $0xffff800000003650,%rax
ffff80000000408d:	80 ff ff 
ffff800000004090:	48 c7 44 24 18 00 00 	movq   $0x0,0x18(%rsp)
ffff800000004097:	00 00 
ffff800000004099:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
ffff80000000409e:	e9 f9 fc ff ff       	jmp    ffff800000003d9c <execute_command+0x34c>
ffff8000000040a3:	48 be 65 64 00 00 00 	movabs $0xffff800000006465,%rsi
ffff8000000040aa:	80 ff ff 
ffff8000000040ad:	48 89 ef             	mov    %rbp,%rdi
ffff8000000040b0:	ff d3                	call   *%rbx
ffff8000000040b2:	85 c0                	test   %eax,%eax
ffff8000000040b4:	0f 85 d2 00 00 00    	jne    ffff80000000418c <execute_command+0x73c>
ffff8000000040ba:	48 bd 52 64 00 00 00 	movabs $0xffff800000006452,%rbp
ffff8000000040c1:	80 ff ff 
ffff8000000040c4:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff8000000040cb:	80 ff ff 
ffff8000000040ce:	48 bf e0 5f 00 00 00 	movabs $0xffff800000005fe0,%rdi
ffff8000000040d5:	80 ff ff 
ffff8000000040d8:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff8000000040df:	80 ff ff 
ffff8000000040e2:	ff d0                	call   *%rax
ffff8000000040e4:	48 bf 6f 64 00 00 00 	movabs $0xffff80000000646f,%rdi
ffff8000000040eb:	80 ff ff 
ffff8000000040ee:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff8000000040f5:	80 ff ff 
ffff8000000040f8:	ff d0                	call   *%rax
ffff8000000040fa:	48 bf 82 64 00 00 00 	movabs $0xffff800000006482,%rdi
ffff800000004101:	80 ff ff 
ffff800000004104:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff80000000410b:	80 ff ff 
ffff80000000410e:	ff d0                	call   *%rax
ffff800000004110:	48 b8 20 38 00 00 00 	movabs $0xffff800000003820,%rax
ffff800000004117:	80 ff ff 
ffff80000000411a:	48 bf 93 64 00 00 00 	movabs $0xffff800000006493,%rdi
ffff800000004121:	80 ff ff 
ffff800000004124:	ff d0                	call   *%rax
ffff800000004126:	48 bf a6 64 00 00 00 	movabs $0xffff8000000064a6,%rdi
ffff80000000412d:	80 ff ff 
ffff800000004130:	ff d3                	call   *%rbx
ffff800000004132:	48 c7 c7 c0 1d fe ff 	mov    $0xfffffffffffe1dc0,%rdi
ffff800000004139:	48 b8 50 36 00 00 00 	movabs $0xffff800000003650,%rax
ffff800000004140:	80 ff ff 
ffff800000004143:	ff d0                	call   *%rax
ffff800000004145:	48 89 ef             	mov    %rbp,%rdi
ffff800000004148:	ff d3                	call   *%rbx
ffff80000000414a:	48 bf b7 64 00 00 00 	movabs $0xffff8000000064b7,%rdi
ffff800000004151:	80 ff ff 
ffff800000004154:	ff d3                	call   *%rbx
ffff800000004156:	bf 4d 3c 2b 1a       	mov    $0x1a2b3c4d,%edi
ffff80000000415b:	48 b8 80 35 00 00 00 	movabs $0xffff800000003580,%rax
ffff800000004162:	80 ff ff 
ffff800000004165:	ff d0                	call   *%rax
ffff800000004167:	48 89 ef             	mov    %rbp,%rdi
ffff80000000416a:	ff d3                	call   *%rbx
ffff80000000416c:	e9 98 f9 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff800000004171:	48 bf b0 5f 00 00 00 	movabs $0xffff800000005fb0,%rdi
ffff800000004178:	80 ff ff 
ffff80000000417b:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000004182:	80 ff ff 
ffff800000004185:	ff d0                	call   *%rax
ffff800000004187:	e9 7d f9 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff80000000418c:	48 be c8 64 00 00 00 	movabs $0xffff8000000064c8,%rsi
ffff800000004193:	80 ff ff 
ffff800000004196:	48 89 ef             	mov    %rbp,%rdi
ffff800000004199:	ff d3                	call   *%rbx
ffff80000000419b:	85 c0                	test   %eax,%eax
ffff80000000419d:	0f 85 c8 00 00 00    	jne    ffff80000000426b <execute_command+0x81b>
ffff8000000041a3:	ba 0a 00 00 00       	mov    $0xa,%edx
ffff8000000041a8:	be 41 00 00 00       	mov    $0x41,%esi
ffff8000000041ad:	48 8d 7c 24 28       	lea    0x28(%rsp),%rdi
ffff8000000041b2:	48 bd 52 64 00 00 00 	movabs $0xffff800000006452,%rbp
ffff8000000041b9:	80 ff ff 
ffff8000000041bc:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff8000000041c3:	80 ff ff 
ffff8000000041c6:	49 bc b0 37 00 00 00 	movabs $0xffff8000000037b0,%r12
ffff8000000041cd:	80 ff ff 
ffff8000000041d0:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff8000000041d7:	80 ff ff 
ffff8000000041da:	ff d0                	call   *%rax
ffff8000000041dc:	c6 44 24 32 00       	movb   $0x0,0x32(%rsp)
ffff8000000041e1:	48 bf d0 64 00 00 00 	movabs $0xffff8000000064d0,%rdi
ffff8000000041e8:	80 ff ff 
ffff8000000041eb:	ff d3                	call   *%rbx
ffff8000000041ed:	48 8d 7c 24 28       	lea    0x28(%rsp),%rdi
ffff8000000041f2:	41 ff d4             	call   *%r12
ffff8000000041f5:	48 89 ef             	mov    %rbp,%rdi
ffff8000000041f8:	ff d3                	call   *%rbx
ffff8000000041fa:	48 8d 7c 24 3c       	lea    0x3c(%rsp),%rdi
ffff8000000041ff:	48 be d9 64 00 00 00 	movabs $0xffff8000000064d9,%rsi
ffff800000004206:	80 ff ff 
ffff800000004209:	48 b8 40 48 00 00 00 	movabs $0xffff800000004840,%rax
ffff800000004210:	80 ff ff 
ffff800000004213:	ff d0                	call   *%rax
ffff800000004215:	48 bf e3 64 00 00 00 	movabs $0xffff8000000064e3,%rdi
ffff80000000421c:	80 ff ff 
ffff80000000421f:	ff d3                	call   *%rbx
ffff800000004221:	48 8d 7c 24 3c       	lea    0x3c(%rsp),%rdi
ffff800000004226:	41 ff d4             	call   *%r12
ffff800000004229:	48 89 ef             	mov    %rbp,%rdi
ffff80000000422c:	ff d3                	call   *%rbx
ffff80000000422e:	48 bf ec 64 00 00 00 	movabs $0xffff8000000064ec,%rdi
ffff800000004235:	80 ff ff 
ffff800000004238:	ff d3                	call   *%rbx
ffff80000000423a:	48 8d 7c 24 3c       	lea    0x3c(%rsp),%rdi
ffff80000000423f:	48 b8 40 47 00 00 00 	movabs $0xffff800000004740,%rax
ffff800000004246:	80 ff ff 
ffff800000004249:	ff d0                	call   *%rax
ffff80000000424b:	48 89 c7             	mov    %rax,%rdi
ffff80000000424e:	48 b8 50 36 00 00 00 	movabs $0xffff800000003650,%rax
ffff800000004255:	80 ff ff 
ffff800000004258:	ff d0                	call   *%rax
ffff80000000425a:	48 bf f5 64 00 00 00 	movabs $0xffff8000000064f5,%rdi
ffff800000004261:	80 ff ff 
ffff800000004264:	ff d3                	call   *%rbx
ffff800000004266:	e9 9e f8 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff80000000426b:	48 be 04 65 00 00 00 	movabs $0xffff800000006504,%rsi
ffff800000004272:	80 ff ff 
ffff800000004275:	48 89 ef             	mov    %rbp,%rdi
ffff800000004278:	ff d3                	call   *%rbx
ffff80000000427a:	85 c0                	test   %eax,%eax
ffff80000000427c:	75 18                	jne    ffff800000004296 <execute_command+0x846>
ffff80000000427e:	48 bf 08 60 00 00 00 	movabs $0xffff800000006008,%rdi
ffff800000004285:	80 ff ff 
ffff800000004288:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff80000000428f:	80 ff ff 
ffff800000004292:	ff d0                	call   *%rax
ffff800000004294:	0f 0b                	ud2    
ffff800000004296:	48 be 0a 65 00 00 00 	movabs $0xffff80000000650a,%rsi
ffff80000000429d:	80 ff ff 
ffff8000000042a0:	48 89 ef             	mov    %rbp,%rdi
ffff8000000042a3:	ff d3                	call   *%rbx
ffff8000000042a5:	85 c0                	test   %eax,%eax
ffff8000000042a7:	75 24                	jne    ffff8000000042cd <execute_command+0x87d>
ffff8000000042a9:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff8000000042b0:	80 ff ff 
ffff8000000042b3:	48 bf 38 60 00 00 00 	movabs $0xffff800000006038,%rdi
ffff8000000042ba:	80 ff ff 
ffff8000000042bd:	ff d0                	call   *%rax
ffff8000000042bf:	a1 0d f0 ad ba 00 00 	movabs 0xbaadf00d,%eax
ffff8000000042c6:	00 00 
ffff8000000042c8:	e9 3c f8 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff8000000042cd:	48 be 11 65 00 00 00 	movabs $0xffff800000006511,%rsi
ffff8000000042d4:	80 ff ff 
ffff8000000042d7:	48 89 ef             	mov    %rbp,%rdi
ffff8000000042da:	ff d3                	call   *%rbx
ffff8000000042dc:	85 c0                	test   %eax,%eax
ffff8000000042de:	0f 85 cd 00 00 00    	jne    ffff8000000043b1 <execute_command+0x961>
ffff8000000042e4:	48 bf 68 60 00 00 00 	movabs $0xffff800000006068,%rdi
ffff8000000042eb:	80 ff ff 
ffff8000000042ee:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff8000000042f5:	80 ff ff 
ffff8000000042f8:	ff d0                	call   *%rax
ffff8000000042fa:	be 05 00 00 00       	mov    $0x5,%esi
ffff8000000042ff:	bf 00 00 40 00       	mov    $0x400000,%edi
ffff800000004304:	48 b8 b0 54 00 00 00 	movabs $0xffff8000000054b0,%rax
ffff80000000430b:	80 ff ff 
ffff80000000430e:	ff d0                	call   *%rax
ffff800000004310:	48 89 c5             	mov    %rax,%rbp
ffff800000004313:	48 85 c0             	test   %rax,%rax
ffff800000004316:	0f 84 d8 01 00 00    	je     ffff8000000044f4 <execute_command+0xaa4>
ffff80000000431c:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff800000004323:	80 ff ff 
ffff800000004326:	31 c0                	xor    %eax,%eax
ffff800000004328:	ff d2                	call   *%rdx
ffff80000000432a:	bf ff ff 01 00       	mov    $0x1ffff,%edi
ffff80000000432f:	ba 02 00 00 00       	mov    $0x2,%edx
ffff800000004334:	48 be c1 67 00 00 00 	movabs $0xffff8000000067c1,%rsi
ffff80000000433b:	80 ff ff 
ffff80000000433e:	49 89 c4             	mov    %rax,%r12
ffff800000004341:	48 c1 e7 2f          	shl    $0x2f,%rdi
ffff800000004345:	48 01 c7             	add    %rax,%rdi
ffff800000004348:	48 b8 10 48 00 00 00 	movabs $0xffff800000004810,%rax
ffff80000000434f:	80 ff ff 
ffff800000004352:	ff d0                	call   *%rax
ffff800000004354:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff800000004359:	4c 89 e2             	mov    %r12,%rdx
ffff80000000435c:	be 00 00 40 00       	mov    $0x400000,%esi
ffff800000004361:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff800000004368:	80 ff ff 
ffff80000000436b:	48 8b 7d 38          	mov    0x38(%rbp),%rdi
ffff80000000436f:	ff d0                	call   *%rax
ffff800000004371:	48 89 ef             	mov    %rbp,%rdi
ffff800000004374:	48 b8 b0 53 00 00 00 	movabs $0xffff8000000053b0,%rax
ffff80000000437b:	80 ff ff 
ffff80000000437e:	ff d0                	call   *%rax
ffff800000004380:	48 bf 98 60 00 00 00 	movabs $0xffff800000006098,%rdi
ffff800000004387:	80 ff ff 
ffff80000000438a:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff800000004391:	80 ff ff 
ffff800000004394:	ff d0                	call   *%rax
ffff800000004396:	48 bf d8 60 00 00 00 	movabs $0xffff8000000060d8,%rdi
ffff80000000439d:	80 ff ff 
ffff8000000043a0:	48 b8 20 38 00 00 00 	movabs $0xffff800000003820,%rax
ffff8000000043a7:	80 ff ff 
ffff8000000043aa:	ff d0                	call   *%rax
ffff8000000043ac:	e9 58 f7 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff8000000043b1:	48 be 37 65 00 00 00 	movabs $0xffff800000006537,%rsi
ffff8000000043b8:	80 ff ff 
ffff8000000043bb:	48 89 ef             	mov    %rbp,%rdi
ffff8000000043be:	ff d3                	call   *%rbx
ffff8000000043c0:	85 c0                	test   %eax,%eax
ffff8000000043c2:	0f 85 47 01 00 00    	jne    ffff80000000450f <execute_command+0xabf>
ffff8000000043c8:	48 bf 28 61 00 00 00 	movabs $0xffff800000006128,%rdi
ffff8000000043cf:	80 ff ff 
ffff8000000043d2:	48 bb d0 2e 00 00 00 	movabs $0xffff800000002ed0,%rbx
ffff8000000043d9:	80 ff ff 
ffff8000000043dc:	49 bf b0 37 00 00 00 	movabs $0xffff8000000037b0,%r15
ffff8000000043e3:	80 ff ff 
ffff8000000043e6:	41 ff d7             	call   *%r15
ffff8000000043e9:	ff d3                	call   *%rbx
ffff8000000043eb:	49 89 c4             	mov    %rax,%r12
ffff8000000043ee:	ff d3                	call   *%rbx
ffff8000000043f0:	48 bb 50 2e 00 00 00 	movabs $0xffff800000002e50,%rbx
ffff8000000043f7:	80 ff ff 
ffff8000000043fa:	48 89 c5             	mov    %rax,%rbp
ffff8000000043fd:	31 c0                	xor    %eax,%eax
ffff8000000043ff:	ff d3                	call   *%rbx
ffff800000004401:	49 89 c6             	mov    %rax,%r14
ffff800000004404:	31 c0                	xor    %eax,%eax
ffff800000004406:	ff d3                	call   *%rbx
ffff800000004408:	bb ff ff 01 00       	mov    $0x1ffff,%ebx
ffff80000000440d:	48 be 3e 65 00 00 00 	movabs $0xffff80000000653e,%rsi
ffff800000004414:	80 ff ff 
ffff800000004417:	48 ba 40 48 00 00 00 	movabs $0xffff800000004840,%rdx
ffff80000000441e:	80 ff ff 
ffff800000004421:	49 89 c5             	mov    %rax,%r13
ffff800000004424:	48 c1 e3 2f          	shl    $0x2f,%rbx
ffff800000004428:	49 8d 3c 1e          	lea    (%r14,%rbx,1),%rdi
ffff80000000442c:	ff d2                	call   *%rdx
ffff80000000442e:	49 8d 7c 1d 00       	lea    0x0(%r13,%rbx,1),%rdi
ffff800000004433:	48 be 59 65 00 00 00 	movabs $0xffff800000006559,%rsi
ffff80000000443a:	80 ff ff 
ffff80000000443d:	48 bb 40 2f 00 00 00 	movabs $0xffff800000002f40,%rbx
ffff800000004444:	80 ff ff 
ffff800000004447:	48 ba 40 48 00 00 00 	movabs $0xffff800000004840,%rdx
ffff80000000444e:	80 ff ff 
ffff800000004451:	ff d2                	call   *%rdx
ffff800000004453:	4c 89 f2             	mov    %r14,%rdx
ffff800000004456:	4c 89 e7             	mov    %r12,%rdi
ffff800000004459:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff80000000445e:	be 00 00 00 40       	mov    $0x40000000,%esi
ffff800000004463:	ff d3                	call   *%rbx
ffff800000004465:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff80000000446a:	4c 89 ea             	mov    %r13,%rdx
ffff80000000446d:	be 00 00 00 40       	mov    $0x40000000,%esi
ffff800000004472:	48 89 ef             	mov    %rbp,%rdi
ffff800000004475:	ff d3                	call   *%rbx
ffff800000004477:	41 0f 20 de          	mov    %cr3,%r14
ffff80000000447b:	48 bf 60 61 00 00 00 	movabs $0xffff800000006160,%rdi
ffff800000004482:	80 ff ff 
ffff800000004485:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff80000000448c:	80 ff ff 
ffff80000000448f:	ff d3                	call   *%rbx
ffff800000004491:	41 0f 22 dc          	mov    %r12,%cr3
ffff800000004495:	49 bc 52 64 00 00 00 	movabs $0xffff800000006452,%r12
ffff80000000449c:	80 ff ff 
ffff80000000449f:	48 bf 74 65 00 00 00 	movabs $0xffff800000006574,%rdi
ffff8000000044a6:	80 ff ff 
ffff8000000044a9:	49 bd 40 37 00 00 00 	movabs $0xffff800000003740,%r13
ffff8000000044b0:	80 ff ff 
ffff8000000044b3:	ff d3                	call   *%rbx
ffff8000000044b5:	bf 00 00 00 40       	mov    $0x40000000,%edi
ffff8000000044ba:	41 ff d5             	call   *%r13
ffff8000000044bd:	4c 89 e7             	mov    %r12,%rdi
ffff8000000044c0:	ff d3                	call   *%rbx
ffff8000000044c2:	0f 22 dd             	mov    %rbp,%cr3
ffff8000000044c5:	48 bf 8c 65 00 00 00 	movabs $0xffff80000000658c,%rdi
ffff8000000044cc:	80 ff ff 
ffff8000000044cf:	ff d3                	call   *%rbx
ffff8000000044d1:	bf 00 00 00 40       	mov    $0x40000000,%edi
ffff8000000044d6:	41 ff d5             	call   *%r13
ffff8000000044d9:	4c 89 e7             	mov    %r12,%rdi
ffff8000000044dc:	ff d3                	call   *%rbx
ffff8000000044de:	41 0f 22 de          	mov    %r14,%cr3
ffff8000000044e2:	48 bf a8 61 00 00 00 	movabs $0xffff8000000061a8,%rdi
ffff8000000044e9:	80 ff ff 
ffff8000000044ec:	41 ff d7             	call   *%r15
ffff8000000044ef:	e9 15 f6 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff8000000044f4:	48 bf 1d 65 00 00 00 	movabs $0xffff80000000651d,%rdi
ffff8000000044fb:	80 ff ff 
ffff8000000044fe:	48 b8 d0 36 00 00 00 	movabs $0xffff8000000036d0,%rax
ffff800000004505:	80 ff ff 
ffff800000004508:	ff d0                	call   *%rax
ffff80000000450a:	e9 fa f5 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff80000000450f:	48 be a4 65 00 00 00 	movabs $0xffff8000000065a4,%rsi
ffff800000004516:	80 ff ff 
ffff800000004519:	48 89 ef             	mov    %rbp,%rdi
ffff80000000451c:	ff d3                	call   *%rbx
ffff80000000451e:	85 c0                	test   %eax,%eax
ffff800000004520:	0f 85 cd 00 00 00    	jne    ffff8000000045f3 <execute_command+0xba3>
ffff800000004526:	48 bf f0 61 00 00 00 	movabs $0xffff8000000061f0,%rdi
ffff80000000452d:	80 ff ff 
ffff800000004530:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000004537:	80 ff ff 
ffff80000000453a:	ff d0                	call   *%rax
ffff80000000453c:	be 05 00 00 00       	mov    $0x5,%esi
ffff800000004541:	bf 00 00 80 00       	mov    $0x800000,%edi
ffff800000004546:	48 b8 b0 54 00 00 00 	movabs $0xffff8000000054b0,%rax
ffff80000000454d:	80 ff ff 
ffff800000004550:	ff d0                	call   *%rax
ffff800000004552:	48 89 c5             	mov    %rax,%rbp
ffff800000004555:	48 85 c0             	test   %rax,%rax
ffff800000004558:	0f 84 ab f5 ff ff    	je     ffff800000003b09 <execute_command+0xb9>
ffff80000000455e:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff800000004565:	80 ff ff 
ffff800000004568:	31 c0                	xor    %eax,%eax
ffff80000000456a:	ff d2                	call   *%rdx
ffff80000000456c:	bf ff ff 01 00       	mov    $0x1ffff,%edi
ffff800000004571:	ba 03 00 00 00       	mov    $0x3,%edx
ffff800000004576:	48 be be 67 00 00 00 	movabs $0xffff8000000067be,%rsi
ffff80000000457d:	80 ff ff 
ffff800000004580:	49 89 c4             	mov    %rax,%r12
ffff800000004583:	48 c1 e7 2f          	shl    $0x2f,%rdi
ffff800000004587:	48 01 c7             	add    %rax,%rdi
ffff80000000458a:	48 b8 10 48 00 00 00 	movabs $0xffff800000004810,%rax
ffff800000004591:	80 ff ff 
ffff800000004594:	ff d0                	call   *%rax
ffff800000004596:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff80000000459b:	4c 89 e2             	mov    %r12,%rdx
ffff80000000459e:	be 00 00 80 00       	mov    $0x800000,%esi
ffff8000000045a3:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff8000000045aa:	80 ff ff 
ffff8000000045ad:	48 8b 7d 38          	mov    0x38(%rbp),%rdi
ffff8000000045b1:	ff d0                	call   *%rax
ffff8000000045b3:	48 89 ef             	mov    %rbp,%rdi
ffff8000000045b6:	48 b8 b0 53 00 00 00 	movabs $0xffff8000000053b0,%rax
ffff8000000045bd:	80 ff ff 
ffff8000000045c0:	ff d0                	call   *%rax
ffff8000000045c2:	48 bf 40 62 00 00 00 	movabs $0xffff800000006240,%rdi
ffff8000000045c9:	80 ff ff 
ffff8000000045cc:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff8000000045d3:	80 ff ff 
ffff8000000045d6:	ff d0                	call   *%rax
ffff8000000045d8:	48 bf 68 62 00 00 00 	movabs $0xffff800000006268,%rdi
ffff8000000045df:	80 ff ff 
ffff8000000045e2:	48 b8 20 38 00 00 00 	movabs $0xffff800000003820,%rax
ffff8000000045e9:	80 ff ff 
ffff8000000045ec:	ff d0                	call   *%rax
ffff8000000045ee:	e9 16 f5 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff8000000045f3:	48 bb d0 36 00 00 00 	movabs $0xffff8000000036d0,%rbx
ffff8000000045fa:	80 ff ff 
ffff8000000045fd:	48 bf ae 65 00 00 00 	movabs $0xffff8000000065ae,%rdi
ffff800000004604:	80 ff ff 
ffff800000004607:	ff d3                	call   *%rbx
ffff800000004609:	48 89 ef             	mov    %rbp,%rdi
ffff80000000460c:	ff d3                	call   *%rbx
ffff80000000460e:	48 bf c0 62 00 00 00 	movabs $0xffff8000000062c0,%rdi
ffff800000004615:	80 ff ff 
ffff800000004618:	ff d3                	call   *%rbx
ffff80000000461a:	e9 ea f4 ff ff       	jmp    ffff800000003b09 <execute_command+0xb9>
ffff80000000461f:	90                   	nop

ffff800000004620 <shell_take_char>:
ffff800000004620:	55                   	push   %rbp
ffff800000004621:	53                   	push   %rbx
ffff800000004622:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000004626:	40 80 ff 0a          	cmp    $0xa,%dil
ffff80000000462a:	74 54                	je     ffff800000004680 <shell_take_char+0x60>
ffff80000000462c:	48 bb a0 89 00 00 00 	movabs $0xffff8000000089a0,%rbx
ffff800000004633:	80 ff ff 
ffff800000004636:	8b 03                	mov    (%rbx),%eax
ffff800000004638:	40 80 ff 08          	cmp    $0x8,%dil
ffff80000000463c:	74 22                	je     ffff800000004660 <shell_take_char+0x40>
ffff80000000463e:	40 80 ff 1b          	cmp    $0x1b,%dil
ffff800000004642:	0f 84 90 00 00 00    	je     ffff8000000046d8 <shell_take_char+0xb8>
ffff800000004648:	3d fe 00 00 00       	cmp    $0xfe,%eax
ffff80000000464d:	0f 8e cd 00 00 00    	jle    ffff800000004720 <shell_take_char+0x100>
ffff800000004653:	48 83 c4 08          	add    $0x8,%rsp
ffff800000004657:	5b                   	pop    %rbx
ffff800000004658:	5d                   	pop    %rbp
ffff800000004659:	c3                   	ret    
ffff80000000465a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000004660:	85 c0                	test   %eax,%eax
ffff800000004662:	7e ef                	jle    ffff800000004653 <shell_take_char+0x33>
ffff800000004664:	83 e8 01             	sub    $0x1,%eax
ffff800000004667:	bf 08 00 00 00       	mov    $0x8,%edi
ffff80000000466c:	89 03                	mov    %eax,(%rbx)
ffff80000000466e:	48 b8 d0 34 00 00 00 	movabs $0xffff8000000034d0,%rax
ffff800000004675:	80 ff ff 
ffff800000004678:	48 83 c4 08          	add    $0x8,%rsp
ffff80000000467c:	5b                   	pop    %rbx
ffff80000000467d:	5d                   	pop    %rbp
ffff80000000467e:	ff e0                	jmp    *%rax
ffff800000004680:	48 b8 d0 34 00 00 00 	movabs $0xffff8000000034d0,%rax
ffff800000004687:	80 ff ff 
ffff80000000468a:	bf 0a 00 00 00       	mov    $0xa,%edi
ffff80000000468f:	ff d0                	call   *%rax
ffff800000004691:	a1 a0 89 00 00 00 80 	movabs 0xffff8000000089a0,%eax
ffff800000004698:	ff ff 
ffff80000000469a:	48 bf c0 89 00 00 00 	movabs $0xffff8000000089c0,%rdi
ffff8000000046a1:	80 ff ff 
ffff8000000046a4:	48 98                	cltq   
ffff8000000046a6:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
ffff8000000046aa:	48 b8 50 3a 00 00 00 	movabs $0xffff800000003a50,%rax
ffff8000000046b1:	80 ff ff 
ffff8000000046b4:	ff d0                	call   *%rax
ffff8000000046b6:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000046ba:	48 bf e7 62 00 00 00 	movabs $0xffff8000000062e7,%rdi
ffff8000000046c1:	80 ff ff 
ffff8000000046c4:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff8000000046cb:	80 ff ff 
ffff8000000046ce:	5b                   	pop    %rbx
ffff8000000046cf:	5d                   	pop    %rbp
ffff8000000046d0:	ff e0                	jmp    *%rax
ffff8000000046d2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff8000000046d8:	48 bd d0 34 00 00 00 	movabs $0xffff8000000034d0,%rbp
ffff8000000046df:	80 ff ff 
ffff8000000046e2:	85 c0                	test   %eax,%eax
ffff8000000046e4:	7e 1c                	jle    ffff800000004702 <shell_take_char+0xe2>
ffff8000000046e6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000046ed:	00 00 00 
ffff8000000046f0:	bf 08 00 00 00       	mov    $0x8,%edi
ffff8000000046f5:	ff d5                	call   *%rbp
ffff8000000046f7:	8b 03                	mov    (%rbx),%eax
ffff8000000046f9:	83 e8 01             	sub    $0x1,%eax
ffff8000000046fc:	89 03                	mov    %eax,(%rbx)
ffff8000000046fe:	85 c0                	test   %eax,%eax
ffff800000004700:	7f ee                	jg     ffff8000000046f0 <shell_take_char+0xd0>
ffff800000004702:	48 b8 c0 89 00 00 00 	movabs $0xffff8000000089c0,%rax
ffff800000004709:	80 ff ff 
ffff80000000470c:	c6 00 00             	movb   $0x0,(%rax)
ffff80000000470f:	48 83 c4 08          	add    $0x8,%rsp
ffff800000004713:	5b                   	pop    %rbx
ffff800000004714:	5d                   	pop    %rbp
ffff800000004715:	c3                   	ret    
ffff800000004716:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff80000000471d:	00 00 00 
ffff800000004720:	48 b9 c0 89 00 00 00 	movabs $0xffff8000000089c0,%rcx
ffff800000004727:	80 ff ff 
ffff80000000472a:	48 63 d0             	movslq %eax,%rdx
ffff80000000472d:	83 c0 01             	add    $0x1,%eax
ffff800000004730:	40 88 3c 11          	mov    %dil,(%rcx,%rdx,1)
ffff800000004734:	40 0f be ff          	movsbl %dil,%edi
ffff800000004738:	89 03                	mov    %eax,(%rbx)
ffff80000000473a:	e9 2f ff ff ff       	jmp    ffff80000000466e <shell_take_char+0x4e>
ffff80000000473f:	90                   	nop

ffff800000004740 <strlen>:
ffff800000004740:	31 c0                	xor    %eax,%eax
ffff800000004742:	80 3f 00             	cmpb   $0x0,(%rdi)
ffff800000004745:	74 19                	je     ffff800000004760 <strlen+0x20>
ffff800000004747:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff80000000474e:	00 00 
ffff800000004750:	48 83 c0 01          	add    $0x1,%rax
ffff800000004754:	80 3c 07 00          	cmpb   $0x0,(%rdi,%rax,1)
ffff800000004758:	75 f6                	jne    ffff800000004750 <strlen+0x10>
ffff80000000475a:	c3                   	ret    
ffff80000000475b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000004760:	c3                   	ret    
ffff800000004761:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000004768:	00 00 00 00 
ffff80000000476c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000004770 <strcmp>:
ffff800000004770:	eb 12                	jmp    ffff800000004784 <strcmp+0x14>
ffff800000004772:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000004778:	38 06                	cmp    %al,(%rsi)
ffff80000000477a:	75 11                	jne    ffff80000000478d <strcmp+0x1d>
ffff80000000477c:	48 83 c7 01          	add    $0x1,%rdi
ffff800000004780:	48 83 c6 01          	add    $0x1,%rsi
ffff800000004784:	0f b6 07             	movzbl (%rdi),%eax
ffff800000004787:	84 c0                	test   %al,%al
ffff800000004789:	75 ed                	jne    ffff800000004778 <strcmp+0x8>
ffff80000000478b:	31 c0                	xor    %eax,%eax
ffff80000000478d:	0f b6 16             	movzbl (%rsi),%edx
ffff800000004790:	29 d0                	sub    %edx,%eax
ffff800000004792:	c3                   	ret    
ffff800000004793:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff80000000479a:	00 00 00 00 
ffff80000000479e:	66 90                	xchg   %ax,%ax

ffff8000000047a0 <strncmp>:
ffff8000000047a0:	85 d2                	test   %edx,%edx
ffff8000000047a2:	7f 1d                	jg     ffff8000000047c1 <strncmp+0x21>
ffff8000000047a4:	eb 35                	jmp    ffff8000000047db <strncmp+0x3b>
ffff8000000047a6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff8000000047ad:	00 00 00 
ffff8000000047b0:	3a 06                	cmp    (%rsi),%al
ffff8000000047b2:	75 14                	jne    ffff8000000047c8 <strncmp+0x28>
ffff8000000047b4:	48 83 c7 01          	add    $0x1,%rdi
ffff8000000047b8:	48 83 c6 01          	add    $0x1,%rsi
ffff8000000047bc:	83 ea 01             	sub    $0x1,%edx
ffff8000000047bf:	74 17                	je     ffff8000000047d8 <strncmp+0x38>
ffff8000000047c1:	0f b6 07             	movzbl (%rdi),%eax
ffff8000000047c4:	84 c0                	test   %al,%al
ffff8000000047c6:	75 e8                	jne    ffff8000000047b0 <strncmp+0x10>
ffff8000000047c8:	0f b6 07             	movzbl (%rdi),%eax
ffff8000000047cb:	0f b6 16             	movzbl (%rsi),%edx
ffff8000000047ce:	29 d0                	sub    %edx,%eax
ffff8000000047d0:	c3                   	ret    
ffff8000000047d1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff8000000047d8:	31 c0                	xor    %eax,%eax
ffff8000000047da:	c3                   	ret    
ffff8000000047db:	b8 00 00 00 00       	mov    $0x0,%eax
ffff8000000047e0:	75 e6                	jne    ffff8000000047c8 <strncmp+0x28>
ffff8000000047e2:	c3                   	ret    
ffff8000000047e3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000047ea:	00 00 00 00 
ffff8000000047ee:	66 90                	xchg   %ax,%ax

ffff8000000047f0 <memset>:
ffff8000000047f0:	48 89 f8             	mov    %rdi,%rax
ffff8000000047f3:	4c 8d 04 17          	lea    (%rdi,%rdx,1),%r8
ffff8000000047f7:	48 89 f9             	mov    %rdi,%rcx
ffff8000000047fa:	48 85 d2             	test   %rdx,%rdx
ffff8000000047fd:	74 0e                	je     ffff80000000480d <memset+0x1d>
ffff8000000047ff:	90                   	nop
ffff800000004800:	48 83 c1 01          	add    $0x1,%rcx
ffff800000004804:	40 88 71 ff          	mov    %sil,-0x1(%rcx)
ffff800000004808:	4c 39 c1             	cmp    %r8,%rcx
ffff80000000480b:	75 f3                	jne    ffff800000004800 <memset+0x10>
ffff80000000480d:	c3                   	ret    
ffff80000000480e:	66 90                	xchg   %ax,%ax

ffff800000004810 <memcpy>:
ffff800000004810:	48 89 f8             	mov    %rdi,%rax
ffff800000004813:	48 85 d2             	test   %rdx,%rdx
ffff800000004816:	74 1a                	je     ffff800000004832 <memcpy+0x22>
ffff800000004818:	31 c9                	xor    %ecx,%ecx
ffff80000000481a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000004820:	44 0f b6 04 0e       	movzbl (%rsi,%rcx,1),%r8d
ffff800000004825:	44 88 04 08          	mov    %r8b,(%rax,%rcx,1)
ffff800000004829:	48 83 c1 01          	add    $0x1,%rcx
ffff80000000482d:	48 39 d1             	cmp    %rdx,%rcx
ffff800000004830:	75 ee                	jne    ffff800000004820 <memcpy+0x10>
ffff800000004832:	c3                   	ret    
ffff800000004833:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff80000000483a:	00 00 00 00 
ffff80000000483e:	66 90                	xchg   %ax,%ax

ffff800000004840 <strcpy>:
ffff800000004840:	48 89 f8             	mov    %rdi,%rax
ffff800000004843:	31 d2                	xor    %edx,%edx
ffff800000004845:	0f 1f 00             	nopl   (%rax)
ffff800000004848:	0f b6 0c 16          	movzbl (%rsi,%rdx,1),%ecx
ffff80000000484c:	88 0c 10             	mov    %cl,(%rax,%rdx,1)
ffff80000000484f:	48 83 c2 01          	add    $0x1,%rdx
ffff800000004853:	84 c9                	test   %cl,%cl
ffff800000004855:	75 f1                	jne    ffff800000004848 <strcpy+0x8>
ffff800000004857:	c3                   	ret    
ffff800000004858:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff80000000485f:	00 

ffff800000004860 <switch_to>:
ffff800000004860:	55                   	push   %rbp
ffff800000004861:	53                   	push   %rbx
ffff800000004862:	41 54                	push   %r12
ffff800000004864:	41 55                	push   %r13
ffff800000004866:	41 56                	push   %r14
ffff800000004868:	41 57                	push   %r15
ffff80000000486a:	48 89 27             	mov    %rsp,(%rdi)
ffff80000000486d:	48 8b 26             	mov    (%rsi),%rsp
ffff800000004870:	41 5f                	pop    %r15
ffff800000004872:	41 5e                	pop    %r14
ffff800000004874:	41 5d                	pop    %r13
ffff800000004876:	41 5c                	pop    %r12
ffff800000004878:	5b                   	pop    %rbx
ffff800000004879:	5d                   	pop    %rbp
ffff80000000487a:	c3                   	ret    
ffff80000000487b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff800000004880 <spinlock_init>:
ffff800000004880:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff800000004886:	48 c7 47 08 00 00 00 	movq   $0x0,0x8(%rdi)
ffff80000000488d:	00 
ffff80000000488e:	c3                   	ret    
ffff80000000488f:	90                   	nop

ffff800000004890 <spinlock_acquire>:
ffff800000004890:	9c                   	pushf  
ffff800000004891:	5e                   	pop    %rsi
ffff800000004892:	fa                   	cli    
ffff800000004893:	48 89 f1             	mov    %rsi,%rcx
ffff800000004896:	ba 01 00 00 00       	mov    $0x1,%edx
ffff80000000489b:	81 e1 00 02 00 00    	and    $0x200,%ecx
ffff8000000048a1:	eb 0a                	jmp    ffff8000000048ad <spinlock_acquire+0x1d>
ffff8000000048a3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff8000000048a8:	48 85 c9             	test   %rcx,%rcx
ffff8000000048ab:	75 13                	jne    ffff8000000048c0 <spinlock_acquire+0x30>
ffff8000000048ad:	89 d0                	mov    %edx,%eax
ffff8000000048af:	87 07                	xchg   %eax,(%rdi)
ffff8000000048b1:	83 f8 01             	cmp    $0x1,%eax
ffff8000000048b4:	74 f2                	je     ffff8000000048a8 <spinlock_acquire+0x18>
ffff8000000048b6:	48 89 77 08          	mov    %rsi,0x8(%rdi)
ffff8000000048ba:	c3                   	ret    
ffff8000000048bb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff8000000048c0:	fb                   	sti    
ffff8000000048c1:	90                   	nop
ffff8000000048c2:	fa                   	cli    
ffff8000000048c3:	eb e8                	jmp    ffff8000000048ad <spinlock_acquire+0x1d>
ffff8000000048c5:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000048cc:	00 00 00 00 

ffff8000000048d0 <spinlock_release>:
ffff8000000048d0:	48 8b 47 08          	mov    0x8(%rdi),%rax
ffff8000000048d4:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff8000000048da:	f6 c4 02             	test   $0x2,%ah
ffff8000000048dd:	74 01                	je     ffff8000000048e0 <spinlock_release+0x10>
ffff8000000048df:	fb                   	sti    
ffff8000000048e0:	c3                   	ret    
ffff8000000048e1:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff8000000048e8:	00 00 00 00 
ffff8000000048ec:	0f 1f 40 00          	nopl   0x0(%rax)

ffff8000000048f0 <mutex_init>:
ffff8000000048f0:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff8000000048f6:	48 c7 47 08 00 00 00 	movq   $0x0,0x8(%rdi)
ffff8000000048fd:	00 
ffff8000000048fe:	c7 47 10 00 00 00 00 	movl   $0x0,0x10(%rdi)
ffff800000004905:	c3                   	ret    
ffff800000004906:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff80000000490d:	00 00 00 

ffff800000004910 <mutex_acquire>:
ffff800000004910:	48 be f0 8a 00 00 00 	movabs $0xffff800000008af0,%rsi
ffff800000004917:	80 ff ff 
ffff80000000491a:	b9 01 00 00 00       	mov    $0x1,%ecx
ffff80000000491f:	90                   	nop
ffff800000004920:	9c                   	pushf  
ffff800000004921:	41 58                	pop    %r8
ffff800000004923:	fa                   	cli    
ffff800000004924:	4c 89 c2             	mov    %r8,%rdx
ffff800000004927:	81 e2 00 02 00 00    	and    $0x200,%edx
ffff80000000492d:	eb 06                	jmp    ffff800000004935 <mutex_acquire+0x25>
ffff80000000492f:	90                   	nop
ffff800000004930:	48 85 d2             	test   %rdx,%rdx
ffff800000004933:	75 4b                	jne    ffff800000004980 <mutex_acquire+0x70>
ffff800000004935:	89 c8                	mov    %ecx,%eax
ffff800000004937:	87 07                	xchg   %eax,(%rdi)
ffff800000004939:	83 f8 01             	cmp    $0x1,%eax
ffff80000000493c:	74 f2                	je     ffff800000004930 <mutex_acquire+0x20>
ffff80000000493e:	8b 47 10             	mov    0x10(%rdi),%eax
ffff800000004941:	4c 89 47 08          	mov    %r8,0x8(%rdi)
ffff800000004945:	85 c0                	test   %eax,%eax
ffff800000004947:	74 3c                	je     ffff800000004985 <mutex_acquire+0x75>
ffff800000004949:	48 8b 06             	mov    (%rsi),%rax
ffff80000000494c:	c7 40 20 01 00 00 00 	movl   $0x1,0x20(%rax)
ffff800000004953:	48 89 78 28          	mov    %rdi,0x28(%rax)
ffff800000004957:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff80000000495d:	48 85 d2             	test   %rdx,%rdx
ffff800000004960:	74 01                	je     ffff800000004963 <mutex_acquire+0x53>
ffff800000004962:	fb                   	sti    
ffff800000004963:	48 8b 06             	mov    (%rsi),%rax
ffff800000004966:	83 78 20 01          	cmpl   $0x1,0x20(%rax)
ffff80000000496a:	75 b4                	jne    ffff800000004920 <mutex_acquire+0x10>
ffff80000000496c:	0f 1f 40 00          	nopl   0x0(%rax)
ffff800000004970:	fb                   	sti    
ffff800000004971:	f4                   	hlt    
ffff800000004972:	48 8b 06             	mov    (%rsi),%rax
ffff800000004975:	83 78 20 01          	cmpl   $0x1,0x20(%rax)
ffff800000004979:	74 f5                	je     ffff800000004970 <mutex_acquire+0x60>
ffff80000000497b:	eb a3                	jmp    ffff800000004920 <mutex_acquire+0x10>
ffff80000000497d:	0f 1f 00             	nopl   (%rax)
ffff800000004980:	fb                   	sti    
ffff800000004981:	90                   	nop
ffff800000004982:	fa                   	cli    
ffff800000004983:	eb b0                	jmp    ffff800000004935 <mutex_acquire+0x25>
ffff800000004985:	c7 47 10 01 00 00 00 	movl   $0x1,0x10(%rdi)
ffff80000000498c:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff800000004992:	48 85 d2             	test   %rdx,%rdx
ffff800000004995:	74 02                	je     ffff800000004999 <mutex_acquire+0x89>
ffff800000004997:	fb                   	sti    
ffff800000004998:	c3                   	ret    
ffff800000004999:	c3                   	ret    
ffff80000000499a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

ffff8000000049a0 <mutex_release>:
ffff8000000049a0:	9c                   	pushf  
ffff8000000049a1:	5e                   	pop    %rsi
ffff8000000049a2:	fa                   	cli    
ffff8000000049a3:	48 89 f1             	mov    %rsi,%rcx
ffff8000000049a6:	ba 01 00 00 00       	mov    $0x1,%edx
ffff8000000049ab:	81 e1 00 02 00 00    	and    $0x200,%ecx
ffff8000000049b1:	eb 0e                	jmp    ffff8000000049c1 <mutex_release+0x21>
ffff8000000049b3:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff8000000049b8:	48 85 c9             	test   %rcx,%rcx
ffff8000000049bb:	0f 85 7f 00 00 00    	jne    ffff800000004a40 <mutex_release+0xa0>
ffff8000000049c1:	89 d0                	mov    %edx,%eax
ffff8000000049c3:	87 07                	xchg   %eax,(%rdi)
ffff8000000049c5:	83 f8 01             	cmp    $0x1,%eax
ffff8000000049c8:	74 ee                	je     ffff8000000049b8 <mutex_release+0x18>
ffff8000000049ca:	48 a1 f0 8a 00 00 00 	movabs 0xffff800000008af0,%rax
ffff8000000049d1:	80 ff ff 
ffff8000000049d4:	48 89 77 08          	mov    %rsi,0x8(%rdi)
ffff8000000049d8:	c7 47 10 00 00 00 00 	movl   $0x0,0x10(%rdi)
ffff8000000049df:	48 85 c0             	test   %rax,%rax
ffff8000000049e2:	74 6c                	je     ffff800000004a50 <mutex_release+0xb0>
ffff8000000049e4:	48 8b 50 18          	mov    0x18(%rax),%rdx
ffff8000000049e8:	48 39 d0             	cmp    %rdx,%rax
ffff8000000049eb:	75 0c                	jne    ffff8000000049f9 <mutex_release+0x59>
ffff8000000049ed:	eb 61                	jmp    ffff800000004a50 <mutex_release+0xb0>
ffff8000000049ef:	90                   	nop
ffff8000000049f0:	48 8b 52 18          	mov    0x18(%rdx),%rdx
ffff8000000049f4:	48 39 d0             	cmp    %rdx,%rax
ffff8000000049f7:	74 57                	je     ffff800000004a50 <mutex_release+0xb0>
ffff8000000049f9:	83 7a 20 01          	cmpl   $0x1,0x20(%rdx)
ffff8000000049fd:	75 f1                	jne    ffff8000000049f0 <mutex_release+0x50>
ffff8000000049ff:	48 39 7a 28          	cmp    %rdi,0x28(%rdx)
ffff800000004a03:	75 eb                	jne    ffff8000000049f0 <mutex_release+0x50>
ffff800000004a05:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000004a09:	c7 42 20 00 00 00 00 	movl   $0x0,0x20(%rdx)
ffff800000004a10:	48 c7 42 28 00 00 00 	movq   $0x0,0x28(%rdx)
ffff800000004a17:	00 
ffff800000004a18:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff800000004a1e:	48 85 c9             	test   %rcx,%rcx
ffff800000004a21:	74 01                	je     ffff800000004a24 <mutex_release+0x84>
ffff800000004a23:	fb                   	sti    
ffff800000004a24:	fa                   	cli    
ffff800000004a25:	48 b8 f0 53 00 00 00 	movabs $0xffff8000000053f0,%rax
ffff800000004a2c:	80 ff ff 
ffff800000004a2f:	ff d0                	call   *%rax
ffff800000004a31:	fb                   	sti    
ffff800000004a32:	48 83 c4 08          	add    $0x8,%rsp
ffff800000004a36:	c3                   	ret    
ffff800000004a37:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff800000004a3e:	00 00 
ffff800000004a40:	fb                   	sti    
ffff800000004a41:	90                   	nop
ffff800000004a42:	fa                   	cli    
ffff800000004a43:	e9 79 ff ff ff       	jmp    ffff8000000049c1 <mutex_release+0x21>
ffff800000004a48:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
ffff800000004a4f:	00 
ffff800000004a50:	c7 07 00 00 00 00    	movl   $0x0,(%rdi)
ffff800000004a56:	48 85 c9             	test   %rcx,%rcx
ffff800000004a59:	74 05                	je     ffff800000004a60 <mutex_release+0xc0>
ffff800000004a5b:	fb                   	sti    
ffff800000004a5c:	c3                   	ret    
ffff800000004a5d:	0f 1f 00             	nopl   (%rax)
ffff800000004a60:	c3                   	ret    

ffff800000004a61 <syscall_entry>:
ffff800000004a61:	0f 01 f8             	swapgs 
ffff800000004a64:	65 48 89 24 25 08 00 	mov    %rsp,%gs:0x8
ffff800000004a6b:	00 00 
ffff800000004a6d:	65 48 8b 24 25 00 00 	mov    %gs:0x0,%rsp
ffff800000004a74:	00 00 
ffff800000004a76:	51                   	push   %rcx
ffff800000004a77:	41 53                	push   %r11
ffff800000004a79:	50                   	push   %rax
ffff800000004a7a:	57                   	push   %rdi
ffff800000004a7b:	56                   	push   %rsi
ffff800000004a7c:	52                   	push   %rdx
ffff800000004a7d:	41 50                	push   %r8
ffff800000004a7f:	41 51                	push   %r9
ffff800000004a81:	41 52                	push   %r10
ffff800000004a83:	48 89 d1             	mov    %rdx,%rcx
ffff800000004a86:	48 89 f2             	mov    %rsi,%rdx
ffff800000004a89:	48 89 fe             	mov    %rdi,%rsi
ffff800000004a8c:	48 89 c7             	mov    %rax,%rdi
ffff800000004a8f:	e8 8c 00 00 00       	call   ffff800000004b20 <syscall_handler>
ffff800000004a94:	41 5a                	pop    %r10
ffff800000004a96:	41 59                	pop    %r9
ffff800000004a98:	41 58                	pop    %r8
ffff800000004a9a:	5a                   	pop    %rdx
ffff800000004a9b:	5e                   	pop    %rsi
ffff800000004a9c:	5f                   	pop    %rdi
ffff800000004a9d:	58                   	pop    %rax
ffff800000004a9e:	41 5b                	pop    %r11
ffff800000004aa0:	59                   	pop    %rcx
ffff800000004aa1:	65 48 8b 24 25 08 00 	mov    %gs:0x8,%rsp
ffff800000004aa8:	00 00 
ffff800000004aaa:	0f 01 f8             	swapgs 
ffff800000004aad:	48 0f 07             	sysretq 

ffff800000004ab0 <syscall_init>:
ffff800000004ab0:	b9 80 00 00 c0       	mov    $0xc0000080,%ecx
ffff800000004ab5:	0f 32                	rdmsr  
ffff800000004ab7:	48 c1 e2 20          	shl    $0x20,%rdx
ffff800000004abb:	89 c0                	mov    %eax,%eax
ffff800000004abd:	48 09 c2             	or     %rax,%rdx
ffff800000004ac0:	48 89 d0             	mov    %rdx,%rax
ffff800000004ac3:	48 c1 ea 20          	shr    $0x20,%rdx
ffff800000004ac7:	48 83 c8 01          	or     $0x1,%rax
ffff800000004acb:	0f 30                	wrmsr  
ffff800000004acd:	31 f6                	xor    %esi,%esi
ffff800000004acf:	b9 81 00 00 c0       	mov    $0xc0000081,%ecx
ffff800000004ad4:	ba 08 00 10 00       	mov    $0x100008,%edx
ffff800000004ad9:	89 f0                	mov    %esi,%eax
ffff800000004adb:	0f 30                	wrmsr  
ffff800000004add:	48 b8 61 4a 00 00 00 	movabs $0xffff800000004a61,%rax
ffff800000004ae4:	80 ff ff 
ffff800000004ae7:	b9 82 00 00 c0       	mov    $0xc0000082,%ecx
ffff800000004aec:	48 89 c2             	mov    %rax,%rdx
ffff800000004aef:	48 c1 ea 20          	shr    $0x20,%rdx
ffff800000004af3:	0f 30                	wrmsr  
ffff800000004af5:	b9 84 00 00 c0       	mov    $0xc0000084,%ecx
ffff800000004afa:	b8 00 02 00 00       	mov    $0x200,%eax
ffff800000004aff:	89 f2                	mov    %esi,%edx
ffff800000004b01:	0f 30                	wrmsr  
ffff800000004b03:	48 b8 c0 8a 00 00 00 	movabs $0xffff800000008ac0,%rax
ffff800000004b0a:	80 ff ff 
ffff800000004b0d:	b9 02 01 00 c0       	mov    $0xc0000102,%ecx
ffff800000004b12:	48 89 c2             	mov    %rax,%rdx
ffff800000004b15:	48 c1 ea 20          	shr    $0x20,%rdx
ffff800000004b19:	0f 30                	wrmsr  
ffff800000004b1b:	c3                   	ret    
ffff800000004b1c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000004b20 <syscall_handler>:
ffff800000004b20:	48 83 ff 01          	cmp    $0x1,%rdi
ffff800000004b24:	74 0a                	je     ffff800000004b30 <syscall_handler+0x10>
ffff800000004b26:	c3                   	ret    
ffff800000004b27:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff800000004b2e:	00 00 
ffff800000004b30:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000004b37:	80 ff ff 
ffff800000004b3a:	48 89 f7             	mov    %rsi,%rdi
ffff800000004b3d:	ff e0                	jmp    *%rax
ffff800000004b3f:	90                   	nop

ffff800000004b40 <test_pmm>:
ffff800000004b40:	48 bf c8 65 00 00 00 	movabs $0xffff8000000065c8,%rdi
ffff800000004b47:	80 ff ff 
ffff800000004b4a:	41 57                	push   %r15
ffff800000004b4c:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000004b53:	80 ff ff 
ffff800000004b56:	41 56                	push   %r14
ffff800000004b58:	49 be e0 30 00 00 00 	movabs $0xffff8000000030e0,%r14
ffff800000004b5f:	80 ff ff 
ffff800000004b62:	41 55                	push   %r13
ffff800000004b64:	41 54                	push   %r12
ffff800000004b66:	49 bc 50 2e 00 00 00 	movabs $0xffff800000002e50,%r12
ffff800000004b6d:	80 ff ff 
ffff800000004b70:	55                   	push   %rbp
ffff800000004b71:	53                   	push   %rbx
ffff800000004b72:	48 81 ec 28 03 00 00 	sub    $0x328,%rsp
ffff800000004b79:	ff d0                	call   *%rax
ffff800000004b7b:	48 89 e3             	mov    %rsp,%rbx
ffff800000004b7e:	48 8d ac 24 20 03 00 	lea    0x320(%rsp),%rbp
ffff800000004b85:	00 
ffff800000004b86:	41 ff d6             	call   *%r14
ffff800000004b89:	49 89 df             	mov    %rbx,%r15
ffff800000004b8c:	41 89 c5             	mov    %eax,%r13d
ffff800000004b8f:	eb 10                	jmp    ffff800000004ba1 <test_pmm+0x61>
ffff800000004b91:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000004b98:	49 83 c7 08          	add    $0x8,%r15
ffff800000004b9c:	49 39 ef             	cmp    %rbp,%r15
ffff800000004b9f:	74 6a                	je     ffff800000004c0b <test_pmm+0xcb>
ffff800000004ba1:	31 c0                	xor    %eax,%eax
ffff800000004ba3:	41 ff d4             	call   *%r12
ffff800000004ba6:	49 89 07             	mov    %rax,(%r15)
ffff800000004ba9:	48 85 c0             	test   %rax,%rax
ffff800000004bac:	75 ea                	jne    ffff800000004b98 <test_pmm+0x58>
ffff800000004bae:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004bb5:	80 ff ff 
ffff800000004bb8:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004bbf:	80 ff ff 
ffff800000004bc2:	ff d3                	call   *%rbx
ffff800000004bc4:	48 bf bd 66 00 00 00 	movabs $0xffff8000000066bd,%rdi
ffff800000004bcb:	80 ff ff 
ffff800000004bce:	ff d3                	call   *%rbx
ffff800000004bd0:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004bd7:	80 ff ff 
ffff800000004bda:	ff d3                	call   *%rbx
ffff800000004bdc:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004be3:	80 ff ff 
ffff800000004be6:	ff d3                	call   *%rbx
ffff800000004be8:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004bef:	80 ff ff 
ffff800000004bf2:	ff d3                	call   *%rbx
ffff800000004bf4:	bf 17 00 00 00       	mov    $0x17,%edi
ffff800000004bf9:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004c00:	80 ff ff 
ffff800000004c03:	ff d0                	call   *%rax
ffff800000004c05:	0f 1f 00             	nopl   (%rax)
ffff800000004c08:	f4                   	hlt    
ffff800000004c09:	eb fd                	jmp    ffff800000004c08 <test_pmm+0xc8>
ffff800000004c0b:	49 bc 70 2e 00 00 00 	movabs $0xffff800000002e70,%r12
ffff800000004c12:	80 ff ff 
ffff800000004c15:	0f 1f 00             	nopl   (%rax)
ffff800000004c18:	48 8b 3b             	mov    (%rbx),%rdi
ffff800000004c1b:	48 83 c3 08          	add    $0x8,%rbx
ffff800000004c1f:	41 ff d4             	call   *%r12
ffff800000004c22:	48 39 eb             	cmp    %rbp,%rbx
ffff800000004c25:	75 f1                	jne    ffff800000004c18 <test_pmm+0xd8>
ffff800000004c27:	48 b8 50 2d 00 00 00 	movabs $0xffff800000002d50,%rax
ffff800000004c2e:	80 ff ff 
ffff800000004c31:	bf 32 00 00 00       	mov    $0x32,%edi
ffff800000004c36:	ff d0                	call   *%rax
ffff800000004c38:	48 89 c3             	mov    %rax,%rbx
ffff800000004c3b:	48 8d a8 00 20 03 00 	lea    0x32000(%rax),%rbp
ffff800000004c42:	48 85 c0             	test   %rax,%rax
ffff800000004c45:	0f 84 a7 00 00 00    	je     ffff800000004cf2 <test_pmm+0x1b2>
ffff800000004c4b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
ffff800000004c50:	48 89 df             	mov    %rbx,%rdi
ffff800000004c53:	48 81 c3 00 10 00 00 	add    $0x1000,%rbx
ffff800000004c5a:	41 ff d4             	call   *%r12
ffff800000004c5d:	48 39 eb             	cmp    %rbp,%rbx
ffff800000004c60:	75 ee                	jne    ffff800000004c50 <test_pmm+0x110>
ffff800000004c62:	41 ff d6             	call   *%r14
ffff800000004c65:	41 39 c5             	cmp    %eax,%r13d
ffff800000004c68:	74 61                	je     ffff800000004ccb <test_pmm+0x18b>
ffff800000004c6a:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004c71:	80 ff ff 
ffff800000004c74:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004c7b:	80 ff ff 
ffff800000004c7e:	ff d3                	call   *%rbx
ffff800000004c80:	48 bf f5 66 00 00 00 	movabs $0xffff8000000066f5,%rdi
ffff800000004c87:	80 ff ff 
ffff800000004c8a:	ff d3                	call   *%rbx
ffff800000004c8c:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004c93:	80 ff ff 
ffff800000004c96:	ff d3                	call   *%rbx
ffff800000004c98:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004c9f:	80 ff ff 
ffff800000004ca2:	ff d3                	call   *%rbx
ffff800000004ca4:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004cab:	80 ff ff 
ffff800000004cae:	ff d3                	call   *%rbx
ffff800000004cb0:	bf 26 00 00 00       	mov    $0x26,%edi
ffff800000004cb5:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004cbc:	80 ff ff 
ffff800000004cbf:	ff d0                	call   *%rax
ffff800000004cc1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000004cc8:	f4                   	hlt    
ffff800000004cc9:	eb fd                	jmp    ffff800000004cc8 <test_pmm+0x188>
ffff800000004ccb:	48 81 c4 28 03 00 00 	add    $0x328,%rsp
ffff800000004cd2:	48 bf da 63 00 00 00 	movabs $0xffff8000000063da,%rdi
ffff800000004cd9:	80 ff ff 
ffff800000004cdc:	48 b8 40 37 00 00 00 	movabs $0xffff800000003740,%rax
ffff800000004ce3:	80 ff ff 
ffff800000004ce6:	5b                   	pop    %rbx
ffff800000004ce7:	5d                   	pop    %rbp
ffff800000004ce8:	41 5c                	pop    %r12
ffff800000004cea:	41 5d                	pop    %r13
ffff800000004cec:	41 5e                	pop    %r14
ffff800000004cee:	41 5f                	pop    %r15
ffff800000004cf0:	ff e0                	jmp    *%rax
ffff800000004cf2:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004cf9:	80 ff ff 
ffff800000004cfc:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004d03:	80 ff ff 
ffff800000004d06:	ff d3                	call   *%rbx
ffff800000004d08:	48 bf e3 66 00 00 00 	movabs $0xffff8000000066e3,%rdi
ffff800000004d0f:	80 ff ff 
ffff800000004d12:	ff d3                	call   *%rbx
ffff800000004d14:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004d1b:	80 ff ff 
ffff800000004d1e:	ff d3                	call   *%rbx
ffff800000004d20:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004d27:	80 ff ff 
ffff800000004d2a:	ff d3                	call   *%rbx
ffff800000004d2c:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004d33:	80 ff ff 
ffff800000004d36:	ff d3                	call   *%rbx
ffff800000004d38:	bf 1f 00 00 00       	mov    $0x1f,%edi
ffff800000004d3d:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004d44:	80 ff ff 
ffff800000004d47:	ff d0                	call   *%rax
ffff800000004d49:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000004d50:	f4                   	hlt    
ffff800000004d51:	eb fd                	jmp    ffff800000004d50 <test_pmm+0x210>
ffff800000004d53:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000004d5a:	00 00 00 00 
ffff800000004d5e:	66 90                	xchg   %ax,%ax

ffff800000004d60 <conc_thread>:
ffff800000004d60:	41 56                	push   %r14
ffff800000004d62:	49 be d0 8a 00 00 00 	movabs $0xffff800000008ad0,%r14
ffff800000004d69:	80 ff ff 
ffff800000004d6c:	41 55                	push   %r13
ffff800000004d6e:	49 bd 10 49 00 00 00 	movabs $0xffff800000004910,%r13
ffff800000004d75:	80 ff ff 
ffff800000004d78:	41 54                	push   %r12
ffff800000004d7a:	49 bc a0 49 00 00 00 	movabs $0xffff8000000049a0,%r12
ffff800000004d81:	80 ff ff 
ffff800000004d84:	55                   	push   %rbp
ffff800000004d85:	48 bd ec 8a 00 00 00 	movabs $0xffff800000008aec,%rbp
ffff800000004d8c:	80 ff ff 
ffff800000004d8f:	53                   	push   %rbx
ffff800000004d90:	bb e8 03 00 00       	mov    $0x3e8,%ebx
ffff800000004d95:	0f 1f 00             	nopl   (%rax)
ffff800000004d98:	4c 89 f7             	mov    %r14,%rdi
ffff800000004d9b:	41 ff d5             	call   *%r13
ffff800000004d9e:	8b 45 00             	mov    0x0(%rbp),%eax
ffff800000004da1:	4c 89 f7             	mov    %r14,%rdi
ffff800000004da4:	83 c0 01             	add    $0x1,%eax
ffff800000004da7:	89 45 00             	mov    %eax,0x0(%rbp)
ffff800000004daa:	41 ff d4             	call   *%r12
ffff800000004dad:	83 eb 01             	sub    $0x1,%ebx
ffff800000004db0:	75 e6                	jne    ffff800000004d98 <conc_thread+0x38>
ffff800000004db2:	4c 89 f7             	mov    %r14,%rdi
ffff800000004db5:	41 ff d5             	call   *%r13
ffff800000004db8:	4c 89 f7             	mov    %r14,%rdi
ffff800000004dbb:	48 ba e8 8a 00 00 00 	movabs $0xffff800000008ae8,%rdx
ffff800000004dc2:	80 ff ff 
ffff800000004dc5:	8b 02                	mov    (%rdx),%eax
ffff800000004dc7:	83 c0 01             	add    $0x1,%eax
ffff800000004dca:	89 02                	mov    %eax,(%rdx)
ffff800000004dcc:	41 ff d4             	call   *%r12
ffff800000004dcf:	5b                   	pop    %rbx
ffff800000004dd0:	5d                   	pop    %rbp
ffff800000004dd1:	48 b8 f0 55 00 00 00 	movabs $0xffff8000000055f0,%rax
ffff800000004dd8:	80 ff ff 
ffff800000004ddb:	41 5c                	pop    %r12
ffff800000004ddd:	41 5d                	pop    %r13
ffff800000004ddf:	41 5e                	pop    %r14
ffff800000004de1:	ff e0                	jmp    *%rax
ffff800000004de3:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
ffff800000004dea:	00 00 00 00 
ffff800000004dee:	66 90                	xchg   %ax,%ax

ffff800000004df0 <run_all_kernel_tests>:
ffff800000004df0:	48 bf e8 5a 00 00 00 	movabs $0xffff800000005ae8,%rdi
ffff800000004df7:	80 ff ff 
ffff800000004dfa:	41 57                	push   %r15
ffff800000004dfc:	48 b8 b0 37 00 00 00 	movabs $0xffff8000000037b0,%rax
ffff800000004e03:	80 ff ff 
ffff800000004e06:	41 56                	push   %r14
ffff800000004e08:	41 55                	push   %r13
ffff800000004e0a:	41 54                	push   %r12
ffff800000004e0c:	49 bc 70 29 00 00 00 	movabs $0xffff800000002970,%r12
ffff800000004e13:	80 ff ff 
ffff800000004e16:	55                   	push   %rbp
ffff800000004e17:	53                   	push   %rbx
ffff800000004e18:	48 bb 20 35 00 00 00 	movabs $0xffff800000003520,%rbx
ffff800000004e1f:	80 ff ff 
ffff800000004e22:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000004e26:	ff d0                	call   *%rax
ffff800000004e28:	48 b8 40 4b 00 00 00 	movabs $0xffff800000004b40,%rax
ffff800000004e2f:	80 ff ff 
ffff800000004e32:	ff d0                	call   *%rax
ffff800000004e34:	48 bf f0 65 00 00 00 	movabs $0xffff8000000065f0,%rdi
ffff800000004e3b:	80 ff ff 
ffff800000004e3e:	ff d3                	call   *%rbx
ffff800000004e40:	bf 11 00 00 00       	mov    $0x11,%edi
ffff800000004e45:	41 ff d4             	call   *%r12
ffff800000004e48:	48 85 c0             	test   %rax,%rax
ffff800000004e4b:	0f 84 1a 01 00 00    	je     ffff800000004f6b <run_all_kernel_tests+0x17b>
ffff800000004e51:	48 be 17 67 00 00 00 	movabs $0xffff800000006717,%rsi
ffff800000004e58:	80 ff ff 
ffff800000004e5b:	48 89 c7             	mov    %rax,%rdi
ffff800000004e5e:	48 89 c5             	mov    %rax,%rbp
ffff800000004e61:	48 b8 40 48 00 00 00 	movabs $0xffff800000004840,%rax
ffff800000004e68:	80 ff ff 
ffff800000004e6b:	ff d0                	call   *%rax
ffff800000004e6d:	bf 00 20 00 00       	mov    $0x2000,%edi
ffff800000004e72:	41 ff d4             	call   *%r12
ffff800000004e75:	49 89 c4             	mov    %rax,%r12
ffff800000004e78:	48 85 c0             	test   %rax,%rax
ffff800000004e7b:	0f 84 8a 00 00 00    	je     ffff800000004f0b <run_all_kernel_tests+0x11b>
ffff800000004e81:	48 89 c7             	mov    %rax,%rdi
ffff800000004e84:	ba 00 20 00 00       	mov    $0x2000,%edx
ffff800000004e89:	be ab 00 00 00       	mov    $0xab,%esi
ffff800000004e8e:	48 b8 f0 47 00 00 00 	movabs $0xffff8000000047f0,%rax
ffff800000004e95:	80 ff ff 
ffff800000004e98:	ff d0                	call   *%rax
ffff800000004e9a:	80 7d 00 4d          	cmpb   $0x4d,0x0(%rbp)
ffff800000004e9e:	75 0a                	jne    ffff800000004eaa <run_all_kernel_tests+0xba>
ffff800000004ea0:	80 7d 04 43          	cmpb   $0x43,0x4(%rbp)
ffff800000004ea4:	0f 84 21 01 00 00    	je     ffff800000004fcb <run_all_kernel_tests+0x1db>
ffff800000004eaa:	48 bd 90 38 00 00 00 	movabs $0xffff800000003890,%rbp
ffff800000004eb1:	80 ff ff 
ffff800000004eb4:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004ebb:	80 ff ff 
ffff800000004ebe:	ff d5                	call   *%rbp
ffff800000004ec0:	48 bf 28 67 00 00 00 	movabs $0xffff800000006728,%rdi
ffff800000004ec7:	80 ff ff 
ffff800000004eca:	ff d5                	call   *%rbp
ffff800000004ecc:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004ed3:	80 ff ff 
ffff800000004ed6:	ff d5                	call   *%rbp
ffff800000004ed8:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004edf:	80 ff ff 
ffff800000004ee2:	ff d5                	call   *%rbp
ffff800000004ee4:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004eeb:	80 ff ff 
ffff800000004eee:	ff d5                	call   *%rbp
ffff800000004ef0:	bf 38 00 00 00       	mov    $0x38,%edi
ffff800000004ef5:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004efc:	80 ff ff 
ffff800000004eff:	ff d0                	call   *%rax
ffff800000004f01:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000004f08:	f4                   	hlt    
ffff800000004f09:	eb fd                	jmp    ffff800000004f08 <run_all_kernel_tests+0x118>
ffff800000004f0b:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004f12:	80 ff ff 
ffff800000004f15:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004f1c:	80 ff ff 
ffff800000004f1f:	ff d3                	call   *%rbx
ffff800000004f21:	48 bf 1d 67 00 00 00 	movabs $0xffff80000000671d,%rdi
ffff800000004f28:	80 ff ff 
ffff800000004f2b:	ff d3                	call   *%rbx
ffff800000004f2d:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004f34:	80 ff ff 
ffff800000004f37:	ff d3                	call   *%rbx
ffff800000004f39:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004f40:	80 ff ff 
ffff800000004f43:	ff d3                	call   *%rbx
ffff800000004f45:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004f4c:	80 ff ff 
ffff800000004f4f:	ff d3                	call   *%rbx
ffff800000004f51:	bf 35 00 00 00       	mov    $0x35,%edi
ffff800000004f56:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004f5d:	80 ff ff 
ffff800000004f60:	ff d0                	call   *%rax
ffff800000004f62:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000004f68:	f4                   	hlt    
ffff800000004f69:	eb fd                	jmp    ffff800000004f68 <run_all_kernel_tests+0x178>
ffff800000004f6b:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004f72:	80 ff ff 
ffff800000004f75:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004f7c:	80 ff ff 
ffff800000004f7f:	ff d3                	call   *%rbx
ffff800000004f81:	48 bf 0c 67 00 00 00 	movabs $0xffff80000000670c,%rdi
ffff800000004f88:	80 ff ff 
ffff800000004f8b:	ff d3                	call   *%rbx
ffff800000004f8d:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004f94:	80 ff ff 
ffff800000004f97:	ff d3                	call   *%rbx
ffff800000004f99:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000004fa0:	80 ff ff 
ffff800000004fa3:	ff d3                	call   *%rbx
ffff800000004fa5:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000004fac:	80 ff ff 
ffff800000004faf:	ff d3                	call   *%rbx
ffff800000004fb1:	bf 30 00 00 00       	mov    $0x30,%edi
ffff800000004fb6:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000004fbd:	80 ff ff 
ffff800000004fc0:	ff d0                	call   *%rax
ffff800000004fc2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000004fc8:	f4                   	hlt    
ffff800000004fc9:	eb fd                	jmp    ffff800000004fc8 <run_all_kernel_tests+0x1d8>
ffff800000004fcb:	41 80 bc 24 ff 1f 00 	cmpb   $0xab,0x1fff(%r12)
ffff800000004fd2:	00 ab 
ffff800000004fd4:	74 5d                	je     ffff800000005033 <run_all_kernel_tests+0x243>
ffff800000004fd6:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000004fdd:	80 ff ff 
ffff800000004fe0:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff800000004fe7:	80 ff ff 
ffff800000004fea:	ff d3                	call   *%rbx
ffff800000004fec:	48 bf 45 67 00 00 00 	movabs $0xffff800000006745,%rdi
ffff800000004ff3:	80 ff ff 
ffff800000004ff6:	ff d3                	call   *%rbx
ffff800000004ff8:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000004fff:	80 ff ff 
ffff800000005002:	ff d3                	call   *%rbx
ffff800000005004:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff80000000500b:	80 ff ff 
ffff80000000500e:	ff d3                	call   *%rbx
ffff800000005010:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff800000005017:	80 ff ff 
ffff80000000501a:	ff d3                	call   *%rbx
ffff80000000501c:	bf 39 00 00 00       	mov    $0x39,%edi
ffff800000005021:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000005028:	80 ff ff 
ffff80000000502b:	ff d0                	call   *%rax
ffff80000000502d:	0f 1f 00             	nopl   (%rax)
ffff800000005030:	f4                   	hlt    
ffff800000005031:	eb fd                	jmp    ffff800000005030 <run_all_kernel_tests+0x240>
ffff800000005033:	49 bf da 63 00 00 00 	movabs $0xffff8000000063da,%r15
ffff80000000503a:	80 ff ff 
ffff80000000503d:	48 89 ef             	mov    %rbp,%rdi
ffff800000005040:	49 be 40 37 00 00 00 	movabs $0xffff800000003740,%r14
ffff800000005047:	80 ff ff 
ffff80000000504a:	48 bd 90 2a 00 00 00 	movabs $0xffff800000002a90,%rbp
ffff800000005051:	80 ff ff 
ffff800000005054:	ff d5                	call   *%rbp
ffff800000005056:	4c 89 e7             	mov    %r12,%rdi
ffff800000005059:	49 bc 50 2e 00 00 00 	movabs $0xffff800000002e50,%r12
ffff800000005060:	80 ff ff 
ffff800000005063:	ff d5                	call   *%rbp
ffff800000005065:	4c 89 ff             	mov    %r15,%rdi
ffff800000005068:	41 ff d6             	call   *%r14
ffff80000000506b:	48 bf 18 66 00 00 00 	movabs $0xffff800000006618,%rdi
ffff800000005072:	80 ff ff 
ffff800000005075:	ff d3                	call   *%rbx
ffff800000005077:	48 b8 d0 2e 00 00 00 	movabs $0xffff800000002ed0,%rax
ffff80000000507e:	80 ff ff 
ffff800000005081:	ff d0                	call   *%rax
ffff800000005083:	48 89 c5             	mov    %rax,%rbp
ffff800000005086:	31 c0                	xor    %eax,%eax
ffff800000005088:	41 ff d4             	call   *%r12
ffff80000000508b:	49 89 c5             	mov    %rax,%r13
ffff80000000508e:	31 c0                	xor    %eax,%eax
ffff800000005090:	41 ff d4             	call   *%r12
ffff800000005093:	48 89 ef             	mov    %rbp,%rdi
ffff800000005096:	be 00 00 00 50       	mov    $0x50000000,%esi
ffff80000000509b:	49 b8 bb bb bb bb bb 	movabs $0xbbbbbbbbbbbbbbbb,%r8
ffff8000000050a2:	bb bb bb 
ffff8000000050a5:	48 b9 aa aa aa aa aa 	movabs $0xaaaaaaaaaaaaaaaa,%rcx
ffff8000000050ac:	aa aa aa 
ffff8000000050af:	49 89 c4             	mov    %rax,%r12
ffff8000000050b2:	48 b8 00 00 00 00 00 	movabs $0xffff800000000000,%rax
ffff8000000050b9:	80 ff ff 
ffff8000000050bc:	49 8d 54 05 00       	lea    0x0(%r13,%rax,1),%rdx
ffff8000000050c1:	4c 01 e0             	add    %r12,%rax
ffff8000000050c4:	48 89 0a             	mov    %rcx,(%rdx)
ffff8000000050c7:	4c 89 ea             	mov    %r13,%rdx
ffff8000000050ca:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff8000000050cf:	4c 89 00             	mov    %r8,(%rax)
ffff8000000050d2:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff8000000050d9:	80 ff ff 
ffff8000000050dc:	ff d0                	call   *%rax
ffff8000000050de:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff8000000050e3:	4c 89 e2             	mov    %r12,%rdx
ffff8000000050e6:	be 00 00 00 50       	mov    $0x50000000,%esi
ffff8000000050eb:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff8000000050f2:	80 ff ff 
ffff8000000050f5:	48 89 ef             	mov    %rbp,%rdi
ffff8000000050f8:	ff d0                	call   *%rax
ffff8000000050fa:	0f 20 da             	mov    %cr3,%rdx
ffff8000000050fd:	0f 22 dd             	mov    %rbp,%cr3
ffff800000005100:	48 8b 04 25 00 00 00 	mov    0x50000000,%rax
ffff800000005107:	50 
ffff800000005108:	0f 22 da             	mov    %rdx,%cr3
ffff80000000510b:	49 b8 bb bb bb bb bb 	movabs $0xbbbbbbbbbbbbbbbb,%r8
ffff800000005112:	bb bb bb 
ffff800000005115:	4c 39 c0             	cmp    %r8,%rax
ffff800000005118:	74 61                	je     ffff80000000517b <run_all_kernel_tests+0x38b>
ffff80000000511a:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000005121:	80 ff ff 
ffff800000005124:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff80000000512b:	80 ff ff 
ffff80000000512e:	ff d3                	call   *%rbx
ffff800000005130:	48 bf 5f 67 00 00 00 	movabs $0xffff80000000675f,%rdi
ffff800000005137:	80 ff ff 
ffff80000000513a:	ff d3                	call   *%rbx
ffff80000000513c:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000005143:	80 ff ff 
ffff800000005146:	ff d3                	call   *%rbx
ffff800000005148:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff80000000514f:	80 ff ff 
ffff800000005152:	ff d3                	call   *%rbx
ffff800000005154:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff80000000515b:	80 ff ff 
ffff80000000515e:	ff d3                	call   *%rbx
ffff800000005160:	bf 89 00 00 00       	mov    $0x89,%edi
ffff800000005165:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff80000000516c:	80 ff ff 
ffff80000000516f:	ff d0                	call   *%rax
ffff800000005171:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000005178:	f4                   	hlt    
ffff800000005179:	eb fd                	jmp    ffff800000005178 <run_all_kernel_tests+0x388>
ffff80000000517b:	4c 89 ef             	mov    %r13,%rdi
ffff80000000517e:	49 bd 70 2e 00 00 00 	movabs $0xffff800000002e70,%r13
ffff800000005185:	80 ff ff 
ffff800000005188:	41 ff d5             	call   *%r13
ffff80000000518b:	4c 89 e7             	mov    %r12,%rdi
ffff80000000518e:	49 bc 60 4d 00 00 00 	movabs $0xffff800000004d60,%r12
ffff800000005195:	80 ff ff 
ffff800000005198:	41 ff d5             	call   *%r13
ffff80000000519b:	48 89 ef             	mov    %rbp,%rdi
ffff80000000519e:	48 bd 10 53 00 00 00 	movabs $0xffff800000005310,%rbp
ffff8000000051a5:	80 ff ff 
ffff8000000051a8:	41 ff d5             	call   *%r13
ffff8000000051ab:	4c 89 ff             	mov    %r15,%rdi
ffff8000000051ae:	41 ff d6             	call   *%r14
ffff8000000051b1:	48 bf 40 66 00 00 00 	movabs $0xffff800000006640,%rdi
ffff8000000051b8:	80 ff ff 
ffff8000000051bb:	ff d3                	call   *%rbx
ffff8000000051bd:	48 bf d0 8a 00 00 00 	movabs $0xffff800000008ad0,%rdi
ffff8000000051c4:	80 ff ff 
ffff8000000051c7:	48 b8 f0 48 00 00 00 	movabs $0xffff8000000048f0,%rax
ffff8000000051ce:	80 ff ff 
ffff8000000051d1:	48 bb b0 53 00 00 00 	movabs $0xffff8000000053b0,%rbx
ffff8000000051d8:	80 ff ff 
ffff8000000051db:	ff d0                	call   *%rax
ffff8000000051dd:	be 05 00 00 00       	mov    $0x5,%esi
ffff8000000051e2:	4c 89 e7             	mov    %r12,%rdi
ffff8000000051e5:	ff d5                	call   *%rbp
ffff8000000051e7:	48 89 c7             	mov    %rax,%rdi
ffff8000000051ea:	ff d3                	call   *%rbx
ffff8000000051ec:	be 05 00 00 00       	mov    $0x5,%esi
ffff8000000051f1:	4c 89 e7             	mov    %r12,%rdi
ffff8000000051f4:	ff d5                	call   *%rbp
ffff8000000051f6:	48 89 c7             	mov    %rax,%rdi
ffff8000000051f9:	ff d3                	call   *%rbx
ffff8000000051fb:	be 05 00 00 00       	mov    $0x5,%esi
ffff800000005200:	4c 89 e7             	mov    %r12,%rdi
ffff800000005203:	ff d5                	call   *%rbp
ffff800000005205:	48 89 c7             	mov    %rax,%rdi
ffff800000005208:	ff d3                	call   *%rbx
ffff80000000520a:	48 bb e8 8a 00 00 00 	movabs $0xffff800000008ae8,%rbx
ffff800000005211:	80 ff ff 
ffff800000005214:	8b 03                	mov    (%rbx),%eax
ffff800000005216:	83 f8 02             	cmp    $0x2,%eax
ffff800000005219:	7f 13                	jg     ffff80000000522e <run_all_kernel_tests+0x43e>
ffff80000000521b:	48 bd 90 54 00 00 00 	movabs $0xffff800000005490,%rbp
ffff800000005222:	80 ff ff 
ffff800000005225:	ff d5                	call   *%rbp
ffff800000005227:	8b 03                	mov    (%rbx),%eax
ffff800000005229:	83 f8 02             	cmp    $0x2,%eax
ffff80000000522c:	7e f7                	jle    ffff800000005225 <run_all_kernel_tests+0x435>
ffff80000000522e:	a1 ec 8a 00 00 00 80 	movabs 0xffff800000008aec,%eax
ffff800000005235:	ff ff 
ffff800000005237:	3d b8 0b 00 00       	cmp    $0xbb8,%eax
ffff80000000523c:	74 5d                	je     ffff80000000529b <run_all_kernel_tests+0x4ab>
ffff80000000523e:	48 bb 90 38 00 00 00 	movabs $0xffff800000003890,%rbx
ffff800000005245:	80 ff ff 
ffff800000005248:	48 bf a8 66 00 00 00 	movabs $0xffff8000000066a8,%rdi
ffff80000000524f:	80 ff ff 
ffff800000005252:	ff d3                	call   *%rbx
ffff800000005254:	48 bf 79 67 00 00 00 	movabs $0xffff800000006779,%rdi
ffff80000000525b:	80 ff ff 
ffff80000000525e:	ff d3                	call   *%rbx
ffff800000005260:	48 bf ce 66 00 00 00 	movabs $0xffff8000000066ce,%rdi
ffff800000005267:	80 ff ff 
ffff80000000526a:	ff d3                	call   *%rbx
ffff80000000526c:	48 bf d3 66 00 00 00 	movabs $0xffff8000000066d3,%rdi
ffff800000005273:	80 ff ff 
ffff800000005276:	ff d3                	call   *%rbx
ffff800000005278:	48 bf e1 66 00 00 00 	movabs $0xffff8000000066e1,%rdi
ffff80000000527f:	80 ff ff 
ffff800000005282:	ff d3                	call   *%rbx
ffff800000005284:	bf 64 00 00 00       	mov    $0x64,%edi
ffff800000005289:	48 b8 a0 39 00 00 00 	movabs $0xffff8000000039a0,%rax
ffff800000005290:	80 ff ff 
ffff800000005293:	ff d0                	call   *%rax
ffff800000005295:	0f 1f 00             	nopl   (%rax)
ffff800000005298:	f4                   	hlt    
ffff800000005299:	eb fd                	jmp    ffff800000005298 <run_all_kernel_tests+0x4a8>
ffff80000000529b:	4c 89 ff             	mov    %r15,%rdi
ffff80000000529e:	41 ff d6             	call   *%r14
ffff8000000052a1:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000052a5:	4c 89 f0             	mov    %r14,%rax
ffff8000000052a8:	48 bf 70 66 00 00 00 	movabs $0xffff800000006670,%rdi
ffff8000000052af:	80 ff ff 
ffff8000000052b2:	5b                   	pop    %rbx
ffff8000000052b3:	5d                   	pop    %rbp
ffff8000000052b4:	41 5c                	pop    %r12
ffff8000000052b6:	41 5d                	pop    %r13
ffff8000000052b8:	41 5e                	pop    %r14
ffff8000000052ba:	41 5f                	pop    %r15
ffff8000000052bc:	ff e0                	jmp    *%rax
ffff8000000052be:	66 90                	xchg   %ax,%ax

ffff8000000052c0 <thread_init>:
ffff8000000052c0:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff8000000052c7:	80 ff ff 
ffff8000000052ca:	48 83 ec 08          	sub    $0x8,%rsp
ffff8000000052ce:	31 c0                	xor    %eax,%eax
ffff8000000052d0:	ff d2                	call   *%rdx
ffff8000000052d2:	48 ba 00 00 00 00 00 	movabs $0xffff800000000000,%rdx
ffff8000000052d9:	80 ff ff 
ffff8000000052dc:	48 b9 05 00 00 00 05 	movabs $0x500000005,%rcx
ffff8000000052e3:	00 00 00 
ffff8000000052e6:	48 01 d0             	add    %rdx,%rax
ffff8000000052e9:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%rax)
ffff8000000052f0:	48 89 48 10          	mov    %rcx,0x10(%rax)
ffff8000000052f4:	48 c7 40 38 00 00 07 	movq   $0x70000,0x38(%rax)
ffff8000000052fb:	00 
ffff8000000052fc:	48 89 40 18          	mov    %rax,0x18(%rax)
ffff800000005300:	48 a3 f0 8a 00 00 00 	movabs %rax,0xffff800000008af0
ffff800000005307:	80 ff ff 
ffff80000000530a:	48 83 c4 08          	add    $0x8,%rsp
ffff80000000530e:	c3                   	ret    
ffff80000000530f:	90                   	nop

ffff800000005310 <thread_create>:
ffff800000005310:	48 ba 50 2e 00 00 00 	movabs $0xffff800000002e50,%rdx
ffff800000005317:	80 ff ff 
ffff80000000531a:	55                   	push   %rbp
ffff80000000531b:	31 c0                	xor    %eax,%eax
ffff80000000531d:	48 89 fd             	mov    %rdi,%rbp
ffff800000005320:	53                   	push   %rbx
ffff800000005321:	89 f3                	mov    %esi,%ebx
ffff800000005323:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000005327:	ff d2                	call   *%rdx
ffff800000005329:	49 b8 00 00 00 00 00 	movabs $0xffff800000000000,%r8
ffff800000005330:	80 ff ff 
ffff800000005333:	48 ba c8 0f 00 00 00 	movabs $0xffff800000000fc8,%rdx
ffff80000000533a:	80 ff ff 
ffff80000000533d:	49 01 c0             	add    %rax,%r8
ffff800000005340:	48 01 d0             	add    %rdx,%rax
ffff800000005343:	4d 89 40 08          	mov    %r8,0x8(%r8)
ffff800000005347:	41 89 58 10          	mov    %ebx,0x10(%r8)
ffff80000000534b:	41 89 58 14          	mov    %ebx,0x14(%r8)
ffff80000000534f:	49 c7 40 18 00 00 00 	movq   $0x0,0x18(%r8)
ffff800000005356:	00 
ffff800000005357:	41 c7 40 20 00 00 00 	movl   $0x0,0x20(%r8)
ffff80000000535e:	00 
ffff80000000535f:	49 c7 40 38 00 00 07 	movq   $0x70000,0x38(%r8)
ffff800000005366:	00 
ffff800000005367:	48 89 68 30          	mov    %rbp,0x30(%rax)
ffff80000000536b:	48 c7 40 28 00 00 00 	movq   $0x0,0x28(%rax)
ffff800000005372:	00 
ffff800000005373:	48 c7 40 20 00 00 00 	movq   $0x0,0x20(%rax)
ffff80000000537a:	00 
ffff80000000537b:	48 c7 40 18 00 00 00 	movq   $0x0,0x18(%rax)
ffff800000005382:	00 
ffff800000005383:	48 c7 40 10 00 00 00 	movq   $0x0,0x10(%rax)
ffff80000000538a:	00 
ffff80000000538b:	48 c7 40 08 00 00 00 	movq   $0x0,0x8(%rax)
ffff800000005392:	00 
ffff800000005393:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
ffff80000000539a:	49 89 00             	mov    %rax,(%r8)
ffff80000000539d:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000053a1:	4c 89 c0             	mov    %r8,%rax
ffff8000000053a4:	5b                   	pop    %rbx
ffff8000000053a5:	5d                   	pop    %rbp
ffff8000000053a6:	c3                   	ret    
ffff8000000053a7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff8000000053ae:	00 00 

ffff8000000053b0 <thread_append>:
ffff8000000053b0:	48 b9 f0 8a 00 00 00 	movabs $0xffff800000008af0,%rcx
ffff8000000053b7:	80 ff ff 
ffff8000000053ba:	48 8b 11             	mov    (%rcx),%rdx
ffff8000000053bd:	48 89 d0             	mov    %rdx,%rax
ffff8000000053c0:	48 85 d2             	test   %rdx,%rdx
ffff8000000053c3:	74 1b                	je     ffff8000000053e0 <thread_append+0x30>
ffff8000000053c5:	0f 1f 00             	nopl   (%rax)
ffff8000000053c8:	48 89 c1             	mov    %rax,%rcx
ffff8000000053cb:	48 8b 40 18          	mov    0x18(%rax),%rax
ffff8000000053cf:	48 39 c2             	cmp    %rax,%rdx
ffff8000000053d2:	75 f4                	jne    ffff8000000053c8 <thread_append+0x18>
ffff8000000053d4:	48 89 79 18          	mov    %rdi,0x18(%rcx)
ffff8000000053d8:	48 89 57 18          	mov    %rdx,0x18(%rdi)
ffff8000000053dc:	c3                   	ret    
ffff8000000053dd:	0f 1f 00             	nopl   (%rax)
ffff8000000053e0:	48 89 fa             	mov    %rdi,%rdx
ffff8000000053e3:	48 89 39             	mov    %rdi,(%rcx)
ffff8000000053e6:	48 89 57 18          	mov    %rdx,0x18(%rdi)
ffff8000000053ea:	c3                   	ret    
ffff8000000053eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff8000000053f0 <schedule>:
ffff8000000053f0:	41 54                	push   %r12
ffff8000000053f2:	55                   	push   %rbp
ffff8000000053f3:	53                   	push   %rbx
ffff8000000053f4:	48 bb f0 8a 00 00 00 	movabs $0xffff800000008af0,%rbx
ffff8000000053fb:	80 ff ff 
ffff8000000053fe:	4c 8b 23             	mov    (%rbx),%r12
ffff800000005401:	4d 85 e4             	test   %r12,%r12
ffff800000005404:	74 62                	je     ffff800000005468 <schedule+0x78>
ffff800000005406:	49 8b 6c 24 18       	mov    0x18(%r12),%rbp
ffff80000000540b:	49 39 ec             	cmp    %rbp,%r12
ffff80000000540e:	75 11                	jne    ffff800000005421 <schedule+0x31>
ffff800000005410:	eb 56                	jmp    ffff800000005468 <schedule+0x78>
ffff800000005412:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
ffff800000005418:	48 8b 6d 18          	mov    0x18(%rbp),%rbp
ffff80000000541c:	49 39 ec             	cmp    %rbp,%r12
ffff80000000541f:	74 47                	je     ffff800000005468 <schedule+0x78>
ffff800000005421:	8b 45 20             	mov    0x20(%rbp),%eax
ffff800000005424:	83 e8 01             	sub    $0x1,%eax
ffff800000005427:	83 f8 01             	cmp    $0x1,%eax
ffff80000000542a:	76 ec                	jbe    ffff800000005418 <schedule+0x28>
ffff80000000542c:	49 39 ec             	cmp    %rbp,%r12
ffff80000000542f:	74 37                	je     ffff800000005468 <schedule+0x78>
ffff800000005431:	48 8b 7d 30          	mov    0x30(%rbp),%rdi
ffff800000005435:	48 85 ff             	test   %rdi,%rdi
ffff800000005438:	75 36                	jne    ffff800000005470 <schedule+0x80>
ffff80000000543a:	48 8b 45 38          	mov    0x38(%rbp),%rax
ffff80000000543e:	49 3b 44 24 38       	cmp    0x38(%r12),%rax
ffff800000005443:	74 03                	je     ffff800000005448 <schedule+0x58>
ffff800000005445:	0f 22 d8             	mov    %rax,%cr3
ffff800000005448:	48 89 2b             	mov    %rbp,(%rbx)
ffff80000000544b:	48 89 ee             	mov    %rbp,%rsi
ffff80000000544e:	5b                   	pop    %rbx
ffff80000000544f:	4c 89 e7             	mov    %r12,%rdi
ffff800000005452:	48 b8 60 48 00 00 00 	movabs $0xffff800000004860,%rax
ffff800000005459:	80 ff ff 
ffff80000000545c:	5d                   	pop    %rbp
ffff80000000545d:	41 5c                	pop    %r12
ffff80000000545f:	ff e0                	jmp    *%rax
ffff800000005461:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000005468:	5b                   	pop    %rbx
ffff800000005469:	5d                   	pop    %rbp
ffff80000000546a:	41 5c                	pop    %r12
ffff80000000546c:	c3                   	ret    
ffff80000000546d:	0f 1f 00             	nopl   (%rax)
ffff800000005470:	48 b8 f0 23 00 00 00 	movabs $0xffff8000000023f0,%rax
ffff800000005477:	80 ff ff 
ffff80000000547a:	ff d0                	call   *%rax
ffff80000000547c:	48 8b 45 30          	mov    0x30(%rbp),%rax
ffff800000005480:	48 a3 c0 8a 00 00 00 	movabs %rax,0xffff800000008ac0
ffff800000005487:	80 ff ff 
ffff80000000548a:	eb ae                	jmp    ffff80000000543a <schedule+0x4a>
ffff80000000548c:	0f 1f 40 00          	nopl   0x0(%rax)

ffff800000005490 <thread_yield>:
ffff800000005490:	48 83 ec 08          	sub    $0x8,%rsp
ffff800000005494:	fa                   	cli    
ffff800000005495:	48 b8 f0 53 00 00 00 	movabs $0xffff8000000053f0,%rax
ffff80000000549c:	80 ff ff 
ffff80000000549f:	ff d0                	call   *%rax
ffff8000000054a1:	fb                   	sti    
ffff8000000054a2:	48 83 c4 08          	add    $0x8,%rsp
ffff8000000054a6:	c3                   	ret    
ffff8000000054a7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
ffff8000000054ae:	00 00 

ffff8000000054b0 <process_create>:
ffff8000000054b0:	41 56                	push   %r14
ffff8000000054b2:	31 c0                	xor    %eax,%eax
ffff8000000054b4:	49 be 50 2e 00 00 00 	movabs $0xffff800000002e50,%r14
ffff8000000054bb:	80 ff ff 
ffff8000000054be:	41 55                	push   %r13
ffff8000000054c0:	49 89 fd             	mov    %rdi,%r13
ffff8000000054c3:	41 54                	push   %r12
ffff8000000054c5:	55                   	push   %rbp
ffff8000000054c6:	53                   	push   %rbx
ffff8000000054c7:	89 f3                	mov    %esi,%ebx
ffff8000000054c9:	41 ff d6             	call   *%r14
ffff8000000054cc:	49 89 c4             	mov    %rax,%r12
ffff8000000054cf:	48 b8 00 00 00 00 00 	movabs $0xffff800000000000,%rax
ffff8000000054d6:	80 ff ff 
ffff8000000054d9:	49 01 c4             	add    %rax,%r12
ffff8000000054dc:	48 b8 d0 2e 00 00 00 	movabs $0xffff800000002ed0,%rax
ffff8000000054e3:	80 ff ff 
ffff8000000054e6:	41 89 5c 24 10       	mov    %ebx,0x10(%r12)
ffff8000000054eb:	41 89 5c 24 14       	mov    %ebx,0x14(%r12)
ffff8000000054f0:	4d 89 64 24 08       	mov    %r12,0x8(%r12)
ffff8000000054f5:	41 c7 44 24 20 00 00 	movl   $0x0,0x20(%r12)
ffff8000000054fc:	00 00 
ffff8000000054fe:	49 c7 44 24 28 00 00 	movq   $0x0,0x28(%r12)
ffff800000005505:	00 00 
ffff800000005507:	49 c7 44 24 18 00 00 	movq   $0x0,0x18(%r12)
ffff80000000550e:	00 00 
ffff800000005510:	ff d0                	call   *%rax
ffff800000005512:	49 8b 6c 24 08       	mov    0x8(%r12),%rbp
ffff800000005517:	49 89 44 24 38       	mov    %rax,0x38(%r12)
ffff80000000551c:	31 c0                	xor    %eax,%eax
ffff80000000551e:	48 8d 9d 00 10 00 00 	lea    0x1000(%rbp),%rbx
ffff800000005525:	49 89 5c 24 30       	mov    %rbx,0x30(%r12)
ffff80000000552a:	41 ff d6             	call   *%r14
ffff80000000552d:	49 8b 7c 24 38       	mov    0x38(%r12),%rdi
ffff800000005532:	b9 07 00 00 00       	mov    $0x7,%ecx
ffff800000005537:	be 00 00 00 c0       	mov    $0xc0000000,%esi
ffff80000000553c:	48 89 c2             	mov    %rax,%rdx
ffff80000000553f:	48 b8 40 2f 00 00 00 	movabs $0xffff800000002f40,%rax
ffff800000005546:	80 ff ff 
ffff800000005549:	ff d0                	call   *%rax
ffff80000000554b:	b8 00 10 00 c0       	mov    $0xc0001000,%eax
ffff800000005550:	4c 89 ad d8 0f 00 00 	mov    %r13,0xfd8(%rbp)
ffff800000005557:	48 b9 c4 56 00 00 00 	movabs $0xffff8000000056c4,%rcx
ffff80000000555e:	80 ff ff 
ffff800000005561:	48 89 85 f0 0f 00 00 	mov    %rax,0xff0(%rbp)
ffff800000005568:	48 8d 85 a0 0f 00 00 	lea    0xfa0(%rbp),%rax
ffff80000000556f:	48 c7 85 f8 0f 00 00 	movq   $0x1b,0xff8(%rbp)
ffff800000005576:	1b 00 00 00 
ffff80000000557a:	48 c7 85 e8 0f 00 00 	movq   $0x202,0xfe8(%rbp)
ffff800000005581:	02 02 00 00 
ffff800000005585:	48 c7 85 e0 0f 00 00 	movq   $0x23,0xfe0(%rbp)
ffff80000000558c:	23 00 00 00 
ffff800000005590:	48 89 8d d0 0f 00 00 	mov    %rcx,0xfd0(%rbp)
ffff800000005597:	48 c7 85 c8 0f 00 00 	movq   $0x0,0xfc8(%rbp)
ffff80000000559e:	00 00 00 00 
ffff8000000055a2:	48 c7 85 c0 0f 00 00 	movq   $0x0,0xfc0(%rbp)
ffff8000000055a9:	00 00 00 00 
ffff8000000055ad:	48 c7 85 b8 0f 00 00 	movq   $0x0,0xfb8(%rbp)
ffff8000000055b4:	00 00 00 00 
ffff8000000055b8:	48 c7 85 b0 0f 00 00 	movq   $0x0,0xfb0(%rbp)
ffff8000000055bf:	00 00 00 00 
ffff8000000055c3:	48 c7 85 a8 0f 00 00 	movq   $0x0,0xfa8(%rbp)
ffff8000000055ca:	00 00 00 00 
ffff8000000055ce:	48 c7 85 a0 0f 00 00 	movq   $0x0,0xfa0(%rbp)
ffff8000000055d5:	00 00 00 00 
ffff8000000055d9:	49 89 04 24          	mov    %rax,(%r12)
ffff8000000055dd:	4c 89 e0             	mov    %r12,%rax
ffff8000000055e0:	5b                   	pop    %rbx
ffff8000000055e1:	5d                   	pop    %rbp
ffff8000000055e2:	41 5c                	pop    %r12
ffff8000000055e4:	41 5d                	pop    %r13
ffff8000000055e6:	41 5e                	pop    %r14
ffff8000000055e8:	c3                   	ret    
ffff8000000055e9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

ffff8000000055f0 <thread_exit>:
ffff8000000055f0:	48 a1 f0 8a 00 00 00 	movabs 0xffff800000008af0,%rax
ffff8000000055f7:	80 ff ff 
ffff8000000055fa:	53                   	push   %rbx
ffff8000000055fb:	48 bb f0 53 00 00 00 	movabs $0xffff8000000053f0,%rbx
ffff800000005602:	80 ff ff 
ffff800000005605:	c7 40 20 02 00 00 00 	movl   $0x2,0x20(%rax)
ffff80000000560c:	0f 1f 40 00          	nopl   0x0(%rax)
ffff800000005610:	fa                   	cli    
ffff800000005611:	ff d3                	call   *%rbx
ffff800000005613:	fb                   	sti    
ffff800000005614:	eb fa                	jmp    ffff800000005610 <thread_exit+0x20>
ffff800000005616:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
ffff80000000561d:	00 00 00 

ffff800000005620 <timer_init>:
ffff800000005620:	b8 36 00 00 00       	mov    $0x36,%eax
ffff800000005625:	e6 43                	out    %al,$0x43
ffff800000005627:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
ffff80000000562c:	e6 40                	out    %al,$0x40
ffff80000000562e:	b8 2e 00 00 00       	mov    $0x2e,%eax
ffff800000005633:	e6 40                	out    %al,$0x40
ffff800000005635:	48 bf 90 67 00 00 00 	movabs $0xffff800000006790,%rdi
ffff80000000563c:	80 ff ff 
ffff80000000563f:	48 b8 20 35 00 00 00 	movabs $0xffff800000003520,%rax
ffff800000005646:	80 ff ff 
ffff800000005649:	ff e0                	jmp    *%rax
ffff80000000564b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

ffff800000005650 <timer_interrupt_handler>:
ffff800000005650:	b8 20 00 00 00       	mov    $0x20,%eax
ffff800000005655:	e6 20                	out    %al,$0x20
ffff800000005657:	48 ba f8 8a 00 00 00 	movabs $0xffff800000008af8,%rdx
ffff80000000565e:	80 ff ff 
ffff800000005661:	48 8b 02             	mov    (%rdx),%rax
ffff800000005664:	48 83 c0 01          	add    $0x1,%rax
ffff800000005668:	48 89 02             	mov    %rax,(%rdx)
ffff80000000566b:	48 a1 f0 8a 00 00 00 	movabs 0xffff800000008af0,%rax
ffff800000005672:	80 ff ff 
ffff800000005675:	48 85 c0             	test   %rax,%rax
ffff800000005678:	74 06                	je     ffff800000005680 <timer_interrupt_handler+0x30>
ffff80000000567a:	83 68 10 01          	subl   $0x1,0x10(%rax)
ffff80000000567e:	74 08                	je     ffff800000005688 <timer_interrupt_handler+0x38>
ffff800000005680:	c3                   	ret    
ffff800000005681:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
ffff800000005688:	8b 50 14             	mov    0x14(%rax),%edx
ffff80000000568b:	89 50 10             	mov    %edx,0x10(%rax)
ffff80000000568e:	48 b8 f0 53 00 00 00 	movabs $0xffff8000000053f0,%rax
ffff800000005695:	80 ff ff 
ffff800000005698:	ff e0                	jmp    *%rax

ffff80000000569a <enter_user_mode>:
ffff80000000569a:	fa                   	cli    
ffff80000000569b:	0f 22 da             	mov    %rdx,%cr3
ffff80000000569e:	31 c0                	xor    %eax,%eax
ffff8000000056a0:	8e d8                	mov    %eax,%ds
ffff8000000056a2:	8e c0                	mov    %eax,%es
ffff8000000056a4:	8e e0                	mov    %eax,%fs
ffff8000000056a6:	8e e8                	mov    %eax,%gs
ffff8000000056a8:	48 c7 c0 1b 00 00 00 	mov    $0x1b,%rax
ffff8000000056af:	50                   	push   %rax
ffff8000000056b0:	56                   	push   %rsi
ffff8000000056b1:	48 c7 c0 02 02 00 00 	mov    $0x202,%rax
ffff8000000056b8:	50                   	push   %rax
ffff8000000056b9:	48 c7 c0 23 00 00 00 	mov    $0x23,%rax
ffff8000000056c0:	50                   	push   %rax
ffff8000000056c1:	57                   	push   %rdi
ffff8000000056c2:	48 cf                	iretq  

ffff8000000056c4 <return_to_user>:
ffff8000000056c4:	48 cf                	iretq  
