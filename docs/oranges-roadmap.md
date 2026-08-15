# Orange'S 功能等价实现路线

本项目采用 x86_64 高半区内核、四级页表和 `syscall/sysretq`，不回退到
原书的 32 位、LDT 或 `int 0x90`。验收以 Orange'S 的可见功能与系统行为为准。

## 0. 构建、镜像与测试基础

目标是将编译产物放在 `build/`，并把“编译”“写入内核”“格式化文件系统”分开。

- `make build`：只构建，不写磁盘。
- `make check`：检查 MBR 大小、Loader/Kernel 的加载边界、ELF 类型和 MyFS 魔数。
- `make install-kernel`：只更新 MBR、Loader、Kernel，保留现有文件系统数据。
- `make format-fs`：显式重建 MyFS；这是唯一会覆盖文件系统区域的目标。
- `make bootstrap`：首次安装或需要全新镜像时使用。
- 默认启动只输出关键启动摘要；`BOOT_DIAGNOSTIC=1` 才输出完整自测、ELF 和资源统计。

完成条件：干净工作树上可执行 `make check`；当前内核二进制不越过两阶段加载器的
188 扇区读取上限（历史上曾为 112 扇区）。MBR 先读取 Loader 和内核首段，Loader 再读取内核余下部分，
避免覆盖仍在 `0x7C00` 执行的 MBR。

## 1. 终端、键盘和基础系统调用

将当前“键盘中断直接调用内核 Shell”的路径改成 `keyboard IRQ -> 键盘环形缓冲区
-> TTY 任务 -> 当前控制台`。

- 定义 `TTY`、`CONSOLE` 和键盘环形缓冲结构；最少支持 3 个虚拟控制台。
- 完整解析常用扫描码，包括按下/释放、Shift、Ctrl、Alt 和 F1/F2/F3 切换控制台。
- 提供 `SYS_WRITE` 与 `SYS_GET_TICKS`；`SYS_WRITE` 统一经过 TTY，用户程序不再直接调用
  `print_string`。
- 为用户地址范围加入页表存在性/用户权限检查，避免无效用户指针导致内核异常。

测试：用户程序通过 `write` 输出；时钟 tick 单调递增；输入文本只进入活动控制台；控制台切换后历史内容保持。

当前进展：`SYS_WRITE(fd, buf, len)`、`SYS_GET_TICKS()`、3 个内存后备控制台、F1/F2/F3
切换、扫描码环形缓冲、Shift/Caps Lock 解析，以及供 `read(0, ...)` 使用的 TTY 输入队列已实现。
`read(0, ...)` 与 `write(1/2, ...)` 现在都通过独立的内核 TTY 服务任务完成同步 IPC；键盘 IRQ
只负责入队，输入服务等待字符后回复，输出服务在内核暂存区写入活动控制台。用户 I/O 不再直接调用
TTY 实现，输入等待不会阻塞输出请求。

当前进展：键盘控制键已进入独立的终端处理路径。Shell 阻塞等待前台子进程时，Ctrl+C、Ctrl+\\
和 Ctrl+Z 会请求终止前台进程；没有前台任务时则由 Shell 完成行取消。Ctrl+L/U/W/D 分别支持
清屏重绘、清行、删除单词和空行退出。`tests/qemu_input_stress.sh` 以 Ctrl+C 加 20 条快速命令
验证前台终止、输入队列容量和 Shell 是否恢复提示符。

## 2. 进程模型与 IPC

Orange'S 的核心是任务/进程通过同步消息通信。保留现有时间片调度器，扩展 PCB。

- 在 PCB 中加入 PID、父 PID、消息缓冲区、发送者队列和 `SENDING/RECEIVING/ZOMBIE` 状态。
- 定义固定大小 `MESSAGE`，实现 `send`、`receive` 和 `sendrecv`。
- 发送者在目标未接收时阻塞；接收者在没有消息时阻塞；匹配后双方唤醒。
- 将时钟、TTY、磁盘和文件系统逐步整理为服务任务，通过 IPC 访问。

测试：两个用户任务互相发送消息；发送/接收阻塞与唤醒顺序正确；任务切换后消息不丢失。

当前进展：同步 `send/receive`、发送者队列和启动期收发自测已加入，并通过 `SYS_SEND`、
`SYS_RECEIVE` 提供给用户进程。发送方会在接收方尚未进入 receive 时阻塞；接收方取到消息后唤醒
发送方。进程退出或因异常终止时会从 IPC 队列撤销并唤醒依赖方，避免悬空 PCB 指针。`ipc-demo.elf`
以 `fork` 创建父子进程，验证“先发送阻塞、后接收唤醒”的完整 Ring 3 路径。下一步才是把 TTY、
文件系统和磁盘改造成真正的服务进程。

## 3. 磁盘、分区与文件系统

保留 ATA PIO 驱动，补齐原书的文件系统行为；MyFS 的磁盘布局可以与书中不同。

