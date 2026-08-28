# Orange/64 VGA 现代终端主题行动方案

状态：IMPLEMENTED
日期：2026-08-15
目标分支：`feature/modern-vga-showcase-20260815`
实施范围：VGA 80×25 文本终端的视觉主题，不引入 framebuffer 或 GUI

---

## 1. 目标

本阶段只把现有 VGA 文本终端调整成接近 Ubuntu Terminal 的视觉风格：

- 深紫色背景；
- 柔和白色等宽文字；
- 保留红、绿、黄、青等状态色；
- 简洁的 `user@host:path$` Prompt；
- 块状或清晰的下划线光标；
- QEMU 窗口使用明确的终端标题；
- 可以保存一张包含真实颜色的 QEMU screenshot；
- 不改变 Shell、TTY、进程、IPC、文件系统和测试 runner 的架构。

目标效果示意：

```text
Orange/64 Terminal
Type 'help' to list commands.

orange@orange-os:/$ help
Commands:
  ls                list directory
  cat <file>        print file
  ps                list processes
  run <program>     start a program
  clear             clear terminal

orange@orange-os:/$ _
```

顶部窗口标题、关闭按钮和窗口边框由 QEMU/宿主机窗口系统提供；Guest 内部不模拟窗口管理器。

---

## 2. 非目标

本阶段明确不做：

- VBE、GOP 或 linear framebuffer；
- 图形模式、桌面、窗口管理器或鼠标；
- 自定义字体渲染；
- Unicode、Emoji 和特殊框线字符；
- 256 色或 true-color terminal；
- 完整 ANSI/VT100 terminal emulator；
- TTY 逻辑层重构；
- 新系统调用；
- 仅为展示而新增内核服务；
- 修改 Loader 的 188-sector 内核窗口；
- 把 `showcase.elf` 功能导览与本次主题验收绑定；
- 改变 fork、exec、IPC、COW、MyFS 或调度语义。

如果将来需要真正的图形终端，应另立 framebuffer 项目；不能在本阶段顺便扩张。

---

## 3. 当前工作区事实

制定本计划时，工作区不是干净状态。当前分支已有上一版方案产生的 WIP：

```text
M  Makefile
M  docs/oranges-design-implementation.md
M  kernel/tty.c
M  kernel/tty.h
M  tests/manifest.sh
M  usr/ps.c
M  usr/shell.c
?? docs/presentation-demo.md
?? tests/suites/showcase.sh
?? usr/showcase.c
?? usr/term.h
```

这些修改属于用户工作，不允许通过 `git reset`、`git checkout --`、删除文件或覆盖整文件来恢复。

当前 WIP 已经包含：

- TTY ANSI/样式解析相关修改；
- Shell dashboard 和彩色 Prompt；
- `showcase.elf`；
- showcase runner case；
- 展示文档；
- `ps` 输出调整。

其中只有一部分与本计划目标一致。本计划实施前必须逐文件审计，并采用以下规则：

1. VGA 调色板、光标、简洁 Prompt 和 QEMU 标题属于本阶段。
2. dashboard 卡片不属于最终目标，应停止继续扩展。
3. ANSI 支持不是本阶段必要条件；已有实现若正确、体积小且测试稳定，可作为独立可选能力保留，但主题不能依赖它。
4. `showcase.elf` 和 `showcase.core` 是功能演示工作，应与主题任务分离；不能用它们的成功或失败判断主题是否完成。
5. 未经维护者明确确认，不删除现有 WIP 文件；可以让它们暂时不参与本阶段验收。

---

## 4. 技术方案

## 4.1 利用 VGA DAC 改变真实显示颜色

当前默认 VGA 文本属性为 `0x0F`：

```text
foreground palette index = 15
background palette index = 0
```

因此不需要改动显存 cell 格式，只需重新编程 VGA DAC：

- palette 0：深紫色背景；
- palette 15：柔和白色前景；
- 其他常用索引设置为较柔和的状态色。

VGA DAC 接口：

```text
0x3C8  palette index
0x3C9  red, green, blue
```

VGA DAC 每个分量为 6 bit。公开接口接受 0–255 RGB，写硬件前右移 2 bit。

建议配色：

