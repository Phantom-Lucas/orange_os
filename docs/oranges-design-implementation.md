# Orange'S x86_64 教学操作系统设计与实现

## 项目设计、实现细节与测试验证文档

文档版本：1.2
适用代码：`baseline/2026-08`；代码/测试冻结 commit `e07f6a0`，证据元数据 HEAD `55b5292`，tag `baseline-2026-08`
目标平台：x86_64、BIOS、QEMU
项目类型：教学型裸机操作系统

---

## 摘要

本项目是一个面向操作系统原理学习、内核实验和 Orange'S 功能复现的 x86_64 裸机操作系统。项目参考《Orange'S：一个操作系统的实现》的知识结构和功能目标，但没有直接照搬其 32 位、LDT、分段式进程以及 `int 0x90` 的实现方式，而是根据 64 位平台的硬件机制重新设计了启动、分页、系统调用、进程、线程、同步、文件系统和用户态运行时。

系统可以从 MBR 启动，经 Loader 进入保护模式和 x86_64 长模式，运行高半区内核，并最终进入 Ring 3 用户态 Shell。内核具备四级页表、物理页分配、内核堆、用户地址空间、物理页引用计数、写时复制 fork、VMA、匿名 mmap、页故障处理、进程与用户线程、时间片调度、阻塞/唤醒、同步 IPC、futex、用户态 mutex/条件变量、TLS、ATA PIO 磁盘驱动、MyFS 文件系统、文件描述符、管道、重定向和基础 libc。

项目目前已经形成从“启动机器”到“运行用户程序”再到“文件持久化和资源回收”的完整闭环。测试不仅覆盖正常路径，也覆盖 fork/exit/wait、exec 成功和失败、用户页错误、COW 分配失败回滚、非法用户指针、同步压力、线程生命周期、TTY 快速输入和 Ctrl+C 前台进程终止。

本文的重点不是罗列接口名称，而是说明各子系统的职责边界、关键不变量、失败路径以及与原书章节的对应关系。对于当前仍然存在的单核、无网络、无动态链接、MyFS 固定起始位置和若干简化，也会在正文中明确标注。

> 说明：仓库中早期的 `docs/project-overview.md` 曾保留“fork 全量复制”的旧描述；当前源码已经实现物理页引用计数和 COW，本文以当前源码和测试行为为准。

> 基线状态（2026-08-15）：路线图阶段 0 和阶段 1 已完成。源码基线、环境、产物哈希和测试证据已经冻结；统一测试 runner、12 个 manifest case、公共 QEMU/monitor/artifacts 库和兼容 Make target 已落地。验收记录见 [`stage-0.md`](milestones/stage-0.md)、[`stage-1.md`](milestones/stage-1.md) 和 [`stage-1-comparison.md`](milestones/stage-1-comparison.md)。

## 目录

