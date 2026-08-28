# MiniOrangeOS 答辩 PPT 逐页文案（12 页 / 10 分钟）

以下“页面正文”可以直接复制到 PPT。正文使用 `MiniOrangeOS`，如果最终项目名改回
`Orange/64`，需要同时替换报告、PPT 和系统截图中的名称。

---

## P1 MiniOrangeOS：从 MBR 到 Ring 3

### 页面标题

```text
MiniOrangeOS：从 MBR 到 Ring 3
```

### 页面副标题

```text
面向 x86-64 与 QEMU 的单核教学操作系统
```

### 页面正文

```text
李晨恺  2453875  第 98 组
指导教师：王冬青

自制启动链 · 64 位内核 · Ring 3 用户态
进程线程 · 虚拟内存 · MyFS · TTY · Shell
```

右侧放系统启动后的真实 framebuffer 截图，画面保留 Shell 提示符：

```text
orange@orange-os:/$
```

### 讲解

MiniOrangeOS 是一个运行在 x86-64 QEMU 环境中的单核操作系统。系统不依赖 GRUB，从自己的
MBR 和二级 Loader 启动，进入 64 位高半区内核，最后运行 Ring 3 Shell 和用户程序。

---

## P2 系统贯通了启动、内核和用户态

### 页面标题

```text
系统贯通了启动、内核和用户态
```

### 页面正文

使用五个模块框：

```text
裸机启动
MBR / Loader / E820 / 长模式 / 高半区

内存隔离
页帧 / 四级页表 / 独立 CR3 / VMA / COW

进程并发
fork / exec / wait / 线程 / 调度 / IPC / futex

存储与终端
ATA LBA48 / MyFS / TTY / framebuffer

用户环境
crt0 / libc / Shell / 管道 / 重定向 / 20+ 程序
```

页面底部放三个数字：

```text
36 个系统调用        3 个虚拟控制台        16/16 完整测试通过
```

右下角写运行范围：

```text
x86-64 · BIOS · QEMU · 1 vCPU
```

### 讲解

系统从硬件启动入口一直实现到用户应用。内核提供内存、进程、线程、文件和终端等基础能力，
用户程序只能通过系统调用访问这些资源。

---

## P3 启动阶段建立环境，运行阶段按特权级分层

### 页面标题

```text
启动阶段建立环境，运行阶段按特权级分层
```

### 页面主图

```text
启动阶段                              运行时架构

BIOS / QEMU                 ┌─────────────────────────────────────┐
    ↓                       │ Ring 3 用户态                       │
MBR（磁盘第一个 512 B）      │ Shell / cat / ls / ps / 用户程序    │
    ↓                       │ crt0 / libc                         │
二级 Loader                 └─────────────────┬───────────────────┘
    │                                         │ SYSCALL ↓  ↑ SYSRET
    ├─ 读取完整内核            ┌───────────────▼───────────────────┐
    ├─ E820 内存探测           │ Ring 0 系统调用与异常入口          │
    ├─ 建立临时四级页表         │ syscall / copyin-copyout / IDT     │
    └─ 进入 x86-64 长模式       ├───────────────────────────────────┤
    ↓                         │ Ring 0 内核核心                    │
kernel_main ────────────────→ │ 进程/线程/调度  PMM/页表/VMA/COW   │
                              │ IPC/futex       文件/pipe/MyFS     │
                              │ TTY/Console                        │
                              ├───────────────────────────────────┤
                              │ Ring 0 驱动                        │
                              │ 时钟/PIC  ATA  键盘  framebuffer   │
                              └─────────────────┬───────────────────┘
                                                ↓
                              ┌─────────────────────────────────────┐
                              │ 硬件：CPU / 内存 / 磁盘 / 键盘 / 显示 │
                              └─────────────────────────────────────┘
```

### 页面正文

```text
Boot：把内核读入内存，并把 CPU 切换到 64 位模式
Ring 0：管理内存、进程、文件和硬件
Ring 3：运行 Shell 和普通用户程序
SYSCALL / SYSRET：用户程序进入内核并返回

kernel_main 初始化顺序：
BSS → 内存 → 中断 → 调度 → 系统调用 → 磁盘/文件系统 → TTY → 用户程序
```

