# Orange'S x86_64 项目代码导读与演进方案

> 适用范围：当前工作区源码，而不只是 Git HEAD。仓库中存在大量尚未提交的功能扩展，本文以当前源码、Makefile、链接产物和测试脚本为准。

## 1. 项目概述与架构选型

### 1.1 项目定位

这是一个参考《Orange'S：一个操作系统的实现》教学主线、但采用现代 x86_64 机制重构的学习和实验型裸机操作系统。

- 目标平台：x86_64、传统 BIOS、QEMU。
- 内核形态：单体内核，带服务化内核线程设计，不是微内核。
- 启动方式：自研 MBR 和 Loader，不使用 GRUB 或 UEFI。
- 特权模型：Ring 0 内核加 Ring 3 用户程序。
- 内存模型：高半区内核、四级页表、物理内存直映射。
- 系统调用：x86-64 `SYSCALL/SYSRETQ`，不是原书的 `int 0x90`。
- 用户程序：静态 ELF64，当前没有动态链接器。
- 已支持能力：进程、用户线程、COW fork、匿名 mmap、futex、同步 IPC、MyFS、管道、TTY、基础 libc 和用户 Shell。

这个项目适合学习完整 OS 生命周期、资源管理和用户/内核边界，但目前不适合作为生产内核或真实硬件通用操作系统。

### 1.2 整体架构

```text
BIOS
  │
  ▼
MBR @ LBA 0
  │ 加载 Loader 和内核前段
  ▼
Loader @ LBA 2
  │ E820、A20、保护模式、四级页表、长模式
  ▼
高半区 Ring 0 内核
┌─────────────────────────────────────────────────────┐
│ syscall/uaccess                                     │
│     │                                               │
│     ├── 进程、线程、调度、VMA、COW、futex           │
│     ├── file object、fd、pipe                       │
│     └── 同步 IPC                                    │
│           ├── TTY 输入服务线程                      │
│           ├── TTY 输出服务线程（当前写路径多为直连）│
│           └── MyFS 服务线程                         │
│                                                     │
│ IDT ─ PIC ─ PIT/PS2      MyFS ─ buffer cache ─ ATA │
└───────────────────────┬─────────────────────────────┘
                        │ syscall/sysretq、iretq
                        ▼
Ring 3 用户态
┌─────────────────────────────────────────────────────┐
│ crt0 / libc / syscall wrapper                       │
│ shell、ls、cat、线程/同步/VM/IPC/FS 测试程序         │
└─────────────────────────────────────────────────────┘
```

“服务化”主要体现在 TTY 和 FS 通过内核线程与同步 IPC 划分职责，但这些服务仍共享 Ring 0 地址空间。普通文件读写等路径还会直接调用内核 FS 函数，所以整体仍属于单体内核。

### 1.3 核心设计理念

1. **64 位优先**：使用四级页表、高半区地址、ELF64 和 64 位系统调用参数。
2. **资源所有权显式化**：每个物理页记录 owner、保留状态和用户映射引用计数。
3. **用户边界集中检查**：系统调用通过 `copy_from_user`、`copy_to_user`，不直接信任用户指针。
4. **阻塞和唤醒**：IPC、TTY、pipe、sleep、wait、futex 等尽量阻塞线程，而不是持续轮询。
5. **失败路径回滚**：页表创建、COW、ELF 装载、mmap 和文件写入都考虑部分失败后的资源回收。
6. **自动化验收**：除功能输出外，还检查页、线程、futex、file object 等资源是否回到基线。

## 2. 核心功能与代码定位

### 2.1 内存管理

| 功能 | 实现方式 | 关键位置 |
| --- | --- | --- |
| E820/PMM 初始化 | Loader 将 E820 ARDS 写到物理 `0x500/0x504`；内核建立分配位图、保留位图、owner 和 refcount | `boot/loader.S`、`kernel/memory.c:init_phy_mem_map` |
| 物理页分配 | 位图上的线性 first-fit，支持连续页和 owner 校验 | `kernel/memory.c:alloc_pages_owned` |
| 高半区直映射 | `PAGE_OFFSET + paddr`；启动时映射前 1GiB，PMM 初始化后按 E820 扩展 | `kernel/memory.h`、`kernel/memory.c:build_kernel_direct_map` |
| 用户页表 | 创建独立 PML4，只复制 PML4[256..511] 的共享内核映射 | `kernel/memory.c:create_page_dir` |
| 页映射 | 四级页表按需创建，`map_page` 不覆盖已有映射 | `kernel/memory.c:map_page/remap_page` |
| 用户地址检查 | 检查低半区、溢出、跨页、P/U/RW/COW 权限 | `kernel/memory.c:user_range_*` |
| COW | fork 后共享物理页、清 RW、设置软件 `PTE_COW`；写页错误时复制 | `kernel/process.c:clone_user_address_space`、`kernel/memory.c:handle_cow_page_fault` |
| VMA/mmap | 链表描述 ELF 段、栈和匿名映射；匿名 mmap 当前提前分配全部页 | `kernel/process.h:vm_area`、`kernel/process.c:process_mmap` |
| 内核堆 | arena + block，支持切分、合并和空 arena 返还 PMM | `kernel/kalloc.c` |

