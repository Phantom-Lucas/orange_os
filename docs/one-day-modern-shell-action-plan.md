# Orange/64 一天版现代 Shell 行动方案

状态：PROPOSED

日期：2026-08-19

时间预算：约 8–12 个 AI 执行小时，必须在一天内形成可演示、可回归的结果

---

## 1. 结论与取舍

一天内可以完成“明显更现代的 Shell 交互”，但不能完成真正的 1080p framebuffer/KMSCon。

本方案保留当前：

- BIOS MBR 和 Loader；
- 188 扇区内核窗口；
- VGA 80×25 文本后端；
- 当前 TTY、IPC、进程和文件系统架构；
- 当前管道、重定向、后台执行和 ANSI SGR 子集。

只增加以下用户能直接看到的能力：

- Left/Right 行内移动；
- Home/End；
- Delete 和当前位置插入；
- Up/Down 会话历史；
- 暗灰色 ghost-text 历史建议；
- Right/End 接受建议；
- 基础实时语法着色；
- Tab 命令补全；
- 多候选时显示紧凑的多列菜单；
- 原有管道、重定向、后台命令继续可用。

最终效果定位为：

```text
现有深紫 VGA 终端
+ Fish 风格输入体验 MVP
+ 稳定演示脚本
+ 自动化键盘回归
```

这不是高清控制台。真正 1080p、PSF2 字体、24-bit framebuffer 和 Job Control 继续保留在长期方案：

```text
docs/modern-console-advanced-shell-execution-plan.md
```

---

## 2. 一天内明确不做

以下内容一旦开始就会把任务扩大为多日改造，本轮禁止：

- 修改 `boot/mbr.S`、`boot/loader.S` 或 `kernel/linker.ld`；
- 修改内核物理布局或解除 188 扇区限制；
- VBE、GOP、framebuffer、PSF2、TTF；
- 重写 TTY cell/history/console 模型；
- 新增 syscall；
- termios、raw mode 或 ioctl；
- 重写 Shell 为 lexer/AST 多文件架构；
- 完整引号、变量和 `$PATH`；
- 多级 pipeline；
- 持久化 history；
- 文件路径补全；
- 进程组、STOPPED、SIGCONT、`jobs/fg/bg`；
- 改变 Ctrl+Z 当前降级语义；
- 为了新增功能执行 `reset`、`clean` 或覆盖现有 WIP。

如果时间有剩余，只允许增强测试和演示，不自动进入长期方案。

---

## 3. 当前代码可复用点

当前项目已经具备：

- `kernel/keyboard.c` 能识别 E0 扩展 scancode，但只消费 PageUp/PageDown；
- 键盘最终把字符放入现有 TTY 输入队列；
- 用户 Shell 一次可以批量读取输入字节；
- TTY 已支持 `\r`、`\n`、`\b` 和 ANSI SGR 色彩；
- `usr/term.h` 已有 GREEN、RED、YELLOW、BLUE、CYAN、MUTED；
- Shell 已有 Ctrl+C、Ctrl+L、Ctrl+U、Ctrl+W；
- Shell 已有最小 `|`、`<`、`>`、`>>`、`&`；
- QEMU monitor 可以发送 Left/Right/Up/Down/Tab 等按键；
- unified runner 已有 `tty.shell`、`input.stress` 和 `showcase.core`。

因此不需要修改 TTY 输出状态机。Shell 可以使用下面的单行重绘策略：

```text
1. 输出 \r 回到当前行首；
2. 重画 Prompt、真实输入和 ghost text；
3. 用空格覆盖上一次更长的残留内容；
4. 再输出 \r；
5. 重画 Prompt 和真实输入中光标之前的部分；
6. 硬件光标自然停在目标位置，光标后的字符仍保留在屏幕上。
```

这比新增 CSI 光标移动和 erase-line 更小，也不会扰动当前 TTY parser。

---

## 4. 修改范围

预计只修改：

```text
kernel/keyboard.c
usr/shell.c
usr/term.h                 # 仅在缺少颜色别名时修改
tests/suites/input.sh
tests/suites/tty.sh        # 如需复用启动/捕获 helper
tests/suites/showcase.sh   # 只增加交互演示断言时修改
docs/presentation-demo.md  # 更新现场演示步骤
docs/one-day-modern-shell-action-plan.md
```

原则上不修改：

```text
kernel/tty.c
kernel/process.c
kernel/syscall.c
kernel/fs.c
boot/*
kernel/linker.ld
```

如果实现过程中发现必须修改这些文件，应先停止并重新评估，不得顺手扩张。

---

## 5. 技术设计