### 讲解

Boot 不是一种 CPU 特权级，而是内核运行前的启动阶段。BIOS 加载 MBR，MBR 加载二级 Loader，
Loader 读取完整内核、探测内存、建立临时页表并进入 64 位模式，最后跳到 `kernel_main`。

系统进入运行阶段后才按特权级分层：普通程序运行在 Ring 3，不能直接访问页表、磁盘和键盘；
它们通过 SYSCALL 进入 Ring 0。Ring 0 的系统调用入口检查参数后，把请求交给内存、调度、文件
或 TTY 模块；底层驱动再访问硬件，完成后通过 SYSRET 返回用户程序。

---

## P4 Loader 完成长模式切换并建立 Ring 3 基础

### 页面标题

```text
Loader 完成长模式切换并建立 Ring 3 基础
```

### 左侧：启动流程

```text
BIOS 加载 MBR 到 0x7C00
        ↓
MBR 读取 Loader 和内核前 42 个扇区
        ↓
Loader 读取剩余内核并执行 E820 探测
        ↓
打开 A20，建立 GDT 和临时四级页表
        ↓
CR4.PAE → EFER.LME → CR0.PG
        ↓
进入 64 位高半区 kernel_main
```

### 右侧：磁盘布局

```text
LBA 0       MBR
LBA 2～9    Loader
LBA 10～    Kernel
LBA 1000～  MyFS
```

### 页面底部

```text
kernel_sectors = (kernel_bytes + 511) / 512

磁盘边界：Kernel 不能覆盖 MyFS
物理边界：Kernel + .bss 不能覆盖 0x70000 启动页表

超过 255 个扇区时分块读取
300 扇区测试内核成功进入 Ring 3
```

### Ring 3 保护

```text
GDT：内核段与用户段
TSS：Ring 3 进入 Ring 0 时提供内核栈
IDT：异常、时钟和键盘中断入口
用户异常：结束当前进程
内核异常：输出现场并 panic
```

### 讲解

Loader 读取的内核大小由构建系统动态计算，不再依赖固定扇区数。进入内核后，GDT、TSS、IDT
和页表权限共同形成 Ring 0 与 Ring 3 的保护边界。

---

## P5 四级页表提供独立地址空间与 COW

### 页面标题

```text
四级页表提供独立地址空间与 COW
```

### 左侧：内存结构

```text
物理内存：4 KiB 页帧
页表层级：PML4 → PDPT → PD → PT → Page

每个用户进程：独立 CR3、用户页表和 VMA
所有用户进程：共享受保护的内核高半区映射

PTE 权限：Present / Writable / User / COW
```

### 中间：VMA 与页错误

```text
匿名 mmap：分配清零页并建立 VMA
munmap：解除映射并减少页引用
用户栈：初始映射 1 页，最多向下增长 8 MiB

Page Fault：
1. COW 写错误 → 分离共享页
2. 栈 VMA 缺页 → 分配新栈页
3. 其他用户错误 → 结束当前进程
4. 内核错误 → panic
```

### 右侧：COW 图

```text
fork 前
Parent ──RW──> Page P = 0x1111

fork 后
Parent ──RO+COW──┐
                 ├──> Page P
Child  ──RO+COW──┘

Child 写入后
Parent ──> Page P = 0x1111
Child  ──> Page Q = 0x2222
```

### 页面底部

```text
共享页：增加 refcount
写时复制：alloc → copy → remap → invlpg
unmap/exit：减少 refcount，归零后释放页帧
```

### 讲解

COW 的正确性由 PTE 权限、物理页引用计数、page fault 和进程回收共同保证。测试中子进程写入
0x2222 后，父进程仍然读到 0x1111。

---

## P6 进程管理资源，线程参与调度

### 页面标题

```text
进程管理资源，线程参与调度
```

### 左侧：资源模型

