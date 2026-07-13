; boot/loader.S
; ------------------------------------------------------------
SECTION LOADER vstart=0x900

; 入口跳转：跳过数据区
jmp loader_start

; 1. 32 位保护模式 GDT 定义
; ------------------------------------------------------------
GDT_BASE:
    dd 0x00000000, 0x00000000    ; 空描述符
CODE_DESC:
    dd 0x0000FFFF, 0x00CF9A00    ; 32位代码段描述符
DATA_DESC:
    dd 0x0000FFFF, 0x00CF9200    ; 32位数据段描述符

GDT_SIZE  equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1

SELECTOR_CODE equ (1 << 3)
SELECTOR_DATA equ (2 << 3)

gdt_ptr:
    dw GDT_LIMIT
    dd GDT_BASE

; 2. 64 位长模式 GDT 定义 (进入 64 位后需要重新加载它)
; ------------------------------------------------------------
GDT64_BASE:
    dd 0x00000000, 0x00000000    ; 空描述符
GDT64_CODE:
    dd 0x00000000, 0x00209A00    ; 64位代码段描述符 (L位=1, D位=0)
GDT64_DATA:
    dd 0x00000000, 0x00009200    ; 64位数据段描述符

GDT64_SIZE  equ $ - GDT64_BASE
GDT64_LIMIT equ GDT64_SIZE - 1

SELECTOR_CODE64 equ (1 << 3)
SELECTOR_DATA64 equ (2 << 3)

gdt64_ptr:
    dw GDT64_LIMIT
    dd GDT64_BASE

; 3. 16 位实模式入口
; ------------------------------------------------------------
[bits 16]
loader_start:
    ; 实模式下打印 'L'
    mov byte [gs:0x04], 'L'
    mov byte [gs:0x05], 0x2A   

    ; ① 开启 A20 地址线
    in al, 0x92
    or al, 0x02
    out 0x92, al

    ; ② 加载 32 位 GDT
    lgdt [gdt_ptr]

    ; ③ 开启保护模式
    mov eax, cr0
    or eax, 0x00000001
    mov cr0, eax

    ; ④ 远跳转进入 32 位保护模式
    jmp dword SELECTOR_CODE:p_mode_start

; 4. 32 位保护模式入口（在此处构建页表，准备起飞）
; ------------------------------------------------------------
[bits 32]
p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x9000

    ; 打印 'P'
    mov byte [0xb8006], 'P'
    mov byte [0xb8007], 0x2E     

    ; ------------------------------------------------------------
    ; 核心任务一：在内存中创建 64 位 4 级页表并建立映射
    ; 我们将页表存放在物理地址 0x70000 开始的安全内存区
    ; ------------------------------------------------------------
    ; 1. 先将 0x70000 到 0x73000 (共 3 个物理页，12KB) 清零
    mov edi, 0x70000
    mov ecx, 3072               ; 12KB / 4 = 3072 次双字清零
    xor eax, eax
    rep stosd                   ; 循环向 [edi] 写入 eax (0)

    ; 2. 填充第 4 级页表 PML4 (在 0x70000 处)
    ; 将 PML4 的第 0 个入口，指向第 3 级页表 PDPT (在 0x71000 处)
    ; 属性设置为 0x03 (存在 Present + 可读写 Read/Write)
    mov dword [0x70000], 0x71000 + 0x03

    ; 3. 填充第 3 级页表 PDPT (在 0x71000 处)
    ; 将 PDPT 的第 0 个入口，指向第 2 级页表 PD (在 0x72000 处)
    mov dword [0x71000], 0x72000 + 0x03

    ; 4. 填充第 2 级页表 PD (在 0x72000 处)
    ; 我们循环填充 512 个入口，每个入口映射 2MB 的大页 (2MB * 512 = 1GB 物理内存对等映射)
    ; 每个页表项属性为 0x83 (存在 Present + 可读写 Read/Write + 页大小 PageSize为1)
    mov ecx, 0                  ; 循环计数器
    mov edi, 0x72000            ; PD 页表首地址
.map_pd:
    mov eax, ecx
    shl eax, 21                 ; eax = ecx * 2MB (计算当前大页的起始物理地址)
    or eax, 0x83                ; 加上 0x83 属性位
    mov [edi], eax              ; 写入低 32 位
    mov dword [edi+4], 0        ; 64位项，高 32 位填 0
    add edi, 8                  ; 一个 64 位页表项占用 8 字节
    inc ecx
    cmp ecx, 512                ; 循环 512 次，填满这 1 页 PD
    jne .map_pd

    ; ------------------------------------------------------------
    ; 核心任务二：加载页表，开启 64 位开关
    ; ------------------------------------------------------------
    ; 1. 将 PML4 的地址 0x70000 加载到 CR3 寄存器
    mov eax, 0x70000
    mov cr3, eax

    ; 2. 开启 PAE 物理地址扩展 (CR4 寄存器的第 5 位置 1)
    mov eax, cr4
    or eax, 0x00000020
    mov cr4, eax

    ; 3. 开启长模式使能 LME (向 EFER MSR 的第 8 位置 1)
    mov ecx, 0xC0000080         ; EFER MSR 地址
    rdmsr                       ; 读取 MSR 的值到 edx:eax
    or eax, 0x00000100          ; 将第 8 位 (LME) 置 1
    wrmsr                       ; 写回 MSR

    ; 4. 开启分页机制 (CR0 寄存器的 PG 位置 1)
    mov eax, cr0
    or eax, 0x80000000          ; 将第 31 位 (PG) 置 1
    mov cr0, eax

    ; 5. 加载全新的 64 位长模式 GDT 表
    lgdt [gdt64_ptr]

    ; 6. 最后的 64 位远跳转！跳入 64 位代码段
    jmp SELECTOR_CODE64:long_mode_start


; 5. 64 位长模式入口代码
; ------------------------------------------------------------
[bits 64]
long_mode_start:
    ; 在 64 位下，将段寄存器清零 (64位下大都强制为 0)
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; 建立一个 64 位的安全栈顶 (0x90000 处)
    mov rsp, 0x90000

    ; 【终极见证】往屏幕第四个位置打印一个红底白字的 '6'
    ; 代表你成功进入了 64-bit Long Mode！
    mov byte [0xb8008], '6'
    mov byte [0xb8009], 0x4F     ; 红底白字

    ; 通过 64 位寄存器过渡，绝对跳转到物理地址 0x1900（即 C 语言内核入口）
    mov rax, 0x1900
    jmp rax