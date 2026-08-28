# Orange'S 功能等价实现：项目总览

## 1. 项目定位

本项目是一个面向教学与实验的 x86_64 裸机操作系统，实现了《Orange'S：一个操作系统的实现》中最重要的可见能力：启动、保护、进程、同步 IPC、终端、文件系统与用户态 Shell。

它不是原书 32 位代码的逐行移植，而是采用现代化的 64 位实现：四级页表、高半区内核、`syscall` 指令进入内核、ELF64 用户程序，以及 ATA PIO 与自定义 MyFS。验收重点是操作系统行为和机制，而不是与书中内部数据结构完全一致。

## 2. 系统架构

```text
                           Ring 3（用户态）
 ┌───────────────────────────────────────────────────────────┐
 │ shell.elf  hello.elf  ipc-demo.elf  fault.elf  exec-demo  │
 │                 用户系统调用封装（usr/syscall.h）           │
 └────────────────────────────┬──────────────────────────────┘
                              │ syscall
 ┌────────────────────────────▼──────────────────────────────┐
 │                    Ring 0（高半区内核）                    │
 │ syscall 分发 · 用户地址检查 · 调度器 · 进程/地址空间        │
 │ 同步 IPC（发送者队列、阻塞/唤醒、退出清理）                 │
 ├───────────────┬───────────────────┬───────────────────────┤
 │ TTY 输入服务   │ TTY 输出服务       │ FS 服务               │
 │ 键盘队列→字符  │ 内核缓冲→VGA       │ inode/位图/根目录     │
 └───────┬───────┴───────────────────┴───────────┬───────────┘
         │ IRQ1 / IRQ0                             │ ATA PIO
 ┌───────▼────────┐                          ┌─────▼───────────┐
 │ PS/2 键盘、PIC  │                          │ 原始硬盘镜像     │
 │ 三个 VGA 控制台 │                          │ MyFS @ LBA 1000  │
 └────────────────┘                          └─────────────────┘
```

服务任务是内核线程而非独立的用户态服务器，但访问边界已通过同步 IPC 划分：用户程序不会直接操作 TTY 或文件系统内部状态。

## 3. 启动、内存与特权级设计

默认启动采用安静模式，只显示启动摘要、致命错误和 Shell 提示符。完整的内核、IPC、
文件系统和进程自测不会污染日常终端；需要查看时使用 `BOOT_DIAGNOSTIC=1`，例如：

```text
BOOT_DIAGNOSTIC=1 make check-all
make BOOT_DIAGNOSTIC=1 run
```

磁盘 MBR 读取失败会重试并停止启动，不会继续使用全零缓冲区伪装成有效 MBR。

| 层次 | 设计与职责 |
| --- | --- |
| MBR | 位于 LBA 0，严格 512B，读取 Loader 与内核首段；避免覆盖仍在 `0x7C00` 执行的引导代码。 |
| Loader | 位于 LBA 2，BIOS E820 探测内存，继续读取剩余内核，建立初始页表，开启 A20、保护模式与 x86_64 长模式。 |
| 内核 | 链接并运行在高半区；初始页表同时提供低地址过渡映射和高半区映射。 |
| 内存管理 | 物理页位图分配器、四级页表映射、用户地址范围/权限校验、用户地址空间销毁。 |
| 特权切换 | Ring 3 使用 `syscall` 进入 Ring 0；内核经 `swapgs`、TSS 内核栈和专用返回路径安全恢复用户态。 |
| 中断与异常 | IDT、PIC、时钟 IRQ、键盘 IRQ；用户态除零、GPF、页错误会终止当前用户进程，内核态异常仍 panic。 |

镜像关键布局如下：

| 区域 | 位置 |
| --- | --- |
| MBR | LBA 0 |
| Loader | LBA 2 起 |
| 内核 | LBA 10 起，当前加载上限为 188 个扇区（94KiB；历史上曾为 112 个扇区） |
| MyFS | LBA 1000 起，按 `DISK_SIZE` 动态生成并覆盖可用文件系统区域 |

## 4. 已支持功能清单

### 4.1 调度、进程与地址空间

- 内核线程的时间片轮转调度，支持就绪、阻塞和终止状态。
- ELF64 装载：解析加载段、为用户段与用户栈创建映射、建立独立 CR3。
- `fork`：复制 PCB、共享用户物理页并清除双方写权限；写入时通过 COW 页故障复制，回滚时维护引用计数。
- `exit` 与 zombie：保存退出码、清理 IPC 状态和文件描述符。
- `wait`：等待并回收子进程的用户地址空间，获得退出状态。
- `spawn`：装载并创建新的子进程。
- `exec`：保留 PID 和 fd 表，装载新 ELF、释放旧用户映像并从新入口继续运行。
- 用户异常隔离：异常子进程退出并唤醒父进程，Shell 可继续执行。

