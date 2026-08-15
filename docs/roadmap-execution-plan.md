# Orange'S OS 分阶段详细执行方案

本文把《项目代码导读》第 9 节的路线图展开为可执行的工程计划。重点不是一次性重构全部代码，而是先建立可复现基线和统一测试入口，再逐步提升可观察性、测试精度、IPC/服务边界以及内核安全性。

计划基于当前仓库实际状态制定：

- 总回归入口是 `make check-all`，当前转发到 `tests/run.sh --profile full`；旧的 `tests/check_all.sh` 保留用于迁移前对照。
- `tests/` 当前约有 1,042 行 Shell；8 个 QEMU 脚本重复维护启动、monitor、cleanup、sendkey 和 VGA 读取逻辑。
- 非交互测试仍主要通过 QEMU monitor 注入按键，并读取 `0xb8000` 文本显存判断结果。
- 内核已经具备 PMM 统计、部分故障注入、COW、匿名 mmap、futex、同步 IPC、TTY/FS 服务和用户态测试程序。
- Loader 当前固定读取最多 188 个内核扇区；文档中仍存在 112/188 扇区和旧进程回收语义的冲突描述。
- 当前工作区包含大量尚未提交的修改，因此阶段 0 是后续所有工作的硬前置条件。

---

## 1. 执行原则

### 1.1 阶段门禁

每个阶段必须满足以下条件才能进入下一阶段：

1. 阶段内新增测试全部通过。
2. `make check-all` 不出现既有行为回归。
3. 文档、测试清单和实际 Make target 保持一致。
4. 失败时能定位到 suite/case，并保留足以复现的日志。
5. 一个阶段只改变计划声明的语义；阶段 1 不顺便重写 IPC，阶段 2 不顺便修改调度算法。

### 1.2 小步提交

推荐每个任务使用独立提交，提交信息包含任务编号，例如：

```text
test(S1.2): extract common QEMU lifecycle helpers
kernel(S2.1): mirror console output to COM1
ipc(S4.1): reject synchronous send dependency cycles
boot(S5.2): load kernel using generated image metadata
```

禁止把“测试框架迁移、内核功能修改、文档修正”混在一个不可拆分的提交中。每个提交都应能单独构建；阶段结束处打里程碑 tag，例如 `roadmap-s1-tests-unified`。

### 1.3 兼容迁移

- 旧的 `make qemu-*-check` 在阶段 1 内不能删除，先转发到新 runner。
- 新日志协议引入后保留 VGA 镜像一段时间，直到串口路径稳定。
- FS 访问 block service 采用适配层渐进迁移，不做一次性全量替换。
- 安全页权限先以诊断模式验证，再切换为默认强制模式。

### 1.4 工作量口径

下文使用“人日”表示一名熟悉 C、x86_64 和 QEMU 的开发者的净开发时间，不包含长期压力测试等待时间。它是排序依据，不是工期承诺。

| 阶段 | 建议工作量 | 硬依赖 | 主要交付物 |
| --- | ---: | --- | --- |
| 0. 冻结基线 | 2–3 人日 | 无 | 可复现基线、环境清单、缺陷清单 |
| 1. 测试脚本去重 | 5–8 人日 | 阶段 0 | runner、manifest、公共 Shell 库 |
| 2. 可观察性 | 5–8 人日 | 阶段 1 | UART、事件协议、自动退出、artifacts |
| 3. 内核测试 API | 7–12 人日 | 阶段 2 | 测试框架、资源快照、故障注入 |
| 4. IPC 与服务 | 15–25 人日 | 阶段 3 | send_recv、wait queue、block/HD service |
| 5. 安全与启动 | 12–20 人日 | 阶段 3；部分可与阶段 4 并行 | 动态装载、IST、NX/W^X、ELF 加固 |
| 6. 现代 OS 能力 | 45+ 人日，多版本推进 | 阶段 4、5 | VFS、SMP、VirtIO、网络等 |

---

## 2. 统一的任务与验收管理

### 2.1 任务状态

所有任务使用以下状态，避免“代码写完”等同于“任务完成”：

- `TODO`：尚未开始。
- `DOING`：正在实现，尚未满足全部测试。
- `VERIFYING`：实现完成，正在执行完整阶段回归。
- `DONE`：代码、测试、文档和验收证据齐全。
- `BLOCKED`：记录阻塞原因、负责人和解除条件。

### 2.2 缺陷分类

建议建立 `docs/known-issues.md`，每项至少记录：

```text
ID: BUG-xxx 或 LIMIT-xxx
类型: regression | known-limitation | flaky-test | documentation
首次发现版本: commit ID
影响 suite/case:
最小复现命令:
期望结果:
实际结果:
artifacts 路径:
临时规避方式:
关闭条件:
```

- `BUG-*`：已有能力偏离既定行为，阻止对应阶段通过。
- `LIMIT-*`：尚未承诺实现的能力，例如当前无 SMP、Swap、文件 mmap。
- `FLAKY-*`：相同 commit 和 seed 下结果不稳定；不能简单重跑后忽略。
- `DOC-*`：文档与源码或测试不一致。

### 2.3 完成定义

一个工程任务只有同时满足以下条件才算 `DONE`：

- 正常路径和至少一个关键失败路径有测试。
- 新增内核资源在失败、取消和进程退出路径均被释放。
- 测试输出包含 suite、case、状态和复现参数。
- 没有新增无期限等待；每个宿主机测试都有 timeout。
- 更新相关头文件、Make target 帮助和文档。
- 完整回归的日志路径与环境信息被记录。

---

## 3. 阶段 0：冻结基线和文档统一

### 3.1 目标

得到一个能明确回答“基于哪份源码、用什么工具、运行了哪些测试、结果是什么”的基线。当前工作区较脏，因此不能直接把当前 `HEAD` 当作实际功能基线。

### 3.2 任务分解

#### S0.1 冻结源码基线

建议操作：

1. 查看 `git status --short`，区分本次 OS 演进代码、临时产物和无关修改。
2. 创建基线分支，例如 `baseline/pre-unified-tests`。
3. 使用 `git add -p` 审阅并分批纳入文件，不使用无差别的全目录提交。
4. 提交后记录完整 commit ID，并确认 `git status --short` 为空；确需保留的本地文件加入 `.gitignore` 或在基线说明中注明。
5. 为该点创建带注释 tag，例如 `baseline-2026-08`。