- 解析 MBR 分区表，并统一设备号与 LBA 范围校验。
- 将磁盘读写封装为磁盘服务请求，而不是任意模块直接访问端口。
- 补齐 inode 位图、数据块位图、目录扫描、路径解析和多块文件读写。
- 在 PCB 中添加文件描述符表，提供 `open/close/read/write/unlink`。
- 将 TTY 作为字符设备接入文件描述符接口，使 `printf/write` 与文件写入共享调用路径。

测试：创建、打开、读取、追加、关闭、删除文件；跨 QEMU 重启后文件内容仍存在；错误路径不会破坏位图。

当前进展：已实现 ATA PIO 写入、根目录文件的 inode/位图分配、11 个直接块（44KiB）读写、
`open/read/write/close/unlink` 与进程私有 fd 表。ELF 加载通过文件系统读取，不再要求物理块连续。
内核自测覆盖创建/读写/删除，QEMU 二次启动验证持久化；用户态也覆盖完整文件调用链。
inode 磁盘记录当前为 72B，按每个 4KiB 块能够容纳的完整 inode 数量布局，并通过编译期断言保证
格式一致；格式升级后必须
执行一次 `make format-fs`，旧 MyFS 镜像不可与新格式混用。
用户态 `open/read/write/unlink/list` 已通过 FS 服务任务执行：系统调用层先校验并复制用户缓冲区，
再以 IPC 把内核请求交给 FS 服务；服务回复后才把读结果复制回用户空间。ELF 的 `stat/read` 现也经
FS 服务执行，因此内核启动、`spawn` 与 `exec` 的装载路径不再绕过该服务；`exec-demo.elf` 在 QEMU
回归中实际替换为 `hello.elf`，覆盖这一调用链。启动期 MyFS 自测仍保持直连，以便服务任务创建前完成挂载验证。

## 4. 地址空间与进程生命周期

把当前“内核直接加载 hello.elf 后跳入 Ring 3”演进为可管理的用户进程。

- `fork`：共享用户页并采用 COW，复制 PCB、地址空间描述和文件描述符引用。
- `exit`：关闭文件、释放用户页、保留退出状态并成为 zombie。
- `wait`：回收指定/任意已退出子进程，返回退出状态。
- `exec`：释放旧用户映射，加载 ELF、建立用户栈和参数，返回用户入口。
- 内核启动第一个 `init` 用户进程，而不是永久占用在 `hello.elf` 的死循环中。

测试：`fork` 后父子返回值不同；子进程 `exit` 后 `wait` 得到状态；`exec` 替换进程映像并继续运行。

当前进展：用户 ELF 已由 PCB 和调度器启动；`fork` 共享用户页并复制 syscall 返回帧，父进程获得
子 PID、子进程返回 0；`exit` 产生 zombie，父进程 `wait` 可回收退出码；`spawn` 创建子进程，`exec`
在保留 PID/fd 的前提下加载新 CR3 并替换当前映像。启动期 `hello.elf` 验证子进程 `exit(7)` 与父进程
`wait`，只有综合结果成功才会进入用户 Shell。
`wait` 回收 zombie 时会释放低半区用户页与页表、线程对象和进程对象；`exec` 会释放旧映像。
进程仅在等待父进程回收期间保持 `PROCESS_ZOMBIE`，回收后从进程表和调度环移除。

## 5. 用户态 Shell 与最终验收

将现有内核 Shell 保留为调试接口；新增用户态 Shell 作为正常交互入口。

- Shell 使用 `read/write/open/exec/wait`，支持至少 `help`、`ls`、`cat`、`echo`、`run`、`rm`。
- 提供至少两个独立用户程序，验证 `exec`、文件读取和多进程并存。
- 增加 QEMU 回归脚本：启动、用户态输出、IPC、文件持久化、异常隔离。
- 编写架构图、系统调用表、镜像布局和复现实验步骤。

最终完成条件：硬盘镜像可从空白环境构建；进入用户态 Shell；可创建并读取文件；可启动、等待和回收用户程序；IPC 与多控制台可演示。

当前进展：`shell.elf` 已成为默认 Ring 3 交互入口，支持 `help`、`ls`、`echo`、`write`、`cat`、`rm`、
`run`、`exec`、`exit`。镜像构建会打包 `hello.elf`、`shell.elf`、`fault.elf`、`ipc-demo.elf` 和
`exec-demo.elf`；QEMU 已验证 Shell 启动、`run hello.elf` 的子进程等待闭环，以及 `exec-demo.elf`
替换自身为 `hello.elf`。`make check-all` 会在临时镜像中自动验证启动 gate、fork、跨重启文件持久化、
用户 Shell、TTY 输入/输出服务、spawn/wait 与 exec。另一个 `fault.elf` 会故意触发 Ring 3 页错误；
内核会终止该子进程并唤醒父 Shell，而不会 panic。除零、通用保护与页错误均采用相同的用户态隔离策略；
内核态异常仍会 panic。`ipc-demo.elf` 则验证用户态同步消息收发；可在 Shell 中执行
`run ipc-demo.elf` 复现。