1. [项目概述](#一项目概述)
2. [系统设计](#二系统设计)
3. [具体实现细节](#三具体实现细节)
4. [系统测试与验证](#四系统测试与验证)
5. [与 Orange'S 原书章节的逐项对比](#五与-oranges-原书章节的逐项对比)
6. [当前边界与后续工作](#六当前边界与后续工作)
7. [附录](#七附录)

---

# 一、项目概述

## 1.1 项目背景

《Orange'S：一个操作系统的实现》采用循序渐进的方式，从 512 字节引导扇区开始，逐步介绍保护模式、分页、中断、进程、输入输出、IPC、文件系统和用户进程。其代码主要面向早期 32 位 x86 环境，适合展示操作系统从无到有的构造过程。

本项目继承原书最重要的学习路线：

```text
引导扇区
    -> Loader 与保护模式
    -> 分页、中断和时钟
    -> 进程与调度
    -> 键盘、TTY 和系统调用
    -> IPC
    -> 磁盘和文件系统
    -> fork/exec/exit/wait
    -> Shell 与用户态运行环境
```

同时，项目根据 64 位系统和后续实验要求补充了原书没有重点展开的机制：

- 四级页表和高半区内核；
- x86_64 `syscall/sysretq` 系统调用入口；
- 用户线程和共享地址空间；
- 物理页引用计数与 COW fork；
- VMA、匿名 `mmap/munmap` 和按需栈增长；
- futex、用户态 mutex、条件变量和 TLS；
- `dup/dup2`、管道、重定向和外部命令；
- 资源统计、失败回滚和 QEMU 自动化验收。

因此，本项目不是原书代码的逐行移植，而是一个在 Orange'S 教学目标上进行 x86_64 重构和扩展的实现。

## 1.2 项目目标

项目目标分成四个层次。

第一，建立能够独立启动的最小系统。系统应当拥有 MBR、Loader、内核入口、基本显示和异常处理，不依赖宿主操作系统完成核心运行时工作。

第二，实现能够运行用户程序的内核。用户程序应运行在 Ring 3，不能直接访问内核地址和设备端口；用户程序异常时只能终止自身，不应导致内核整体崩溃。

第三，实现可持续使用的交互环境。Shell 应支持基本命令、目录、文件、管道、重定向、当前工作目录和任务控制，磁盘内容在重启后仍然存在。

第四，建立可以验证的内核工程基础。每一个重要模块都应有清晰的所有权、锁、状态机、失败路径和测试，不以“能够运行一次”作为完成标准。

## 1.3 功能范围总览

当前系统功能状态如下。状态含义为：

- **已完成**：代码路径已实现，并有对应的构建或 QEMU 测试。
- **已完成但有限制**：核心功能可用，但存在单核、容量、格式或接口简化。
- **部分完成**：已有基础代码或预留接口，尚未达到完整操作系统语义。
- **未实现**：当前没有可用实现，不应在项目演示中宣称支持。

| 子系统 | 当前状态 | 说明 |
| --- | --- | --- |
| MBR 与 Loader | 已完成但有限制 | BIOS 启动、读取 Loader/内核、进入长模式；加载窗口固定。 |
| 保护模式与长模式 | 已完成 | GDT、A20、页表、CR3、Ring 3 入口和返回路径。 |
| 中断与异常 | 已完成 | IDT、PIC、时钟、键盘、用户页错误和异常隔离。 |
| 物理内存管理 | 已完成 | E820、位图、owner、引用计数和统计。 |
| 内核堆 | 已完成 | arena/block 分配、释放、合并和压力测试。 |
| 进程 | 已完成但有限制 | 多进程、父子关系、fork/exec/exit/wait；PCB 和 TCB 尚未完全拆成独立文件对象。 |
| 用户线程 | 已完成 | 共享进程地址空间，支持 create/join/detach/exit、用户栈、TLS。 |
| 调度 | 已完成但有限制 | 单 CPU 时间片轮转；不支持 SMP 并行。 |
| 同步 | 已完成 | 阻塞/唤醒、同步 IPC、futex、mutex、条件变量。 |
| 虚拟内存 | 已完成但有限制 | 四级页表、COW、VMA、匿名 mmap、部分 munmap；文件映射尚未完成。 |
| 磁盘驱动 | 已完成但有限制 | ATA PIO 轮询读写；无 DMA、日志和复杂错误恢复。 |
| MyFS | 已完成但有限制 | 动态容量、版本化格式、inode、目录、路径、读写、删除和持久化；无日志、权限和多挂载。 |
| 文件描述符 | 已完成 | open/read/write/close、引用计数、dup/dup2、pipe、重定向。 |
| 用户态运行时 | 已完成但有限制 | crt0、libc、malloc/free、格式化输出、文件/进程/线程/同步 API。 |
| Shell | 已完成但有限制 | 外部命令、参数、管道、重定向、后台、TTY 控制键。 |
| 网络与信号 | 部分完成 | `kill` 和简化异常终止可用；完整 POSIX 信号和网络协议栈未实现。 |
| SMP | 未实现 | `QEMU_CPUS` 当前应保持为 1。 |

## 1.4 开发环境与启动方式

项目使用宿主机 GCC、NASM、GNU binutils、QEMU 和常用 Unix 工具。构建入口位于根目录 `Makefile`，产物集中在 `build/`。

常用命令如下：

```bash
# 只构建，不写入已有磁盘
make build

# 构建并检查 MBR、Loader、内核尺寸、ELF 和 MyFS
make check

# 创建或重建磁盘，安装内核并格式化 MyFS
# 注意：format-fs 会覆盖文件系统区域中的旧数据
make bootstrap

# 仅更新 MBR、Loader 和内核，保留已有文件
make install-kernel

# 启动 QEMU
make run

# 启用完整启动诊断
make BOOT_DIAGNOSTIC=1 run
```

默认资源配置为：

```text
QEMU_MEMORY = 1G
QEMU_CPUS   = 1
DISK_IMAGE  = build/images/orange-dev.img
DISK_SIZE   = 256M
```

例如：

```bash
make DISK_IMAGE=build/images/orange-dev.img DISK_SIZE=256M bootstrap
make DISK_IMAGE=build/images/orange-dev.img QEMU_MEMORY=1G QEMU_CPUS=1 run
```

需要注意，QEMU 磁盘文件大小和 MyFS 可用容量仍是两个需要区分的量，但当前
`tools/mkfs.c` 已按 `DISK_SIZE - FS_START_LBA * 512` 动态生成 MyFS 区域。默认
256MiB 镜像的 MyFS 超级块记录为 65,411 个 4KiB 块、约 267,923,456 字节，
数据区从动态计算的元数据末尾开始；因此磁盘尾部空间已经纳入文件系统管理。
已有镜像不会自动扩容，改变 `DISK_SIZE` 时应使用新的镜像并重新格式化。

日常使用时，启动后进入用户态 Shell：

```text
orange$ help
orange$ pwd
orange$ ls /
orange$ mkdir home
orange$ echo hello > /home/a.txt
orange$ cat /home/a.txt
orange$ run thread-demo.elf
orange$ demo
orange$ exit
```

启动默认采用简略输出，只显示必要启动摘要和 Shell。需要查看内核自测、PMM owner、堆统计、FS 自测和进程生命周期日志时，设置 `BOOT_DIAGNOSTIC=1`。

## 1.5 项目目录

| 路径 | 主要职责 |
| --- | --- |
| `boot/mbr.S` | 512 字节 BIOS 引导扇区。 |
| `boot/loader.S` | 内存探测、内核读取、页表建立和长模式切换。 |
| `kernel/memory.*` | PMM、页表、用户地址检查、引用计数、COW 和 mmap。 |
| `kernel/kalloc.*` | 内核堆 arena/block 分配器。 |
| `kernel/process.*` | PCB、进程树、地址空间、fork/exec/exit/wait、VMA。 |
| `kernel/thread.*` | 调度实体、上下文切换、内核栈、用户线程生命周期。 |
| `kernel/sync.*` | 自旋锁、阻塞/唤醒相关基础同步。 |
| `kernel/futex.*` | futex 哈希桶、等待节点、唤醒和退出清理。 |
| `kernel/syscall.*` | 系统调用分发、参数检查和用户边界。 |
| `kernel/tty.*`、`keyboard.*` | TTY 服务、键盘输入、控制台和控制键。 |
| `kernel/disk.*`、`fs.*`、`file.*` | ATA、MyFS、inode、路径、文件对象和管道。 |
| `usr/` | 用户态启动代码、libc、Shell、命令和各类验收程序。 |
| `usr/term.h` | Shell 使用的最小 ANSI SGR 样式常量。 |
| `usr/showcase.c` | 用户态 ORANGE/64 六步 guided tour。 |
| `tools/mkfs.c` | 制作 MyFS 镜像并打包用户程序。 |
| `tests/` | 构建、启动、文件系统、Shell、输入、同步和虚拟内存测试。 |
| `docs/` | 项目路线、总览和本设计实现文档。 |

## 1.6 项目边界

为了保持教学系统的规模可控，当前系统有以下明确边界：

1. 内核为单 CPU 设计。自旋锁和阻塞机制已经考虑中断重入，但没有完成 AP 启动、per-CPU 数据和真正 SMP 并行，因此 QEMU 应使用 `-smp 1`。
2. 文件系统是固定起始位置、动态容量的 MyFS，不是完整 POSIX 文件系统。当前没有权限位、硬链接、符号链接、日志、挂载多个文件系统和在线扩容。
3. ATA 驱动使用轮询 PIO，不支持 DMA、命令队列和复杂的坏盘恢复。
4. 服务组件主要是内核线程，不是独立的 Ring 3 用户态服务器。
5. `kill` 是简化的用户进程终止机制，不等同于完整信号系统。
6. 没有网络协议栈、动态链接器、共享库加载器和完整 POSIX 兼容层。

这些限制不影响项目完成 Orange'S 核心教学闭环，但必须在实验报告和演示中如实说明。

---

# 二、系统设计

## 2.1 总体设计原则

### 2.1.1 64 位优先

系统所有核心地址和页表接口使用 64 位类型。用户地址、物理地址、页表项和系统调用参数不能通过 32 位整数截断。用户空间位于低半区，内核运行于高半区，通过高半区映射访问内核代码、内核堆和内核数据。

### 2.1.2 资源所有权显式化

物理页同时记录 owner、是否已分配、引用计数和保留状态。owner 描述“这页由哪类内核对象负责”，refcount 描述“有多少用户映射引用它”，二者不互相替代。例如页表页是 `PAGE_OWNER_PAGE_TABLE`，堆页是 `PAGE_OWNER_HEAP`，用户数据页是 `PAGE_OWNER_USER`，线程内核栈是 `PAGE_OWNER_THREAD`。

### 2.1.3 阻塞代替忙等

等待子进程、等待 IPC、等待输入、sleep、futex 和竞争锁都必须把线程从 ready queue 移出，进入 BLOCKED 状态，由事件发生方明确唤醒。`yield()` 可以作为主动让出 CPU 的接口，但不能作为条件等待的主要实现。

### 2.1.4 内核只在边界处接触用户内存

系统调用不能直接把用户指针当作内核指针。每个缓冲区都必须检查起止地址、整数溢出、页表存在性、用户权限和跨页情况；写入用户空间时还要处理 COW 页故障。

### 2.1.5 正常路径和失败路径同等重要

分页建表、连续页分配、ELF 加载、COW fault、文件写入、目录创建、线程创建和页表销毁都要有回滚路径。分配到一半失败时，不能留下部分 owner、悬空映射、泄漏的位图或不可回收的线程。

## 2.2 分层架构

系统总体结构如下：

```text
┌──────────────────────────────────────────────────────────────┐
│ Ring 3 用户态                                                │
│ _start/crt0 -> libc -> syscall wrapper -> Shell/命令/测试程序 │
│ libc: malloc、printf、文件 API、进程 API、线程 API、同步 API    │
└────────────────────────────┬─────────────────────────────────┘
                             │ syscall/sysretq
┌────────────────────────────▼─────────────────────────────────┐
│ Ring 0 内核                                                   │
│ syscall/uaccess · 进程/线程 · 调度 · futex · 虚拟内存          │
│ 文件对象/fd · MyFS · ATA PIO · TTY/键盘 · IPC · timer         │
└──────────────┬─────────────┴─────────────────┬────────────────┘
               │ IRQ0/IRQ1/PIC                 │ ATA PIO
       ┌───────▼────────┐              ┌───────▼─────────┐
       │ 定时器/键盘/VGA │              │ QEMU raw disk   │
       │ 三个虚拟控制台  │              │ MyFS 文件系统   │
       └────────────────┘              └─────────────────┘
```

服务任务在内核中运行，但 TTY 输入、TTY 输出和文件系统访问仍然通过消息请求划分职责。用户程序不能直接访问 VGA 显存、ATA 端口、inode 位图或内核文件对象。

## 2.3 启动与特权级设计

启动流程为：

```text
BIOS 加载 LBA 0
    -> MBR 加载 Loader
    -> Loader 探测 E820 内存
    -> 读取内核并保存启动信息
    -> 开启 A20
    -> 加载 GDT，进入保护模式
    -> 建立 PML4/PDPT/PD/PT
    -> 设置 CR3，开启 PAE 与 EFER.LME
    -> 进入 x86_64 长模式
    -> 跳转高半区 kernel_main
    -> 初始化中断、内存、调度、FS、TTY、用户进程
    -> Ring 3 shell.elf
```

MBR 位于 LBA 0，严格保持 512 字节并带有 `0x55AA` 引导标记。Loader 位于 LBA 2 起，内核从 LBA 10 起加载。MBR 只读取必要的第一段，避免在仍然执行 `0x7C00` 代码时覆盖自身；Loader 接管后再读取内核剩余部分。

内核通过 GDT 和 TSS 提供内核代码段、用户代码段、数据段以及系统调用所需的栈切换环境。用户程序使用 `syscall` 进入 Ring 0，入口保存用户现场、切换到内核栈并执行系统调用分发，返回时恢复用户现场。用户程序的异常由 IDT 统一处理：

- 合法的 COW 写故障由虚拟内存层修复后继续执行；
- 合法的用户栈按需增长由 VMA/页故障路径处理；
- 未映射访问、权限错误和不可恢复异常终止当前用户进程；
- 内核态页错误和严重保护异常仍然触发 panic，防止静默损坏内核状态。

## 2.4 进程与线程模型

当前结构还没有把 `struct process` 和 `struct thread` 拆成两个完全独立的内核对象文件，但逻辑职责已经分离。

进程拥有：

- PID、父子关系和退出状态；
- CR3、VMA 链表和用户地址空间；
- 当前工作目录；
- 文件描述符表和文件对象引用；
- 进程级线程链表和线程数量；
- 终止请求、名称和终端控制权。

线程拥有：

- TID、调度状态和 ready/block 链表节点；
- 内核栈和上下文保存区；
- 用户入口、用户栈和 TLS 页；
- 阻塞原因、等待对象、退出状态；
- futex waiter 节点和 join/detach 状态。

关系可以表示为：

```text
一个进程
├── 一个共享 CR3
├── 一个共享文件描述符表
├── 一个共享 cwd 和 VMA 集合
├── 主线程
│   ├── 内核栈
│   ├── 用户栈
│   └── TLS
└── 零个或多个用户线程
    ├── 各自的内核栈
    ├── 各自的用户栈
    └── 各自的 TLS
```

因此，多个进程拥有相互隔离的地址空间；同一进程的多个用户线程共享代码、全局数据、堆、mmap 区域、文件表和 cwd，但拥有独立的栈、寄存器现场、TID、阻塞状态和 TLS。

`fork` 当前要求调用进程处于可复制的进程状态，复制进程级资源和调用线程的执行现场；对多线程进程的语义采用保守策略，避免把其他线程的锁、futex 等待和栈状态错误复制到子进程。`exec` 只允许在进程级资源可以安全替换时进行，重新建立 ELF 映像、主线程用户栈和 TLS，保留 PID 与按设计允许继承的文件描述符。

## 2.5 调度和阻塞设计

调度实体是线程，不是进程。调度器维护 ready queue，线程在以下状态间转换：

```text
READY -> RUNNING -> READY       时间片耗尽或主动 yield
RUNNING -> BLOCKED              等待锁、IPC、输入、futex、sleep、wait
BLOCKED -> READY                对应事件 wakeup
RUNNING -> ZOMBIE               线程退出但仍需 join 或 detach
ZOMBIE -> DEAD                  被 join 或 detached 自动回收
```

调度不变量包括：

1. ready queue 中不能有重复线程节点；
2. BLOCKED、ZOMBIE、DEAD 线程不在 ready queue；
3. 当前 RUNNING 线程最多只有一个；
4. 被切换出的线程状态必须先更新，再插入或移出队列；
5. 上下文切换过程中中断状态可控；
6. 持有自旋锁或处于不可抢占临界区时不能直接切换。

定时器中断负责减少时间片并设置重新调度请求，真正的上下文切换在安全点发生。当前系统为单 CPU，锁主要用于中断上下文和内核线程之间的互斥，而不是提供多核并行性能。

## 2.6 虚拟内存设计

虚拟内存层分为四个职责：

1. PMM 负责物理页分配、释放、owner 和引用计数；
2. 页表层负责 PML4/PDPT/PD/PT 的创建、映射和销毁；
3. 进程地址空间层负责 VMA、用户栈、堆和 mmap 区域；
4. 页故障层区分 COW、按需栈增长、未映射和权限错误。

用户页映射的引用计数只统计用户 PTE 映射引用，不用来管理页表页、内核堆页和线程对象。父子进程 COW 共享时，双方 PTE 都标记为只读并设置软件位 `PTE_COW`；任一方写入触发页故障，只有在引用数大于一时才分配新页并复制。引用数为一时可以直接恢复写权限并清除 COW 标记。

VMA 描述如下：

```c
struct vm_area {
    vaddr_t start;
    vaddr_t end;             /* end 为开区间 */
    uint64_t flags;          /* READ/WRITE/EXEC/GROWSDOWN/ANON/PRIVATE */
    void* file;              /* 当前文件映射预留 */
    uint64_t file_offset;
    struct vm_area* next;
};
```

当前已支持 ELF 段、用户栈、匿名私有 mmap、部分 munmap 和栈按需增长；文件映射和共享映射属于后续扩展。

## 2.7 系统调用边界

系统调用层负责四项工作：

- 解析寄存器参数和系统调用号；
- 验证用户地址和长度；
- 调用进程、线程、FS、TTY 或 VM 子系统；
- 将结果和错误码安全返回用户态。

核心用户内存接口为：

```c
int copy_from_user(void* kernel_dst, vaddr_t user_src, size_t length);
int copy_to_user(vaddr_t user_dst, const void* kernel_src, size_t length);
int copy_string_from_user(char* kernel_dst, vaddr_t user_src,
                          size_t max_length);
```

检查内容包括：

- 地址是否处于低半区用户范围；
- `address + length` 是否溢出；
- 起止页是否全部存在；
- 页表项是否具有用户位；
- 读内核还是写内核时权限是否正确；
- 跨页缓冲区是否每页分别验证；
- 用户字符串是否在上限内遇到 `\0`。

## 2.8 TTY、键盘和控制台

键盘中断不直接执行 Shell 或文件系统逻辑，而是采用：

```text
PS/2 IRQ1
    -> 扫描码解析
    -> 键盘环形队列
    -> TTY 输入服务
    -> read(0) 请求回复
    -> 用户 Shell 或程序
```

输出路径为：

```text
用户 write(1/2)
    -> copy_from_user
    -> TTY 输出请求
    -> TTY 输出服务
    -> 活动 VGA 控制台
```

系统提供三个内存后备 VGA 文本控制台，可使用 F1/F2/F3 切换。每个控制台保留显示内容和滚动历史。Shell 支持 Ctrl+C、Ctrl+\\、Ctrl+Z、Ctrl+L、Ctrl+U、Ctrl+W、Ctrl+D 等控制键；PageUp/PageDown 的现有实现保留为控制台历史翻页，后续可继续改进输入行和浏览模式之间的状态隔离。

## 2.9 文件系统设计

磁盘从 QEMU raw image 提供 ATA 主盘。当前驱动采用 LBA48 EXT 轮询 PIO，每次读写 512 字节扇区，LBA 接口为 64 位。MyFS 从固定起始 LBA 开始，按镜像剩余空间动态计算 4KiB 块数、超级块、inode 位图、数据块位图、inode 区、根目录和数据区；当前格式版本为 v4。

文件系统层分为：

```text
syscall 文件 API
    -> file object / fd table
    -> 路径解析、目录项、inode
    -> 位图和块分配
    -> buffer cache
    -> ATA PIO
    -> QEMU disk image
```

目录和普通文件共享 inode 基础，但读写权限和操作类型由 syscall 层区分。路径解析支持绝对路径、相对路径、`.`、`..`、多级目录和每进程 cwd。

文件对象和文件描述符分离：fd 是进程表中的整数槽位，file object 保存 inode、偏移量、打开引用计数和操作类型。`dup/dup2` 复制的是 file object 引用，因此共享文件偏移；`close` 只在引用数归零时释放对象。管道由读端和写端 file object 共享环形缓冲区和读写端引用计数。

## 2.10 用户态运行环境

用户程序通过 `crt0.S` 的 `_start` 进入，获得参数并调用 C 入口。`usr/libc.c` 和 `usr/libc.h` 提供：

- `memcpy/memmove/memset/memcmp`；
- 字符串操作和简单格式化输出；
- `malloc/calloc/realloc/free`；
- 文件、目录、cwd、fd、管道和重定向 API；
- `fork/spawn/exec/exit/wait/getpid/gettid`；
- 用户线程 create/join/detach/exit；
- futex、mutex、条件变量和 TLS/errno；
- `printf`、`puts` 等基础输出。

基础用户程序包括 `ls`、`cat`、`echo`、`mkdir`、`rm`、`pwd`、`ps`、`sleep`、`kill`，以及用于回归的 `hello`、`ipc-demo`、`thread-demo`、`sync-demo`、`vm-demo`、`fs-demo`、`fault` 和 `exec-demo`。

---

# 三、具体实现细节

## 3.1 MBR、Loader 与内核装载

### 3.1.1 MBR

MBR 的职责被限制为最小化：建立初始段寄存器和栈，读取 Loader，检查 BIOS 磁盘读结果，并跳转到 Loader。由于 MBR 本身只有 512 字节，复杂的内存探测和长模式初始化不放在 MBR 中。

关键约束是加载区域不能覆盖当前 MBR 仍在执行的内存。项目将 Loader 放在低地址安全区域，内核在 Loader 接管后再加载到高半区对应的物理位置。

### 3.1.2 Loader

Loader 负责 BIOS E820 内存布局探测、A20、GDT、初始页表、CR3、长模式控制寄存器和内核入口。Loader 以扇区为单位读取内核，受固定加载窗口约束；构建脚本通过 `check_build.sh` 检查内核大小，防止构建出启动阶段无法加载的镜像。

Loader 保存 E820 结果，内核 PMM 初始化时据此建立物理页位图。不可用内存、BIOS 保留区、Loader、内核、初始页表和显存区域会被标记为 reserved，不能交给普通分配器。

## 3.2 GDT、IDT、分页与异常

### 3.2.1 GDT 与特权级

当前设计使用 x86_64 平坦地址空间，段基址和段限长不再承担原书中 LDT 进程隔离的主要职责。隔离依赖分页的 U/S 位、R/W 位和 Ring 3 权限。GDT/TSS 主要用于代码段选择、特权级切换和内核栈。

与原书不同之处：当前不实现 LDT，也不采用 Ring 1 作为用户进程级别，而是直接采用 Ring 0/Ring 3 两级结构。这更符合 x86_64 现代系统的常见实现。

### 3.2.2 四级页表

虚拟地址按如下层次解析：

```text
PML4[47:39] -> PDPT[38:30] -> PD[29:21] -> PT[20:12] -> offset[11:0]
```

页表项中的地址部分和权限部分严格分离。页表页由 PMM 以 `PAGE_OWNER_PAGE_TABLE` 分配，建立途中任一层分配失败都要释放已经建立的中间层，不能只释放最后一页。

内核高半区映射在不同进程之间共享；销毁用户地址空间时只回收低半区用户页和用户页表，不误释放共享高半区结构。

### 3.2.3 中断和页故障

IDT 处理时钟、键盘、系统调用相关入口以及除零、一般保护错误、页错误。页错误处理读取 CR2、错误码和当前特权级，按下列顺序判断：

1. 是否是用户态 COW 写故障；
2. 是否是 VMA 中允许的按需栈增长；
3. 是否是合法但尚未物化的匿名页；
4. 是否为未映射地址或权限错误；
5. 若来自内核态，进入 panic。

用户故障不会直接把内核停死，而是设置用户进程终止状态，清理其等待节点和资源，并让父进程通过 wait 观察异常退出。

## 3.3 PMM、内核堆和物理页生命周期

### 3.3.1 PMM 元数据

`kernel/memory.h` 中的 `Bitmap` 维护：

```c
uint8_t* bits;          /* allocated */
uint8_t* reserved_bits; /* reserved */
uint8_t* owners;        /* PAGE_OWNER_* */
uint32_t* refcounts;    /* 用户映射引用计数 */
```

统计信息包括空闲页、已分配页、保留页、各 owner 页数、用户映射页数和用户映射引用总数。owner 和引用计数分开管理，避免把“物理页归谁负责”和“用户 PTE 有几份引用”混成一个字段。

### 3.3.2 分配和回滚

PMM 提供按页分配和带 owner 分配接口：

```c
paddr_t alloc_page_owned(page_owner_t owner);
paddr_t alloc_pages_owned(uint32_t count, page_owner_t owner);
int free_page_owned(paddr_t page, page_owner_t owner);
int free_pages_owned(paddr_t page, uint32_t count,
                     page_owner_t owner);
```

连续页申请失败时，已成功获得的部分页必须按相同 owner 逐页释放；不能只释放第一个页，也不能让后续页保留默认 owner。测试代码支持注入一次 PMM 分配失败，用来验证回滚路径。

### 3.3.3 内核堆

`kalloc.c` 使用 arena/block 组织内核堆。arena 从 PMM 获取若干物理页，block 保存空闲/已用状态和大小。`kmalloc` 负责对齐、切分和查找；`kfree` 负责回收 block，并在相邻 block 空闲时合并。统计项包括 arena 数量、活动 block 数量和已分配字节数。

分配器的关键约束是：PMM 锁临界区内不能调用 kmalloc、打印或页表创建；这样可以避免锁递归、日志分配导致的死锁和中断重入。

## 3.4 引用计数与 COW fork

### 3.4.1 建立共享映射

fork 遍历父进程用户页表，对每个用户映射执行：

1. 获得对应物理页；
2. 增加用户映射引用计数；
3. 在子页表映射同一物理页；
4. 清除父子双方的 PTE_RW；
5. 设置 `PTE_COW`；
6. 失效或刷新相关 TLB 映射。

如果子页表创建失败、某页引用计数增加失败或子映射失败，必须逆序撤销已经建立的子映射并恢复父页的原有写权限和引用计数。父进程不能在 fork 失败后留下只读但没有有效子引用的页面。

### 3.4.2 写故障

`handle_cow_page_fault` 检查 PTE 必须同时包含 Present、User 和 COW。若页面引用数为一，说明没有其他用户映射，可以直接清除 COW 并恢复写权限；若引用数大于一，则：

```text
分配 PAGE_OWNER_USER 新页
    -> 复制旧页内容
    -> 在当前地址空间替换 PTE
    -> 新页引用数设为一
    -> 旧页用户映射引用减一
    -> 刷新当前页 TLB
```

新页分配或复制失败时，原 PTE 和原引用计数必须保持不变。测试覆盖父写、子写、双方写、多代 fork、任一方先退出、COW 分配失败和只读代码页写入。

## 3.5 VMA、mmap 和用户栈

ELF 加载阶段将代码段、只读数据段、可写数据段和用户栈记录为 VMA。匿名私有 mmap 检查：

- 长度非零且地址/长度页对齐或可安全向上取整；
- 地址范围没有与已有 VMA 冲突；
- `PROT_*` 和 `MAP_PRIVATE|MAP_ANON` 标志合法；
- 创建失败时释放已建立的页表和物理页。

`munmap` 支持整段和部分区间解除映射。部分解除时可能把一个 VMA 拆成前后两个 VMA；物理页、页表页和引用计数必须只释放被解除的区间。

用户栈按需增长时，页故障地址必须位于允许的栈增长窗口内，且不能越过栈底限制。合法故障分配新页并加入栈 VMA；越界或权限错误终止用户进程。

## 3.6 进程生命周期

### 3.6.1 创建和加载 ELF

`spawn` 或 Shell 的 `run` 创建进程对象，调用 ELF 加载器读取文件系统中的 ELF64 文件，验证 ELF 头、程序头和加载段范围，为各段建立 VMA 和页映射，分配用户栈、主线程内核栈和 TLS，最后设置 Ring 3 入口。

ELF 读取不能直接假设文件块连续；加载器通过 FS 服务和文件对象读取。任一加载阶段失败时，必须释放：

- 已分配用户页；
- 页表页；
- VMA 节点；
- 用户栈和 TLS；
- 主线程内核栈；
- 暂存 buffer；
- 打开的 inode/file object 引用。

### 3.6.2 exit、zombie 和 wait

进程退出分为“大资源释放”和“最小退出记录保留”两步：

```text
exit(status)
    -> 标记退出请求
    -> 取消 futex/IPC 等待
    -> 清理线程、用户地址空间、文件引用和 VMA
    -> 保存 PID、父关系、退出码和异常信息
    -> 进入 ZOMBIE
    -> 唤醒父进程 wait
    -> 父 wait 读取状态并回收最小 PCB
    -> DEAD
```

父进程先 wait 时，wait 线程阻塞；子进程先 exit 时，子进程保留 zombie 状态，父进程随后立即取得退出结果。多个子进程和指定 PID/任意子进程 wait 都应只成功回收一次。

父进程先退出时，子进程不能保留悬空 parent 指针。当前策略是把孤儿重新交给内核回收路径或 init 类父对象；无法由用户态 init 接管时，至少清除悬空关系并保证子进程最终能回收。

### 3.6.3 多线程进程退出

用户线程退出不应立即销毁共享进程地址空间。joinable 线程保留最小 zombie 线程对象，等待另一个线程 join；detached 线程在退出时自动释放内核栈、用户栈、TLS 和线程对象。进程退出时先取消所有线程的 futex waiter，再统一回收共享地址空间和剩余线程资源。

## 3.7 调度、上下文切换和锁

`switch.S` 保存 callee-saved 寄存器、栈指针和返回现场，在两个线程之间切换内核上下文。每个线程拥有独立内核栈，用户线程返回用户态前恢复自己的用户栈、入口和 FS.base。

锁和调度遵循以下约束：

```text
地址空间锁 -> 进程文件/生命周期锁 -> 文件对象锁
地址空间锁 -> kmalloc 相关保护 -> PMM 锁
```

实际实现中尽量缩短锁的持有时间，尤其不在 PMM 锁内调用可能再次分配内存的函数。自旋锁获取和释放会控制本地中断，当前中断处理程序也不调用 PMM 或 kmalloc，从而避免同一 CPU 被中断重入后再次获取同一锁。

## 3.8 futex、用户 mutex、条件变量和 TLS

### 3.8.1 futex key 和哈希桶

futex 的 key 是：

```text
(process address space, user virtual address)
```

同一用户虚拟地址在不同进程中不会误唤醒。内核使用固定数量哈希桶，每个桶有锁和 waiter 链表。waiter 节点直接嵌入线程对象，避免在桶锁内调用 kmalloc。

`futex_wait` 的关键顺序是：

```text
验证用户地址和可读/可写权限
    -> 在桶锁保护下再次检查用户值
    -> 加入等待队列
    -> 设置 BLOCKED
    -> 释放桶锁并调度
```

唤醒方在同一桶锁下摘除 waiter、设置结果并转为 READY。值检查、入队和阻塞之间不能出现“检查完成后通知先发生、随后才入队”的窗口。线程退出和进程退出都调用取消函数，确保 waiter 不保留悬空线程或进程指针。

非法空地址、未对齐地址、跨页地址、只读地址、未映射地址和期望值不匹配都返回错误。被唤醒后用户态必须重新检查条件，以处理虚假唤醒。

### 3.8.2 用户 mutex

mutex 无竞争时使用用户态原子 CAS：

```text
0 = unlocked
1 = locked/no known waiter
2 = locked/has waiter
```

竞争时将状态改为 2 并进入 futex。解锁者使用 release 语义发布临界区写入，唤醒一个 waiter；加锁者使用 acquire 语义获取临界区数据。`owner_tid` 用于拒绝非持有者解锁和重复解锁。

### 3.8.3 条件变量

条件变量使用递增 sequence 作为 futex 值。waiter 先读取 sequence，再原子地释放 mutex 并等待 sequence 变化；返回后重新获得 mutex。调用者必须使用循环重新检查条件谓词：

```c
user_mutex_lock(&mutex);
while (!ready) {
    user_cond_wait(&condition, &mutex);
}
consume_data();
user_mutex_unlock(&mutex);
```

`signal` 唤醒一个等待者，`broadcast` 唤醒全部等待者。允许虚假唤醒，但不允许通知丢失。

### 3.8.4 用户 TLS

每个用户线程有独立 TLS 页，并通过 FS.base 指向自己的 TLS 结构：

```c
struct user_tls {
    uint64_t self;
    int errno_value;
    uint32_t reserved;
    uint64_t custom_value;
};
```

TLS 在创建线程时分配，在上下文切换和用户态返回时恢复 FS.base。`errno` 与自定义变量不共享，测试通过频繁切换线程确认每个线程读回自己的值。

## 3.9 系统调用和用户访问

系统调用覆盖：

```text
write/read/open/close/unlink
mkdir/stat/chdir/getcwd/list
dup/dup2/pipe
fork/spawn/exec/exit/wait/getpid/gettid
thread_create/thread_join/thread_detach/thread_exit/thread_yield
futex_wait/futex_wake
mmap/munmap
get_ticks/sleep/kill/ps/clear
send/receive
```

以 `write(fd, buf, len)` 为例：

1. 检查 fd 是否有效；
2. 检查 `buf..buf+len` 是否无溢出、可读且为用户范围；
3. 将用户数据复制到内核暂存区；
4. 根据 fd 类型进入 TTY、普通文件或管道路径；
5. 阻塞时只阻塞当前线程；
6. 返回写入字节数或负错误码。

`read` 的目标缓冲区则必须是完整可写用户范围，并在写入 COW 页时通过 COW fault 修复。字符串参数使用最大长度限制，防止在未映射区域中无限寻找结束符。

## 3.10 ATA PIO、MyFS 和缓存

ATA 读写流程采用状态轮询：检查设备就绪、写入 LBA 和扇区数、发送读写命令、等待 DRQ/错误位、传输 512 字节。驱动对超时和错误返回失败，不使用全零缓冲区伪装成功。

MyFS 的基本对象包括：

- 超级块：魔数、块大小、inode 区和数据区位置；
- inode 位图：记录 inode 分配状态；
- 数据块位图：记录数据块分配状态；
- inode：64 位文件大小、文件类型、11 个直接块和一级/二级/三级间接块；
- 目录项：名称和 inode 号；
- 根目录和子目录数据块。

文件写入按数据块分配，遇到空间不足或 ATA 错误时释放本次新分配块，恢复文件大小和 inode 指针。目录创建和 unlink 同样需要保证 inode 位图、目录项和数据块位图的一致性。

buffer cache 负责减少重复磁盘访问，并在写回时把脏块提交到 ATA。当前系统仍是教学型小型缓存，不具备完整日志式文件系统的崩溃一致性；突然断电时不能承诺所有元数据操作都具备事务原子性。

## 3.11 文件描述符、dup、管道与 Shell

进程 fd 表的 0、1、2 为标准输入、输出、错误；普通文件从 3 开始。`dup` 找到新的空槽并增加 file object 引用；`dup2` 先关闭目标槽位，再让目标 fd 指向源 file object。

管道由共享对象维护：

```text
读端引用数、写端引用数、环形缓冲、读等待队列、写等待队列
```

读端无数据时阻塞，写端无空间时阻塞，所有写端关闭后读端读到 EOF，所有读端关闭后写端返回错误。Shell 执行管道时创建 pipe、fork/spawn 两个子进程、分别 `dup2` 标准输入输出，再关闭父子不需要的端点。

重定向流程为打开目标文件、复制到 stdout/stderr 或 stdin、执行外部程序；父 Shell 等待前台任务时设置前台 PID，任务结束后清除。

## 3.12 Ctrl+C 问题的根因与修复

压力测试中曾出现：执行 `sync-demo.elf` 后按 Ctrl+C 无法终止前台程序，甚至 Shell 的前台 PID 变成 0。根因不是键盘扫描码，而是前台任务归属管理错误。

旧路径把 `foreground_pid` 当作所有 `process_wait` 的全局副作用。`sync-demo` 内部又会 fork 多个子进程并执行 wait，因此内部 wait 覆盖了 Shell 设置的前台 PID，随后清零。键盘中断到来时，TTY 找不到有效前台任务，Ctrl+C 只能作为普通输入或被丢弃。

修复方案是给进程增加 `terminal_controller` 标记：

- 只有 Shell 进程可以设置和清除终端前台 PID；
- 普通用户程序内部的 fork/wait 不得改变 TTY 前台归属；
- 子进程退出、被 kill 或 Shell wait 返回后清除前台 PID；
- Ctrl+C、Ctrl+\\、Ctrl+Z 通过前台进程终止请求进入进程生命周期路径。

修复后，输入压力测试加入多线程同步程序的 Ctrl+C 场景，并验证 Shell 能重新显示提示符、继续处理 20 条快速命令。该问题说明“终端控制权”和“父子进程关系”不能用一个全局变量隐式耦合。

## 3.13 用户态命令和演示程序

| 程序 | 主要使用方式 | 观察现象 |
| --- | --- | --- |
| `hello.elf` | `run hello.elf` | 输出 tick、执行 fork/exit/wait 并回到 Shell。 |
| `ipc-demo.elf` | `run ipc-demo.elf` | 父进程先发送阻塞，子进程接收后双方继续，显示 IPC PASSED。 |
| `thread-demo.elf` | `run thread-demo.elf` | 创建多个用户线程，共享数据并 join，显示 thread demo PASSED。 |
| `sync-demo.elf` | `run sync-demo.elf` | 高竞争 mutex、条件变量、futex、TLS、detach 和非法地址测试。 |
| `vm-demo.elf` | `run vm-demo.elf` | COW fork、匿名 mmap、部分 munmap 和栈增长测试。 |
| `fs-demo.elf` | `run fs-demo.elf` | 文件和目录创建、读取、删除和失败路径测试。 |
| `fault.elf` | `run fault.elf` | 故意触发 Ring 3 页错误，进程终止但 Shell 保持运行。 |
| `exec-demo.elf` | `run exec-demo.elf` | 当前映像通过 FS 服务替换为 `hello.elf`。 |
| `libc-demo.elf` | `run libc-demo.elf` | crt0、argv、格式化输出和 libc 分配器演示。 |
| `ls/cat/echo` | `ls /`、`cat file`、`echo text` | 基本目录、文件和输出操作。 |
| `mkdir/rm/pwd` | `mkdir d`、`rm f`、`pwd` | 目录创建、文件删除和 cwd 查询。 |
| `ps/sleep/kill` | `ps`、`sleep 20`、`kill pid` | 进程状态、定时阻塞和简化终止。 |

## 3.14 Modern VGA Shell 与 ORANGE/64 Showcase

Shell 保留 80x25 VGA 文本模式和 ASCII 输出，不使用 framebuffer、图形模式、Unicode、
动态字体或第三方库。`kernel/vga.c` 在 `print_init()` 中通过 VGA DAC（`0x3C8/0x3C9`）
应用深紫背景 `#300A24`、柔和白色 `#F2F2F2` 和红/绿/黄/青等状态色；VGA cell 的
默认属性仍为 `0x0F`。panic 使用的 `0x4F` 仍是红底白字，光标使用 CRTC 的块状形状。

启动后的 Shell 文本保持简洁：

```text
Orange/64 Terminal
Type 'help' to list commands.

orange@orange-os:/$
```

不再把 dashboard 卡片作为当前主题的一部分。Prompt 的用户名、host 和 cwd 均为 ASCII
文本；cwd 继续由成功的 `cd` 更新，控制键和控制台切换保留原有语义。

`kernel/tty.c` 只在未重定向的用户 TTY 输出路径解析有限 ANSI SGR：`ESC[0m`、
`ESC[1m`、`ESC[30-37m`、`ESC[90-97m` 和背景 `ESC[40-47m`。解析状态、颜色、
bold 标志和未完成序列都保存在每个 VGA console 中；`tty_write_colored` 仍是内核
原始彩色 API。`clear`、console 初始化会复位解析状态；未知、损坏或超过固定缓冲区
的序列会被丢弃，不写入 VGA/history。TTY 锁内的解析路径不分配内存、不打印日志。
Shell 在 stdout 被重定向或写入 pipe 时关闭自己的样式字节，普通文件和 pipe 内容
不会被 dashboard/prompt 的终端控制序列污染。

新增命令如下：

```text
orange@orange-os:/$ help
orange@orange-os:/$ about
orange@orange-os:/$ demo
```

`help` 使用不超过 80 列的纵向列表；`about` 清屏并重绘简洁欢迎页；`demo` 等价于
运行 `showcase.elf`。Shell 原有 Ctrl+C、Ctrl+\\、Ctrl+Z、Ctrl+L、
Ctrl+U、Ctrl+W、Ctrl+D、F1/F2/F3 和 PageUp/PageDown 行为保持不变。

ANSI SGR 解析是现有 WIP 的独立可选能力，不是主题门禁；本版默认 Shell 文本不发送
样式控制字节，因此重定向和 pipe 内容不会依赖 ANSI。若保留该解析器，它只能继续支持
固定的小子集，不能宣称为完整 ANSI/VT100 terminal emulator。

`showcase.elf` 完全运行在用户态，不增加展示专用内核 syscall，输出最多约两屏且
固定为以下六步：

```text
ORANGE/64 GUIDED TOUR
[1/6] SYSTEM
[2/6] PROCESS + COW
[3/6] IPC
[4/6] THREADS
[5/6] FILESYSTEM
[6/6] FAULT ISOLATION
RESULT 6 passed 0 failed
```

SYSTEM 使用 `getpid/get_ticks/ps` 显示 PID、ticks、进程数、线程数和当前用户页数；
PROCESS + COW 使用一页匿名 mmap、父子写入和 wait；IPC 验证指定来源、同步唤醒、
`0xC0DE` 回传和退出状态；THREADS 创建四个线程，用用户 mutex 更新共享 counter，
校验 TID、退出码和 counter；FILESYSTEM 创建或截断 `demo-proof.txt`，写入并重新
打开读取固定内容 `ORANGE/64 showcase proof v1`，然后 stat 并保留文件；FAULT
ISOLATION spawn `fault.elf`，确认异常退出后 showcase 仍能打印汇总。任一步失败只
增加失败数，最后以非零状态退出。

主题演示使用与默认磁盘隔离的入口：`make showcase-prepare` 创建或重建
`build/showcase-demo.img`，`make showcase` 以 512MiB、单核和标题
`Orange/64 Terminal` 启动正常 QEMU 窗口。`showcase.elf` 是独立的用户态功能导览，
本主题只将 `screendump` 生成的 `terminal-theme.ppm` 作为真实颜色验收 artifact。

限制：showcase 的 ticks、PID、TID 和页数是运行时值；MyFS 仍无日志式崩溃一致性，
文件持久化演示验证的是正常 QEMU 关闭/重启；Loader 的当前内核窗口仍是 188 sectors /
96,256B，新增内核代码必须继续通过 `make check`，不能用删除已有功能换取空间。

本轮主题验收（2026-08-15）记录如下：默认主题构建的 `kernel.bin` 为 92,036B，
修改前基线为 91,692B；VGA DAC 实际截图背景为约 `RGB(48,8,39)`，在目标
`#300A24` 的量化容差内。完整 `make check-all` 使用 seed `1786775869` 的 13 个
case 全部通过；`terminal-theme.ppm`、`vga.bin`、`vga.txt`、`qemu.log` 和结果元数据
位于 `build/test-artifacts/20260815-180436-12425-1786775869/showcase/core/1/`。

---

# 四、系统测试与验证

## 4.1 测试原则

测试分为静态构建测试、启动测试、子系统测试、集成测试和压力测试。测试的验收对象不是单一输出字符串，而是以下不变量：

- 失败路径不留下部分资源；
- 子进程异常不影响内核和 Shell；
- BLOCKED/ZOMBIE 线程不重新进入 ready queue；
- futex waiter 在唤醒、线程退出和进程退出后都能清零；
- COW 引用计数不下溢、不泄漏、不双重释放；
- 文件对象和 fd 引用数最终回到基线；
- 快速输入不会使 Shell 永久阻塞；
- QEMU 重启后文件内容仍然存在。

所有测试现由 `tests/run.sh` 统一编排，`tests/manifest.sh` 声明 suite、case、profile、timeout 和执行函数。公共逻辑位于 `tests/lib/`，负责临时工作目录、QEMU 生命周期、monitor/VGA、镜像、断言、事件和 artifacts。旧 `qemu_*.sh` 脚本仍作为迁移对照保留，但 Make target 已转发到统一 runner，不再由每个入口分别实现 QEMU 启停和清理。

runner 统一区分以下结果：断言失败、参数/manifest 错误、构建或依赖错误、超时和 QEMU/monitor 基础设施错误。每个 case 都写入 `result.env`、`environment.txt`、`command.txt`、`test.log` 和必要的 QEMU/VGA 现场，因此测试失败不能只依赖终端最后一屏判断。

## 4.2 静态构建检查

`make check` 调用 `tests/check_build.sh`，检查：

1. MBR 是否严格为 512 字节；
2. Loader 是否满足启动加载限制；
3. 内核二进制是否未超过 Loader 固定读取窗口；
4. 内核 ELF 是否为 x86_64 类型；
5. 用户 ELF 是否可被打包；
6. MyFS 超级块、魔数和块布局是否正确；
7. `BOOT_DIAGNOSTIC=0` 和 `BOOT_DIAGNOSTIC=1` 两种编译配置是否都能重新构建。

内核当前构建规模受 Loader 加载窗口约束，因此 Makefile 对 `thread.c`、`process.c` 和 `syscall.c` 使用大小优化选项。这是启动格式约束，不代表运行时接口被截断。

## 4.3 QEMU 测试矩阵

统一入口如下：

| 命令 | 作用 |
| --- | --- |
| `make test-list` | 只列出 manifest，不构建、不启动 QEMU。 |
| `make test-self` | 验证 list/filter、timeout=4、cleanup、重复 manifest 和 SIGTERM 处理。 |
| `make test-fast` | 运行 `build.artifacts` 与 `mkfs.index`。 |
| `make test CASE=vm.cow` | 只运行一个具名 case。 |
| `make test SUITE=mkfs` | 运行一个 suite 的全部 case。 |
| `make test CASE=sync.core REPEAT=3 SEED=20260815 KEEP_FAILED=1` | 固定 seed 重复运行并保留失败现场。 |
| `make test-all` | 运行 full profile。 |
| `make check-all` | 兼容的全矩阵入口，转发到 `make test-all`。 |

当前 manifest 包含 13 个 case：

| Case | Profile | 覆盖内容 |
| --- | --- | --- |
| `build.artifacts` | fast | MBR、Loader、Kernel、ELF 和 MyFS 静态检查。 |
| `mkfs.index` | fast | 64 位文件大小与多级索引镜像制作。 |
| `mkfs.lba48` | full | 超过 LBA28 边界的宿主机格式化。 |
| `boot.quiet` | full | 简略启动、storage gate、Shell ready 和稳定 VGA 快照。 |
| `lba48.boot` | full | 256GiB 稀疏盘和高 LBA MyFS 启动。 |
| `fs.service` | full | 持久化、目录、fd、dup、pipe 和资源回收。 |
| `tty.shell` | full | cwd、重定向、管道和 Shell 外部命令。 |
| `userland.core` | full | crt0、argv、libc、malloc、errno 和命令程序。 |
| `input.stress` | stress | Ctrl+C、Ctrl+\\、快速键盘输入和提示符恢复。 |
| `sync.core` | full | mutex、条件变量、futex、TLS、线程生命周期和压力。 |
| `vm.cow` | full | COW、mmap/munmap、栈增长、页故障和资源回收。 |
| `integration.smoke` | full | 启动、持久化、fork/exec、IPC、sync、VM 和异常隔离。 |
| `showcase.core` | full | 六步用户态 guided tour、prompt 恢复、proof 文件和重启持久化。 |

旧 `make qemu-*-check` 和 `make mkfs-*-check` 入口仍可使用，当前均转发到上表对应 case。新 runner 默认把结果写入 `build/test-artifacts/<run-id>/<suite>/<case>/<iteration>/`；可用 `ARTIFACTS_DIR` 改变根目录，用 `KEEP_FAILED=1` 保留失败工作目录。较长的 monitor socket 自动缩短到 `/tmp/oranges-qemu-*.sock`，因此运行 QEMU 测试的环境必须允许创建 Unix socket；若被沙箱拒绝，runner 会记录 `INFRASTRUCTURE_ERROR`，而不是误报为内核断言失败。

## 4.4 启动和文件系统测试

启动测试首先验证：

```text
启动摘要出现
没有未处理的磁盘 gate 错误
Shell ready 出现
```

文件持久化测试流程为：

```text
第一次启动
    -> Shell 执行 write persist persist-hello
    -> 关闭 QEMU
第二次启动
    -> Shell 执行 cat persist
    -> 必须读到 persist-hello
```

这个测试区分了真实磁盘持久化和仅存在于内核内存中的假成功。FS 自测还覆盖创建、读、写、追加、关闭、删除、目录、路径解析、单/双/三级索引的多个分支、间接块回滚和异常写入；`mkfs-index-check` 另外从宿主机直接检查大文件 inode 的索引指针。

## 4.5 进程、exec 和异常隔离测试

综合测试反复执行 `hello.elf`，验证 fork/exit/wait 的父子生命周期；执行 `exec-demo.elf`，验证当前进程通过文件系统加载并替换自己的映像；执行不存在的路径，验证 exec 失败时旧进程不会被错误销毁。

`fault.elf` 主动触发用户页错误。正确现象是：

```text
[Ring 3] deliberate page fault
run: child terminated by exception
orange$              # Shell 仍可继续使用
```

错误现象包括内核 panic、QEMU 自动重启、Shell 永久等待或异常子进程变成无法回收的 zombie。

## 4.6 多线程和同步压力测试

同步演示程序覆盖：

- 1、2、4、8、16 个线程竞争同一个 mutex；
- 每线程数万次加锁、更新共享计数和解锁；
- 多个 mutex 交错竞争；
- 条件变量单 waiter、多 waiter、单 signal 和 broadcast；
- signal 在 wait 前后发生；
- 随机 yield、定时器抢占和高竞争混合；
- join、detach、thread_exit 并发竞争；
- 线程阻塞在 futex 时进程退出；
- 非法、未对齐、跨页、只读、未映射 futex 地址；
- TLS errno 和用户自定义变量隔离；
- 连续创建和销毁大量用户线程。

脚本默认把同步测试重复 100 轮、worker 循环设置为 20000 次；可通过 `SYNC_TEST_ROUNDS` 和 `SYNC_WORKER_ROUNDS` 调整。每轮结束时检查：

```text
futex_waiters = 0
zombies = 0
线程数量回到基线
用户映射数和引用数一致
堆 arena/block/bytes 回到基线
文件对象和 pipe 对象回到基线
```

## 4.7 虚拟内存和 COW 测试

VM 测试覆盖：

1. fork 后父子初始共享物理页；
2. 只有父写时父获得独立副本；
3. 只有子写时子获得独立副本；
4. 父子都写时分别获得副本；
5. 多代 fork 后引用数逐级变化；
6. 任一方先退出时另一方映射仍然有效；
7. COW 新页分配失败时恢复原 PTE 和引用计数；
8. 只读代码页写入被判为权限错误；
9. 匿名 mmap、部分 munmap、重复 munmap 和地址冲突；
10. 栈按需增长和越界访问；
11. 每轮结束后用户页、页表页、refcount、进程和线程回到基线。

VM 测试通过 `VM_TEST_ROUNDS` 控制重复次数，默认值为 32。重点检查 refcount 下溢、悬空映射、父子 PTE 权限不一致和失败路径中的部分回滚。

## 4.8 输入压力和 Ctrl+C 验证

输入压力测试包括：

- 快速注入 20 条命令；
- 命令执行期间发送 Ctrl+C；
- 多线程同步程序作为前台任务时发送 Ctrl+C；
- 终止后检查 Shell 是否重新获得输入；
- 检查队列没有大量丢失普通字符；
- 检查提示符、当前行和前台 PID 状态恢复。

曾经失败的关键场景是：

```text
orange$ run sync-demo.elf
...同步程序持续输出...
按 Ctrl+C
```

修复后验收条件为：前台进程被终止或返回，Shell 重新打印提示符，随后 20 条快速命令仍能按顺序执行。这个测试同时验证了键盘扫描码、TTY 前台控制、进程终止、wait 返回、线程清理和输入队列恢复。

## 4.9 资源基线和验收口径

资源诊断在测试前后比较以下数据：

| 资源 | 检查方式 |
| --- | --- |
| PMM owner 页 | `pmm_get_stats` / owner 分类统计。 |
| 用户映射页 | `user_mapped_pages`。 |
| 用户映射引用 | `user_mapping_refs`，应与映射关系一致。 |
| 内核堆 arena | `kalloc` 统计。 |
| 活动 block | arena/block 统计。 |
| 已分配字节 | heap bytes 统计。 |
| 进程/线程 | runtime stats。 |
| zombie | 进程和线程状态统计。 |
| futex waiter | futex bucket 统计。 |
| 文件对象 | file object 引用统计。 |
| pipe 对象 | pipe 引用统计。 |

允许长期存在的对象包括内核进程、TTY 服务、FS 服务、Shell、内核高半区页表和启动保留页。除这些永久对象外，测试结束后新增资源应恢复到测试前基线。

当前 Shell 基线示例为：

```text
processes=2 threads=5 zombies=0 futex_waiters=0
user_mapped=7 user_refs=7
heap_arenas=1 heap_blocks=5 heap_bytes=240
```

基线会随 Shell ELF、TLS 和常驻服务变化，因此验收时应比较同一启动配置下的前后差值，而不能机械使用旧版本的固定数字。

## 4.10 已有测试结果与发布前要求

阶段 0/1 的冻结验收已经完成，不再使用“尚未重跑最终矩阵”的旧状态：

- 代码/测试冻结 commit `e07f6a0` 使用 seed `20260815` 执行 full profile，12/12 case 全部 PASS；证据位于 `build/baseline/2026-08/frozen-check-all-final2/20260815-101753-178844-20260815/`。
- `tests/selftest_runner.sh`、`make test-fast`、所有旧入口对照和 `make check-all` 均有 PASS 记录。
- `FLAKY-001` 的非原子 VGA 快照和 `FLAKY-002` 的子进程回收时序已经修复并关闭。
- 当前基线分支、commit/tag、工具链和产物哈希记录见 `docs/baselines/2026-08/` 与 `docs/milestones/`。

2026-08-15 在证据元数据 HEAD `55b5292` 上又进行了一次独立复核：

| 验证 | 结果 | Artifact |
| --- | --- | --- |
| Shell 语法、`--list`、runner selftest | PASS | 终端复核；manifest 共 13 case |
| `make test-fast` | PASS（2/2） | `build/test-artifacts/20260815-105948-85-1786762865/` |
| `make check-all` | 前 9 个 case PASS；`sync.core` 在 900 秒门限 TIMEOUT | `build/test-artifacts/20260815-110053-199644-1786568121/` |
| `sync.core`，10×20,000，seed 20260815 | PASS | `build/test-artifacts/20260815-112239-212651-20260815/` |
| `vm.cow`，默认 32 轮 | PASS | `build/test-artifacts/20260815-112423-213600-20260815/` |
| `integration.smoke`，sync 10×20,000、VM 32 轮 | PASS | `build/test-artifacts/20260815-112508-214015-20260815/` |
| `showcase.core`，seed 20260815 | PASS | `build/test-artifacts/20260815-141250-13695-20260815/` |
| 本轮显式矩阵：boot/tty/input/showcase/vm，seed 20260815 | PASS | 分别保留在 `build/test-artifacts/20260815-140746-10778-20260815/`、`20260815-140821-10964-20260815/`、`20260815-141051-12804-20260815/`、`20260815-141250-13695-20260815/`、`20260815-141337-14105-20260815/` |
| 本轮 `make check-all` | FAIL：`integration.smoke` 在 `thread-demo.elf` 加载处失败；不是 `INFRASTRUCTURE_ERROR`，也不是超时 | `build/test-artifacts/20260815-141503-14550-1786788656/` |

本分支最后一次 quiet `make check` 的 `kernel.bin` 为 91,692B；`showcase.core` 使用的
诊断启动构建为 93,500B，均低于 188 sectors / 96,256B。`showcase.elf` 为 26,440B。

本轮 `integration.smoke` 的失败现场显示，8GiB MyFS 镜像内的 `thread-demo.elf` 字节内容
与构建产物一致；干净启动后直接运行它在 64MiB 和保留的 8GiB 镜像上都通过，但在
`hello/exec/ipc/uaccess` 前置序列后加载失败。失败返回路径是既有 ELF loader 的
`[ELF] Failed to load.`，当前尚未定位到具体资源或地址空间原因，不能把这次
`make check-all` 记为全量通过。独立 `showcase.core` 仍完整通过；该集成回归风险需在
后续修复或复现后重新执行，不应通过降低轮次、增加 sleep 或跳过旧功能来掩盖。

本轮 full profile 的 sync 超时前已完成 mutex、condvar、broadcast、线程生命周期、detach 和 futex 参数校验，并持续输出 stress progress；没有 `sync demo FAILED` 或 QEMU 错误。同一代码冻结点此前在相同 900 秒 manifest 门限内完整通过，因此当前证据支持“阶段 0/1 功能完成”，但也暴露了默认 100×20,000 压力负载对宿主机性能敏感。不能把这次 TIMEOUT 写成 PASS，也不能仅靠无限重试掩盖。后续应把功能门禁和长压力 profile 的耗时预算分开，并记录宿主机/QEMU 版本、seed、轮次和实际耗时。

正式发布仍应执行：

```bash
make test-self
make test-fast
make check-all
```

若 `sync.core` 超时，先使用同一 seed 保留 artifact，再运行较低轮次确认功能路径；调整 manifest timeout 或压力规模必须作为独立测试策略变更评审，不能在失败后临时扩大门限并把原结果改写为通过。

---

# 五、与 Orange'S 原书章节的逐项对比

## 5.1 第一章：最小操作系统与引导扇区

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 512 字节最小系统 | 已完成 | `boot/mbr.S` 生成严格 512 字节 MBR。 |
| 引导扇区输出字符 | 已完成但实现不同 | 当前最终输出由内核 VGA/TTY 完成。 |
| 代码解释和回顾 | 已完成 | 通过源码注释、路线文档和本文说明。 |
| 水面下的冰山 | 已覆盖 | 通过 Loader、页表、PMM、异常和调度进入完整系统。 |

本项目没有停留在“打印一个字符”，而是保留该章的最小启动实验作为整个启动链的第一阶段。

## 5.2 第二章：工作环境、Bochs、QEMU 和调试

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| Bochs 初体验和安装 | 未实现专门适配 | 当前主验证平台为 QEMU。 |
| Bochs 调试 | 未实现专门脚本 | 可用通用工具调试，但没有原书同等配置。 |
| QEMU | 已完成 | `Makefile`、QEMU monitor 和多类测试脚本。 |
| GNU/Linux 开发环境 | 已完成 | GCC/NASM/binutils/QEMU 构建链。 |
| Windows 开发环境 | 未专门维护 | 没有承诺 Windows 原生脚本兼容。 |

## 5.3 第三章：保护模式、分页、中断和 I/O 权限

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 保护模式 | 已完成 | Loader 建立 GDT 并进入保护模式。 |
| GDT | 已完成 | 用于代码段、数据段、TSS 和特权切换。 |
| LDT | 未实现 | x86_64 采用分页和 Ring 3，不依赖 LDT 隔离。 |
| Ring 0/Ring 1 转移 | 替换为 Ring 0/Ring 3 | 更符合 x86_64 现代实现。 |
| 页式存储、PDE/PTE、CR3 | 已完成并扩展 | 使用 PML4/PDPT/PD/PT 四级页表。 |
| 8259A、IDT、外部中断 | 已完成 | PIC、IRQ0、IRQ1、异常入口。 |
| 时钟中断 | 已完成 | 时间片、sleep 和重新调度请求。 |
| IOPL、I/O 许可位图 | 未作为用户接口开放 | 用户态不能直接访问设备端口。 |

## 5.4 第四章：突破 512 字节、FAT12 和 Loader

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| FAT12 引导盘 | 未实现 | 使用固定 LBA 布局而非 FAT12。 |
| DOS 可识别引导盘 | 未作为目标 | 目标是 BIOS/QEMU 裸机启动。 |
| Loader 加载内核 | 已完成 | Loader 读取固定 LBA 的内核。 |
| 保护模式下运行内核 | 已完成并升级 | 进一步进入 x86_64 长模式和高半区。 |

## 5.5 第五章：C、汇编、ELF 和内核雏形

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| Linux 下汇编 Hello World | 已完成同类实验 | 用户态 crt0 和汇编入口存在。 |
| C 与汇编协作 | 已完成 | 启动、上下文切换、syscall、usermode 等均混合实现。 |
| ELF | 已完成 | 采用 ELF64 用户程序；Loader 对内核使用固定二进制加载。 |
| Loader 加载 ELF 内核 | 部分不同 | 当前用户 ELF 由内核加载，内核本身由 Loader 读取 raw binary。 |
| 内核堆栈、GDT、中断 | 已完成 | 进一步加入 TSS、用户栈和线程内核栈。 |
| Makefile 和目录整理 | 已完成并扩展 | 构建、安装、格式化、测试分离。 |

## 5.6 第六章：进程、系统调用和调度

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 进程概念 | 已完成 | PCB、PID、父子关系、地址空间。 |
| 简单进程 | 已完成 | Ring 3 用户进程。 |
| 多进程 | 已完成 | spawn、fork、wait、异常隔离。 |
| LDT 进程表 | 未实现 | 采用 CR3 + PTE U/S + Ring 3。 |
| 系统调用 | 已完成并扩展 | `syscall/sysretq`，不是 `int 0x90`。 |
| get_ticks | 已完成 | 直接系统调用；没有刻意改写为 IPC 消息。 |
| 优先级调度 | 部分完成 | 基础时间片轮转；复杂优先级策略未实现。 |

## 5.7 第七章：键盘、显示器、TTY 和 printf

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 键盘中断和扫描码 | 已完成 | PS/2 IRQ1、扫描码和控制键。 |
| 键盘缓冲区 | 已完成并扩容 | 环形队列、快速输入压力测试。 |
| TTY | 已完成 | 输入/输出服务和阻塞读取。 |
| 多控制台 | 已完成 | 三个 VGA 内存后备控制台，F1/F2/F3 切换。 |
| 区分任务和用户进程 | 已完成 | 内核服务线程与 Ring 3 进程分离。 |
| printf | 已完成 | libc 格式化输出和 write 系统调用。 |

## 5.8 第八章：IPC

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 微内核/宏内核讨论 | 已体现 | 采用宏内核中的内核服务线程，但使用消息边界。 |
| 消息结构 | 已完成 | 固定大小消息、来源 PID、类型和值。 |
| msg_send/msg_receive | 已完成 | 发送者/接收者队列和阻塞唤醒。 |
| 调度与消息结合 | 已完成 | IPC 阻塞直接进入调度器。 |
| 用 IPC 替代 get_ticks | 未完全照搬 | tick 保留为直接 syscall，TTY/FS 路径使用服务边界。 |

## 5.9 第九章：硬盘和文件系统

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| 硬盘和端口 | 已完成 | ATA PIO LBA 读写。 |
| MBR/分区表遍历 | 部分完成 | 固定 FS 起始 LBA，完整分区管理未实现。 |
| 设备号 | 部分完成 | 有设备访问边界，但不是完整 Unix 设备号体系。 |
| inode、目录项、路径 | 已完成 | MyFS inode/目录/相对绝对路径/cwd。 |
| open/close/read/write | 已完成 | 文件对象、fd 表和引用计数。 |
| 文件删除 | 已完成 | unlink 和位图回收。 |
| TTY 纳入文件系统 | 部分完成 | fd 语义接入 TTY，内部仍为 TTY 服务。 |
| printf 改造 | 已完成 | 用户 libc 通过 write 输出。 |
| 权限、链接、日志、挂载 | 未实现 | 属于后续完整 FS 方向。 |

## 5.10 第十章：fork、exit、wait、exec、Shell 和内存管理

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| fork | 已完成并增强 | 物理页引用计数 + COW，而非立即全量复制。 |
| exit/wait | 已完成 | zombie、退出码、父子回收和孤儿处理。 |
| exec | 已完成 | ELF64、FS 服务读取、成功/失败回滚。 |
| 用户应用编译安装 | 已完成 | Makefile 编译并由 mkfs 打包。 |
| 简单 Shell | 已完成并增强 | 外部命令、参数、cwd、管道、重定向、后台和控制键。 |
| 用户态线程 | 超出原书基础范围 | create/join/detach/exit、TLS 和 futex。 |
| mmap/VM | 超出原书基础范围 | VMA、匿名映射、munmap、栈增长。 |
| libc | 超出原书基础范围 | crt0、malloc、errno、格式化和用户 API。 |

## 5.11 第十一章：尾声、从硬盘引导和安装

| 原书内容 | 本项目情况 | 差异说明 |
| --- | --- | --- |
| mkfs 只执行一次 | 部分完成 | `bootstrap` 和 `format-fs` 已分离，默认不随 `run` 重建 FS。 |
| 硬盘引导扇区 | 已完成 | 当前磁盘镜像直接包含 MBR/Loader/内核。 |
| GRUB | 未采用 | 使用自有 MBR/Loader。 |
| 真实计算机安装 | 未作为验收目标 | 主要面向 QEMU。 |

总体来看，本项目覆盖了原书的主线功能，并在内存管理、线程同步、用户态运行时和自动化测试方面明显超出原书的最小实现；未覆盖部分主要集中在 32 位兼容路线、LDT、FAT12、完整分区体系、真实硬件安装和 POSIX 扩展。

---

# 六、当前边界与后续工作

## 6.1 近期应优先完成的工作

### 6.1.1 稳定 full 与 stress 的时间预算

阶段 0/1 已有冻结后的 12/12 PASS 证据，但独立复核中默认 `sync.core` 在较慢宿主环境达到 900 秒门限。应测量 10/50/100 轮的实际耗时，明确 full profile 是固定工作量还是固定时间预算，并把更重的随机重复放入 stress profile。需要分别记录 512MiB/1 CPU 和 2GiB/1 CPU 结果，超时必须保留 seed 和 artifacts。

### 6.1.2 进入阶段 2：串口和结构化事件

阶段 1 已统一宿主机 runner，但 QEMU case 仍主要依赖 sendkey 和 VGA 快照。下一步应实现 COM1 日志镜像、稳定的 `[TEST]`/`[RESOURCE]` 事件和 `isa-debug-exit`，使非交互 case 不再依赖屏幕最后一页，并让长压力测试能直接报告轮次进度。

### 6.1.3 完善失败诊断

在现有 `result.env`、environment、command、test/qemu/VGA artifacts 基础上增加统一资源前后差异、monitor 超时现场和可复制复现命令。日志应区分启动摘要、结构化测试事件和详细诊断，避免日常 Shell 被大量内部测试输出淹没。

## 6.2 中期工作

- 把 `struct process` 和 `struct thread` 进一步拆为独立模块，减少生命周期交叉；
- 完成统一的 wait queue 原语，供 wait、IPC、pipe、TTY、sleep 和 futex 复用；
- 增加锁顺序静态检查和调度状态断言；
- 完成文件系统缓存一致性和写回失败处理；
- 增加 VFS 层、文件类型操作表和更通用的设备 fd；
- 完善异常退出与简化信号模型；
- 扩展 Shell 的历史浏览模式、行编辑和后台任务状态。

## 6.3 长期工作

- AP 启动、per-CPU 数据、IPI 和真正 SMP 调度；
- DMA、磁盘命令队列和设备驱动恢复；
- 文件系统日志、挂载、权限、链接和动态容量；
- 共享内存、文件映射和 MAP_SHARED；
- 动态链接器、共享库和更完整 libc；
- 网络驱动、套接字和远程文件系统；
- 更完整的 POSIX 线程和信号语义。

---

# 七、附录

## 附录 A：常用操作速查

```bash
# 构建和静态检查
make build
make check

# 创建 256MiB 磁盘、1GB 内存、单 CPU 的默认实验环境
make DISK_IMAGE=build/images/orange-dev.img DISK_SIZE=256M bootstrap
make QEMU_MEMORY=1G QEMU_CPUS=1 run

# 只更新内核，保留用户文件
make install-kernel
make run

# 查看完整启动诊断
make BOOT_DIAGNOSTIC=1 run

# 运行单项回归
make test-list
make test-self
make test-fast
make test CASE=fs.service
make test CASE=tty.shell
make test CASE=input.stress
make test CASE=userland.core
make test CASE=sync.core SEED=20260815 KEEP_FAILED=1
make test CASE=vm.cow

# 最终全量验收
make check-all

# 兼容入口仍可使用，例如
make qemu-fs-check
make qemu-sync-check
```

## 附录 B：Shell 命令示例

```text
orange$ help
orange$ pwd
orange$ ls /
orange$ mkdir home
orange$ echo hello > /home/hello.txt
orange$ cat /home/hello.txt
orange$ echo second >> /home/hello.txt
orange$ cat /home/hello.txt
orange$ run hello.elf
orange$ run ipc-demo.elf
orange$ run thread-demo.elf
orange$ run sync-demo.elf
orange$ run vm-demo.elf
orange$ run fs-demo.elf
orange$ demo
orange$ cat demo-proof.txt
orange$ about
orange$ run fault.elf
orange$ ps
orange$ sleep 100 &
orange$ clear
orange$ exit
```

控制键：

| 组合键 | 行为 |
| --- | --- |
| Ctrl+C | 终止当前前台进程；没有前台进程时取消当前行。 |
| Ctrl+\\ | 终止当前前台进程，使用不同退出状态。 |
| Ctrl+Z | 当前版本以简化方式终止前台任务，完整停止/继续未实现。 |
| Ctrl+L | 清屏并重绘提示符。 |
| Ctrl+U | 清空当前输入行。 |
| Ctrl+W | 删除前一个单词。 |
| Ctrl+D | 空行时退出 Shell。 |
| PageUp/PageDown | 翻看控制台历史；输入行与浏览状态的进一步隔离属于后续改进。 |

## 附录 C：关键接口索引

```text
kernel/memory.h
    alloc_page_owned / free_page_owned
    pmm_acquire_user_mapping / pmm_release_user_mapping
    create_page_dir / map_page / unmap_user_page
    handle_cow_page_fault
    copy_from_user / copy_to_user / copy_string_from_user

kernel/process.h
    process_create_loaded
    process_create_thread
    process_fork / process_wait / process_exit
    process_mmap / process_munmap
    process_handle_page_fault

kernel/futex.h
    futex_wait / futex_wake
    futex_cancel_thread / futex_cancel_process

用户态
    sys_futex_wait / sys_futex_wake
    user_mutex_lock / user_mutex_unlock
    user_cond_wait / user_cond_signal / user_cond_broadcast
    user_tls_set_custom / user_tls_get_custom
```

## 附录 D：故障排查顺序

### 1. 启动失败

先执行 `make check`，检查 MBR、Loader 和内核大小；再使用 `BOOT_DIAGNOSTIC=1` 查看磁盘 gate、E820、页表和内核初始化信息。若磁盘读超时，先确认 QEMU 磁盘路径和镜像是否存在，不要把全零 MBR 当作有效磁盘。

### 2. Shell 不出现

检查 ELF 是否被 `mkfs` 打包、FS 是否被重新格式化、Loader 是否成功进入高半区内核，以及用户页表、主线程用户栈和 TLS 是否创建成功。

### 3. 命令输入卡住

区分是键盘队列、TTY 输入服务、Shell 行编辑还是前台进程 wait。使用 `qemu-input-stress-check`，并检查前台 PID 是否仍然有效、Shell 是否只由 `terminal_controller` 修改 foreground 状态。

### 4. 同步程序不返回

检查 futex 值验证、入队和阻塞是否在同一桶锁保护下；检查 waiter 是否在唤醒前已加入队列；检查线程退出和进程退出是否调用取消函数；最后比较 `futex_waiters`、zombie 和 thread 数量。

### 5. COW 或 mmap 泄漏

比较 fork 前后 PMM owner、用户映射数、用户引用数、页表页和 heap 统计；若只有一方写入，另一方退出后 refcount 应下降；COW 分配失败时父子 PTE 和 refcount 都应保持原状态。

### 6. 文件重启后消失

确认使用的是 `install-kernel` 而不是 `format-fs`，确认测试脚本没有每次启动重建 MyFS，并检查 ATA 写超时、超级块、inode 位图和数据块位图。

## 附录 E：最终验收清单

- [x] 基线分支、冻结 commit 和 annotated tag 可检出。
- [x] 环境、产物哈希、known issues 和阶段验收记录已归档。
- [x] `make test-list` 列出 13 个 manifest case。
- [x] `make test-self` 通过。
- [x] `make test-fast` 通过。
- [x] 冻结 commit 的 `make check-all` 通过（12/12）。
- [x] `boot.quiet`、`fs.service`、`tty.shell`、`userland.core`、`input.stress` 通过。
- [x] `vm.cow` 默认 32 轮通过。
- [x] `sync.core` 10×20,000 功能回归通过。
- [x] `integration.smoke` 在 sync 10×20,000、VM 32 轮下通过。
- [x] `showcase.core` 六步、prompt、proof 文件和重启持久化通过。
- [ ] 当前分支最新 `make check-all` 全量通过；本轮在 `integration.smoke` 的
  `thread-demo.elf` 加载阶段失败，现场已保留。
- [ ] 当前宿主环境再次执行默认 sync 100×20,000 时在 900 秒内通过。
- [ ] 2GiB/1 CPU QEMU 全量回归通过。
- [x] 冻结验收中的同步和线程生命周期压力测试连续 100 轮通过。
- [ ] PMM owner、refcount、heap、进程、线程、futex、file object 和 pipe 资源回到基线。
- [ ] 没有死锁、忙等、丢失唤醒、重复唤醒、双重释放或 zombie 泄漏。
- [ ] 文档中的“已完成”状态与源码、测试和限制保持一致。

---

## 结论

Orange'S x86_64 项目已经从一个启动实验发展为具备完整用户态运行闭环的教学操作系统：它能够启动、隔离用户程序、调度多个进程和线程、处理同步与阻塞、管理虚拟内存、读写持久化文件、运行 Shell 命令，并通过自动化测试观察资源是否正确回收。

它与原书的关系不是“完全相同的代码”，而是“相同的操作系统主线，不同的 64 位实现”。原书中的 MBR、保护、进程、TTY、IPC、文件系统和 Shell 主线均能在本项目中找到对应模块；LDT、FAT12、Ring 1、`int 0x90` 等 32 位路径则被四级页表、Ring 3、ELF64 和 `syscall` 替代。

路线图阶段 0 和阶段 1 已经完成：项目现在拥有可检出的冻结基线和统一测试入口。下一步重点是解决长压力测试预算对宿主机性能敏感的问题，并进入阶段 2，用 UART、结构化事件和自动退出取代非交互测试对 VGA/sendkey 的依赖；随后再推进统一内核测试 API、IPC/服务边界、安全启动、SMP、VFS、日志文件系统和网络等大型功能。