交付物：

- 一个可检出的 commit 和 tag。
- `docs/baselines/<date>/source.txt`，包含 commit、branch、tag 和工作树状态。
- 对未纳入基线文件的书面说明。

注意：建立基线会提交当前修改，必须由维护者确认纳入范围；本计划本身不执行提交。

#### S0.2 固化工具链信息

新增只读采集脚本 `tests/collect_env.sh`，采集但不修改环境：

```text
uname -a
gcc --version
ld --version
nasm --version
qemu-system-x86_64 --version
gdb --version
make --version
sha256sum Makefile boot/loader.S kernel/linker.ld
git rev-parse HEAD
git status --short
```

输出写入指定 artifacts 目录，不依赖开发者主目录。无法找到某工具时输出 `missing` 并返回非零，但仍保留已采集内容。

#### S0.3 记录基线测试

在固定 commit 上执行：

```bash
make clean
make check
CHECK_LOG_DIR=build/baseline/check-all-logs make check-all
```

记录：

- 每个步骤的开始、结束时间和退出码。
- 内核、Loader、MBR、用户 ELF、FS 镜像大小与 SHA-256。
- `make check-all` 的所有日志。
- 失败项不能删掉；登记为 `BUG-*` 或 `FLAKY-*`，并决定它是否阻塞后续阶段。

若完整压力测试耗时过长，可先记录 fast 基线，但阶段 0 验收前仍需完成一次 full 基线。

#### S0.4 清理文档冲突

逐项核对并统一：

| 冲突主题 | 当前事实来源 | 处理方式 |
| --- | --- | --- |
| 112/188 扇区 | `Makefile:KERNEL_MAX_SECTORS`、`boot/loader.S` | 统一表述为“当前 188，历史曾为 112”；阶段 5 后删除固定值描述 |
| fork 复制方式 | `kernel/process.c`、`PTE_COW` | 统一为 COW，不再写全量复制 |
| tombstone/回收 | `kernel/thread.c`、`kernel/process.c` | 以当前实际释放范围和 scheduler ring 行为为准 |
| FS/TTY 服务化 | `kernel/fs.c`、`kernel/tty.c`、`kernel/ipc.c` | 区分启动期直连和运行期 IPC 服务路径 |
| 测试入口 | `Makefile`、`tests/check_all.sh` | 所有文档统一引用 `make check-all` |

优先检查：

- `docs/oranges-roadmap.md`
- `docs/project-overview.md`
- `docs/oranges-design-implementation.md`
- `docs/project-code-reading-guide.md`

#### S0.5 建立基线报告和缺陷清单

建议目录：

```text
docs/baselines/2026-08/
├── README.md
├── source.txt
├── environment.txt
├── artifacts.sha256
└── test-summary.md
docs/known-issues.md
```

`test-summary.md` 不复制大段日志，只列命令、结果、耗时和日志相对路径。

### 3.3 验收命令

```bash
git status --short
git rev-parse HEAD
make check
make check-all
```

### 3.4 阶段门禁

- commit、工具版本和测试结果三者能互相对应。
- 另一台满足工具版本要求的机器可检出并重复 `make check`。
- 所有基线失败都有缺陷 ID，没有“暂时忽略”的匿名失败。
- 文档不再同时声称当前限制为 112 和 188 扇区。

### 3.5 回退点

阶段 0 不改变内核行为。若文档修正有争议，保留原文的“历史状态”说明，而不是删除可追溯信息。

---

## 4. 阶段 1：测试脚本去重

### 4.1 目标

只统一宿主机测试编排，不改变内核、用户程序和既有断言语义。阶段完成后，开发者可以列出全部测试、只跑一个 case、重复执行并保留失败现场。

### 4.2 目标目录结构

```text
tests/
├── run.sh
├── manifest.sh
├── collect_env.sh
├── lib/
│   ├── common.sh
│   ├── qemu.sh
│   ├── image.sh
│   ├── monitor.sh
│   ├── assertions.sh
│   └── artifacts.sh
├── suites/
│   ├── build.sh
│   ├── mkfs.sh
│   ├── boot.sh
│   ├── fs.sh
│   ├── shell.sh
│   ├── userland.sh
│   ├── sync.sh
│   ├── vm.sh
│   ├── input.sh
│   └── integration.sh
└── legacy/
    └── README.md
```

不要求第一天就移动所有旧脚本。迁移期间旧脚本可留在原位，但公共实现只能有一份。

### 4.3 Runner 对外接口

`tests/run.sh` 支持：

```text
tests/run.sh --list
tests/run.sh --suite vm
tests/run.sh --suite vm --case cow
tests/run.sh --case boot.quiet
tests/run.sh --repeat 20 --seed 12345 --case ipc.cancel
tests/run.sh --keep-failed --artifacts-dir build/test-artifacts
tests/run.sh --profile fast
tests/run.sh --profile full
```

建议约定：

- `--list`：不构建、不启动 QEMU，只输出 suite、case、profile 和 timeout。
- `--suite`：运行 suite 内全部已启用 case。
- `--case`：接受唯一全名 `suite.case`；短名不唯一时返回使用错误。
- `--repeat N`：同一 seed 序列重复 N 次，第一次失败后默认停止。
- `--seed N`：传递给宿主机编排和内核/用户测试。
- `--keep-failed`：失败时保留临时镜像和全部现场；成功默认删除大文件。
- `--profile fast|full|stress`：控制测试集合，不在 suite 脚本内隐式判断。
- `--timeout N`：只覆盖 case 默认值，并记录到环境文件。

统一退出码：

| 退出码 | 含义 |
| ---: | --- |
| 0 | 全部通过 |
| 1 | 至少一个测试断言失败 |
| 2 | 命令行或 manifest 配置错误 |
| 3 | 缺少依赖或构建失败 |
| 4 | 测试超时 |
| 5 | QEMU/monitor 基础设施失败 |

### 4.4 Manifest 设计

Shell 项目无需立即引入 Python。`tests/manifest.sh` 提供声明函数，不执行测试：

```bash
register_case build artifacts fast 60 suite_build_artifacts
register_case boot quiet fast 45 suite_boot_quiet
register_case vm cow full 180 suite_vm_cow
register_case input ctrl_c stress 120 suite_input_ctrl_c
```

