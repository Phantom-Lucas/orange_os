; boot/mbr.S
; ------------------------------------------------------------
SECTION MBR vstart=0x7c00
    jmp 0x0000:start

start:
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
    mov byte [gs:0x01], 0xA4   ; 绿底红字（由于闪烁位原因，QEMU里可能会显示为一个绿块）

    ; 2. 准备读取 Loader 并加载到内存的 0x900 处
    mov ax, 2           ; LBA 2
    mov bx, 0x900       ; 物理地址 0x900
    mov cx, 50          ; 连续读 50 个扇区，把后面的 C 内核也一起读进来！
    call rd_disk_m_16

    ; 3. 【调试哨兵】如果读盘成功返回了，我们在这里打一个黄色的 'S' (Success)
    ; 如果屏幕上成功亮起了 'S'，说明读盘完全成功，问题出在 Loader 内部！
    ; 如果没有亮起 'S'，说明 MBR 读盘卡死在等待硬盘（.not_ready 循环）里了！
    mov byte [gs:0x02], 'S'
    mov byte [gs:0x03], 0x2E   ; 绿底黄字

    ; 4. 跳转到 Loader 的物理地址
    ; 为了绝对安全和消除歧义，我们使用 16 位远跳转直接跳转到 0x0000:0x0900
    jmp 0x0000:0x0900

; ------------------------------------------------------------
; 读盘函数：rd_disk_m_16
; ------------------------------------------------------------
rd_disk_m_16:
    mov esi, eax        ; 备份 eax
    mov di, cx          ; 备份 cx

    ; 第一步：写入要读取的扇区数
    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi        ; 还原 eax

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

    ; 第三步：往 Command 寄存器 (0x1f7) 写入读命令 0x20
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

    ; 第四步：检测硬盘状态 (等待硬盘准备好数据)
.not_ready:
    nop
    in al, dx           
    and al, 0x88        
    cmp al, 0x08        
    jne .not_ready      

    ; 第五步：从 Data 寄存器 (0x1f0) 读取数据
    mov ax, di          
    mov dx, 256         
    mul dx              
    mov cx, ax          
    
    mov dx, 0x1f0       
.go_on_read:
    in ax, dx           
    mov [bx], ax        
    add bx, 2           
    loop .go_on_read    
    ret

; 填充引导扇区
    times 510-($-$$) db 0
    db 0x55, 0xaa