| Index | 用途 | RGB | DAC 近似值 |
| ---: | --- | --- | --- |
| 0 | 默认背景 | `#300A24` | `12,2,9` |
| 7 | 普通浅灰 | `#C8C8C8` | `50,50,50` |
| 8 | 辅助深灰 | `#707070` | `28,28,28` |
| 9 | 蓝 | `#5F87FF` | `23,33,63` |
| 10 | 绿 | `#5FD75F` | `23,53,23` |
| 11 | 青 | `#5FD7D7` | `23,53,53` |
| 12 | 红 | `#FF5F5F` | `63,23,23` |
| 13 | 紫红 | `#D75FD7` | `53,23,53` |
| 14 | 黄 | `#FFD75F` | `63,53,23` |
| 15 | 默认前景 | `#F2F2F2` | `60,60,60` |

背景最终可能因 VGA DAC 量化显示为约 `#310824`，这是正常现象。

## 4.2 VGA 主题模块

优先新增小型模块：

```text
kernel/vga.h
kernel/vga.c
```

接口：

```c
void vga_palette_set(uint8_t index,
                     uint8_t red,
                     uint8_t green,
                     uint8_t blue);
void vga_apply_terminal_theme(void);
void vga_set_block_cursor(void);
void vga_set_underline_cursor(void);
```

实现约束：

- 只能调用 `outb`；
- 不调用 print、TTY、mutex、spinlock、PMM 或 kmalloc；
- 不维护动态状态；
- 索引范围必须限制在 0–15；
- RGB 进入 DAC 前转换为 6 bit；
- 重复调用结果一致；
- 不修改显存字符或光标位置；
- 不在 panic 路径重新编程调色板。

如果项目维护者希望减少文件数量，也可以把实现放在已有的 VGA/print 模块，但不得在 `tty.c` 中散落端口写入。

## 4.3 初始化时机

建议在 `print_init()` 初始化锁后调用：

```c
void print_init(void)
{
    mutex_init(&print_lock);
    vga_apply_terminal_theme();
    vga_set_block_cursor();
}
```

调用时机必须满足：

- I/O port 指令已经可用；
- 不依赖 TTY 初始化；
- 后续 `tty_init()` 不会恢复 BIOS 默认 palette；
- quiet 和 diagnostic 两种启动模式颜色一致。

如果 `print_init()` 前已有必须展示的 Loader 字符，它们可以短暂使用 BIOS 默认颜色；本阶段不改 Loader 调色板。

## 4.4 默认属性和空白区域

保持：

```c
#define VGA_DEFAULT_COLOR 0x0F
```

统一检查以下路径：

- `print.c` 早期清屏；
- `tty.c:console_clear`；
- TTY history 空白初始化；
- `flush_active_console` 的无内容行；
- 滚屏新行；
- PageUp/PageDown 后的空白行；
- F1/F2/F3 新控制台；
- 退格擦除后的 cell。

所有默认空白 cell 都应使用 `0x0F`，不能混入 BIOS 遗留属性。主题颜色由 palette 决定，而不是把每个 cell 改成紫色 background index。

## 4.5 Panic 和语义色

当前 panic 使用 `0x4F`，即红底白字。重新编程 palette 后必须确认：

- 红色背景仍与紫色背景明显区分；
- 白色文字在红底上可读；
- `print_error`、`print_success`、`print_info`、`print_warning` 仍分别可辨；
- quiet boot 不因主题初始化产生额外日志。

不要为了主题改变 panic 的控制流和锁行为。

## 4.6 光标

使用 VGA CRTC：

```text
0x3D4  register selector
0x3D5  register value
0x0A  cursor start scanline
0x0B  cursor end scanline
```

首选块状光标：

```text
start = 0
end   = 15
```

回退下划线光标：

```text
start = 13
end   = 15
```

验收时使用实际 QEMU 窗口检查。如果块光标在当前 VGA 字体模式中遮挡字符、显示异常或无法稳定截图，则改用下划线光标，并在文档中记录最终选择。

本阶段不实现软件光标、定时闪烁或自定义光标颜色。

---

## 5. Shell 文本布局

## 5.1 删除大 dashboard 依赖

最终界面不需要模块卡片或两屏欢迎页。Shell 启动只输出：

```text
Orange/64 Terminal
Type 'help' to list commands.

orange@orange-os:/$
```

当前 WIP 的 `draw_dashboard()` 可以在后续实现时收敛为上述两行；不要继续增加 TTY、PROCESS、FILES 等卡片。