每项至少包含：suite、case、profile、timeout、执行函数和必要标签。runner 在解析后检查重复 ID、空函数和非法 timeout。

### 4.5 公共库职责

#### `tests/lib/common.sh`

- 定位仓库根目录。
- 检查命令依赖。
- 统一日志、错误和退出码。
- 创建 case 工作目录。
- 注册 cleanup，保证多次调用只清理一次。
- 禁止直接使用未校验的空变量作为删除目标。

建议 API：

```text
die <exit-code> <message>
require_command <name>
case_workspace_create <suite> <case>
run_with_timeout <seconds> <log-file> <command...>
record_command <command...>
```

#### `tests/lib/qemu.sh`

- 组装公共 QEMU 参数。
- 启动并记录 PID。
- 等待 monitor socket 或进程提前退出。
- 正常关闭、超时终止和最终回收。
- 支持附加 suite 专用参数，例如 256GiB 稀疏盘。

建议 API：

```text
qemu_start
qemu_wait_ready
qemu_wait_exit
qemu_stop
qemu_is_alive
qemu_add_arg
```

#### `tests/lib/monitor.sh`

- 发送 monitor 命令。
- 文本按键编码。
- VGA `pmemsave` 和解码。
- `info registers`、`info pic` 等失败现场采集。

#### `tests/lib/image.sh`

- 创建明确大小的稀疏磁盘。
- 调用构建和 bootstrap。
- 复制或复用基础镜像时保证原镜像不被测试污染。
- 提供 MyFS superblock、LBA 边界和镜像哈希检查。

#### `tests/lib/assertions.sh`

提供统一的：

```text
assert_eq
assert_contains
assert_not_contains
assert_file_exists
assert_process_exited
assert_event_passed
```

所有失败信息必须包含 suite、case、期望、实际摘要和 artifacts 路径。

### 4.6 迁移顺序

按风险从低到高迁移：

1. `check_build.sh`、`mkfs_index.sh`、`mkfs_lba48.sh`：无 QEMU，验证 runner/manifest 基础。
2. `qemu_boot.sh`：单次启动、无 sendkey，验证 QEMU 生命周期和 VGA 抓取。
3. `qemu_vm.sh`、`qemu_sync.sh`：行为单一，适合验证 case timeout。
4. `qemu_userland.sh`、`qemu_fs.sh`、`qemu_lba48.sh`。
5. `qemu_shell_fs.sh`、`qemu_input_stress.sh`：保留交互特性。
6. `qemu_smoke.sh`：最后拆成多个 case，避免继续作为重复覆盖全部能力的巨型脚本。
7. `check_all.sh` 改为调用 `tests/run.sh --profile full`。

每迁移一个脚本，在同一 commit 上分别运行旧、新入口，并比较最终断言和退出码。阶段 1 不要求日志文本逐字相同，但不能减少断言。

### 4.7 Makefile 兼容层

新增入口：

```text
make test-list
make test-fast
make test-all
make test SUITE=vm
make test CASE=vm.cow REPEAT=20 SEED=12345 KEEP_FAILED=1
```

旧 target 转发示例：

```make
qemu-vm-check:
	./tests/run.sh --suite vm
```

`make check-all` 在一个稳定周期内保留，转发到 `make test-all`。文档和 CI 优先使用新命令。

### 4.8 Runner 自测

新增 `tests/selftest_runner.sh`，使用假的 suite 函数验证：

- list 不执行 case。
- case 过滤正确。
- timeout 映射为退出码 4。
- 成功时清理、失败时 `--keep-failed` 保留目录。
- cleanup 在 SIGTERM 和普通退出时都执行。
- manifest 重复 case 会失败。

这些自测不启动 QEMU，应在数秒内完成。

### 4.9 阶段门禁

- `tests/run.sh --list` 能列出当前全部测试能力。
- 任意 suite/case 可单独运行。
- 旧 Make target 仍可用且断言没有减少。
- `tests/selftest_runner.sh` 通过。
- 完整 `make check-all` 与基线结果一致。
- QEMU 生命周期、monitor 和 cleanup 只有一套公共实现。

---

## 5. 阶段 2：可观察性与确定性

### 5.1 目标

非交互测试通过串口事件判断结果，并由内核主动结束 QEMU；VGA/sendkey 只用于验证真实键盘、TTY、控制台和 Shell 编辑行为。

### 5.2 S2.1 COM1 UART

新增：

```text
kernel/uart.h
kernel/uart.c
```

建议功能：

- 初始化 COM1 `0x3F8`，默认 115200 8N1。
- `uart_putc` 在发送保持寄存器可用后写入，设置有限循环或明确的 early-boot 策略，避免硬件缺失时永久卡死。
- `uart_write` 输出定长缓冲区，不要求 NUL 结尾。
- 初期只实现轮询发送；中断接收不属于本阶段。
- 在 `kernel/kernel.c` 尽早初始化，至少早于大部分自测和用户态启动。

修改 `kernel/print.c`，让公共输出同时写入 VGA 与 UART。为避免递归和锁顺序问题：

- UART 底层不能调用 `print_*`。
- panic 路径使用无锁或最小依赖的 `panic_uart_putc`。
- 镜像开关使用编译期配置，例如 `SERIAL_LOG=1`，最终默认开启。

QEMU 增加：

```text
-serial file:<case-artifacts>/serial.log
```

验收：从复位到用户 Shell 的关键日志均出现在 `serial.log`；禁用 VGA 抓取后 boot 测试仍可判断成功。

### 5.3 S2.2 结构化事件协议

人类日志可以继续保留，但自动化只依赖稳定事件：

```text
[TEST] suite=vm case=cow-parent-write state=START seed=12345
[RESOURCE] suite=vm case=cow-parent-write phase=before free_pages=123 heap_bytes=456
[RESOURCE] suite=vm case=cow-parent-write phase=after free_pages=123 heap_bytes=456
[TEST] suite=vm case=cow-parent-write state=PASS duration_ticks=37
[TEST] suite=ipc case=cancel-on-exit state=FAIL file=kernel/tests/ipc_test.c line=88 code=12
[TEST-RUN] state=PASS passed=24 failed=0 skipped=1 seed=12345
```

协议约束：

