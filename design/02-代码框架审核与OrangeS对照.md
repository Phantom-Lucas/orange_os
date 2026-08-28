# 代码框架审核与 Orange'S 对照

## 1. 审核结论

当前代码框架已经覆盖课程通知中“引导程序、核心代码、文件系统、控制台”的 A 级功能
范围，并且有用户态、自动测试和现场演示闭环。代码审核后，不建议在答辩前继续增加网络、
GUI 或 SMP 等大模块；收益最高的是保证当前能力可解释、可复现、可演示。

评分等级不能仅由功能判定。课程还要求至少一半代码量由项目组完成，而仓库行数、Git 作者
和程序运行结果都不能自动证明“手写比例”。这部分必须依据真实开发记录，由本人完成
[原创性说明](07-成员分工与原创性说明.md)，并能现场解释选定核心模块。

## 2. 代码框架

| 目录/文件 | 作用 | 答辩阅读入口 |
|---|---|---|
| `boot/mbr.S` | BIOS 首阶段、读 Loader | 启动扇区签名、磁盘读取 |
| `boot/loader.S` | E820、A20、内核读取、页表、长模式 | `KERNEL_SECTORS`、分块读取、跳转 |
| `kernel/linker.ld` | 高半区布局、BSS/物理边界符号 | `__bss_*`, `__kernel_phys_end` |
| `kernel/kernel.c` | 初始化总线与自检入口 | 初始化顺序、进入用户态 |
| `kernel/memory.c`, `paging.c` | 页帧、引用计数、四级页表 | 分配/映射/释放 |
| `kernel/process.c`, `thread.c` | 进程地址空间、线程与调度 | fork/COW、wait、上下文切换 |
| `kernel/syscall_entry.S`, `syscall.c` | 64 位 syscall ABI 与分发 | swapgs、用户复制、36 调用 |
| `kernel/ipc.c`, `sync.c` | 消息、阻塞/唤醒、锁 | send/receive、futex |
| `kernel/disk.c`, `fs.c`, `file.c` | LBA48、MyFS、文件对象 | 索引、路径、FD offset |
| `kernel/tty.c`, `keyboard.c` | 终端队列、控制台、键盘 | IRQ 排空、编辑/前台任务 |
| `kernel/qemu_fb.c`, `vga.c` | 图形终端与文本回退 | PCI/Bochs framebuffer、字体渲染 |
| `usr/libc.c`, `usr/shell.c` | 用户运行库和交互 Shell | argv、pipe/redirection/background |
| `usr/showcase.c` | 六步 guided tour | input/actual/expect/PASS |
| `tools/mkfs.c` | 宿主机构造 MyFS | 动态布局、镜像边界 |
| `tests/` | manifest 与 QEMU 黑盒测试 | profile、case、artifact |

粗略物理行数（含注释/空行）为：Boot 442、Kernel 15,336、User 2,826、Tools 531，
合计 19,135。该统计用于说明工程范围，不能用于证明原创比例。

## 3. 与最新版 Orange'S 的概念对照

| Orange'S 学习主线 | Orange/64 对应实现 | 差异/增量 | 现场证据 |
|---|---|---|---|
| 引导扇区与 Loader | MBR + 二级 Loader | 动态内核扇区、x86-64 长模式、高半区、E820 | `boot.dynamic-loader` |
| 保护模式、GDT/IDT | GDT/TSS/IDT/Ring 0/3 | 64 位异常现场与独立用户栈 | `fault.elf` 后 Shell 存活 |
| 时钟与进程调度 | 抢占线程调度器 | 进程/线程拆分、用户线程、TLS | `demo` THREADS、`ps` |
| 消息机制 | `send/receive` | 与阻塞队列、进程生命周期集成 | `demo` IPC `0xC0DE` |
| TTY/Console | TTY 服务、3 控制台 | framebuffer、历史/编辑、VGA 回退 | F1-F3、编辑键、截图 |
| 硬盘驱动 | ATA PIO | LBA48、边界测试 | `lba48.boot` |
| 文件系统 | MyFS 与服务线程 | 层级目录、三级间接、stat、FD/pipe | proof 文件跨重启 |
| 系统调用 | 36 个 x86-64 syscall | `SYSCALL/SYSRET`、用户复制 | Shell/用户程序均经 syscall |
| 用户程序 | ELF Loader、libc、工具 | fork/exec、管道、重定向、后台 | Shell 组合命令 |
| 内存管理 | 页帧与四级页表 | 独立 CR3、COW、VMA、栈按页增长 | `demo` COW、`vm.cow` |