| Process | Thread |
|---|---|
| PID、父子关系 | TID、调度状态 |
| CR3、VMA | 寄存器上下文 |
| cwd、文件描述符表 | 内核栈、用户栈 |
| 线程链、退出码 | TLS、join/detach 状态 |

### 右侧：调度状态

```text
              timer / yield
READY ─────────────────────→ RUNNING
  ↑                              │
  │ wakeup                       │ wait / IPC / futex / pipe
  └──────────── BLOCKED ←────────┘

RUNNING → JOINABLE_ZOMBIE → join → REAPED
RUNNING → DETACHED_ZOMBIE → scheduler reap
```

### 页面正文

```text
抢占式调度：时钟中断提供抢占点
上下文切换：保存寄存器和用户 RSP，按需切换 CR3
线程切换：更新 TSS.RSP0 和 FS.base

fork：复制 VMA、文件对象引用、页表和 syscall frame
exec：替换当前用户地址空间，不改变 PID
exit：记录退出状态并释放进程资源
wait：取得子进程状态并回收 zombie
```

### 当前限制

```text
fork 当前要求调用进程只有一个线程
调度器面向单核，不支持 SMP
```

### 讲解

同一进程的线程共享地址空间和文件表，但每个线程拥有独立的执行现场、内核栈、用户栈和 TLS。
BLOCKED 线程不能被调度为 RUNNING，退出对象只能回收一次。

---

## P7 用户程序通过系统调用请求内核服务

### 页面标题

```text
六、系统调用、IPC 与线程同步
```

### 左侧：系统调用

```text
用户程序（Ring 3）
read / write / fork / mmap
          ↓ SYSCALL
内核（Ring 0）
检查参数 → 执行对应服务
          ↓ SYSRET
用户程序继续运行
```

```text
系统调用是用户程序请求内核服务的统一入口。
文件读写、进程创建和内存映射都要经过系统调用。

用户地址先检查，再通过 copyin / copyout 传递数据。
```

### 中间：消息 IPC

```text
进程 A
send(B, type, value)
          ↓
内核消息等待队列
          ↓
进程 B
receive(A)
```

```text
接收方已经等待：立即传递消息并唤醒接收方
接收方尚未等待：发送方进入 BLOCKED 状态
消息匹配后：阻塞线程转为 READY 状态
```

```text
IPC 用于进程之间传递来源、类型和值。
示例测试：父子进程往返值为 0xC0DE
```

### 右侧：futex 线程同步

```text
线程先在用户态尝试加锁
          ↓
成功 → 进入临界区，不进入内核
失败 → futex_wait → BLOCKED
          ↓
解锁 → futex_wake → READY
```

```text
futex 不负责传递消息。
它只在线程争用共享数据时负责阻塞和唤醒。
示例测试：4 个线程完成同步，counter = 4
```

### 页面底部总结

```text
系统调用：用户程序请求内核服务
IPC：进程之间传递消息
futex：线程竞争时进行阻塞和唤醒
```

### 讲解

用户程序运行在 Ring 3，不能直接访问内核资源，因此需要通过系统调用进入 Ring 0，请求文件读写、进程创建或内存映射等服务。内核完成参数检查和具体操作后，再返回用户程序。

IPC 解决的是进程之间如何传递消息：发送方调用 send，接收方调用 receive；双方尚未匹配时，相关线程会阻塞，匹配后由内核唤醒。

futex 解决的是同一进程中多个线程如何安全访问共享数据。没有竞争时只执行用户态原子操作；发生竞争时，等待线程才进入内核阻塞，解锁线程通过 futex_wake 将其唤醒。

### 不放在主页面的实现细节

```text
RAX、RDI、RSI、RDX 的寄存器约定
swapgs、用户 RIP/RFLAGS/RSP 和内核栈切换
36 个系统调用的完整函数名清单
```

这些内容保留在备份页，用于老师追问系统调用入口实现时回答。

---

## P8 ATA LBA48 与 MyFS 提供持久文件存储

### 页面标题

```text
ATA LBA48 与 MyFS 提供持久文件存储
```