- 一行一个事件，ASCII，可由简单 Shell 工具解析。
- 键名稳定，值中不允许裸空格；必要时使用十六进制或下划线。
- `suite+case+state` 是 `[TEST]` 必填字段。
- FAIL 必须包含数值 code；断言失败还包含 file/line。
- 协议版本写入首条事件：`[TEST-PROTOCOL] version=1`。
- runner 只把结构化事件作为 pass/fail 真值，人类描述不能替代 PASS 事件。

新增 `tests/lib/events.sh`，负责等待事件、提取字段、检测重复终态和生成摘要。

### 5.4 S2.3 isa-debug-exit

QEMU 测试实例加入：

```text
-device isa-debug-exit,iobase=0xf4,iosize=0x04
```

内核新增仅测试构建使用的接口：

```text
kernel/test_exit.h
kernel/test_exit.c
test_exit_pass(void)
test_exit_fail(uint8_t code)
```

注意 QEMU 的进程退出状态不是写入口值本身；公共 runner 必须集中完成编码/解码，suite 不得自行解释。生产构建不应因意外端口写入退出，建议由 `KERNEL_TEST_MODE=1` 控制。

终止顺序：

1. 输出最终 `[TEST-RUN]` 事件。
2. 确保 UART 字节已发送。
3. 写 debug-exit 端口。
4. 如果设备不存在，则停机循环作为后备。

### 5.5 S2.4 固定 seed

- runner 未指定 seed 时生成一次，并在运行开始立即打印。
- 同一轮 `--repeat` 使用可推导序列，例如 `base_seed + iteration`。
- seed 通过编译宏、启动参数区或测试配置扇区传入；阶段 2 可先使用编译宏，后续再改成运行时配置。
- 调度扰动、故障注入位置和随机测试数据都从同一明确算法派生。
- 算法或 seed 解释改变时提升测试协议版本。

任何失败摘要必须给出一条可复制命令：

```text
make test CASE=vm.cow-parent-write SEED=12345 KEEP_FAILED=1
```

### 5.6 S2.5 Artifacts

统一目录：

```text
build/test-artifacts/<run-id>/<suite>/<case>/<iteration>/
├── result.env
├── command.txt
├── environment.txt
├── serial.log
├── qemu.log
├── monitor-info.txt
├── vga.bin
├── vga.txt
├── resource-before.txt
├── resource-after.txt
├── kernel.elf
├── kernel.asm
├── disk.sha256
└── disk.img
```

策略：

- 成功 case 保留 `result.env`、事件摘要和命令，删除大镜像。
- 失败 case 默认保留所有小型日志；`--keep-failed` 时额外保留磁盘镜像。
- 超时时 runner 先抓 monitor 状态，再终止 QEMU。
- artifacts 写入完成后才输出最终失败路径。
- `result.env` 至少包含 commit、suite、case、iteration、seed、timeout、QEMU 退出码和测试状态。

### 5.7 测试迁移策略

第一批改为纯串口/自动退出：

- build/mkfs 静态检查。
- boot quiet/diagnostic。
- VM、sync、IPC 和内核自测。
- FS 非交互读写与持久化。
- libc/userland 自动测试程序。

继续保留 sendkey/VGA：

- 键盘扫描码和快速输入。
- Ctrl+C/Ctrl+Z 等 job-control 行为。
- F1/F2/F3 控制台切换。
- Shell 行编辑、重定向和 pipeline 的端到端交互验收。

### 5.8 阶段门禁

- boot、VM、sync、IPC、FS 核心回归不读取 VGA。
- 非交互测试不调用 `sendkey`。
- 超时、断言失败、内核 panic 都能留下串口和 QEMU 日志。
- 相同 commit、case、seed 可稳定复现结果。
- 最终摘要能直接给出 case 和 artifacts 路径。

---

## 6. 阶段 3：统一内核测试 API

### 6.1 目标

把当前集中在 `kernel/test.c` 和各模块自测函数中的检查整理为具名 suite/case，使失败精确指向源文件、行号和资源差异。

### 6.2 目录与构建调整

建议结构：

```text
kernel/test.h
kernel/test.c
kernel/tests/
├── test_registry.c
├── pmm_test.c
├── heap_test.c
├── vm_test.c
├── scheduler_test.c
├── ipc_test.c
├── fs_test.c
└── fault_injection_test.c
```

当前 Makefile 只使用 `kernel/*.c` 通配符；新增子目录时必须显式加入 `kernel/tests/*.c` 及对应对象规则、依赖文件。不要依赖链接器偶然保留未引用测试对象。

为降低 freestanding 链接复杂度，第一版使用显式 suite 数组，不急于引入 linker section 自动注册。

### 6.3 测试 API

建议核心定义：

```c
struct test_case {
    const char *suite;
    const char *name;
    void (*run)(struct test_context *ctx);
    uint32_t flags;
};

struct test_context {
    uint64_t seed;
    uint32_t failures;
    uint32_t assertions;
    const char *current_file;
    uint32_t current_line;
};
```

宏至少包括：

```text
TEST_CASE(suite, name)
ASSERT_TRUE(expr)
ASSERT_FALSE(expr)
ASSERT_EQ(expected, actual)
ASSERT_NE(expected, actual)
ASSERT_NULL(value)
ASSERT_NOT_NULL(value)
ASSERT_RESOURCE_BASELINE(snapshot)
FAIL(code, message)
```

宏要求：

- 表达式只求值一次。
- 打印 suite、case、file、line、expected、actual。
- 单 case 失败后可选择继续收集断言或立即停止，但全项目统一一种默认策略。
- panic 测试与普通断言分开，避免把真实内核 panic 误报为通过。

### 6.4 `runtime_snapshot`

新增 `kernel/runtime_stats.h/.c`，只负责聚合已有模块统计，不直接了解测试逻辑：

```c
struct runtime_snapshot {
    struct pmm_stats pmm;
    struct kalloc_stats heap;
    uint64_t processes_live;
    uint64_t processes_zombie;
    uint64_t threads_live;
    uint64_t threads_blocked;
    uint64_t user_page_refs;
    uint64_t page_table_pages;
    uint64_t open_file_descriptions;
    uint64_t pipe_objects;
    uint64_t futex_waiters;
    uint64_t ipc_blocked_senders;
    uint64_t ipc_blocked_receivers;
    uint64_t wait_queue_nodes;
};
```

实施顺序：