### 4.2 同步 IPC 与服务化

- 固定大小消息结构，包含来源 PID、类型和 64 位值。
- `send`：接收者尚未等待时，发送者进入阻塞队列。
- `receive`：没有匹配消息时，接收者阻塞；匹配后双方恢复执行。
- 支持按特定 PID 或任意来源接收。
- 进程退出/异常时会从 IPC 队列撤销，并唤醒依赖它的发送者，避免保留悬空 PCB 指针。
- TTY 输入服务、TTY 输出服务与 FS 服务均使用该 IPC 机制。

### 4.3 终端、键盘与控制台

- 默认交互界面使用 QEMU framebuffer（1280×720、102×28、深紫主题）；VGA 文本仅作为
  `BOOT_DIAGNOSTIC=1`、自动测试和 `CONSOLE_BACKEND=vga` 的回退后端。
- framebuffer renderer 保存可见字符网格，只重绘改变的字形与旧/新光标，避免每次输入
  清屏重绘造成的闪烁和卡顿。
- 三个内存后备 VGA 文本控制台，按 F1/F2/F3 切换并保留各自历史画面。
- PS/2 键盘扫描码解析，支持普通键、Shift、Caps Lock、退格、回车和控制台切换。
- IRQ1 只负责将字符压入键盘队列；TTY 输入服务阻塞等待字符并回复 `read(0, ...)` 请求。
- `write(1, ...)` / `write(2, ...)` 的用户缓冲先复制至内核堆，再由独立 TTY 输出服务写入活动控制台。
- `SYS_GET_TICKS` 提供时钟 tick 查询。
- 键盘队列和 TTY 输入队列均为 4096 项，快速输入不会因 128 项小队列立即截断；队列满时优先保留回车和控制键。
- `Ctrl+C` 终止 Shell 当前等待的前台子进程（退出码 130），`Ctrl+\\` 使用 131，`Ctrl+Z` 在尚未实现停止/继续状态时使用 148 终止前台任务。
- 没有前台任务时，Shell 支持 `Ctrl+C`/`Ctrl+\\`/`Ctrl+Z` 取消当前行，`Ctrl+L` 清屏并重绘，`Ctrl+U` 清空行，`Ctrl+W` 删除前一单词，空行 `Ctrl+D` 退出。
- 前台归属在 Shell 阻塞 `wait` 子进程期间设置，进程退出、被终止或 wait 返回时清除，避免 PID 悬挂。

### 4.4 磁盘与 MyFS 文件系统

- ATA 主盘 LBA48 轮询 PIO EXT 读写（512B 扇区），LBA 使用 64 位接口。
- MyFS 使用 4KiB 块、版本化超级块、inode 位图、数据块位图、动态 inode 表、根目录和目录项。
- inode 为 72B，使用 11 个直接指针、一级/二级/三级间接索引，文件大小为 64 位；每个块的尾部保留不能容纳完整 inode 的空间。
- 文件和目录支持创建、打开、读取、写入、关闭、删除、列举、层级路径和当前目录。
- 每个文件有 11 个直接数据块及一级、二级、三级间接块；在 4KiB 块和 1024 项索引块下，三级索引的理论单文件上限约为 4TiB，实际受文件系统块数和镜像大小约束。
- 每个进程维护独立 fd 表；0/1/2 保留给标准输入/输出/错误，普通文件从 3 开始。
- 文件系统操作通过 FS 服务执行；用户缓冲区先做页表权限检查并复制到内核暂存区。
- ELF 装载的元数据查询和读取也通过 FS 服务，覆盖内核启动、`spawn` 与 `exec`。
- QEMU 重启后的文件持久化已验证。

### 4.5 用户态程序与 Shell

| 程序 | 作用 |
| --- | --- |
| `shell.elf` | 默认 Ring 3 交互入口。 |
| `hello.elf` | 自检 `write`、tick、文件调用链、`fork/exit/wait`。 |
| `ipc-demo.elf` | 以父子进程验证“先发送阻塞、后接收唤醒”。 |
| `fault.elf` | 故意触发用户页错误，验证异常隔离。 |
| `exec-demo.elf` | 通过 `SYS_EXEC` 将自身替换为 `hello.elf`，验证实际映像替换。 |
| `libc-demo.elf` | 验证 crt0、malloc/calloc/realloc/free、字符串和格式化输出。 |
| `libc-test.elf` | 验证 TLS/errno、用户 mutex、文件 API 和分配器失败路径。 |
| `ls/cat/echo/mkdir/rm/pwd/ps/sleep/kill.elf` | 基础文件、目录、进程和时间管理命令。 |