## 5.2 Prompt

目标可见文本：

```text
orange@orange-os:<cwd>$
```

示例：

```text
orange@orange-os:/$
orange@orange-os:/home$
```

规则：

- 用户名固定为 `orange`；
- host 固定为 `orange-os`；
- cwd 继续复用现有 `prompt_cwd`；
- 只在 `cd` 成功后刷新 cwd，保持当前 IPC 优化；
- Prompt 总长度仍计入当前行编辑擦除逻辑；
- Ctrl+C、Ctrl+L、Ctrl+U、Ctrl+W 后必须重绘相同 Prompt；
- PageUp/PageDown 和控制台切换不改变 Prompt；
- 不显示 Unicode 图标或特殊箭头。

如果保留当前 ANSI WIP，可以给 Prompt 分段着色；如果 ANSI 仍存在重定向或历史问题，则第一版全部使用柔和白色。紫底白字本身已经满足目标，不以彩色 Prompt 作为门禁。

## 5.3 Help

将 help 调整为纵向列表，固定行不超过 80 字符：

```text
Commands:
  help              show this help
  ls                list directory
  cat <file>        print file
  echo <text>       print text
  mkdir <dir>       create directory
  cd <dir>          change directory
  pwd               print working directory
  ps                list processes
  run <program>     start a program
  clear             clear terminal

Keyboard:
  F1-F3             switch console
  PgUp/PgDn         scroll history
  Ctrl+L            clear screen
  Ctrl+C            interrupt foreground process
```

命令实现不变，只改变帮助文本。

## 5.4 测试稳定标记

欢迎文本和 Prompt 被多个 QEMU suite 使用。采用以下统一值：

```text
Welcome marker: Orange/64 Terminal
Prompt marker:  orange@orange-os:/$
```

需要更新所有活动 suite 和仍保留的 legacy 对照脚本。禁止让部分测试查旧 Prompt、另一部分查新 Prompt。

---

## 6. QEMU 演示入口

## 6.1 Make target

新增变量：

```make
SHOWCASE_IMAGE ?= build/showcase-demo.img
SHOWCASE_DISK_SIZE ?= 64M
SHOWCASE_MEMORY ?= 512M
```

建议入口：

```text
make showcase-prepare
make showcase
```

语义：

- `showcase-prepare` 只创建或重建 `build/showcase-demo.img`；
- `showcase` 启动准备好的镜像；
- 不覆盖默认 `hd8G.img`；
- 不执行 `make clean`；
- 默认 `BOOT_DIAGNOSTIC=0`；
- QEMU 单核、512MiB；
- QEMU 窗口标题为 `Orange/64 Terminal`。

QEMU 参数示意：

```text
-name "Orange/64 Terminal"
-drive file=build/showcase-demo.img,format=raw,index=0,media=disk
-m 512M
-smp 1
-no-reboot
-no-shutdown
```

不使用 `-display none`，让 QEMU 打开正常窗口。是否加入 GTK `zoom-to-fit` 必须以当前 QEMU 版本实际支持为准，不写入未经验证的选项。

## 6.2 与现有 showcase WIP 的命名冲突

当前工作区可能同时包含 `usr/showcase.c`。需要明确区分：

- `showcase.elf`：用户态功能导览程序；
- `make showcase`：启动主题演示镜像。

两者可以共存，但本阶段只验收后者。若维护者认为名称容易混淆，可将 Make target 改为：

```text
make terminal-demo
```

在实施前确定一个名称，之后不要在文档和 Makefile 中混用。

---

## 7. 测试方案

## 7.1 静态检查

```bash
git diff --check
bash -n tests/run.sh tests/manifest.sh tests/lib/*.sh tests/suites/*.sh
make check
```

记录：

- MBR、Loader、kernel.bin 大小；
- 修改前后 kernel.bin 差值；
- 188-sector 上限剩余空间；
- quiet/diagnostic 构建结果。

VGA 主题模块预期很小；如果内核增长异常，应检查是否错误纳入已有 ANSI/showcase WIP，而不是删减其他内核功能。

## 7.2 Runner 自测和快速测试

```bash
make test-self
make test-fast
```

主题不能改变 runner、manifest 解析、artifact 或宿主机 mkfs 行为。

## 7.3 Boot