关键地址：

```text
PAGE_OFFSET             = 0xFFFF800000000000
启动 PML4 物理地址      = 0x70000
PMM 元数据起点          = 0x200000
用户 mmap 默认起点      = 0x0000600000000000
用户线程栈分配区        = 0x00007FFFE0000000 向下
用户 TLS 分配区         = 0x00007FFFD0000000 向下
ELF 初始栈顶            = 0x00007FFFFFFFF000
```

### 2.2 进程、线程与调度

项目已经将 PCB 和 TCB 的逻辑职责分开：

- `struct process`：PID、父子关系、CR3、VMA、cwd、fd 表、进程状态。
- `struct thread`：TID、内核栈、用户栈、TLS、寄存器上下文和阻塞状态。

关键代码：

- PCB：`kernel/process.h:struct process`
- TCB：`kernel/thread.h:struct thread`
- 进程创建与 ELF 线程初始化：`kernel/process.c:process_create_loaded`
- 用户线程创建：`kernel/process.c:process_create_thread`
- fork/COW：`kernel/process.c:process_fork`
- exit/wait/zombie：`kernel/process.c:process_exit/process_wait`

调度算法是单 CPU 环形链表上的时间片轮转：

1. `priority` 当前实际表示每轮时间片长度。
2. PIT 以 100Hz 递减 `ticks`。
3. 时间片用尽时设置 `need_resched`。
4. `schedule()` 跳过 BLOCKED、ZOMBIE、DEAD 线程，选择下一个 READY 线程。
5. 更新 CR3、TSS.RSP0、用户 TLS 的 FS.base 和 per-CPU 栈状态。
6. `switch_to` 保存/恢复 callee-saved 寄存器并切换内核栈。

定位：

- 调度器：`kernel/thread.c:schedule`
- 汇编切换：`kernel/switch.S:switch_to`
- 时钟抢占：`kernel/timer.c:timer_interrupt_handler`
- 线程状态和生命周期：`kernel/thread.h`

IPC 是同步 rendezvous 模型：

- 接收者已等待时，消息直接交付并唤醒接收者。
- 接收者未等待时，发送者进入接收者的 sender queue 并阻塞。
- `receive(IPC_ANY)` 或指定 PID 匹配发送者。
- 进程退出时撤销 IPC 等待，避免队列中留下悬空 TCB。

实现位于 `kernel/ipc.c`。此外还有 futex 哈希桶、sleep 有序队列和 pipe 阻塞读写。

### 2.3 中断、异常与系统调用

中断体系：

- GDT/TSS：`kernel/gdt.c`
- IDT 描述符：`kernel/idt.h`
- IDT 初始化与处理：`kernel/idt.c`
- PIC 重映射：`kernel/pic.c`

当前实际注册的 IDT 向量只有：

- 0：除零
- 13：GPF
- 14：页错误
- 32：PIT
- 33：键盘

页错误处理顺序：

```text
用户态写保护故障
    -> 是否为 COW
    -> 修复 PTE 或复制页面
非 present 用户故障
    -> 是否命中 VM_GROWSDOWN 栈 VMA
    -> 分配栈页
否则
    -> 终止当前用户进程
```

系统调用不通过 IDT，而是使用 MSR 入口：

- STAR/LSTAR/FMASK：`kernel/syscall.c:syscall_init`
- 汇编入口：`kernel/syscall_entry.S`
- 分发器：`kernel/syscall.c:syscall_handler_impl`
- 用户包装：`usr/syscall.h:syscall3`

ABI：

```text
RAX = syscall number
RDI = arg1
RSI = arg2
RDX = arg3
RAX = return value
```

当前只有三个直接参数；更多参数需要打包结构体或扩展入口约定。

### 2.4 文件系统与 I/O

当前没有完整 VFS。`file_object` 是一层有限统一抽象，只支持普通文件、pipe read end 和 pipe write end。

```text
fd table
   -> file_object
      ├── regular file -> inode/MyFS
      ├── pipe read
      └── pipe write
```

关键位置：

- fd/file object/pipe：`kernel/file.h`、`kernel/file.c`
- MyFS 格式：`kernel/fs.h`
- buffer cache：`kernel/fs.c:cache_get/cache_sync`
- inode 块索引：`kernel/fs.c:inode_data_block`
- 路径和目录：`kernel/fs.c`
- 挂载与超级块验证：`kernel/fs.c:fs_init`
- FS 服务线程：`kernel/fs.c:fs_service_main`
- 宿主机 mkfs：`tools/mkfs.c`