Shell 命令：

```text
help
ls
echo <text>
write <file> <text>
cat <file>
rm <file>
run <elf>
exec <elf>
exit
```

Shell 还支持带参数的外部命令、`<`/`>`/`>>` 重定向、单级管道和后台命令（`&`）。
每个控制台保留 256 行历史；`PageUp/PageDown` 可翻看和回到底部，`clear` 清空当前控制台。
用户态运行时位于 `usr/libc.h`/`usr/libc.c`，提供 `_start` 参数传递、堆分配、
字符串/内存函数、格式化输出、文件/目录 API、进程 API、errno、futex mutex/条件变量
以及线程 create/join/detach/exit 封装。用户 mutex 无竞争时只走用户态原子操作，竞争时
通过 futex 阻塞；TLS 使用每线程 FS.base 保存 errno 和用户自定义槽位。

## 5. 系统调用接口

| 编号 | 接口 | 说明 |
| ---: | --- | --- |
| 1 | `write(fd, buf, len)` | 写标准输出/错误或普通文件。 |
| 2 | `get_ticks()` | 获取系统时钟 tick。 |
| 3 | `open(path, flags)` | 打开文件；`O_CREATE` 可创建。 |
| 4 | `read(fd, buf, len)` | 从标准输入或普通文件读取。 |
| 5 | `close(fd)` | 关闭普通文件描述符。 |
| 6 | `unlink(path)` | 删除文件。 |
| 7 | `exit(status)` | 终止当前进程。 |
| 8 | `wait(pid, status)` | 等待并回收子进程。 |
| 9 | `spawn(path)` | 从 ELF 创建子进程。 |
| 10 | `list(buf, len)` | 列出根目录文件。 |
| 11 | `exec(path)` | 替换当前进程映像。 |
| 12 | `fork()` | 创建当前进程副本。 |
| 13 | `send(pid, message)` | 向另一个进程同步发送消息。 |
| 14 | `receive(source, message)` | 从指定/任意来源同步接收消息。 |
| 15 | `thread_create(entry, arg)` | 在当前进程共享地址空间中创建用户线程。 |
| 16 | `thread_join(tid, status)` | 等待并回收 joinable 用户线程。 |
| 17 | `thread_exit(status)` | 退出当前用户线程。 |
| 18 | `gettid()` | 获取当前线程 ID。 |
| 19 | `futex_wait(addr, expected)` | 值匹配时阻塞在用户地址对应的 futex 队列。 |
| 20 | `futex_wake(addr, count)` | 唤醒一个或多个 futex waiter。 |
| 21 | `thread_detach(tid)` | 将线程转为 detached，退出后自动回收。 |
| 22 | `thread_yield()` | 主动让出当前时间片。 |
| 23 | `mmap/munmap` | 匿名私有用户映射及解除映射。 |
| 24 | `mkdir/stat/chdir/getcwd` | 目录、状态和当前工作目录。 |
| 25 | `dup/dup2/pipe` | fd 引用计数、重定向和管道。 |
| 32 | `getpid()` | 获取当前进程 ID。 |
| 33 | `sleep(ticks)` | 阻塞到定时器唤醒，不忙等。 |
| 34 | `kill(pid, signal)` | 请求目标用户进程异常退出。 |
| 35 | `ps(buffer, count)` | 获取进程/线程状态快照。 |
| 36 | `clear()` | 清空当前控制台显示和历史。 |

用户态封装及常量位于 [`usr/syscall.h`](../usr/syscall.h)。

## 6. 构建、运行与测试

推荐使用根目录 `Makefile`，它将构建、写内核与格式化文件系统明确分开：

```bash
# 构建全部产物，不写磁盘
make build

# 静态检查：MBR/Loader/Kernel 尺寸、ELF64 与 MyFS 超级块
make check

# 首次运行，或需要把全部用户程序重新写入 MyFS
# 注意：此命令会重建 MyFS，清除其中已有文件。
make bootstrap
make run
```

当前默认启动配置是 `build/images/orange-dev.img`（256MiB）、QEMU 1GiB 内存和 1 个虚拟 CPU；
交互界面默认使用 QEMU framebuffer 现代 Shell，而非 VGA 文本显示。需要旧文本回退时可运行
`make CONSOLE_BACKEND=vga run`。

有关图形 Shell、增量渲染和帧缓冲模式的当前细节，优先阅读
[`adaptive-framebuffer-modern-shell-implementation.md`](adaptive-framebuffer-modern-shell-implementation.md)；
镜像清理和容量规范见 [`image-storage.md`](image-storage.md)。

QEMU 资源可以通过 Make 变量设置：