```bash
make test CASE=boot.quiet SEED=20260815 KEEP_FAILED=1
```

断言：

- `[BOOT] kernel ready`；
- `[BOOT] storage ready`；
- `[BOOT] launching shell` 独占一行；
- `Orange/64 Terminal`；
- `orange@orange-os:/$`；
- quiet 模式没有泄漏 diagnostic；
- VGA 文本稳定快照仍能解码。

## 7.4 TTY 和输入

```bash
make test CASE=tty.shell SEED=20260815 KEEP_FAILED=1
make test CASE=input.stress SEED=20260815 KEEP_FAILED=1
```

重点检查：

- clear 后所有空白使用一致背景；
- Ctrl+L 后 Prompt 正确；
- Ctrl+C 后 Prompt 正确；
- 快速输入没有丢失；
- F1/F2/F3 控制台均使用主题；
- PageUp/PageDown 不出现黑色空白条；
- 重定向文件中没有 Prompt、欢迎文本或样式控制字节。

## 7.5 真实彩色截图

`pmemsave 0xb8000` 只保存文本 cell，不能证明紫色 palette 的最终显示效果。新增或扩展一个测试，通过 QEMU monitor 执行：

```text
screendump <artifact>/terminal-theme.ppm
```

artifact 至少保存：

```text
terminal-theme.ppm
vga.bin
vga.txt
qemu.log
environment.txt
result.env
```

自动检查：

- PPM 文件存在且非空；
- magic 为 `P6`；
- 宽高为 QEMU 当前 VGA 文本显示尺寸；
- 最大颜色值为 255；
- 选取明确的空白背景区域，RGB 接近 DAC 量化后的 `#310824`，允许每个分量 ±4；
- 选取文字区域只做“存在非背景像素”检查，不做整图 hash。

如果在 Shell 脚本中可靠解析二进制 PPM 过于复杂，可以新增一个很小的宿主机检查工具；不能引入 Python、ImageMagick 或网络依赖作为构建必需项。

## 7.6 其他回归

Prompt 变化可能影响多项集成测试，至少运行：

```bash
make test CASE=fs.service SEED=20260815 KEEP_FAILED=1
make test CASE=userland.core SEED=20260815 KEEP_FAILED=1
make test CASE=vm.cow SEED=20260815 KEEP_FAILED=1
```

随后尝试：

```bash
make check-all
```

已知事项：

- QEMU Unix monitor socket 在受限沙箱中可能返回 `Operation not permitted`，应按权限流程重跑，不能当作内核失败；
- 默认 `sync.core` 在较慢环境可能达到 900 秒门限；必须如实记录 TIMEOUT；
- 当前分支文档记录过 `integration.smoke` 在加载 `thread-demo.elf` 时的独立失败；主题工作不能掩盖或错误关闭该问题。

主题验收可以先依赖目标 suite 全部通过，但发布验收仍要求解释完整矩阵中的任何失败。

---

## 8. Prompt 迁移清单

使用：

```bash
rg -n 'orange:/\$|Orange.S user shell ready' tests docs Makefile
```

优先更新活动测试：

```text
tests/suites/boot.sh
tests/suites/fs.sh
tests/suites/lba48.sh
tests/suites/tty.sh
tests/suites/input.sh
tests/suites/userland.sh
tests/suites/sync.sh
tests/suites/vm.sh
tests/suites/integration.sh
```

然后更新仍保留的 legacy 脚本：

```text
tests/qemu_boot.sh
tests/qemu_fs.sh
tests/qemu_lba48.sh
tests/qemu_shell_fs.sh
tests/qemu_input_stress.sh
tests/qemu_userland.sh
tests/qemu_sync.sh
tests/qemu_vm.sh
tests/qemu_smoke.sh
```

历史 baseline 和 milestone 文档记录的是历史输出，不应机械重写。只在当前设计文档和演示文档中说明新 Prompt；历史验收证据保留当时的真实字符串。

---

## 9. 分任务实施顺序

## T0：审计现有 WIP

预计：0.5 人日。

操作：

1. 保存 `git status --short` 和 `git diff --stat`。
2. 查看 `Makefile`、`kernel/tty.*`、`usr/shell.c`、`usr/term.h`、showcase 文件的 diff。
3. 标记哪些修改属于：主题、ANSI、dashboard、功能 showcase、测试修复。
4. 不删除任何用户修改。
5. 记录开始前 `make check` 和 kernel.bin 大小。

