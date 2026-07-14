; boot/mbr.S
; ------------------------------------------------------------
SECTION MBR vstart=0x7c00
    jmp 0x0000:start

start:
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00

    ; 初始化显存段寄存器 gs 指向文本模式显存（0xb8000）
    mov ax, 0xb800
    mov gs, ax

    ; 1. 在屏幕上打一个 'M' (代表 MBR 正在运行)
    mov byte [gs:0x00], 'M'
    mov byte [gs:0x01], 0xA4   ; 绿底红字

    ; 2. 准备读取 Loader 并加载到内存的 0x900 处
    ; ！！！极其重要：必须用 eax，确保高 16 位完全清零，防止加载到垃圾 LBA 地址！！！
    mov eax, 2          
    mov bx, 0x900       ; 物理地址 0x900
    mov cx, 50          ; 连续读 50 个扇区，把后面的 C 内核也一起读进来！
    call rd_disk_m_16

    ; 3. 【调试哨兵】如果读盘成功返回了，我们在这里打一个黄色的 'S' (Success)
    mov byte [gs:0x02], 'S'
    mov byte [gs:0x03], 0x2E   ; 绿底黄字

    ; 4. 跳转到 Loader 的物理地址
    jmp 0x0000:0x0900

; ------------------------------------------------------------
; 修复后的读盘函数：必须为每一个扇区等待 DRQ 准备就绪
; ------------------------------------------------------------
rd_disk_m_16:
    mov esi, eax        ; 备份 LBA 扇区号
    mov di, cx          ; 备份 要读取的扇区数量

    ; 第一步：写入要读取的扇区数
    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi        ; 还原 LBA

    ; 第二步：写入 LBA 地址 (LBA28 方式)
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

    ; 第三步：往 Command 寄存器写入读命令 0x20
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

    ; 【关键修复】：使用外层循环处理扇区，确保每个扇区都重新检查状态
.read_sector_loop:
    
    ; 第四步：检测硬盘状态 (每次读取一个扇区前，都必须等待数据就绪！)
    mov dx, 0x1f7
.not_ready:
    nop
    in al, dx           
    and al, 0x88        ; 提取 BUSY (bit 7) 和 DRQ (bit 3)
    cmp al, 0x08        ; 必须满足 BUSY=0 且 DRQ=1
    jne .not_ready      

    ; 第五步：读取 1 个扇区的数据（256 个字）
    mov cx, 256         
    mov dx, 0x1f0       
.go_on_read:
    in ax, dx           
    mov [bx], ax        
    add bx, 2           
    loop .go_on_read    
    
    ; 检查是否还有扇区没读完，如果没读完就跳回外层循环
    dec di
    jnz .read_sector_loop

    ret

; 填充引导扇区
    times 510-($-$$) db 0
    db 0x55, 0xaa