```bash
# 使用 2GiB 内存启动
make QEMU_MEMORY=2G QEMU_CPUS=1 run

# 创建并使用一个新的 128MiB 磁盘镜像
make DISK_IMAGE=hd128M.img DISK_SIZE=128M bootstrap
make DISK_IMAGE=hd128M.img QEMU_MEMORY=1G QEMU_CPUS=1 run
```

这里要区分两层容量：`DISK_SIZE` 是整个 QEMU 磁盘镜像的逻辑大小，MyFS 从
`FS_START_LBA` 开始，按剩余空间动态计算块数、位图和 inode 表。默认 256MiB 镜像
会生成约 254MiB 的 MyFS 区域（扣除起始保留区和动态元数据），不再固定为 16MiB。
已有镜像不会被 `DISK_SIZE` 自动扩容；要改变容量应指定新的 `DISK_IMAGE` 并重新
执行 `bootstrap`，这会重建文件系统并清除旧文件。

当前内核是单核、未实现 SMP，多于一个虚拟 CPU 只能改变 QEMU 的设备配置，不能让
内核安全地并行执行。因此 `QEMU_CPUS` 目前应保持为 `1`；后续完成 AP 启动、per-CPU
数据和 SMP 锁改造后再开放多 CPU 验收。

日常只修改内核时，可保留现有文件系统：

```bash
make install-kernel
make run
```

完整自动回归：

```bash
make check-all

# 用户态运行时和基础命令回归（需要 QEMU monitor socket 权限）
make qemu-userland-check
```

该测试在 `/tmp` 创建临时磁盘副本，不会修改项目的 `hd60M.img`；它会验证：

- 首次启动和进入 Ring 3 Shell；
- `fork/exit/wait` 自检；
- 写文件、重启、读文件的持久化闭环；
- TTY 输入/输出服务；
- `spawn/wait`、用户同步 IPC 和真实 `exec` 替换；
- Ring 3 页错误只终止子进程、不使内核 panic。

`qemu-userland-check` 另外验证 crt0/argv、libc 分配器与 TLS/errno、用户 mutex、
文件 API、外部命令、`ps`、`sleep` 和 `ls`。每次测试结束都会检查进程、线程、futex
等待者、文件对象和堆统计是否回到 Shell 基线；QEMU 512MiB 与 2GiB 配置均已回归。

`sh/start.sh` 是早期兼容脚本，会清理编译产物、重建文件系统并结束所有 QEMU 进程；日常开发应优先使用上面的 `make` 命令。

## 7. 源码组织

| 目录 | 内容 |
| --- | --- |
| `boot/` | MBR、Loader、长模式切换与初始页表。 |
| `kernel/` | 内核、内存、调度、IPC、TTY、键盘、ATA、MyFS、系统调用。 |
| `usr/` | Ring 3 程序及系统调用封装。 |
| `tools/` | MyFS 镜像制作工具。 |
| `tests/` | 静态构建检查与 QEMU 冒烟/回归测试。 |
| `docs/` | 路线图与本项目总览。 |

## 8. 与原版 Orange'S 的对应关系与边界

已经覆盖的 Orange'S 核心思想包括：特权级隔离、任务/进程切换、同步消息通信、TTY/控制台、磁盘文件系统、用户 Shell 和系统服务化边界。

当前有意保留的简化如下：

- 使用 x86_64、四级页表、ELF64 和 `syscall`，不采用原书的 32 位 LDT、`int 0x90` 与分段式进程模型。
- MyFS 使用固定起始 LBA、动态容量和版本化布局，支持层级目录、相对/绝对路径、路径解析、三级间接块和小型 write-back buffer cache；暂不支持权限、链接、日志和挂载多个文件系统。
- ATA 是轮询 PIO 驱动，尚未拆成独立磁盘服务任务，也没有 DMA、超时恢复或持久化日志。
- 服务均为内核线程，不是运行在 Ring 3 的独立系统进程。
- `fork` 使用物理页引用计数和写时复制（COW）；写故障时才复制用户页。
- 进程在等待父进程回收期间保持 `PROCESS_ZOMBIE`，`wait` 会回收用户地址空间、线程对象和进程对象，并将其从进程表和调度环移除。
- 单核、无 SMP、无网络、无动态链接和无 POSIX 兼容层。

这些限制不影响本项目既定的 Orange'S 功能等价目标，但它们也是后续继续演进为更完整操作系统的清晰方向。

## 9. 验收结论

项目已经具备从原始磁盘镜像构建并启动到 Ring 3 Shell 的完整闭环，能够演示多控制台、文件持久化、多进程、`fork/exec/wait`、异常隔离和同步 IPC。构建尺寸检查与 QEMU 自动回归均已接入，适合作为《Orange'S：一个操作系统的实现》课程项目的提交文档和演示基础。