MyFS v4 特征：

- 4KiB 块。
- 72B inode。
- 64B 目录项。
- 11 个直接块。
- 一级、二级、三级间接索引。
- inode bitmap 和 data bitmap。
- 16 项 write-back block cache。
- 支持多级目录、绝对/相对路径、`.`、`..` 和每进程 cwd。

实际服务边界需要特别注意：路径操作和 ELF 加载通过 FS 服务线程；普通已打开文件的 `read/write` 会由 `file.c` 直接调用 inode 层。这是服务化单体内核，而不是微内核或完整 VFS。

### 2.5 驱动与硬件

| 硬件 | 实现 | 代码 |
| --- | --- | --- |
| 显示 | VGA 文本模式 `0xB8000`，三个内存后备控制台 | `kernel/tty.c` |
| 键盘 | PS/2 扫描码、Shift/Caps/Ctrl、F1-F3、PageUp/Down | `kernel/keyboard.c` |
| 时钟 | PIT 8253/8254，端口 `0x43/0x40`，100Hz | `kernel/timer.c` |
| 中断控制器 | 双 8259A PIC，仅开放 IRQ0/IRQ1 | `kernel/pic.c` |
| 磁盘 | ATA primary master，LBA48 EXT 轮询 PIO | `kernel/disk.c` |

当前没有 UART/串口、APIC、IOAPIC、PLIC、PCI 枚举或 DMA。

## 3. 关键执行流与核心数据结构

### 3.1 从 BIOS 到第一个用户程序

```text
BIOS
  -> 将 LBA0 加载到 0x7C00
  -> MBR 从 LBA2 读取 50 个扇区到 0x900
  -> 跳转 0x900
  -> Loader BIOS E820 探测，结果写入 0x500/0x504
  -> Loader 读取内核剩余 LBA52..197
  -> 开启 A20
  -> 进入 32 位保护模式
  -> 在 0x70000 建 PML4
  -> 同时建立低地址和 PAGE_OFFSET 高半区映射
  -> CR4.PAE、EFER.LME、CR0.PG
  -> 进入长模式
  -> RSP = 0xFFFF800000090000
  -> 跳到 0xFFFF800000001900
  -> kernel_main
```

`kernel_main()` 初始化顺序：

```text
显示
-> IDT/PIC/PIT/GDT
-> PMM/直映射
-> 内核堆
-> TTY/键盘
-> process/thread
-> futex/IPC/TTY 服务
-> syscall MSR
-> sti
-> ATA
-> MyFS mount
-> FS 服务
-> 用户 ELF
```

正常 quiet 启动时第一个用户程序是 `shell.elf`；`BOOT_DIAGNOSTIC=1` 时会先运行 `hello.elf` 和 `fs-demo.elf`，再启动 Shell。

用户 ELF 生命周期：

1. FS 服务 `stat/read` ELF。
2. 校验 ELF 魔数。
3. 创建新 PML4。
4. 为每个 `PT_LOAD` 分配用户页并复制数据。
5. 创建用户栈，构造 `argc/argv`。
6. 创建 `process + main thread`。
7. 伪造 `iretq` 用户返回帧。
8. 把线程加入调度环。
9. 调度器切 CR3。
10. `return_to_user -> swapgs -> iretq` 进入 Ring 3。

对应文件为 `kernel/elf.c`、`kernel/process.c` 和 `kernel/usermode.S`。

### 3.2 一次系统调用的完整流转

以 `write(1, buffer, len)` 为例：

1. 用户 wrapper 把编号放入 RAX，参数放入 RDI/RSI/RDX，执行 `syscall`。
2. CPU 把用户 RIP 保存到 RCX，把 RFLAGS 保存到 R11，从 LSTAR 取入口，并按 FMASK 清 IF。CPU 不自动切内核栈。
3. `syscall_entry` 执行 `swapgs`，保存用户 RSP，切换当前线程内核栈，保存寄存器，并保留一份可供 fork 复制的 14 qword syscall frame。
4. C 分发器验证长度和用户页，把数据复制到内核 staging buffer，再调用 TTY 或普通文件写入路径。
5. 返回路径恢复寄存器和用户 RSP，执行 `swapgs` 和 `sysretq`。
6. 如果系统调用中阻塞，调度器还会切换 CR3、TSS.RSP0、内核栈、FS.base/TLS 和 per-CPU GS 数据。

fork 子进程不会从 C 分发器正常返回，而是从复制的 syscall frame 进入 `syscall_child_return`，将 RAX 清零后走共同返回路径。

### 3.3 核心结构体