### 左侧：文件访问路径

```text
Ring 3 Application
        ↓ open/read/write/stat
File Descriptor
        ↓
Shared File Object
        ↓
FS Service + Block Cache
        ↓
MyFS
        ↓
ATA PIO LBA48
```

### 中间：MyFS 磁盘格式

```text
4 KiB block · format version 4

Superblock
Inode Bitmap
Data Bitmap
Inode Table
Data Blocks

inode：72 B
directory entry：64 B
```

### 右侧：文件块索引

```text
11 个直接块
      ↓
一级间接索引
      ↓
二级间接索引
      ↓
三级间接索引
```

### 页面底部

```text
路径：绝对路径 + 相对路径 + cwd
文件：open/read/write/close/unlink/stat
目录：list/mkdir/chdir/getcwd
FD：fork/dup 后共享 file object 和 offset
Pipe：环形缓冲、阻塞读写、EOF、readers/writers

256 GiB 稀疏磁盘，MyFS 位于 128 GiB 以上：LBA48 PASS
文件写入后重新启动 QEMU：内容仍然存在
```

### 讲解

ATA 驱动使用 LBA48 访问磁盘。MyFS 的超级块记录各区域位置，宿主机 mkfs 与 Guest 使用相同
的 inode 和目录项格式。文件描述符、共享 file object 和 pipe 共同支持 Shell 的组合操作。

---

## P9 TTY 与 Shell 形成完整交互环境

### 页面标题

```text
TTY 与 Shell 形成完整交互环境
```

### 左侧：键盘输入路径

```text
8042 Keyboard IRQ
        ↓
读取并解码 scancode
        ↓
Keyboard Event Queue
        ↓
TTY Input Service
        ↓
Foreground Process read(0, ...)
```

### 中间：显示路径

```text
Application write(1, ...)
        ↓
TTY / Console Cells
        ↓
VGA 80×25 或 framebuffer

3 个虚拟控制台：F1 / F2 / F3
framebuffer：1280×720，32 bpp
支持滚屏、光标和 PSF 字体
```

### 右侧：用户环境

```text
crt0：建立 C 程序入口
libc：字符串、内存、printf、malloc
Shell：内建命令与 ELF 程序

支持：
argv
A | B
<、>、>>
后台 &
历史、Tab 补全、行编辑
```

### 页面底部

```text
Ctrl+C：终止前台进程
用户 fault：只结束错误进程，Shell 继续运行
当前 Shell 支持单级管道，不是完整 POSIX Shell
```

右下角放真实终端截图。

### 讲解

键盘中断只完成有界的扫描码读取和事件入队，可能阻塞的读取由 TTY 服务在线程上下文中完成。
Shell 通过公开系统调用组合 fork、exec、pipe 和 dup2，不依赖专用演示接口。

---

## P10 四个错误暴露了跨模块不变量

### 页面标题

```text
四个错误暴露了跨模块不变量
```

### 页面正文

| 问题 | 原因 | 修改 | 结果 |
|---|---|---|---|
| 内核增长后 Loader 截断 | 固定读取扇区数，超过 255 时计数回绕 | 动态计算扇区、分块读取、磁盘与物理双边界 | 300 扇区启动通过 |
| syscall 阻塞后返回错误栈 | 用户 RSP 保存为全局临时状态 | 用户 RSP 和 syscall frame 随线程保存 | 多线程、IPC、futex 通过 |
| 快速输入出现 `scroll-fter` | 一次键盘 IRQ 只读取一个扫描码 | ISR 排空最多 64 个就绪字节后发送 EOI | input.stress 通过 |
| fork 后页面可能互相覆盖 | COW 写权限和引用计数不一致 | 父子页改为 RO+COW，fault 时复制或恢复写权限 | vm.cow 通过 |

### 页面底部

```text
磁盘不变量：MBR / Loader / Kernel / MyFS 不能重叠
内存不变量：PTE、VMA、refcount 和页帧生命周期一致
调度不变量：最多一个 RUNNING，BLOCKED 不进入执行
中断不变量：IRQ 路径有界、不睡眠、设备处理后发送 EOI
```

