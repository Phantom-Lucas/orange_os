# Orange/64 自适应 Framebuffer 与现代 Shell 平衡方案

状态：IMPLEMENTED（2026-08-20 完成增量 framebuffer 重绘优化；持久化 history、多列菜单和实时高亮仍按原计划暂缓）

日期：2026-08-19

推荐预算：2–3 个 AI 工作日；第 1 天结束时必须有可启动、可回退的中间交付

目标：正常演示完全脱离 VGA 文本显示，不再固定 80×25；支持多种屏幕比例、动态计算终端行列，并增加历史搜索、Shell 内部复制粘贴、翻页、autosuggestion 和补全等现代交互。

---

## 1. 最终建议

推荐实现三个层次，而不是把所有“现代 Shell”能力一次塞入：

### 第 1 层：现代显示基础，必须完成

- QEMU `1280×720×32` framebuffer；
- 支持 `1024×768`、`1280×720`、`1440×900` 三种比例预设；
- PSF2 12×24 字体；
- TTY 的 columns/rows 不再写死为 80/25；
- 根据 framebuffer 和 margin 自动计算行列；
- 深紫 RGB 主题和软件 cursor；
- PageUp/PageDown 按当前可见 rows 翻页；
- 旧 VGA 只保留为 fallback/diagnostic，不是正常演示输出。

### 第 2 层：现代 Shell 核心，推荐完成

- Left/Right/Home/End/Delete；
- 行中插入和删除；
- Up/Down 历史；
- Ctrl+R 增量反向搜索；
- 64 条会话历史；
- 可选持久化历史；
- Ctrl+U/K/W 剪切；
- Ctrl+Y 粘贴；
- history prefix ghost suggestion；
- Right/End 接受 suggestion；
- 唯一 Tab 补全和共同前缀补全；
- 基础实时语法着色。

### 第 3 层：高成本能力，暂缓

- 宿主 Linux 系统剪贴板互通；
- 鼠标拖选终端输出；
- Ctrl+Shift+C/V 复制任意 scrollback；
- QEMU 窗口拖拽时实时改变 guest 分辨率；
- 完整多列补全 UI；
- 24-bit ANSI、UTF-8/CJK；
- 真正 Job Control。

---

## 2. 功能难度权衡

| 功能 | 用户价值 | 实现难度 | 预计时间 | 本轮建议 |
|---|---:|---:|---:|---|
| 1280×720 framebuffer | 很高 | 高 | 6–8h | 必做 |
| 三种分辨率预设 | 高 | 中 | 2–3h | 必做 |
| 去掉 80×25 硬编码 | 很高 | 中高 | 4–6h | 必做 |
| 动态 PageUp/PageDown | 高 | 低 | 1h | 必做 |
| Left/Right 行编辑 | 高 | 中 | 2–3h | 推荐 |
| Up/Down 历史 | 高 | 低 | 1–2h | 推荐 |
| Ctrl+R 历史搜索 | 很高 | 中 | 2–3h | 推荐 |
| Shell kill-ring 剪贴板 | 高 | 低 | 1–2h | 推荐 |
| 持久化 history | 中高 | 中 | 2–3h | 可选 |
| Ghost suggestion | 高 | 中 | 2h | 推荐 |
| 唯一/共同前缀 Tab | 高 | 中 | 2–3h | 推荐 |
| 多列补全菜单 | 中 | 中高 | 3–5h | 有余量再做 |
| 基础语法高亮 | 中高 | 中 | 2–3h | 推荐 |
| 宿主机剪贴板 | 高 | 很高 | 2–4 天 | 暂缓 |
| 鼠标选择 scrollback | 中高 | 很高 | 3–5 天 | 暂缓 |
| 窗口实时 resize | 中 | 很高 | 2–3 天 | 暂缓 |
| UTF-8/CJK 光标 | 高 | 很高 | 3–7 天 | 长期 |
| 真正 jobs/fg/bg | 高 | 很高 | 3–7 天 | 长期 |