| 结构 | 关键字段 |
| --- | --- |
| `struct process` | `pid/state/exit_status/cr3_paddr/parent/children/thread_head/cwd/vma_head/fd tables/locks` |
| `struct thread` | `rsp/user_rsp/tid/ticks/priority/status/kernel_stack/user_stack/tls/process/futex/ipc/sleep` |
| `struct thread_context` | `r15..r12/rbx/rbp/rip`，与 `switch.S` 栈布局匹配 |
| `struct interrupt_frame` | `rip/cs/rflags/rsp/ss`，表示 CPU 异常或中断帧 |
| `struct vm_area` | `[start,end)`、VM 权限、文件预留字段和链表 |
| `Bitmap` | allocated bits、reserved bits、owners、refcounts |
| `struct inode` | size/type/link_count/11 direct/3 levels indirect |
| `struct message` | `source_pid/type/value` |

需要注意：

1. 项目没有统一 `TrapFrame`。中断使用 `interrupt_frame`，调度使用 `thread_context`，syscall 由汇编手工维护 14 个 qword 的栈帧。
2. PTE 不是结构体，而是原始 `uint64_t`。当前定义了 P、RW、US、PS 和软件 COW 位。

## 4. 构建、运行与调试

### 4.1 构建流程

项目只使用 Makefile，没有 CMake。

```bash
make build      # 构建，不写入磁盘镜像
make check      # 构建并执行静态产物检查
make bootstrap  # 安装内核并重新格式化 MyFS
make run        # 更新 MBR/Loader/Kernel 后启动 QEMU
```

构建过程：

- 所有 `kernel/*.c` 自动加入内核。
- 汇编对象显式列出。
- 内核使用 `-ffreestanding -mcmodel=large -mno-red-zone`。
- `process.c/thread.c/syscall.c` 使用 `-Os` 控制固定加载窗口。
- 链接为高半区 ELF，再由 `objcopy` 生成 flat binary。
- 用户程序静态链接为 ELF64。
- `mkfs` 将全部 `USER_APPS` 打包进 MyFS。

### 4.2 链接与镜像布局

```text
KERNEL_LMA = 0x1900
KERNEL_VMA = 0xFFFF800000000000 + 0x1900
```

磁盘布局：

| 区域 | 位置 |
| --- | --- |
| MBR | LBA 0 |
| 空隙 | LBA 1 |
| Loader | LBA 2 起 |
| 内核 | LBA 10 起 |
| 内核最大加载窗口 | 188 sectors = 96,256B |
| MyFS | LBA 1000 起 |

当前现成产物的静态检查结果：

```text
MBR          512B
Loader       509B
Kernel       92,348B
Kernel 上限  96,256B
剩余空间     3,908B
```

当前内核已经非常接近固定 Loader 窗口上限。另一个需要注意的链接结果是，`ld -N` 使内核形成单一 RWE LOAD segment，`.text` 和 GNU stack 也可写可执行，不满足生产内核的 W^X 要求。

### 4.3 QEMU

首次使用或添加新用户程序：

```bash
make DISK_IMAGE=hd128M.img DISK_SIZE=128M bootstrap
make DISK_IMAGE=hd128M.img QEMU_MEMORY=1G QEMU_CPUS=1 run
```

只修改内核并保留文件系统：

```bash
make install-kernel
make run
```

注意：

- `format-fs` 和 `bootstrap` 会覆盖所选镜像中的 MyFS。
- 当前必须保持 `QEMU_CPUS=1`。
- 默认使用 VGA 窗口，没有串口输出。

### 4.4 GDB

终端一：

```bash
# 如果镜像尚未格式化，先执行一次 make bootstrap
make debug
```

终端二：

```bash
gdb build/kernel/kernel.elf
```

GDB 中：

```gdb
set disassembly-flavor intel
target remote :1234

hbreak *0x7c00
continue
hbreak *0x900
continue
hbreak kernel_main
continue

break syscall_handler
break schedule
break isr14_page_fault
continue
```

常用命令：

```gdb
info registers
p/x $cr3
x/16gx $rsp
x/10i $rip
layout asm
layout regs
monitor info registers
```

调试用户程序时，可在对应地址空间建立后使用：

```gdb
add-symbol-file build/shell.elf
break _start
```

多个用户 ELF 通常链接到相近低地址，切换目标程序后应删除旧符号再加载新 ELF。

## 5. 当前测试体系

### 5.1 测试层次

当前测试分四层。

内核启动期单元和不变量测试：

- PMM owner、连续分配、重复释放。
- kmalloc 碎片、double-free、arena 回收。
- 页表映射和 COW 分配失败回滚。
- 内核线程竞争和生命周期。

实现位于 `kernel/test.c`，仅在 `BOOT_DIAGNOSTIC=1` 时运行。

用户态功能程序：