### 5.1 特殊键输入

在 `kernel/keyboard.c` 的 E0 分支补充标准 ANSI 输入序列：

| 按键 | PS/2 E0 scancode | 输入字节 |
|---|---:|---|
| Up | `0x48` | `ESC [ A` |
| Down | `0x50` | `ESC [ B` |
| Right | `0x4D` | `ESC [ C` |
| Left | `0x4B` | `ESC [ D` |
| Home | `0x47` | `ESC [ H` |
| End | `0x4F` | `ESC [ F` |
| Delete | `0x53` | `ESC [ 3 ~` |

PageUp/PageDown 继续由内核切换 TTY scrollback，不发送给 Shell。

实现约束：

- 新增 `enqueue_char()` 和 `enqueue_sequence()` 小 helper；
- 多字节序列必须全入队或全丢弃，不能留下半个 `ESC [`；
- 不修改 `struct keyboard_event`；
- 不修改用户/内核 ABI；
- 队列接近满时仍优先保护 Enter 和控制字符；
- release scancode 不产生输入。

### 5.2 Shell 输入解码器

Shell 的 `sys_read()` 可能在任意字节边界返回，因此不能假设一次 read 得到完整 `ESC[A`。

增加小型流式状态机：

```c
enum input_decode_state {
    INPUT_NORMAL,
    INPUT_ESC,
    INPUT_CSI,
    INPUT_CSI_DELETE
};
```

输出为内部动作：

```c
enum editor_action {
    EDIT_INSERT,
    EDIT_LEFT,
    EDIT_RIGHT,
    EDIT_UP,
    EDIT_DOWN,
    EDIT_HOME,
    EDIT_END,
    EDIT_DELETE,
    EDIT_TAB
};
```

约束：

- 状态必须跨 `sys_read()` 保存；
- 未识别序列直接复位，不显示控制字节；
- 最长只接受本方案列出的 4 字节序列；
- 不解析任意数字 CSI，避免一天版变成第二个终端模拟器；
- 普通 Tab 字节 `\t` 映射为 EDIT_TAB。

### 5.3 编辑器状态

不引入 malloc 和多文件重构，使用固定上限：

```c
#define LINE_SIZE 128
#define HISTORY_COUNT 16

struct line_editor {
    char line[LINE_SIZE];
    unsigned long length;
    unsigned long cursor;
    unsigned long previous_render_cells;

    char history[HISTORY_COUNT][LINE_SIZE];
    unsigned int history_count;
    unsigned int history_head;
    int history_view;

    const char* suggestion;
    unsigned long suggestion_offset;
    int completion_menu_visible;
};
```

必须保持：

```text
0 <= cursor <= length < LINE_SIZE
line[length] == '\0'
```

编辑操作：

- 普通字符：在 cursor 插入，后半段右移；
- Backspace：删除 cursor 前一个字符；
- Delete：删除 cursor 所在字符；
- Left/Right：边界内移动；
- Home/End：移动到 0/length；
- Ctrl+U：清空；
- Ctrl+W：删除 cursor 前一个单词，不再假设 cursor 在结尾；
- Ctrl+C：取消当前行并清空 suggestion/menu；
- Ctrl+L：清屏后重新绘制当前编辑状态。

一天版按 ASCII byte 编辑。UTF-8 codepoint 光标属于长期方案，必须在文档中明确。

### 5.4 单行重绘

增加：

```c
static void editor_redraw(struct line_editor* editor);
```

逻辑：

```text
write("\r")
draw_prompt()
draw_highlighted(line[0:length])
draw_muted(suggestion_suffix)
write(spaces to previous_render_cells)
write("\r")
draw_prompt()
draw_highlighted(line[0:cursor])
```

注意：

- 第二次绘制只用于定位光标；
- suggestion 不写入 `line`；
- Enter 前先隐藏 suggestion，再换行；
- menu 输出后必须重新绘制 Prompt 和当前输入；
- 输入可继续保留 128 字节，但一天版只保证 Prompt + 输入不跨 VGA 行时光标正确；
- cwd 太长或输入即将换行时，关闭 ghost/menu，退化为普通输入；
- 记录 `previous_render_cells`，防止较长旧输入留下尾巴。

### 5.5 会话历史

只实现当前 Shell 进程内的 16 条历史：

- 空命令不记录；
- 与上一条完全相同的不重复记录；
- ring 满后覆盖最旧项；
- Up 向旧记录移动；
- Down 向新记录移动；
- 离开 history 后恢复进入浏览前的草稿；
- 执行历史命令后按正常规则再次记录。

本轮不写 MyFS，不实现跨重启 history，避免引入异常断电、append 和损坏恢复问题。