结论：2–3 天可以做到“视觉不再是 VGA + Shell 明显现代化”。宿主剪贴板、鼠标选择和实时 resize 不适合一起做。

---

## 3. “复制粘贴”需要区分三种语义

### 3.1 Shell 内部 kill-ring：本轮实现

类似 Emacs/readline：

```text
Ctrl+U  剪切 cursor 前全部内容
Ctrl+K  剪切 cursor 后全部内容
Ctrl+W  剪切 cursor 前一个单词
Ctrl+Y  粘贴最近一次剪切内容
```

特点：

- 完全在用户态 Shell 内实现；
- 不需要新 syscall；
- 可以跨多次命令粘贴；
- 只能操作当前 Shell 编辑行；
- 不能复制屏幕上某段历史输出。

这是短周期内最可靠的“复制粘贴”。

### 3.2 Shell 行内选择：可选

可增加：

```text
Shift+Left/Right  扩展选择
Alt+W             复制选择到 kill-ring
Ctrl+Y            粘贴
```

这要求键盘事件保留 Shift/Alt，而当前驱动主要输出 char。实现难度中等，建议放在第 3 天。

### 3.3 宿主机系统剪贴板：本轮不做

QEMU 图形窗口不会自动把宿主剪贴板文本送进裸机 PS/2 键盘。真正互通至少需要一种：

- virtio-serial + guest clipboard agent；
- 自定义 QEMU chardev 协议；
- USB tablet/mouse + terminal selection + host helper；
- SPICE agent。

这些都不是小改动。若宣称支持 Ctrl+Shift+V，却没有文本传输通道，只是假的粘贴功能。

---

## 4. “任意比例”如何定义

本轮将“任意比例”定义为：

- 代码不再假设 80×25；
- width/height/font/margin 决定实际 cols/rows；
- 同一份源代码可配置多个分辨率；
- 不需要手工修改 TTY 常量；
- QEMU 启动前选择 mode；
- 不支持运行中拖动窗口动态 resize。

计算公式：

```c
cols = (framebuffer_width  - 2 * margin_x) / glyph_width;
rows = (framebuffer_height - 2 * margin_y) / glyph_height;
```

建议：

```text
glyph    12×24
margin_x 24
margin_y 24
```

预期结果：

| 分辨率 | 比例 | 预计 cols×rows |
|---|---:|---:|
| 1024×768 | 4:3 | 81×30 |
| 1280×720 | 16:9 | 102×28 |
| 1440×900 | 16:10 | 116×35 |
| 1920×1080（后续） | 16:9 | 156×43 |

实际值必须由代码计算并写入日志，测试不能硬编码成上述表之外的隐含假设。

范围限制：

```text
40 <= cols <= 200
15 <= rows <= 60
```

超出范围时拒绝 mode 或调整 margin，不能产生零行、超大分配或整数溢出。

---

## 5. 总体架构

```text
QEMU stdvga 1234:1111
        │ PCI BAR0 + Bochs DISPI mode
        ▼
1280×720 / 1024×768 / 1440×900 framebuffer
        │
        ▼
PSF2 12×24 renderer
        │ computes cols/rows
        ▼
dynamic TTY model
  ├── cols / visible_rows
  ├── 256 history lines
  ├── active view_top
  ├── dynamic PageUp/PageDown
  └── RGB renderer / VGA fallback backend
        │
        ▼
user Shell editor
  ├── cursor-aware line buffer
  ├── history + Ctrl+R
  ├── kill-ring
  ├── autosuggestion
  ├── completion
  └── existing command execution
```

不修改：

- MBR/Loader；
- linker 和内核 LMA；
- syscall ABI；
- process/thread 结构；
- FS on-disk format；
- 当前最小 pipe/redirection 执行器。

---

## 6. 构建模式

新增：

```make
CONSOLE_BACKEND ?= vga
FB_MODE ?= 1280x720
FB_VGA_MIRROR ?= 0
```

支持：