- `hello.elf`：write、ticks、FS、fork/wait。
- `uaccess-demo.elf`：非法和跨页用户指针。
- `thread-demo.elf`：线程生命周期。
- `sync-demo.elf`：futex、mutex、condvar、TLS 压力。
- `vm-demo.elf`：COW、mmap、munmap、栈增长。
- `fault.elf`：用户页错误隔离。
- `fs-demo.elf`：目录、fd、pipe 等。

宿主机静态测试：

- MBR、Loader、Kernel 尺寸。
- ELF64 架构。
- MyFS 魔数。
- mkfs 大文件间接索引和 LBA48。

QEMU 集成测试：

```bash
make qemu-boot-check
make qemu-fs-check
make qemu-shell-fs-check
make qemu-input-stress-check
make qemu-userland-check
make qemu-sync-check
make qemu-vm-check
make check-all
```

`make check-all` 是本地自动回归入口，目前通过 `make test-all` 转发到
`tests/run.sh --profile full`；保留的 `tests/check_all.sh` 是迁移前的旧编排，
可用于历史对照。QEMU suite 仍通过 monitor 的 `sendkey` 注入输入，并通过
`pmemsave 0xb8000` 读取 VGA 文本进行断言。仓库当前没有 GitHub Actions 或
GitLab CI。

### 5.2 添加新系统调用

以 `getppid()`、编号 37 为例：

1. 在 `kernel/syscall.h` 和 `usr/syscall.h` 同时增加 `SYS_GETPPID 37`。
2. 在用户头文件中增加 `sys_getppid()` wrapper。
3. 在 `kernel/syscall.c` 的分发器中返回当前进程父 PID。
4. 如需 libc API，再修改 `usr/libc.h` 和 `usr/libc.c`。
5. 新增用户测试：父进程记录 PID，fork 后子进程断言 `getppid() == parent_pid`，通过 exit status 将结果交给父进程。
6. 修改 Makefile，将测试 ELF 加入 `USER_APPS`。
7. 使用临时磁盘执行 `bootstrap`，确保新 ELF 被打包进 MyFS。
8. 在 QEMU 测试中加入执行命令和成功结果断言。

新增系统调用时最容易遗漏的是两份 syscall 编号头文件，以及重新生成 MyFS 以打包新 ELF。

## 6. 设计亮点与当前局限

### 6.1 设计亮点

- COW 包含引用计数、父方延迟修改 PTE、失败回滚和单引用快速恢复 RW。
- PMM 同时记录 owner、reserved 和 user mapping refcount，便于定位泄漏。
- 用户内存检查覆盖跨页、整数溢出、字符串终止和 COW 写入。
- 进程资源与线程调度状态已经明显拆分，支持同地址空间多线程和独立 TLS。
- fork 子进程通过复制 syscall 返回现场自然得到返回值 0。
- 用户异常不会默认拖垮内核，Shell 可以继续运行。
- FS 有真实跨重启持久化测试，不只是内存缓存演示。
- 测试重视资源回到基线。
- `bootstrap`、`install-kernel`、`format-fs` 分开，降低日常开发误删文件系统的风险。

### 6.2 当前局限

处理器与调度：

- 单核，无 AP 启动、IPI、完整 per-CPU 和 SMP 调度。
- 没有 APIC/IOAPIC，只使用 8259A PIC。
- 简单轮转，没有真正优先级队列、负载均衡或实时策略。

内存与安全：

- 已支持 COW，但没有 Swap。
- 匿名 mmap 是 eager allocation，不是按需匿名分页。
- 不支持文件映射、`MAP_SHARED`、共享内存和页缓存。
- 未实现 NX PTE，VMA EXEC 目前主要是元数据。
- 内核 ELF 和栈当前可写可执行。
- 无 ASLR，用户 ELF 使用固定地址。
- PMM 连续页分配为线性扫描。
- ELF 校验可继续加强 machine、program header 边界、重叠和整数溢出检查。

启动与异常：

- 仅支持传统 BIOS，不支持 UEFI。
- 内核加载窗口固定，当前只剩约 3.8KiB。
- Loader 没有显式清零完整 `.bss`，真实硬件不应依赖初始 RAM 为零。
- IDT 只安装少数异常；double fault、invalid opcode、NMI 等没有可靠 handler。
- 没有 IST 独立异常栈。

文件系统与驱动：

- 没有真正 VFS、多文件系统挂载或设备文件框架。
- MyFS 无权限、用户/组、链接 API、日志和崩溃一致性。
- 固定 `FS_START_LBA`，不解析完整分区表。
- ATA 仅支持一个 primary master，轮询 PIO，无 DMA、NCQ 和设备发现。
- 无 UART、网络、USB、PCI、图形 framebuffer 和音频驱动。

用户态与工程：

- 无动态链接器和共享库。
- `kill` 只是终止请求，不是完整信号机制。
- Ctrl+Z 没有 stopped/continued 状态和完整 job control。
- fork/exec 对多线程进程采取拒绝策略。
- syscall ABI 只有三个参数，错误码多数统一为 `-1`。
- 有本地回归脚本，但没有持续集成配置。