### 5.6 Ghost-text suggestion

规则保持简单、确定：

1. 只在 cursor 位于行尾时显示；
2. 从最新到最旧查找 history；
3. 候选必须以当前真实 line 为前缀；
4. 候选必须比当前 line 长；
5. 只绘制候选剩余后缀；
6. 后缀使用 `MUTED`；
7. Right 或 End 接受完整 suggestion；
8. 输入新字符、删除或历史移动后重新计算；
9. Enter 永远只执行 `line`，不能隐式执行 ghost text。

示例：

```text
先执行： echo project-status
再输入： ec
显示：   ec|ho project-status     # | 后为暗灰 ghost，不在真实 buffer
按 End： echo project-status      # 此时才写入真实 buffer
```

### 5.7 基础实时高亮

把 `style_enabled` 的交互默认值设为 1；重定向和 pipeline 路径继续临时关闭 style，保证文件中没有 ANSI。

一天版只做词法颜色，不判断复杂语义：

- 第一个 command word：CYAN 或 GREEN；
- `|`、`<`、`>`、`>>`、`&`：YELLOW；
- 单/双引号包围的片段：YELLOW；
- 普通参数：默认柔和白；
- 未闭合引号：RED；
- ghost：MUTED。

高亮器必须：

- 单次线性扫描；
- 不修改真实 line；
- 不改变 `run_command()` 现有执行语义；
- style 关闭时只输出原始文本；
- 每段输出后 RESET，不能让后续命令继承颜色。

这不是完整语法高亮。引号执行语义仍按现有 Shell，颜色只用于交互提示。

### 5.8 Tab 命令补全

为控制范围，只补全“行首 command word”。候选来源为静态命令表：

```text
help ls cat echo write mkdir cd pwd stat rm run demo exec clear about exit
hello ipc-demo exec-demo uaccess-demo thread-demo sync-demo vm-demo fs-demo
libc-demo libc-test ps sleep kill showcase
```

表应与 builtin dispatch 和构建用户程序保持在同一处或至少有测试检查，避免长期漂移。

行为：

- 0 个候选：不修改，发出可选提示；
- 1 个候选：补全剩余字符并加空格；
- 多候选：先补全共同前缀；
- 已无更长共同前缀时，再次 Tab 输出多列菜单；
- 菜单固定使用 VGA 80 列计算列宽；
- 输出菜单后恢复 Prompt、line、ghost 和 cursor；
- 输入变化后关闭菜单。

本轮不补文件路径、不读取目录、不增加 `getdents`。

---

## 6. 逐小时执行安排

### T0：基线与保护（0.5 小时）

- [ ] 记录 HEAD 和 dirty worktree；
- [ ] 保存修改前 `make check`、`test-self`、`tty.shell`、`input.stress`；
- [ ] 记录 kernel.bin 大小；
- [ ] 建立修改文件白名单；
- [ ] 不执行 clean/reset/checkout/commit/tag。

验收：基线结果和 artifacts 可定位。

### T1：方向键输入（1 小时）

- [ ] `keyboard.c` 增加 ANSI sequence enqueue；
- [ ] Left/Right/Up/Down/Home/End/Delete 全部映射；
- [ ] 保持 PgUp/PgDn、F1-F3 和控制键行为；
- [ ] 增加序列 all-or-none 队列边界检查；
- [ ] 编译并运行 input smoke。

验收：用户态能收到完整序列，压力输入不产生残缺 ESC。

### T2：编辑器核心（2 小时）

- [ ] 在 `usr/shell.c` 增加 editor state；
- [ ] 流式解码特殊键；
- [ ] insert/backspace/delete/left/right/home/end；
- [ ] Ctrl+U/W/L/C 适配 cursor；
- [ ] 单行 redraw；
- [ ] Enter 后继续复用原 `run_command()`。

验收：可以把 `echo hllo` 的光标移回中间插入 `e` 并得到 `hello`。

### T3：历史与 ghost suggestion（1.5 小时）

- [ ] 16 条 session history ring；
- [ ] Up/Down 浏览和草稿恢复；
- [ ] prefix suggestion；
- [ ] MUTED ghost；
- [ ] Right/End 接受；
- [ ] Enter 不隐式接受。

验收：历史、建议、接受和取消都有自动测试。

### T4：高亮与 Tab 补全（2 小时）

- [ ] 打开交互 style；
- [ ] 增加 bounded line highlighter；
- [ ] 静态 command candidate table；
- [ ] 唯一补全、共同前缀和多列菜单；
- [ ] menu 后 redraw；
- [ ] 重定向文件不含 ESC。