1. 先聚合已有 `pmm_get_stats`、heap 和进程/线程统计。
2. 为 file、pipe、futex、IPC 增加只读计数器查询接口。
3. 明确哪些计数允许因缓存或后台回收延迟而变化。
4. `runtime_snapshot_diff` 输出所有变化，而不是只输出第一个差异。
5. 需要异步回收的 case 在快照前调用明确的 quiesce/reap 测试钩子，禁止用随意 sleep 掩盖竞态。

`ASSERT_RESOURCE_BASELINE` 默认比较“必须守恒”的字段；允许变化的字段必须由 case 显式声明。

### 6.5 Suite 拆分顺序

1. PMM/heap：依赖最少，先验证测试 API 和资源快照。
2. VM/COW：复用现有 PMM 故障注入和 COW 回滚检查。
3. scheduler/thread：覆盖 block/unblock、join/detach、退出回收。
4. IPC：覆盖先发后收、先收后发、指定来源、取消和退出。
5. FS/file：覆盖 fd、open file description、pipe 和失败回滚。

每迁移一组，删除旧位置的重复断言，但保留一个兼容入口调用新 suite，直到阶段结束。

### 6.6 故障注入

从当前 `pmm_test_inject_alloc_failure_once()` 扩展为统一控制器：

```text
fault_inject_enable(point, fail_after, repeat)
fault_inject_hit(point)
fault_inject_disable(point)
fault_inject_reset_all()
```

首批注入点：

- `PMM_ALLOC`
- `KMALLOC_ALLOC`
- `PAGE_TABLE_ALLOC`
- `IPC_ENQUEUE`
- `WAIT_QUEUE_ENQUEUE`
- `FILE_ALLOC`
- `ATA_REQUEST`

规则：

- 仅 `KERNEL_TEST_MODE` 编译包含。
- case 结束必须自动 reset，防止污染后续 case。
- 注入前后都取资源快照。
- 对部分成功的多步操作检查事务式回滚。

### 6.7 用户态测试统一

复用并扩展 `usr/test.h`：

- 每个测试程序最终调用 `exit(0)` 或非零状态。
- 同时输出结构化事件，宿主机不再只匹配描述性文本。
- 一个二进制内的多个 case 输出独立终态。
- Shell 展示人类友好的总结，但 runner 依据 exit status 和事件。
- 增加 `usr/test_runner.c` 时，先保持 libc-test、vm-demo 等旧入口兼容。

### 6.8 阶段门禁

- 任一断言失败包含 suite、case、file 和 line。
- PMM、heap、VM、scheduler、IPC 至少各有一个独立 suite。
- 资源泄漏会列出全部字段差异。
- 故障注入 case 可重复且不会污染下一个 case。
- 用户测试的最终状态由 exit status 与结构化事件共同确认。

---

## 7. 阶段 4：补齐 Orange'S 服务与 IPC 语义

### 7.1 目标与边界

本阶段追求 Orange'S 的同步消息和服务边界，但保留当前 x86_64、高半区、共享内核地址空间设计。所谓“服务”首先是独立内核线程和清晰请求协议，不等同于具备微内核级地址空间隔离。

### 7.2 S4.1 `send_recv` 与死锁检测

在 `kernel/ipc.h/.c` 增加：

```text
ipc_send_recv(destination, request, reply)
ipc_would_deadlock(sender, destination)
```

建议语义：

1. `send_recv` 先同步发送，再只接收目标 PID 的回复。
2. 请求与回复使用同一个 request ID，但 message type 可不同。
3. 发送前沿 `destination->ipc_waiting_for` 链检查是否回到 sender。
4. 遍历步数不得超过当前 live thread 上限；检测到损坏或环时返回明确错误，不进入阻塞。
5. 自发自收、目标退出、等待过程中被取消分别定义稳定错误码。

需要测试：

- A→B 正常收发。
- A→B→C 无环阻塞。
- A→B→A 和 A→B→C→A 主动拒绝。
- 发送者/接收者在阻塞期间退出。
- 只接收指定服务回复，不误取其他来源消息。

### 7.3 S4.2 服务协议

新增 `kernel/service.h`，定义固定头：

```c
struct service_header {
    uint32_t version;
    uint32_t service;
    uint32_t opcode;
    int32_t status;
    uint64_t request_id;
    uint32_t payload_size;
    uint32_t flags;
};
```

协议规则：

- 请求由客户端生成非零 request ID；reply 必须回显。
- 未知 version/opcode 返回稳定错误码。
- payload 长度先验证再解释。
- 内核指针不出现在跨服务 ABI 中。
- 取消、超时和目标退出有可区分状态。

先让 TTY 和现有 FS service 使用公共 header，再引入 block service。这样能在磁盘迁移前验证协议。

### 7.4 S4.3 通用 wait queue

新增：

```text
kernel/wait_queue.h
kernel/wait_queue.c
```

建议结构支持：

- FIFO 等待节点。
- 在调用方持锁条件下原子入队并 block，避免丢失唤醒。
- `wake_one`、`wake_all`、按 predicate 唤醒。
- 从队列取消指定线程。
- 线程退出时安全摘链。
- debug 构建检查重复入队、跨队列复用和悬空 owner。

迁移顺序：join/wait → pipe/TTY → IPC → futex → sleep。每次只迁移一个消费者并运行其专项压力测试。

### 7.5 S4.4 Block、partition 与 HD service

建议新增：

```text
kernel/block.h
kernel/block.c
kernel/partition.h
kernel/partition.c
kernel/hd_service.h
kernel/hd_service.c
```

职责分层：

```text
FS service
    -> block_read/block_write(device, lba, count, buffer)
        -> HD service request/reply
            -> ATA PIO driver
                -> I/O ports
```

- `disk.c` 只保留 ATA 控制器、命令、PIO 数据传输、超时和错误状态。
- `block.c` 管理设备号、扇区范围、请求大小和同步请求。
- `partition.c` 解析 MBR 分区表，验证溢出、重叠和磁盘边界。
- `hd_service.c` 串行化请求，维护 request ID，并把 ATA 错误转换为服务状态。
- `fs.c` 不再直接调用 ATA 接口，只依赖 block API。

迁移采用双后端：

1. block API 先包装现有直接 ATA 调用。
2. FS 改为只调用 block API，验证行为不变。
3. block API 内部切换到 HD service。
4. 删除运行期 FS→ATA 直连；启动期若暂时保留，必须标注并有清除任务。