## 7. 与原版 Orange'S 的比较和建议补齐项

### 7.1 已经覆盖或超出原书的部分

当前项目已经覆盖原书的主要可观察教学闭环：

- MBR、Loader、保护模式和内核启动。
- 进程、时间片调度和上下文切换。
- 键盘、TTY、多控制台和时钟。
- 同步 IPC。
- ATA 磁盘、inode 文件系统和用户 Shell。
- fork、exec、exit、wait。

在以下方向已经明显超出原书基础实现：

- x86_64 高半区内核和四级页表。
- 用户/内核地址空间隔离。
- COW fork 和用户页引用计数。
- 用户线程、TLS、futex、mutex、条件变量。
- VMA、匿名 mmap、部分 munmap 和按需栈增长。
- fd 引用计数、dup/dup2、pipe、重定向。
- 用户态 libc 和较完整的自动化回归。

### 7.2 若追求 Orange'S 架构语义，应优先补齐

| 优先级 | 建议项 | 当前差距 | 目标 |
| --- | --- | --- | --- |
| P0 | IPC `send_recv` 和死锁检测 | 当前只有 send/receive，缺少完整组合操作和发送依赖环检查 | 更接近原书 IPC 语义，能诊断 A→B→C→A 的发送死锁 |
| P0 | 统一系统服务请求协议 | TTY、FS、普通文件和磁盘路径的服务边界不一致 | 统一 message header、request ID、status、超时/取消语义 |
| P1 | 独立 HD/block service | ATA 仍由 FS 或调用者直接进入 | 形成 `FS -> block service -> ATA` 路径，并为以后增加设备留接口 |
| P1 | 分区与块设备抽象 | 固定 FS 起始 LBA，不解析 MBR 分区 | 支持 block device、partition 和 LBA 边界检查 |
| P1 | 统一 wait queue | IPC、pipe、TTY、sleep、futex 各自维护等待逻辑 | 减少丢失唤醒、重复节点和退出清理错误 |
| P2 | 服务线程隔离边界 | 当前服务是 kernel process 内的 Ring 0 线程 | 至少形成独立 kernel service process；更进一步可做 Ring 3 server 实验 |
| P2 | IPC tracing | IPC 阻塞问题难定位 | 输出 source/destination/type/request ID 和状态迁移 |

这里不建议为了“代码长得像原书”而回退到 32 位、LDT、Ring 1 或 `int 0x90`。更有价值的是补足原书强调的服务边界、消息语义和可诊断性。

### 7.3 若希望继续演进为现代教学 OS，建议补齐

第一组是稳定性和安全基础，优先于增加更多 syscall：

1. 显式清零 `.bss`，解除对 QEMU 初始 RAM 的依赖。
2. 完整异常表、double-fault IST、NMI 和 panic 上下文转储。
3. 启用 EFER.NXE、PTE NX 和内核/用户 W^X。
4. 加强 ELF64 header、program header、地址范围和段重叠验证。
5. 移除固定 188 扇区限制，改为 Loader 读取内核长度或加载 ELF kernel。
6. 增加 UART COM1 日志，这是统一测试和故障定位的基础设施。

第二组是内核抽象：

1. VFS、inode/file operations 和设备文件。
2. block device 与 partition 层。
3. 通用 wait queue、completion 和 event 原语。
4. per-CPU 数据结构，为 SMP 做准备。
5. 页缓存、按需匿名分页、文件 mmap 和共享内存。

第三组是高级能力：

1. APIC/IOAPIC、AP 启动、IPI、SMP 调度。
2. PCI 枚举、virtio-blk/virtio-net。
3. 文件系统日志和崩溃一致性。
4. POSIX 风格信号和 job control。
5. socket、网络协议栈、动态链接器和共享库。

## 8. 统一测试体系设计

### 8.1 当前问题

现有测试覆盖面不错，但故障定位成本较高：

- 多个 QEMU 脚本重复实现启动、monitor、sendkey、VGA 解码和 cleanup。
- 主要依赖 VGA 文本和 Shell 输入，速度慢且容易受时序影响。
- 成功字符串很多，但失败时缺少统一 case ID、阶段和资源差异。
- 内核测试、用户测试、Shell 集成测试采用不同报告格式。
- 测试入口较多，不容易快速回答“某个 case 属于哪个 suite”。
- 完整 `check-all` 时间较长，缺少统一 filter、repeat、seed 和保留现场选项。
- 没有 CI 对结果进行长期保存和展示。

### 8.2 目标测试分层