完成条件：能够逐项说明当前 WIP 与本计划的关系。

## T1：VGA palette 模块

预计：0.5 人日。

改动：

- 新增 `kernel/vga.h/.c`；
- 在安全的早期初始化点应用 palette；
- 保持默认属性 `0x0F`；
- 验证 panic 和语义色。

提交边界建议：

```text
ui(T1): add VGA DAC terminal palette
```

完成条件：实际 QEMU 窗口显示深紫底白字，`make check` 通过。

## T2：光标和空白一致性

预计：0.25 人日。

改动：

- 配置块状光标；
- 审计 clear、scroll、history、console switch 的默认属性；
- 修复任何黑底残留。

提交边界建议：

```text
ui(T2): apply themed cursor and blank cells
```

完成条件：三个控制台、清屏和滚动都没有黑色条带。

## T3：Shell 文本收敛

预计：0.5 人日。

改动：

- 欢迎信息改为两行；
- Prompt 改为 `orange@orange-os:<cwd>$`；
- help 改为纵向对齐；
- 停止扩展 dashboard；
- 保留所有 Shell 行为。

提交边界建议：

```text
shell(T3): simplify terminal welcome and prompt
```

完成条件：80 列内显示整洁，控制键重绘正确。

## T4：演示 Make target

预计：0.25 人日。

改动：

- 新增独立演示镜像变量；
- 新增 prepare/run target；
- 设置 QEMU title；
- 更新 `make help`。

提交边界建议：

```text
build(T4): add isolated terminal showcase target
```

完成条件：一条命令打开带标题的紫色 QEMU 终端，不覆盖默认镜像。

## T5：测试迁移和 screenshot

预计：0.5–1 人日。

改动：

- 更新活动 suite 的 Prompt marker；
- 更新 legacy 对照脚本；
- 增加实际彩色 screenshot artifact；
- 验证背景像素和文本 shadow。

提交边界建议：

```text
test(T5): validate VGA theme and updated prompt
```

完成条件：目标 QEMU suites 通过，截图可直接用于 PPT。

## T6：文档和最终审计

预计：0.25 人日。

改动：

- 更新 `docs/oranges-design-implementation.md` 当前 UI 描述；
- 更新 `docs/presentation-demo.md` 演示命令；
- 记录最终颜色、Prompt、截图、kernel 大小和测试 artifact。

完成条件：文档不再宣称 framebuffer、dashboard 或完整 ANSI 是当前主题必需项。

总预计：约 2–3 人日；如果现有 ANSI/showcase WIP 存在回归，相关修复单独估算，不计入主题本身。

---

## 10. 阶段门禁

本主题只有满足以下条件才算完成：

- [ ] 实际 QEMU 窗口为深紫底、柔和白字。
- [ ] 默认空白、清屏、滚屏和三个控制台背景一致。
- [ ] 光标清晰可见且不破坏输入。
- [ ] 欢迎信息只有简洁两行。
- [ ] Prompt 为 `orange@orange-os:<cwd>$`。
- [ ] help 对齐且不超过 80 列。
- [ ] QEMU 窗口标题为 `Orange/64 Terminal`。
- [ ] 演示使用独立镜像，不覆盖默认磁盘。
- [ ] `pmemsave` 文本测试仍可用。
- [ ] `screendump` 产生可用于 PPT 的彩色图片。
- [ ] `make check`、`make test-self`、`make test-fast` 通过。
- [ ] boot、TTY、input、FS、userland、VM 目标 case 通过。
- [ ] 没有减少既有功能断言。
- [ ] 任何 full matrix 失败均被如实记录。
- [ ] `git diff --check` 通过。
- [ ] 未执行未授权的 reset、clean、commit 或 tag。

---

## 11. 回退方案

主题实现必须容易关闭。建议提供编译配置：

```make
VGA_TERMINAL_THEME ?= 1
```

关闭时：

```bash
make VGA_TERMINAL_THEME=0 build
```

行为：

- 不重新编程 VGA DAC；
- 使用 BIOS 默认黑底白字；
- Shell 功能和 Prompt 是否回退应明确规定。推荐只回退 palette，Prompt 保持当前版本，避免维护两套 Shell 文本测试。

如果主题导致硬件或模拟器兼容问题：