```bash
make fb-showcase-prepare FB_MODE=1024x768
make fb-showcase-prepare FB_MODE=1280x720
make fb-showcase-prepare FB_MODE=1440x900
```

Makefile 将 mode 转为编译宏：

```text
FB_WIDTH
FB_HEIGHT
FB_BPP=32
```

这些值进入 `.boot-config`，确保切换比例后所有相关对象重编译。

构建矩阵：

```text
legacy tests:
  CONSOLE_BACKEND=vga TTY_COLS=80 TTY_ROWS=25

normal framebuffer:
  CONSOLE_BACKEND=qemu-fb FB_VGA_MIRROR=0

framebuffer tests:
  CONSOLE_BACKEND=qemu-fb FB_VGA_MIRROR=1
```

quiet framebuffer build 不链接 `kernel/test.c`，字体放 MyFS，继续满足 188-sector Loader 上限。

---

## 7. 动态 TTY 改造

### 7.1 当前问题

当前 `kernel/tty.c` 在以下位置依赖固定值：

- `VGA_WIDTH 80`；
- `VGA_HEIGHT 25`；
- history cell 数；
- cursor row/column；
- newline/wrap；
- scrollback top；
- PageUp/PageDown 固定 24 行；
- VGA flush 循环；
- 测试解码 80 列。

只改 renderer 而不改这些值，画面虽然是 framebuffer，交互仍然是 80×25，不符合新目标。

### 7.2 新的 terminal geometry

```c
struct tty_geometry {
    uint32_t columns;
    uint32_t visible_rows;
    uint32_t history_rows;
    uint32_t glyph_width;
    uint32_t glyph_height;
    uint32_t origin_x;
    uint32_t origin_y;
};
```

每个 console 共用 geometry，但拥有独立 cells/cursor/view_top。

### 7.3 History 分配

运行时计算：

```text
cells_per_console = columns * history_rows
bytes = console_count * cells_per_console * sizeof(term_cell)
pages = ceil(bytes / 4096)
```

本轮仍可保留 `uint16_t` cell：

```text
低 8 bit  ASCII glyph
高 8 bit  16-color attribute
```

这样避免同时做 UTF-8 和 24-bit terminal model。

必须检查：

- columns * history_rows 溢出；
- console_count 乘法溢出；
- pages 超过 PMM `uint32_t`；
- 分配失败；
- geometry 小于最小值或超过最大值。

### 7.4 所有索引使用 columns

统一替换：

```text
cursor / columns
cursor % columns
row * columns + col
history_rows * columns
```

禁止留下局部 80/25 magic number。

### 7.5 Resize 策略

本轮 mode 在 boot 时确定，一次启动期间 geometry 不变化，因此不需要复杂 reflow。

初始化顺序：

1. 确定 framebuffer mode；
2. 根据 PSF2 固定 metrics 计算 geometry；
3. 初始化 TTY buffer；
4. 启动用户 Shell。

如果 framebuffer 初始化失败，使用独立 VGA build/fallback geometry 80×25。不要在同一运行中把已有 102×28 history 强行缩回 80×25。

---

## 8. 自适应 framebuffer renderer

沿用 QEMU-only 折中方案：

- PCI `0xCF8/0xCFC`；
- 识别 `1234:1111`；
- 读取和验证 BAR0；
- Bochs VBE DISPI `0x1CE/0x1CF`；
- 32-bit mode；
- 独立高半区 MMIO 映射；
- PSF2 12×24；
- framebuffer 失败回退。

变化：renderer 不再接收固定 80×25，而是：

```c
void qemu_fb_render_cells(const uint16_t* cells,
                          const struct tty_geometry* geometry,
                          uint32_t view_top,
                          uint32_t cursor,
                          int cursor_visible);
```

每次只绘制 `columns * visible_rows`。

第一版仍允许 full redraw，但增加批量控制：

- 一次 `tty_write(buffer, n)` 只 flush 一次；
- kernel semantic print 尽量使用 buffer API，不逐字符 flush；
- 光标移动导致 redraw 时只在编辑动作结束后 flush；
- 不在 timer IRQ 中绘制。