### 7.6 专项测试

新增 case：

```text
ipc.send-before-receive
ipc.receive-before-send
ipc.deadlock-two-node
ipc.deadlock-three-node
ipc.sender-exit
ipc.receiver-exit
ipc.cancel
wait_queue.no-lost-wakeup
wait_queue.cancel-on-exit
block.bounds
block.multi-sector
partition.invalid-signature
partition.out-of-range
hd.ata-error-propagation
fs.via-block-service
fs.persistence-via-service
```

压力测试至少重复 100 次 IPC 取消/退出交错，并比较 runtime snapshot。

### 7.7 阶段门禁

- 可从日志重建 `user -> syscall -> FS -> block -> ATA` 的同一 request ID。
- IPC 环在阻塞前被报告，系统仍能继续运行其他测试。
- 进程退出不会在 IPC 或 wait queue 留下节点。
- 运行期 FS 不直接引用 ATA 传输 API。
- 持久化、LBA48、错误边界和资源基线测试全部通过。

---

## 8. 阶段 5：内核安全和启动可靠性

### 8.1 实施顺序

推荐顺序是 `.bss` → 动态内核装载 → 异常/IST → NX/W^X → ELF 校验。前两项先解除内核增长约束，随后再加入会增加代码体积的诊断和安全逻辑。

### 8.2 S5.1 `.bss` 清零

在 `kernel/linker.ld` 导出页对齐前后的：

```text
__bss_start
__bss_end
```

在最早进入 C 之前的内核入口汇编中清零 `[__bss_start, __bss_end)`。要求：

- 不依赖尚未初始化的栈外全局状态。
- 正确处理非 8 字节倍数尾部。
- linker script 对 `.bss` 和 COMMON 符号统一收集。
- 增加测试专用未初始化数组，进入 `kernel_main` 第一时间验证全零。

### 8.3 S5.2 解除 188 扇区限制

推荐先实现“生成的内核镜像头”，比直接在实模式 Loader 中完整解析 ELF 风险低：

```text
magic
header_version
header_size
payload_bytes
payload_sectors
load_paddr
entry_offset
checksum
```

构建流程生成 header，Loader 读取并验证后按实际扇区数分批读取。必须检查：

- 扇区计数乘法和地址加法溢出。
- 读取范围不能覆盖 Loader、临时页表或 MyFS 起始 LBA。
- BIOS 单次读取限制与跨柱面/64KiB 边界；复用已有分块读取和重试逻辑。
- checksum 错误、截断镜像、超大镜像要停止启动并输出明确错误码。

过渡步骤：

1. 先让新 header 描述当前 188 扇区以内的内核。
2. 新旧构建产物逐字节验证 payload 一致。
3. 人工填充内核到超过 188 扇区，验证仍能启动。
4. 删除 `KERNEL_MAX_SECTORS := 188` 和相关 `-Os` 被迫优化说明。
5. 保留“不得越过 FS 起始 LBA”的新上界检查。

后续可再演进为 Loader 解析 ELF program headers；不把两个高风险改动放在同一提交。

### 8.4 S5.3 完整 IDT、TSS 与 IST

- 为 0–31 号 CPU 异常建立统一入口，正确区分 CPU 自动压入 error code 的向量。
- TrapFrame 统一保存向量号、错误码、通用寄存器、RIP/CS/RFLAGS/RSP/SS。
- TSS 配置至少为 double fault、NMI、machine check 分配独立 IST 栈。
- guard page 或 canary 检测异常栈溢出。
- 用户异常终止当前进程；内核异常打印完整上下文后停机。
- page fault 额外输出 CR2，并解码 present/write/user/reserved/instruction-fetch 位。

测试覆盖用户除零、非法指令、GP、页错误，以及测试模式下可控触发的 double fault 路径。危险异常测试每个使用独立 QEMU 实例。

### 8.5 S5.4 NX、W^X 和只读内核段

步骤：

1. 检测 CPUID NX 支持并设置 `EFER.NXE`。
2. 在 `memory.h` 定义 `PTE_NX`，页表 API 接受明确的执行权限。
3. `linker.ld` 将 text、rodata、data、bss 按页对齐，导出边界。
4. 内核 text 映射为 RX、rodata 为 R/NX、data/bss/heap/stack 为 RW/NX。
5. 用户 ELF 根据 `PT_LOAD.p_flags` 建立 R/W/X 权限，拒绝 W+X 段或在策略中明确处理。
6. 页表初始化后刷新 TLB，再开启强制检查。

测试：

- 用户从匿名数据页执行应产生用户异常。
- 用户写只读代码页应被终止。
- 测试模式尝试修改内核 rodata 应进入预期内核故障 QEMU case。
- 正常 syscall、COW 和 ELF 程序不回归。

### 8.6 S5.5 ELF 校验

在 `kernel/elf.c` 加强：

- ELF magic、class、endianness、machine、type、version。
- program header 数量、大小、文件偏移和乘法溢出。
- `p_filesz <= p_memsz`。
- 文件范围不能越过实际文件长度。
- 虚拟地址必须在允许的用户区，不能碰内核高半区、保留区或栈 guard。
- `p_align` 合法，段映射重叠策略明确。
- 入口必须落在可执行的已加载段。
- 加载失败完整回滚页、页表和 VMA。

新增宿主机工具生成或变异坏 ELF，分别验证截断、超界、重叠、错误入口和 W+X 段。

### 8.7 阶段门禁

- 超过 188 扇区的测试内核可以启动，损坏 header 会安全停止。
- `.bss` 在所有构建模式中为零。
- 所有 CPU 异常都有确定入口，double fault 使用独立 IST。
- 内核 text/rodata/data 和用户段权限有自动检查。
- 所有坏 ELF case 都失败且资源回到基线。
- `make test-all` 在安全权限默认开启时通过。

---

## 9. 阶段 6：现代 OS 能力

阶段 6 不应作为一个大分支实施，应拆成多个可发布里程碑。

### 9.1 M6.1 VFS、devfs 与统一对象接口

建议先定义 vnode/file_operations/superblock/mount 接口，再让 MyFS 成为第一个后端。完成条件：