验收：`pw<Tab>` 变为 `pwd `，多候选不会破坏当前输入。

### T5：自动化回归（2 小时）

- [ ] 扩展 `input.stress` 或新增 `input.editor`；
- [ ] QEMU sendkey 验证 Left/Right 插入；
- [ ] 验证 Delete/Home/End；
- [ ] 验证 Up/Down history；
- [ ] 验证 ghost accept；
- [ ] 验证 Tab 唯一补全；
- [ ] 验证 Ctrl+C/Ctrl+L；
- [ ] 复跑 `tty.shell`，保证 pipe/redirection/background；
- [ ] 复跑 `showcase.core`；
- [ ] 检查资源 baseline。

验收：失败能定位到具体按键和实际 VGA 文本。

### T6：文档与演示（1 小时）

- [ ] help 增加快捷键说明；
- [ ] presentation demo 加入 60–90 秒现代交互段；
- [ ] 保存最终 screenshot；
- [ ] 记录限制：ASCII、session history、command-only completion、非真正 job control；
- [ ] `git diff --check`、bash syntax、`make check`、目标 suite 全部通过。

验收：一条命令启动，一组固定按键即可重复演示。

### 时间缓冲（2 小时）

只用于：

- 修复输入批处理/序列分片；
- 修复 redraw 残留；
- 修复测试竞态；
- 控制 kernel.bin 尺寸；
- 改进文档和 artifact。

不用于增加 path completion、持久化 history 或 framebuffer。

---

## 7. 内核尺寸门禁

当前 Loader 仍限制 188 扇区，内核空间余量很小。

每次修改 `kernel/keyboard.c` 后运行：

```bash
make check
wc -c build/kernel/kernel.bin
```

规则：

- kernel.bin 必须小于等于 96,256 字节；
- 目标是新增内核代码不超过约 1 KiB；
- 大部分功能必须放在用户态 `shell.elf`；
- 若超限，先简化键盘 helper；
- 必要时只对 `keyboard.c` 使用 `-Os`；
- 禁止为了本轮功能改 Loader 或删除其他内核能力。

---

## 8. 自动化测试明细

建议新增 case：

```text
input.editor
```

如果不增加 manifest case，则将以下断言放进现有 `input.stress` 的独立小节，不能与压力循环混在一起。

### Case 1：行内插入

按键：

```text
echo hllo
Left Left Left
e
Enter
```

断言输出包含：

```text
hello
```

实际 Left 次数应根据输入 cursor 精确计算，脚本中写清每一步。

### Case 2：Delete/Home/End

构造带多余字符的 echo 命令，通过 Home/End/Right/Delete 修正，断言只输出修正结果。

### Case 3：History

```text
echo history-one
Up
Enter
```

断言 `history-one` 至少出现两次，并且 Prompt 恢复。

### Case 4：Ghost accept

```text
echo ghost-value
ec
End
Enter
```

断言第二次执行得到 `ghost-value`。另加一次输入 prefix 后直接 Enter，确认未接受的 ghost 不执行。

### Case 5：Tab

```text
pw
Tab
Enter
```

断言输出 cwd `/`。

### Case 6：多候选菜单

```text
l
Tab
Tab
```

断言候选列表出现，随后输入仍可继续编辑并执行。

### Case 7：样式隔离

```text
echo style-file > style-output
cat style-output
```

断言文件内容没有 `0x1B`。

### 回归矩阵

```bash
git diff --check
bash -n tests/run.sh tests/manifest.sh tests/lib/*.sh tests/suites/*.sh
make check
make test-self
make test-fast
make test CASE=boot.quiet SEED=20260819 KEEP_FAILED=1
make test CASE=tty.shell SEED=20260819 KEEP_FAILED=1
make test CASE=input.stress SEED=20260819 KEEP_FAILED=1
make test CASE=showcase.core SEED=20260819 KEEP_FAILED=1
```

完整 `make check-all` 只在目标 case 稳定后运行。

---

## 9. 演示脚本

启动：

```bash
make showcase-prepare
make showcase
```

建议现场输入：

```text
1. echo modern-shell
2. 输入 ec，展示暗灰 suggestion
3. 按 End 接受，再按 Enter
4. 输入 echo hllo，用 Left 移动并插入 e
5. 按 Up 调出上一条命令
6. 输入 pw，按 Tab，执行 pwd
7. 输入 l，按两次 Tab，展示多列候选
8. echo pipeline-ok | cat
9. echo saved > demo-file
10. cat demo-file
```

讲解口径：

