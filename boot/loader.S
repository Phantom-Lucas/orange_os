; boot/loader.S
; ------------------------------------------------------------
SECTION LOADER vstart=0x900

%ifndef KERNEL_SECTORS
    %error "KERNEL_SECTORS must be provided by the build"
%endif

KERNEL_START_LBA          equ 10
KERNEL_PRELOADED_SECTORS  equ 42
KERNEL_TAIL_START_LBA     equ KERNEL_START_LBA + KERNEL_PRELOADED_SECTORS
KERNEL_TAIL_SECTORS       equ KERNEL_SECTORS - KERNEL_PRELOADED_SECTORS

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

; 2. 64 位长模式 GDT 定义 (平坦模式 flat model，提高硬件兼容性)
; ------------------------------------------------------------
GDT64_BASE:
    dd 0x00000000, 0x00000000    ; 空描述符
GDT64_CODE:
    dd 0x0000FFFF, 0x00AF9A00    ; 64位平坦代码段描述符 (L位=1, G位=1, Limit最大)
GDT64_DATA:
    dd 0x0000FFFF, 0x00CF9200    ; 64位平坦数据段描述符 (G位=1, Limit最大)

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
    cli
    ; 实模式下打印 'L'
    mov byte [gs:0x04], 'L'
    mov byte [gs:0x05], 0x2A   

    ; =========================================================
    ; 新增任务：BIOS e820 获取物理内存布局 (时空胶囊埋设)
    ; =========================================================
    ; 1. 初始化寄存器环境
    xor ax, ax
    mov es, ax              ; 将 ES 段寄存器清零，确保 ES:DI 精准指向物理地址
    mov di, 0x504           ; DI 指向 0x504，这是第一个 ARDS 结构体存入的物理地址
    xor ebx, ebx            ; ebx 清零，这是 BIOS 要求的首次调用“书签”
    xor ebp, ebp            ; ebp 清零，我们用它来当计数器，记录一共探测到了几块内存

.e820_loop_start:
    ; 2. 设置三大接头暗号
    mov eax, 0x0000E820     ; 暗号1：子功能号 E820
    mov edx, 0x534D4150     ; 暗号2："SMAP" 的 ASCII 码防伪签名
    mov ecx, 20             ; 暗号3：告诉 BIOS 我们准备的缓冲区大小是 20 字节

    ; 3. 呼叫 BIOS 大爷
    int 0x15

    ; 4. 严苛的错误检查
    jc .e820_done           ; 如果 CF=1，说明探测结束了（或者发生错误），直接跳到结束保存阶段
    cmp eax, 0x534D4150     ; 检查 BIOS 是否把 eax 设为了 "SMAP"
    jne .e820_failed        ; 如果不是，说明主板不支持 e820，跳到失败死机处理

    ; 5. 成功获取一块，保存战果
    inc ebp                 ; 计数器加 1 (又发现了一块内存)
    add di, 20              ; 笔尖向后移动 20 字节，准备给下一次存放腾出空间

    ; 6. 判断是否彻底查完
    cmp ebx, 0              ; BIOS 如果把 ebx 变成了 0，说明后面没内存了
    jne .e820_loop_start    ; 如果 ebx 不为 0，跳回循环开头，继续要下一块！

.e820_done:
    ; 7. 封存时空胶囊：把总数写入 0x500
    mov dword [0x500], ebp 
    jmp .e820_success_continue ; 成功搞定，跳过错误处理代码，继续往下走

.e820_failed:
    ; 如果不幸来到这里，说明主板太老不支持，直接打印个红色的 'E' 然后死机
    mov byte [gs:0x00], 'E'
    mov byte [gs:0x01], 0x4F
    jmp $                   ; 死循环停在这里

.e820_success_continue:

    ; =========================================================
    ; MBR 只能安全读取到 0x6D00，避免覆盖自身位于 0x7C00 的代码。
    ; 现在 Loader 已在 0x900 运行，因此由它按构建时注入的实际内核大小
    ; 继续加载 LBA 52 之后的尾部，不再维护固定的 188-sector 窗口。
    ; 调用栈放在 0x1800，避开即将写入的内核区域。
    ; =========================================================
    mov sp, 0x1800
    ; 使用 EBX 作为 32 位物理写入游标，避免超过 64KiB 后 BX 回绕，
    ; 覆盖 IVT、E820 表和 BIOS 数据。
    mov ebx, 0x6d00