1. 用配置关闭 palette 初始化；
2. 保留 VGA cell、TTY 和 Shell 逻辑；
3. 运行同一目标测试确认问题只来自 palette；
4. 不通过回滚无关内核功能解决。

---

## 12. 实施时可直接使用的执行 Prompt

```text
请在 /home/orange/my_os 中按照
docs/vga-terminal-theme-action-plan.md 实施 Orange/64 VGA 现代终端主题。

本任务只实现类似 Ubuntu Terminal 的 VGA 文本视觉：深紫背景、柔和白字、
状态色、块状光标、简洁 user@host:path$ Prompt、QEMU 窗口标题和真实彩色截图。

禁止扩张为 framebuffer、VBE、GUI、窗口管理器、字体渲染、完整 ANSI terminal、
TTY 架构重构或新系统调用。

开始前：
1. 阅读完整行动方案和相关 AGENTS.md。
2. 检查 git status 和所有现有 diff。当前工作区包含 ANSI、dashboard、showcase.elf
   等未提交 WIP；这些属于用户工作，禁止 reset、checkout 覆盖、删除或整文件重写。
3. 先把 WIP 按主题/ANSI/dashboard/showcase/测试分类，报告审计结果。
4. 记录修改前 kernel.bin 大小、make check 和目标测试状态。

严格按 T0 到 T6 执行，每个任务完成后先验证再继续：
- T0 审计 WIP；
- T1 VGA DAC palette；
- T2 光标和空白属性一致性；
- T3 简化欢迎页、Prompt 和 help；
- T4 独立 QEMU 演示 target；
- T5 Prompt 测试迁移和 screendump；
- T6 文档与最终审计。

颜色和 ABI：
- default cell attribute 保持 0x0F；
- palette 0 = #300A24；
- palette 15 = #F2F2F2；
- 使用 0x3C8/0x3C9，RGB 8-bit 转 VGA DAC 6-bit；
- 保留 red/green/cyan/yellow 等语义色；
- panic 红底白字必须可读。

Shell 最终文本：
Orange/64 Terminal
Type 'help' to list commands.

orange@orange-os:<cwd>$

不要继续扩展 dashboard。ANSI 不是主题门禁；已有 ANSI WIP 只有在正确、稳定、
不污染重定向且体积合理时才保留。showcase.elf 不纳入主题完成条件。

最低测试：
- git diff --check
- bash -n tests/run.sh tests/manifest.sh tests/lib/*.sh tests/suites/*.sh
- make check
- make test-self
- make test-fast
- make test CASE=boot.quiet SEED=20260815 KEEP_FAILED=1
- make test CASE=tty.shell SEED=20260815 KEEP_FAILED=1
- make test CASE=input.stress SEED=20260815 KEEP_FAILED=1
- make test CASE=fs.service SEED=20260815 KEEP_FAILED=1
- make test CASE=userland.core SEED=20260815 KEEP_FAILED=1
- make test CASE=vm.cow SEED=20260815 KEEP_FAILED=1

QEMU socket 被沙箱禁止时按权限流程重跑，不得把 INFRASTRUCTURE_ERROR 当作内核失败。
最后尝试 make check-all；sync 超时或 integration 失败必须如实记录。

完成后报告：
1. 最终 RGB/DAC palette；
2. Prompt、welcome、help 和光标效果；
3. 修改文件；
4. kernel.bin 修改前后大小；
5. 演示命令；
6. 测试、seed 和 artifacts；
7. terminal-theme.ppm 路径；
8. 未解决问题；
9. 与现有 ANSI/showcase WIP 的最终关系。

不要自行 commit、tag、reset、clean 或改写 Git 历史。
```

---

## 13. 最终演示命令

实施完成后的演示流程应保持简单：

```bash
make showcase-prepare
make showcase
```

Guest 中：

```text
orange@orange-os:/$ help
orange@orange-os:/$ ps
orange@orange-os:/$ ls
orange@orange-os:/$ clear
```

PPT 使用的截图直接取自最终测试 artifact：

```text
build/test-artifacts/<run-id>/ui/theme/1/terminal-theme.ppm
```

本次没有新增独立 `ui.theme` case；screenshot 保存在 showcase artifact：

```text
build/test-artifacts/20260815-180436-12425-1786775869/showcase/core/1/terminal-theme.ppm
```