```text
“这仍然是我自己 OS 的 VGA 文本后端，不是假桌面。一天版没有重写启动和
显示系统，而是在用户态 Shell 上加入了流式按键解码、可移动行编辑器、
历史建议、实时着色和补全；现有 pipe/dup2/FS 路径继续提供执行语义。”
```

不要宣称：

- 这是 1080p framebuffer；
- 支持完整 Fish/Zsh；
- 支持持久化 history；
- 支持完整引号和变量；
- `&` 已经是真正 Job Control；
- Ctrl+Z 可以停止/恢复任务。

---

## 10. 一天版完成标准

- [ ] 修改集中在 keyboard/Shell/tests/docs；
- [ ] 未修改 Loader、linker、页表、进程模型和 syscall；
- [ ] kernel.bin 不超过 188 扇区；
- [ ] Left/Right/Home/End/Delete 正常；
- [ ] 中间插入和删除正常；
- [ ] Up/Down session history 正常；
- [ ] ghost suggestion 可见、可接受、不隐式执行；
- [ ] 基础高亮不污染重定向；
- [ ] Tab 唯一补全与多候选菜单正常；
- [ ] 原 pipe/redirection/background 测试通过；
- [ ] Ctrl+C/Ctrl+L/Input stress 无回归；
- [ ] screenshot 和测试 artifacts 已保存；
- [ ] help 与演示文档同步；
- [ ] 所有限制如实记录。

---

## 11. 停止条件

遇到以下任一情况，停止加功能，优先恢复稳定：

- kernel.bin 超过 96,256 字节；
- 需要新增 syscall；
- 需要改变 `struct process` 或调度状态；
- 需要重写 TTY parser；
- 输入压力测试出现残缺 ESC 或丢 Enter；
- redraw 在常用 cwd 下跨行错位；
- pipe/redirection/background 回归；
- 当天剩余时间少于 2 小时且核心测试未通过。

功能裁剪顺序：

```text
多列菜单视觉优化
→ 未闭合引号高亮
→ Home/End 接受 ghost 的附加行为
→ Delete
→ ghost suggestion
```

必须保留的最小交付：

```text
方向键行内编辑 + history + Tab 唯一补全 + 全部旧测试通过
```

---

## 12. 可直接执行的 Prompt

```text
请在 /home/orange/my_os 中严格按照
docs/one-day-modern-shell-action-plan.md 实施一天版现代 Shell。

目标时间为 8–12 个 AI 执行小时。任务只允许局部增强，不实施 framebuffer、
VBE/GOP、字体引擎、动态 Loader、完整 Shell AST、环境变量或 Job Control。

开始前：
1. 阅读完整方案、git status、现有 diff 和所有适用 AGENTS.md。
2. 当前 dirty worktree 属于用户；禁止 reset、checkout 覆盖、clean、删除、提交或 tag。
3. 记录 HEAD、make check、test-self、tty.shell、input.stress、showcase.core 和
   kernel.bin 大小。
4. 修改白名单原则上只有 kernel/keyboard.c、usr/shell.c、必要测试和文档。

严格执行 T0 到 T6：
- T1 只把 Left/Right/Up/Down/Home/End/Delete 编码成标准 ANSI 输入序列；
- 多字节序列必须全入队或全丢弃；
- Shell 解码器必须支持序列跨 sys_read 分片；
- 编辑器使用固定 128-byte buffer 和 16 条 session history；
- redraw 使用现有 \r 和 SGR，不扩张 kernel/tty.c；
- ghost text 不进入真实 line，Right/End 才接受；
- 高亮关闭时输出必须完全无 ESC；
- Tab 只补全 command，不做 path completion；
- 保留现有 run_command、pipe、redirect 和 background 语义。

每个任务后运行最小相关测试。kernel 改动后立即运行 make check，kernel.bin 不得
超过 96,256 字节。若超限，不修改 Loader，优先裁剪内核新增代码。

QEMU socket 被沙箱拒绝时按权限流程重跑，标记为 INFRASTRUCTURE_ERROR，不修改
OS 规避宿主限制。

最低最终测试：
- git diff --check
- bash -n tests/run.sh tests/manifest.sh tests/lib/*.sh tests/suites/*.sh
- make check
- make test-self
- make test-fast
- boot.quiet
- tty.shell
- input.stress 或新增 input.editor
- showcase.core

完成后报告：
1. 修改文件；
2. 各按键和 editor 行为；
3. history/ghost/highlight/completion 限制；
4. kernel.bin 修改前后大小；
5. 测试 seed 和 artifact；
6. 现场演示命令；
7. 未实现项。

当天目标达到后停止，不自动进入长期高清控制台方案。
```