%if KERNEL_TAIL_SECTORS > 0
    mov dword [kernel_tail_lba], KERNEL_TAIL_START_LBA
    mov word [kernel_tail_remaining], KERNEL_TAIL_SECTORS
    call rd_disk_many_16
%endif

    ; =========================================================
    ; 内存探测结束，时空胶囊已埋在 0x8000，继续原本的保护模式流程
    ; =========================================================

    
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

; ------------------------------------------------------------
; Loader 阶段只读取固定低端的内核镜像，因此保留短小的 28 位兼容
; PIO 读盘函数；内核接管后的文件系统 I/O 统一由 LBA48 驱动负责。
; 调用约定与 MBR 中的版本一致：
; EAX=LBA, BX=目标物理地址, CX=扇区数。
; ------------------------------------------------------------
rd_disk_many_16:
.next_chunk:
    mov ax, [kernel_tail_remaining]
    cmp ax, 255
    jbe .last_chunk
    mov cx, 255
    jmp .read_chunk
.last_chunk:
    mov cx, ax
.read_chunk:
    mov [kernel_tail_chunk], cx
    mov eax, [kernel_tail_lba]
    call rd_disk_m_16
    movzx eax, word [kernel_tail_chunk]
    add [kernel_tail_lba], eax
    sub [kernel_tail_remaining], ax
    jnz .next_chunk
    ret

rd_disk_m_16:
    mov esi, eax
    mov di, cx

    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi
    mov dx, 0x1f3
    out dx, al
    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al
    shr eax, cl
    mov dx, 0x1f5
    out dx, al
    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

.read_sector_loop:
    mov dx, 0x1f7
.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jne .not_ready

    mov cx, 256
    mov dx, 0x1f0
.read_word_loop:
    in ax, dx
    mov [ebx], ax
    add ebx, 2
    loop .read_word_loop

    dec di
    jnz .read_sector_loop
    ret

kernel_tail_lba:       dd 0
kernel_tail_remaining: dw 0
kernel_tail_chunk:     dw 0

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
    ; 属性设置为 0x07 (存在 Present + 可读写 Read/Write)
    mov dword [0x70000], 0x71000 + 0x07

    ; ========================================================
    ; 【新增代码】：建立高半区内核映射！
    ; 虚拟地址 0xFFFF800000000000 对应的 PML4 索引是 256
    ; 偏移量 = 256 * 8 字节 = 2048 = 0x800
    ; 让 PML4[256] 也指向同一个 PDPT，实现物理内存的高端映射
    ; ========================================================
    mov dword [0x70800], 0x71000 + 0x07

    ; 3. 填充第 3 级页表 PDPT (在 0x71000 处)
    ; 将 PDPT 的第 0 个入口，指向第 2 级页表 PD (在 0x72000 处)
    mov dword [0x71000], 0x72000 + 0x07

    ; 4. 填充第 2 级页表 PD (在 0x72000 处)
    ; 我们循环填充 512 个入口，每个入口映射 2MB 的大页 (2MB * 512 = 1GB 物理内存对等映射)
    ; 每个页表项属性为 0x83 (存在 Present + 可读写 Read/Write + 页大小 PageSize为1)
    mov ecx, 0                  ; 循环计数器
    mov edi, 0x72000            ; PD 页表首地址
.map_pd:
    mov eax, ecx
    shl eax, 21                 ; eax = ecx * 2MB (计算当前大页的起始物理地址)
    or eax, 0x87                ; 加上 0x87 属性位
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
; boot/loader.S 的 long_mode_start 部分
[bits 64]
long_mode_start:
    ; 初始化段寄存器为标准的 64 位平坦数据段选择子 (0x10)
    mov ax, SELECTOR_DATA64
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    xor ax, ax
    mov fs, ax
    mov gs, ax

    ; 建立一个 64 位的安全栈顶 (0x90000 处)
   mov rsp, 0xFFFF800000090000

   ; 往屏幕第四个位置打印一个红底白字的 '6'
    mov byte [0xb8008], '6'
    mov byte [0xb8009], 0x4F     ; 红底白字

    ; ========================================================
    ; 直接跃迁到 64 位 C 语言内核！起飞！
    ; ========================================================
    mov rax, 0xFFFF800000001900
    jmp rax
    jmp $