### 讲解

这些错误都不是单个语句问题，而是不同模块对同一状态理解不一致。修复时把隐含条件改为明确
检查，并增加能够触发边界的测试。

---

## P11 测试覆盖启动、内存、并发、存储和终端

### 页面标题

```text
测试覆盖启动、内存、并发、存储和终端
```

### 页面左侧：测试结果

```text
固定随机种子：20260821

完整测试：16 / 16 PASS

同步压力：
100 轮
× 4 个线程
× 每线程 20,000 次共享更新
PASS
```

### 页面中间：测试范围

```text
启动
MBR、Loader、300 扇区内核、Ring 3

内存
mmap、栈增长、fork/COW、用户 fault

并发
调度、IPC、futex、mutex、join/detach

存储
MyFS、共享 FD、pipe、LBA48、跨重启

终端
快速输入、Ctrl+C、Shell 编辑、framebuffer 像素
```

### 页面右侧：现场演示

```text
about
ps
demo
cat demo-proof.txt
```

`demo` 输出：

```text
[PASS] SYSTEM
[PASS] PROCESS + COW
[PASS] IPC
[PASS] THREADS
[PASS] FILESYSTEM
[PASS] FAULT ISOLATION

RESULT 6 passed 0 failed
```

### 现场讲解顺序

1. `about`：显示系统信息和功能范围。
2. `ps`：显示进程、线程和状态。
3. `demo`：依次执行 COW、IPC、线程、文件系统和异常隔离。
4. `cat demo-proof.txt`：读取演示创建的持久文件。
5. 时间允许时按 F2/F1 展示虚拟控制台切换。

页面上放一张 `RESULT 6 passed 0 failed` 的真实截图。

---

## P12 MiniOrangeOS 已形成完整的课程级操作系统

### 页面标题

```text
MiniOrangeOS 已形成完整的课程级操作系统
```

### 左侧：已实现

```text
自制 MBR 与 Loader
x86-64 长模式与高半区内核
Ring 3 与用户异常隔离
物理内存、四级页表、VMA、COW
进程、线程、抢占调度、IPC、futex
ATA LBA48、MyFS、文件描述符与 pipe
TTY、三控制台、framebuffer
libc、Shell 和用户程序
```

### 右侧：当前限制

```text
仅支持单核，不支持 SMP
主要在 QEMU 中运行，未完成真机适配
ATA 使用 PIO，没有 DMA
MyFS 没有日志和崩溃恢复
没有 swap 和 file-backed mmap
没有网络、USB、音频和图形窗口系统
Shell 不是完整 POSIX Shell
```

### 页面底部：后续方向

```text
MyFS 日志与崩溃一致性
页缓存与 file-backed mmap
多核调度与 TLB shootdown
```

### 结束语

```text
系统已经完成从裸机启动、内核资源管理、用户态执行、
持久文件存储到交互式 Shell 的完整运行路径。

谢谢老师，欢迎提问。
```

---

## 备份页内容

以下页面不在主讲流程中，教师追问时再打开。

### B1 36 个系统调用完整表

放系统调用编号、用户态封装和内核处理函数，重点标出：

```text
fork / exec / wait
mmap / munmap
send / receive
futex_wait / futex_wake
pipe / dup / dup2
```

### B2 SYSCALL 栈帧

```text
STAR / LSTAR / FMASK
swapgs
用户 RIP / RFLAGS / RSP
线程内核栈
syscall frame
sysretq
```

### B3 COW Page Fault

```text
Present + User + COW + Write Fault
refcount == 1：恢复 Writable
refcount > 1：分配新页、复制、remap
失败：保持旧 PTE 为只读 COW
```

### B4 MyFS 磁盘格式

```text
Superblock / Bitmap / Inode Table / Data
inode 72 B / directory entry 64 B
11 direct + single + double + triple indirect
```

### B5 完整测试列表

放 16 个测试名称、固定 seed、运行结果以及独立 100 轮同步压力结果。