```text
L0 host/static
   编译、链接、镜像布局、mkfs、纯算法宿主机测试

L1 kernel/unit
   PMM、heap、page table、scheduler、IPC、wait queue 不变量

L2 user/subsystem
   syscall、process、thread、VM、FS、TTY、futex 独立用户程序

L3 integration
   boot -> init/test-runner -> 多子系统组合

L4 stress/matrix
   多轮同步、内存规模、磁盘规模、重复启动、故障注入
```

每层都使用统一结果格式：

```text
[TEST] suite=vm case=cow-parent-write state=START
[TEST] suite=vm case=cow-parent-write state=PASS duration_ms=12
[TEST] suite=vm case=cow-parent-write state=FAIL code=214 detail=unexpected-status
[RESOURCE] pmm_free=... user_refs=... threads=... futex_waiters=...
```

### 8.3 建议目录结构

```text
tests/
├── run.sh                  # 唯一对外入口
├── manifest.sh             # suite/case/timeout/matrix 定义
├── lib/
│   ├── common.sh           # assert、日志、临时目录、超时
│   ├── qemu.sh             # QEMU 生命周期、monitor、退出
│   ├── serial.sh           # 串口日志等待和事件解析
│   ├── image.sh            # 临时磁盘和 MyFS 操作
│   └── artifacts.sh        # 失败现场收集
├── suites/
│   ├── build.sh
│   ├── boot.sh
│   ├── process.sh
│   ├── vm.sh
│   ├── fs.sh
│   ├── sync.sh
│   └── shell.sh
└── artifacts/              # 默认在 build/test-artifacts 下生成
```

兼容入口可以保留：旧的 `make qemu-vm-check` 内部转为调用 `tests/run.sh --suite vm`，避免一次性破坏现有使用习惯。

### 8.4 统一命令接口

建议最终提供：

```bash
make test-list
make test-fast
make test SUITE=vm
make test SUITE=vm CASE=cow-parent-write
make test SUITE=sync REPEAT=100 SEED=1234
make test-all
make test-all KEEP_FAILED=1
```

`tests/run.sh` 应支持：

```text
--list
--suite <name>
--case <name>
--repeat <n>
--seed <n>
--timeout <seconds>
--keep-failed
--junit <path>
```

### 8.5 优先增加 UART 和 test exit

统一测试的第一项内核能力应是 COM1 UART：

- 初始化 `0x3F8`。
- 内核日志可选择同时输出到 VGA 和串口。
- 用户测试结果通过 syscall 最终进入串口日志。
- QEMU 使用 `-serial file:...` 或 `-serial stdio`。
- 测试脚本不再通过 `pmemsave` 才能获得完整历史。

同时增加 QEMU test exit：

- QEMU 启动时加入 `-device isa-debug-exit,iobase=0xf4,iosize=0x04`。
- test runner 完成后向 `0xF4` 写入结果。
- 成功、失败和超时由 QEMU 退出码明确区分。

VGA/sendkey 测试只保留给真正需要验证交互输入、控制台切换和 Shell 行编辑的 suite。

### 8.6 统一资源基线

增加统一的 `runtime_snapshot`：

```c
struct runtime_snapshot {
    struct pmm_stats pmm;
    struct kalloc_stats heap;
    struct process_runtime_stats process;
    struct futex_stats futex;
    struct file_runtime_stats file;
};
```

每个用户测试或内核 case 执行：

```text
snapshot before
-> run case
-> reap child/threads
-> snapshot after
-> assert expected delta or exact baseline
```

失败时统一打印字段差异，而不是只打印一行 `FAILED`。这样可以直接判断问题属于用户页泄漏、页表页泄漏、zombie、futex waiter、file object 或 heap arena。

### 8.7 失败现场

每个失败 case 自动保留：

```text
serial.log
qemu.log
vga.bin/vga.txt
monitor-info.txt
test.env
kernel.elf
kernel.asm
disk.img（可配置，仅失败时保留）
resource-before.txt
resource-after.txt
```

最终只输出一条明确路径：

```text
[FAIL] suite=vm case=cow-parent-write artifacts=build/test-artifacts/...
```

## 9. 分阶段行动方案

本节是路线摘要。任务编号、代码落点、测试 runner 接口、日志协议、验收门禁、风险与前两个迭代安排见 [`docs/roadmap-execution-plan.md`](roadmap-execution-plan.md)。

### 阶段 0：冻结基线和文档统一

目标：先确保所有人分析的是同一版本。

- [ ] 提交或建立当前工作区基线分支（等待维护者确认脏工作树纳入范围）。
- [x] 以本文和当前源码为准，清理旧文档中的 112/188 扇区、COW、进程回收等冲突描述。
- [x] 记录一次完整 `make check-all` 结果和环境版本。
- [x] 建立缺陷清单，区分“已知限制”和“回归错误”。

验收：能从 commit ID、编译器版本和 QEMU 版本复现当前结果。

### 阶段 1：测试脚本去重

目标：不改变测试语义，先统一宿主机框架。