这不是逐章节“完成书中原代码”的声明，而是用当前源码对书中操作系统构件做功能对照。

## 4. 已补齐的高风险项

### 4.1 Loader 不再硬编码内核长度

问题：固定 188 扇区尾部读取会在内核增长时截断，且普通小内核测试无法发现。  
措施：构建时计算精确扇区数；ATA 读取按 255 扇区分块；同时检查磁盘区间和物理内存上界。  
证据：`boot.dynamic-loader` 人为把内核填充到 300 扇区，仍进入 Ring 3 Shell。

### 4.2 `.bss` 显式清零

问题：原始二进制加载不能假定所有未初始化静态对象由 Loader 自动归零。  
措施：链接脚本导出 BSS 边界，内核最早入口清零，并检查含 BSS 的物理末端。  
证据：构建检查 + 完整启动/功能回归。

### 4.3 键盘 IRQ 排空控制器缓冲

问题：HMP 自动输入较快时可能出现 `scroll-after` 变成 `scroll-fter` 或命令乱序。  
措施：一次 IRQ 最多读取 64 个待处理扫描码，再确认 PIC；自动输入保留合理节奏。  
证据：`userland.core` 连续 3 次、`input.stress` 连续 2 次及最终完整回归通过。

### 4.4 区分核心回归和压力门

问题：100 轮同步压力在资源受限宿主机可能超过 900 秒，不应把超时伪装为内核失败或低轮
结果伪装成 full PASS。  
措施：full 使用确定性的 10×20,000；stress 单列 100×20,000、1800 秒；profile 语义明确。  
证据：full 的 `sync.core` 通过，独立 `sync.stress` 通过。

## 5. 功能缺口与决策

| 候选功能 | 是否答辩前加入 | 原因 |
|---|---|---|
| 网络栈 | 否 | 会引入驱动、协议和测试大面，不能提高现有闭环可信度 |
| SMP | 否 | 会改变调度、页表和锁的正确性假设，风险很高 |
| GUI/窗口系统 | 否 | 已有 framebuffer 终端，GUI 对课程核心价值有限 |
| 文件系统日志 | 后续 | 有价值，但需要崩溃一致性模型和断电注入测试 |
| 文件映射/swap | 后续 | 是 VM 的自然扩展，需与页缓存设计一起完成 |
| 完整 POSIX job control | 后续 | 当前管道/重定向/后台已足以展示系统调用组合 |
| 代码来源标注与模块讲解 | 必须 | 直接影响“50%”要求与现场可信度 |
| 最终 commit/tag 与复测 | 必须 | 保证提交链接和测试报告对应同一份源码 |

## 6. 答辩重点选择

个人 10 分钟答辩不可能讲完所有源码。建议只深讲四条链：

1. Loader：为何固定扇区不可靠，如何计算、分块和做双边界检查。
2. `fork` + COW：页表权限、引用计数、页错误和可观察结果。
3. MyFS：超级块动态布局、inode 多级索引、服务线程与跨重启证明。
4. 键盘/TTY/Shell：IRQ 缓冲、前台控制、FD/pipe 组合与输入压力测试。

这四条同时覆盖汇编、内存、并发、存储、用户态和测试，能体现系统级工作量。其余能力用
架构图和 guided tour 结果概括。

## 7. 最终判断

- 功能完整度：达到 A 级范围候选。
- 工程与证据：完整回归和压力门较强，适合答辩。
- 当前最大非技术风险：真实原创/参考边界尚未由本人填写确认。
- 当前最大交付风险：工作区仍有未提交变更，托管链接尚未固定到最终 commit/tag。
- 推荐动作：不再扩功能；完成原创性表、源码整理、最终复测、截图和 10 分钟彩排。