---

## 9. 翻页与 scrollback

### 9.1 键盘

保留：

```text
PageUp    向旧内容移动 visible_rows - 1
PageDown  向新内容移动 visible_rows - 1
```

增加：

```text
Ctrl+PageUp    跳到 history 顶部
Ctrl+PageDown  回到 live bottom
```

如果实现 modifier 事件成本过高，第 1 版只保留动态步长 PageUp/PageDown。

### 9.2 行为

- scrollback 模式下 cursor 隐藏；
- 用户输入任意字符时自动回到 live bottom；
- 新输出到达时不强制打断用户正在查看的历史；
- 可选右上角绘制 `[scroll 42/256]` overlay；
- overlay 不写入 terminal cells，不进入命令输出；
- F1/F2/F3 各自保存 view_top。

### 9.3 鼠标滚轮

当前没有 PS/2 mouse driver。本轮不做。PageUp/PageDown 已提供稳定翻页。

---

## 10. Shell 行编辑器

### 10.1 数据模型

保持单文件、固定内存，降低风险：

```c
#define SHELL_LINE_MAX 256
#define SHELL_HISTORY_MAX 64

struct shell_editor {
    char line[SHELL_LINE_MAX];
    uint32_t length;
    uint32_t cursor;

    char history[SHELL_HISTORY_MAX][SHELL_LINE_MAX];
    uint32_t history_count;
    uint32_t history_head;
    int32_t history_view;

    char draft[SHELL_LINE_MAX];
    char kill_ring[SHELL_LINE_MAX];

    int32_t suggestion_history_index;
    uint32_t previous_render_cells;
};
```

这些大数组必须是 static/BSS，不能放在当前单页用户栈上。

### 10.2 编辑键

```text
Left/Right       移动
Home/End         行首/行尾
Backspace        删除 cursor 前字符
Delete           删除 cursor 字符
Ctrl+A/E         行首/行尾
Ctrl+U/K/W       剪切到 kill-ring
Ctrl+Y           粘贴 kill-ring
Ctrl+C           取消行
Ctrl+L           清屏重画
Up/Down          历史
Ctrl+R           反向搜索
Tab              补全
```

本轮按 ASCII byte 操作。UTF-8 光标明确暂缓。

### 10.3 Redraw

不要求 TTY 新增完整 CSI cursor engine。使用：

1. `\r` 回行首；
2. 绘制 Prompt、真实输入、ghost；
3. 用空格清理旧尾部；
4. `\r`；
5. 绘制 Prompt 和 cursor 前输入定位硬件/软件 cursor。

因为新 terminal columns 大于 80，更长命令不容易换行。但仍必须检测：

```text
prompt_cells + rendered_line_cells < columns
```

接近右边界时关闭 ghost，并暂时禁止超过单行的新增字符。真正多行编辑属于后续。

---

## 11. 历史与 Ctrl+R

### 11.1 会话历史

- 64 条 ring；
- 空行不记录；
- 连续重复不记录；
- Up/Down 浏览；
- 进入历史前保存 draft；
- Down 回到最新位置时恢复 draft。

### 11.2 Ctrl+R 增量搜索

进入状态：