- `/dev/tty*`、块设备通过 devfs 暴露。
- 路径解析不再硬编码 MyFS。
- 当前 open/read/write/close/dup/pipe 回归全部通过。
- mount 生命周期和 vnode/file 引用计数纳入 runtime snapshot。

### 9.2 M6.2 页缓存与高级 VM

顺序：页缓存 → 按需匿名页 → 文件私有 mmap → 文件共享 mmap → 共享内存。必须先定义：

- page cache key 和脏页回写。
- truncate/unlink 与映射并存语义。
- fork 对共享/私有映射的行为。
- 内存压力下的回收策略。

Swap 放在页回收和反向映射成熟之后，不与最初的 mmap 实现捆绑。

### 9.3 M6.3 APIC、IOAPIC、SMP

顺序：local APIC 单核 → IOAPIC → 多 CPU 启动 → per-CPU 数据 → SMP scheduler → TLB shootdown。进入 SMP 前必须审计：

- PMM、kalloc、页表、进程表和文件表锁。
- `current_thread`、preempt count、kernel stack 改为 per-CPU。
- IPC/wait queue 的锁顺序。
- 中断亲和性和时钟源。

SMP 测试至少覆盖 1/2/4 CPU，不能只在 `QEMU_CPUS=1` 下验收。

### 9.4 M6.4 PCI 与 VirtIO

先 PCI 枚举和 BAR，再 virtio-blk，最后 virtio-net。virtio-blk 必须接入阶段 4 的 block 层，使 FS 无需知道 ATA 或 VirtIO 后端。

### 9.5 M6.5 文件系统日志

先写出崩溃一致性模型，再选择 redo journal。测试通过 QEMU 在事务的不同写入点强制断电，重启后执行 fsck/挂载验证，不能只验证正常关机。

### 9.6 M6.6 信号、job control、socket、动态链接

建议顺序：

1. 信号投递与用户返回帧。
2. process group/session/前台 TTY。
3. pipe/poll 等待模型统一。
4. socket API 与 loopback。
5. 网络设备与协议栈。
6. 用户 ELF 动态加载器和共享库。

### 9.7 M6.7 CI

阶段 1–5 应一直生成 CI 友好的本地产物；阶段 6 正式接入托管 CI：

- 每次提交：runner 自测、build、静态检查、fast profile。
- 合并请求：full profile，至少一个 QEMU 版本。
- 定时任务：stress profile、1/2/4 CPU 矩阵、大内存/LBA48。
- 失败上传 JUnit、serial.log、qemu.log、环境、资源差异和压缩后的必要镜像。
- flaky 测试仍标记失败并建立 `FLAKY-*`，不能用无限自动重试变绿。

---

## 10. 统一测试矩阵

### 10.1 Profile

| Profile | 目标 | 内容 | 建议触发 |
| --- | --- | --- | --- |
| `fast` | 快速发现明显回归 | build、mkfs、小型 boot、核心内核 suite | 每次提交 |
| `full` | 功能完整性 | 当前 `check-all` 的全部能力 | 合并前 |
| `stress` | 竞态和泄漏 | sync/IPC/VM 重复、随机 seed、输入压力 | 定时或手动 |
| `security` | 失败路径 | 坏 ELF、NX/W^X、异常、损坏镜像 | 阶段 5 后合并前 |
| `smp` | 并发扩展 | 1/2/4 CPU 和不同内存规格 | 阶段 6 后 |

### 10.2 Suite 责任边界

| Suite | 主要责任 | 不应承担 |
| --- | --- | --- |
| build | 产物格式、大小、链接属性 | 启动行为 |
| boot | Loader、初始化 gate、首个用户程序 | Shell 复杂交互 |
| memory | PMM、heap、页表、COW、mmap | FS 持久化 |
| process | fork/exec/exit/wait、线程生命周期 | ATA 细节 |
| ipc | 阻塞、匹配、取消、死锁 | FS 数据格式 |
| fs | inode、目录、fd、pipe、持久化 | 键盘扫描码 |
| userland | crt0、libc、命令参数、退出码 | 内核内部统计细节 |
| tty/input | 键盘、控制台、控制字符、Shell 编辑 | 通用 VM 测试 |
| integration | 少量跨层关键链路 | 重复所有 subsystem case |

integration 只保留跨层合同测试，例如一次 `user -> syscall -> FS -> block -> ATA`；底层边界组合留在对应 suite，避免当前 smoke 脚本再次膨胀。

### 10.3 资源守恒检查点

以下操作默认要求前后资源回到基线：

- fork 子进程退出并 wait。
- 线程 join/detach 后回收。
- IPC 被取消或目标退出。
- mmap 后 munmap。
- open/dup/pipe 后全部 close。
- ELF 加载失败。
- page table、kmalloc、ATA 请求故障注入。

允许缓存增长的模块必须提供 `quiesce` 或精确豁免字段，不接受“忽略所有页数变化”。

---

## 11. 建议的里程碑和提交序列

### 11.1 里程碑 A：基线可复现

```text
S0.1 baseline commit/tag
S0.2 environment collector
S0.3 baseline report
S0.4 documentation reconciliation
S0.5 known issues registry
```

退出条件：另一位开发者仅凭文档可复现 `make check` 和完整测试结果。

### 11.2 里程碑 B：测试只有一个入口

```text
S1.1 runner skeleton and manifest
S1.2 common/image/assertion helpers
S1.3 QEMU/monitor lifecycle helpers
S1.4 migrate non-QEMU tests
S1.5 migrate simple QEMU suites
S1.6 migrate interactive suites
S1.7 split integration smoke
S1.8 Make compatibility targets and runner self-tests
```

退出条件：`make test CASE=...` 可运行任意 case，旧 target 仍兼容。

### 11.3 里程碑 C：失败可诊断

```text
S2.1 UART driver
S2.2 print mirroring
S2.3 event protocol/parser
S2.4 debug-exit
S2.5 seed propagation
S2.6 artifact collector
S2.7 non-interactive suite migration
```

退出条件：关闭 VGA 抓取后，核心 suite 仍可完整判断结果。

### 11.4 里程碑 D：资源错误可定位

```text
S3.1 test API and registry
S3.2 runtime snapshot
S3.3 PMM/heap suites
S3.4 VM/scheduler suites
S3.5 IPC/FS suites
S3.6 fault injection controller
S3.7 user test exit/event normalization
```

退出条件：故意制造一次泄漏，测试必须报告具体 case 和差异字段。