- [x] 提取 `tests/lib/common.sh`、`qemu.sh`、`image.sh`。
- [x] 统一临时目录、QEMU cleanup、monitor、timeout 和断言。
- [x] 新建 `tests/run.sh` 与 manifest。
- [x] 旧 Make target 转发到新 runner。
- [x] 支持 `--list/--suite/--case/--repeat/--keep-failed`。

验收：所有旧 suite 仍能通过；重复 shell 代码明显减少；可以单独运行任意 suite。

### 阶段 2：可观察性与确定性

目标：测试失败后不用依赖最后一屏 VGA 猜测原因。

- [ ] 实现 COM1 UART 驱动和日志镜像。
- [ ] 统一 `[TEST]`、`[RESOURCE]` 事件格式。
- [ ] 增加 isa-debug-exit 测试退出。
- [ ] 加入固定随机 seed，并在失败日志中记录 seed。
- [ ] 自动收集串口、QEMU、VGA、环境和资源差异。

验收：非交互测试完全不依赖 sendkey/VGA；失败 case 可由一条命令和 seed 重现。

### 阶段 3：统一内核测试 API

目标：把资源泄漏和状态机错误定位到具体 case。

- [ ] 增加 `runtime_snapshot` 和差异输出。
- [ ] 将 `kernel/test.c` 拆成 PMM、heap、VM、scheduler、IPC suites。
- [ ] 建立统一 `TEST_CASE/ASSERT_EQ/ASSERT_RESOURCE_BASELINE` 宏。
- [ ] 增加 PMM、kmalloc、IPC、page table、wait queue 故障注入。
- [ ] 用户测试统一用 exit status 和结构化结果报告。

验收：任一内核断言失败时输出 suite、case、源文件、行号和资源差异。

### 阶段 4：补齐 Orange'S 服务与 IPC 语义

目标：完成行为闭环后，进一步收紧模块边界。

- [ ] 实现 `send_recv` 和 IPC 依赖环死锁检测。
- [ ] 设计统一 service request/reply header 和 request ID。
- [ ] 抽出通用 wait queue。
- [ ] 增加 block device、partition 和 HD service。
- [ ] 让 FS 稳定通过 block service 访问磁盘。
- [ ] 为 IPC 阻塞、取消、进程退出增加专项测试。

验收：可以绘制并测试清晰的 `user -> syscall -> FS -> block -> ATA` 消息流，IPC 死锁能被主动报告。

### 阶段 5：内核安全和启动可靠性

目标：消除会阻碍继续扩展的底层技术债。

- [ ] 清零 `.bss`。
- [ ] 改造 Loader，解除固定内核窗口。
- [ ] 完整 IDT、IST 和异常上下文转储。
- [ ] NX、W^X、只读内核 text/rodata。
- [ ] 强化 ELF 校验。
- [ ] 为这些失败路径增加 QEMU 自动测试。

验收：内核增长不再受 188 扇区限制；不可执行页、只读内核段和异常栈均有自动化验证。

### 阶段 6：现代 OS 能力

在前五个阶段稳定后再开始：

- [ ] VFS、devfs 和多文件系统接口。
- [ ] 页缓存、按需匿名分页、文件 mmap、共享内存。
- [ ] APIC/IOAPIC、SMP 和 per-CPU scheduler。
- [ ] PCI、virtio-blk、virtio-net。
- [ ] 文件系统日志。
- [ ] 信号、job control、socket 和动态链接。
- [ ] 接入 CI，保存 JUnit 与失败 artifacts。

## 10. 推荐代码阅读顺序

1. `Makefile` 与 `kernel/linker.ld`：理解产物和地址。
2. `boot/mbr.S`、`boot/loader.S`：理解机器如何进入长模式。
3. `kernel/kernel.c`：建立初始化时间线。
4. `kernel/memory.h`、`kernel/memory.c`：理解所有模块的地址基础。
5. `kernel/thread.h`、`kernel/thread.c`、`kernel/switch.S`：理解调度实体和切换。
6. `kernel/process.h`、`kernel/process.c`：理解 exit/wait/fork/COW。
7. `usr/syscall.h`、`kernel/syscall_entry.S`、`kernel/syscall.c`：理解用户/内核边界。
8. `kernel/elf.c`、`kernel/usermode.S`：串起首次进入 Ring 3。
9. `kernel/ipc.c`、`kernel/tty.c`、`kernel/fs.c`：理解服务化边界。
10. `tests/qemu_smoke.sh` 和用户测试程序：把实现与可观察行为对应起来。

最适合第一次完整追踪的三条路径：

```text
hello.elf 的 write syscall
shell spawn -> ELF load -> process wait
vm-demo fork -> COW page fault -> wait/reap
```

它们基本覆盖项目最核心的用户/内核边界、调度、内存、文件系统和资源回收机制。