```text
(reverse-i-search)`query': matching command
```

规则：

- 普通字符追加 query；
- Backspace 删除 query；
- Ctrl+R 继续找更旧匹配；
- Enter 接受匹配；
- Esc/Ctrl+C 取消并恢复原 line；
- 搜索使用 substring，不做 fuzzy ranking；
- 没有匹配时明确显示 `failing reverse-i-search`；
- 搜索状态不执行命令。

### 11.3 持久化历史

推荐第 3 天再做。

路径：

```text
/.orange_history
```

原因：当前系统没有稳定的用户 home 初始化流程，直接使用根目录文件改动最小。

格式：一行一条，最多读取末尾 64 条，每条最多 255 bytes。

安全规则：

- 忽略超长/损坏行；
- 不写空行；
- 写失败不阻止 Shell；
- ANSI 控制字符不写入；
- 最简单版本退出时重写；
- 如果 Shell 长期不退出，则每 N 条 append；
- 没有原子 rename 前不得宣称崩溃安全。

---

## 12. Ghost suggestion

从最新历史向前寻找 prefix match：

- 仅 cursor 在行尾时显示；
- 真实 line 非空；
- 候选更长；
- 后缀用 MUTED；
- Right 接受一个字符或一个 token；
- End 接受全部；
- Enter 不自动接受；
- 搜索模式和 scrollback 模式隐藏 suggestion。

建议第 1 版：Right 接受全部，减少状态分支。稳定后再改为逐字符接受。

---

## 13. Tab 补全

### 13.1 第 1 版

- builtin 静态表；
- 已安装用户程序静态表；
- 只补第一个 command word；
- 唯一候选直接完成；
- 多候选补共同前缀；
- 无共同前缀则打印一行候选数量提示。

### 13.2 第 2 版

- 当前目录文件名；
- `cd` 只补目录；
- `cat/rm/stat` 补文件；
- 多列布局使用动态 `columns`；
- 菜单高度不超过 `visible_rows / 2`；
- 输出菜单后恢复 editor line/cursor。

当前 `SYS_LIST` 只面向 cwd 且输出是展示文本，不是稳定目录项 ABI。若实现路径补全需要修改 syscall，就移到长期方案；本轮不要解析人类可读 `ls` 输出冒充结构化目录 API。

---

## 14. 基础实时高亮

只做词法扫描，不重写 command executor：

```text
command word   cyan/green
operator       yellow/magenta
quoted text    yellow
normal arg     white
unclosed quote red
ghost          muted gray
```

约束：

- O(n) 单次扫描；
- 不修改 line；
- style disabled 时完全无 ESC；
- pipeline/redirection 输出文件不得包含 ANSI；
- 高亮不代表执行器已支持完整引号语义；
- help/documentation 必须标明当前 parser 限制。

---

## 15. 实施阶段与时间

### Day 1：无 VGA 显示 + 非 80×25

#### D1.0 基线（0.5h）

- HEAD/worktree；
- quiet/diagnostic kernel size；
- check/test-self；
- boot/tty/input/showcase artifacts。

#### D1.1 QEMU framebuffer（4–5h）

- PCI BAR；
- Bochs mode；
- mapping；
- PSF2；
- RGB renderer；
- fallback。

#### D1.2 动态 geometry（3–4h）

- columns/rows；
- runtime history allocation；
- cursor/wrap/scroll；
- backend flush；
- PageUp/PageDown 动态步长。

#### D1.3 启动与 screenshot（2h）

- `fb-showcase`；
- 1280×720 screenshot；
- 1024×768 smoke；
- framebuffer.core；
- VGA 回归。

Day 1 停止点：

```text
1280×720 framebuffer
+ 102×28 左右动态 TTY
+ 12×24 字体
+ PageUp/PageDown
+ 当前 Shell
```

如果 D1 未通过，不开始 Shell 编辑器。

### Day 2：现代 Shell 核心

#### D2.1 特殊键和编辑器（3h）

- ANSI key input；
- Left/Right/Home/End/Delete；
- cursor-aware insert/delete；
- redraw。

#### D2.2 History/Ctrl+R（3h）

- 64 条 history；
- draft restore；
- reverse substring search；
- cancel/accept。

#### D2.3 Kill-ring（1.5h）

- Ctrl+U/K/W cut；
- Ctrl+Y paste；
- overflow/boundary tests。

#### D2.4 Autosuggest/Tab（2.5h）

- ghost suggestion；
- accept；
- command unique/common-prefix completion。

Day 2 停止点：现代 Shell 的核心交互已经可演示。

### Day 3：增强、压力和文档

- 持久化 history；
- 基础高亮；
- 可选多列 command menu；
- 三种分辨率测试；
- input stress；
- screenshot；
- presentation demo；
- full check-all。

如果预算只有一天，严格停在 Day 1；如果预算两天，停在 Day 2，不实现持久化和多列菜单。

---

## 16. 测试设计

### 16.1 Geometry

三个独立构建/启动：

```text
1024×768  -> cols/rows 非 80×25
1280×720  -> cols/rows 非 80×25
1440×900  -> cols/rows 非 80×25
```

断言：

- `columns * glyph_width + margins <= width`；
- `rows * glyph_height + margins <= height`；
- last cell 不越 framebuffer；
- wrap 在最后一列正确；
- scroll 后 Prompt 可见；
- resize preset 改变 cols/rows。

### 16.2 History 与搜索

- 空/重复 history；
- ring wrap；
- Up/Down 和 draft；
- Ctrl+R 首个匹配；
- 连续 Ctrl+R 更旧匹配；
- cancel/accept；
- query 无匹配。

### 16.3 Kill-ring

- Ctrl+U；
- Ctrl+K；
- Ctrl+W；
- Ctrl+Y；
- 空 kill-ring；
- paste 超过 LINE_MAX 时截断且不越界。

### 16.4 Scrollback

- 输出超过 history rows；
- PageUp 动态步长；
- PageDown；
- 输入恢复 live bottom；
- console 切换保存 view_top；
- cursor 在 scrollback 时隐藏。

### 16.5 回归

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
make test CASE=framebuffer.core SEED=20260819 KEEP_FAILED=1
make test CASE=shell.editor SEED=20260819 KEEP_FAILED=1
```