### 11.5 里程碑 E：服务链闭环

```text
S4.1 IPC deadlock detection
S4.2 send_recv
S4.3 service protocol
S4.4 wait queue
S4.5 block abstraction
S4.6 partition parser
S4.7 HD service
S4.8 FS migration and service tests
```

退出条件：FS 正常路径不再直接访问 ATA，IPC 环能主动失败。

### 11.6 里程碑 F：安全启动基座

```text
S5.1 bss initialization
S5.2 kernel image metadata and dynamic loading
S5.3 complete traps and IST
S5.4 NX/W^X mappings
S5.5 ELF validation
S5.6 negative QEMU matrix
```

退出条件：超 188 扇区、安全页权限、异常栈和坏 ELF 均有自动测试。

---

## 12. 前两个迭代的具体安排

假设一名开发者每个迭代约 5 个工作日，建议先完成以下内容。

### 迭代 1：只做基线和 runner 骨架

第 1 天：

- 审阅脏工作区并建立基线 commit/tag。
- 采集工具版本、产物哈希。
- 启动一次完整 `make check-all`，保留原始结果。

第 2 天：

- 整理文档冲突和 `known-issues.md`。
- 定义 suite/case 命名、runner 退出码和 artifacts 路径。

第 3 天：

- 实现 `tests/run.sh`、manifest 和 runner 自测。
- 迁移 build/mkfs 三组无 QEMU 测试。

第 4 天：

- 实现 common/image/assertions。
- 实现 QEMU/monitor 公共生命周期。
- 迁移 boot suite。

第 5 天：

- 运行新旧 boot/build 测试对照。
- 修正 cleanup、timeout 和错误码。
- 提交里程碑 A，并准备里程碑 B 的中间验收。

### 迭代 2：完成 runner 迁移并接入串口

第 1–2 天：

- 迁移 VM、sync、userland、FS、LBA48 suites。
- 为旧 Make targets 增加转发。

第 3 天：

- 迁移交互测试。
- 拆分 smoke，去掉与 subsystem suite 重复的断言。

第 4 天：

- 实现 UART 轮询发送和 `print.c` 镜像。
- QEMU runner 收集 serial.log。

第 5 天：

- 先迁移 boot/VM 到结构化串口判断。
- 完整执行 fast 和 full profile。
- 记录不稳定 case，不能通过扩大 sleep 直接关闭问题。

如果迭代 2 末尾 full profile 不稳定，暂停阶段 3，先把失败归类为内核回归或测试基础设施问题。

---

## 13. 风险、决策点与规避方式

| 风险 | 表现 | 规避方式 |
| --- | --- | --- |
| 当前工作树不可追溯 | 同名文件包含 staged/unstaged/untracked 多层修改 | 阶段 0 人工审阅并提交；不自动清理或 reset |
| 测试重构改变语义 | 新 runner 变绿但少跑了断言 | 每个旧脚本建立断言清单，新旧入口对照 |
| UART 输出改变时序 | 大量轮询输出掩盖竞态或使测试变慢 | 结构化事件精简；压力测试分别跑 quiet/diagnostic |
| debug-exit 误用于普通内核 | 真实运行意外退出 QEMU | 仅 `KERNEL_TEST_MODE` 编译启用 |
| wait queue 重构丢失唤醒 | 偶发永久阻塞 | 原子“持锁入队+block”，高重复 seed 压力测试 |
| IPC 死锁检查本身遍历坏链 | 内核无限循环 | 以 live thread 数为硬上限，异常链返回错误 |
| FS→HD service 一次性迁移过大 | 难区分 IPC、block、ATA 或 FS 错误 | 先 block 包装，再迁 FS，最后切 service |
| 动态 Loader 损坏磁盘范围 | 加载覆盖 FS 或内存临时区 | 校验 header、LBA 上界、物理地址区间和 checksum |
| NX/W^X 一次开启导致无法启动 | 旧映射权限隐含依赖 | 先审计/诊断，按段切换，保留独立 QEMU case |
| SMP 放大现有单核假设 | 锁顺序、全局 current_thread 失效 | SMP 前完成 wait queue、资源快照和 per-CPU 设计审计 |

需要维护者提前做出的三个决策：

1. Loader 阶段 5 选择“自定义内核镜像头”还是“直接解析 ELF”。本计划推荐先镜像头。
2. 服务线程是否长期共享内核地址空间。本计划按逻辑隔离设计，不承诺微内核级故障隔离。
3. 阶段 6 的首要目标是 VFS/存储、SMP 还是网络。推荐 VFS/块层优先，因为它复用阶段 4 的服务边界且风险较可控。

---

## 14. 每阶段验收记录模板

每个阶段结束时新增一份 `docs/milestones/<stage>.md`：

```markdown
# Stage N 验收记录

- Commit:
- Tag:
- Date:
- Toolchain:
- Test protocol version:

## 交付物

- [ ] ...

## 验证命令与结果

| Command | Result | Duration | Artifacts |
| --- | --- | ---: | --- |
| make test-fast | PASS | ... | ... |
| make test-all | PASS | ... | ... |

## 已知问题

- LIMIT-...
- FLAKY-...

## 与上一阶段的资源基线差异

...

## 回退点

- Previous tag:
- Data-format compatibility:
```

涉及磁盘格式、服务协议或测试事件协议时，必须明确版本变化和向后兼容策略。

---

## 15. 立即开始时的最小行动清单

不要直接从 UART 或 IPC 重构开始。当前最短正确路径是：

1. 人工确认当前脏工作区哪些修改属于基线。
2. 创建基线分支、commit 和 tag。
3. 保存工具链版本与一次完整 `make check-all` 日志。
4. 修正文档中的 112/188、COW 和 tombstone 冲突。
5. 创建 `known-issues.md`，把所有基线失败编号。
6. 实现 runner 骨架及自测，仅迁移 build/mkfs。
7. 提取 QEMU 生命周期，迁移 boot。
8. 逐个迁移 VM、sync、FS、userland 和交互 suites。
9. 所有旧入口对照通过后，再实现 COM1 UART。
10. 串口稳定后引入结构化事件与 debug-exit。

完成第 10 项时，项目才具备继续做内核级重构所需要的诊断能力。后续每项 IPC、内存或启动改动都应通过统一 runner、结构化事件和资源快照验收。