最后运行 `make check-all`。

---

## 17. 现场演示

```bash
make fb-showcase-prepare FB_MODE=1280x720
make fb-showcase
```

展示顺序：

1. 说明实际 mode 和动态 cols×rows；
2. 执行长输出，PageUp/PageDown 翻页；
3. 输入命令并用 Left/Right 修改中间字符；
4. Up 调出历史；
5. Ctrl+R 查找早期命令；
6. Ctrl+K 剪切后半行，Ctrl+Y 粘贴；
7. 输入历史前缀展示 ghost suggestion；
8. Tab 补全命令；
9. 运行 pipeline 和重定向；
10. 展示测试 screenshot/artifact。

讲解口径：

```text
“终端显示已经脱离 VGA 文本模式，行列由 framebuffer 分辨率和 PSF2 字体
计算，不再固定 80×25。Shell 的历史搜索和 kill-ring 全部在 Ring 3 实现；
当前复制粘贴是 Shell 内部剪切环，不冒充宿主系统剪贴板。实时窗口 resize、
鼠标选择和通用 GPU 支持属于下一阶段。”
```

---

## 18. 裁剪策略

如果时间不足，按以下顺序裁剪：

```text
持久化 history
→ 多列补全菜单
→ 实时高亮
→ ghost suggestion
→ Ctrl+R UI 美化
→ Home/End/Delete
```

不可裁剪：

```text
framebuffer
dynamic cols/rows
PageUp/PageDown
Left/Right
Up/Down history
kill-ring
旧测试回归
```

如果只剩一天，则 Shell 功能全部移到 Day 2，确保 Day 1 的 framebuffer 和动态 geometry 可靠。

---

## 19. 完成标准

### 显示

- [ ] 正常演示无 VGA 文本输出；
- [ ] 1024×768、1280×720、1440×900 至少 smoke；
- [ ] cols/rows 从 mode/font/margin 计算；
- [ ] 源码没有 TTY 80/25 硬编码；
- [ ] wrap/scroll/clear/cursor/console switch 正常；
- [ ] PageUp/PageDown 使用动态 rows；
- [ ] VGA fallback/diagnostic 保留。

### Shell

- [ ] 行中编辑；
- [ ] Up/Down history；
- [ ] Ctrl+R；
- [ ] Ctrl+U/K/W 和 Ctrl+Y；
- [ ] suggestion 不进入真实 buffer；
- [ ] Tab 唯一/共同前缀补全；
- [ ] style 不污染重定向；
- [ ] 当前 pipe/redirection/background 无回归。

### 工程

- [ ] quiet/diagnostic kernel 均不超过 96,256 bytes；
- [ ] 字体不进入 kernel.bin；
- [ ] framebuffer/geometry/editor 有独立 case；
- [ ] 三种比例至少保存 mode/result artifact；
- [ ] `make check-all` 通过；
- [ ] QEMU-only、ASCII、16 色、无 host clipboard、无 live resize 等限制已记录。

---

## 20. 可直接执行的 Prompt

```text
请在 /home/orange/my_os 中严格按照
docs/adaptive-framebuffer-modern-shell-balanced-plan.md 实施自适应 framebuffer
和现代 Shell。

推荐预算为 2–3 个 AI 工作日。必须按 Day 1、Day 2、Day 3 设置独立门禁；
Day 1 framebuffer/geometry 未通过时禁止开始 Shell editor。

开始前：
1. 阅读完整方案、git status、全部现有 diff 和适用 AGENTS.md。
2. dirty worktree 属于用户；禁止 reset、checkout 覆盖、clean、删除、提交或 tag。
3. 记录 HEAD、quiet/diagnostic kernel.bin、make check、test-self、boot、tty、input、
   showcase artifacts。
4. 不修改 MBR、Loader、linker、syscall ABI、process/thread model 或 FS format。

Day 1：
- QEMU stdvga 1234:1111；
- PCI BAR 必须探测和验证；
- 支持 FB_MODE=1024x768/1280x720/1440x900；
- PSF2 12x24 从 MyFS 加载，不进入 kernel.bin；
- columns/rows 根据 framebuffer/font/margin 计算；
- tty cells/history 在运行时按 geometry 分配；
- 所有 cursor/wrap/scroll 索引使用 columns；
- PageUp/PageDown 步长使用 visible_rows-1；
- 正常演示无 VGA，旧 VGA 只作 fallback/diagnostic/mirror；
- 添加 framebuffer.core 和 geometry tests。

Day 2：
- 键盘特殊键编码为有界 ANSI 输入序列；
- Shell 输入 decoder 支持跨 read 分片；
- 固定 256-byte ASCII line editor；
- Left/Right/Home/End/Delete；
- 64 条 session history 和 draft restore；
- Ctrl+R substring reverse search；
- Ctrl+U/K/W cut 到 kill-ring，Ctrl+Y paste；
- ghost suggestion 和 command unique/common-prefix Tab；
- 保留现有 run_command/pipe/redirect/background 语义。

Day 3 可选：
- 持久化 history；
- 基础高亮；
- 多列 command menu；
- 三种 mode 压力与完整 check-all；
- 演示文档和截图。

复制粘贴只实现 Shell kill-ring。禁止宣称支持宿主 Linux 剪贴板或鼠标选择。
任意比例指启动前可选择不同 framebuffer mode 并自动计算 geometry，不实现运行时
拖拽窗口 resize。

尺寸门禁：quiet 和 diagnostic kernel.bin 都不得超过 96,256 bytes；字体留在
MyFS；quiet 可不链接 kernel/test.c；超限时裁剪 Shell/视觉功能，不修改 Loader。

最低测试：
- git diff --check
- bash -n tests/run.sh tests/manifest.sh tests/lib/*.sh tests/suites/*.sh
- make check
- make test-self
- make test-fast
- boot.quiet
- tty.shell
- input.stress
- showcase.core
- framebuffer.core
- shell.editor
- 最后 make check-all

QEMU socket 沙箱失败标记为 INFRASTRUCTURE_ERROR 并按权限流程重跑，不修改 OS。

完成后报告：
1. 三种 mode 和实际 cols/rows；
2. PCI BAR、映射窗口、字体信息；
3. history/search/kill-ring/suggestion/completion 行为；
4. 不支持的 host clipboard/mouse/live resize；
5. kernel.bin 前后大小；
6. 修改文件、测试 seed 和 artifacts；
7. 启动与演示命令。
```
