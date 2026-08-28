# Orange/64 高清控制台与高级 Shell 执行方案

状态：PROPOSED

日期：2026-08-19

适用项目：`/home/orange/my_os`

目标：从 VGA 80×25 文本终端迁移到类似 Linux KMSCon 的高清纯控制台，并把现有最小 Shell 演进为具备 Fish/Zsh 风格交互和可靠 POSIX-like 执行语义的高级 Shell。

---

## 1. 最终交付定义

本计划不实现桌面、窗口管理器或图标 GUI。最终画面仍是全屏纯终端，但显示和交互能力不再受 VGA 文本模式限制。

### 1.1 高清控制台

- 默认优先选择 `1920×1080×32`，可配置 `2560×1440×32`；
- 没有目标分辨率时，按 `1600×900`、`1280×720`、`1024×768` 顺序降级；
- framebuffer 使用 32-bit XRGB/BGRX 像素格式，终端颜色语义支持 24-bit RGB；
- 字体由 PSF2 字体资产提供，第一版使用 12×24 或 16×32 点阵；
- 支持 UTF-8 解码、基础 Unicode 字形映射和 CJK 字体包扩展；
- 支持光标、滚屏、选定的 ANSI/ECMA-48 控制序列和 `38;2`/`48;2` 真彩色；
- 使用 shadow buffer、dirty rows/rectangles，普通字符输出不得整屏重绘；
- VGA 文本后端只作为启动失败和回归诊断后备，不再是正常演示路径。

### 1.2 高级 Shell

- 光标可在行内移动，支持 Home/End、Delete、方向键、Ctrl 快捷键；
- 历史记录持久化；
- 根据历史提供暗灰色 ghost-text，Right/End 接受建议；
- 输入过程中实时语法高亮；
- Tab 打开多列补全菜单，可补全命令、路径和变量；
- 支持单引号、双引号、反斜杠、环境变量和 `$?`；
- 支持任意长度 pipeline、`<`、`>`、`>>`、`2>`、`;`、`&&`、`||` 和 `&`；
- 支持 `$PATH` 查找，用户不再需要感知 `.elf` 后缀；
- 支持进程组、前台组、后台 job、`jobs`、`fg`、`bg`；
- Ctrl+C/Ctrl+Z/Ctrl+\\ 作用于前台进程组，而不是只处理单个 PID；
- Shell 继续运行在 Ring 3，内核只提供 framebuffer、TTY、进程、信号和文件描述符机制。

### 1.3 明确非目标

第一轮不做：

- 窗口系统、桌面、鼠标指针、图标或合成器；
- GPU 3D 加速；
- 完整 Bash 兼容、Shell 脚本语言函数和复杂命令替换；
- 第一版即支持 TTF/OTF 抗锯齿字体；
- 第一版即实现完整 Unicode normalization、双向文字和复杂字形塑形；
- 为了画面好看而把 Shell 或命令执行逻辑移进内核。

---

## 2. 当前基线与差距

| 能力 | 当前实现 | 目标差距 |
|---|---|---|
| 启动 | BIOS MBR + 自研 Loader，内核从 LBA 10 固定加载 | 需要动态内核大小和 framebuffer 启动信息 |
| 内核尺寸 | 188 扇区上限，当前约 92 KiB | framebuffer、字体和终端引擎无法在剩余约 4 KiB 中实现 |
| 显示 | `0xB8000`、80×25、16 色 VGA cell | 1080p/2K、32bpp、24-bit 颜色、字体渲染 |
| 页表 | Loader 初始映射前 1 GiB | framebuffer 通常位于 `0xE0000000` 等高物理地址 |
| TTY | 256 行 cell 历史、3 console、有限 ANSI SGR | 后端解耦、动态行列、完整重绘和真彩状态 |
| 输入 | PS/2 scancode 转普通字符和少量控制字符 | 键码、修饰键、方向键、Home/End/Delete/Tab |
| Shell 行编辑 | 128 字节尾部追加和 Backspace | 行内编辑、历史、补全、ghost text、高亮 |
| Shell 语法 | 单个 `|`、简单重定向、末尾 `&` | lexer、AST、多级 pipeline、引号和扩展 |
| 环境变量 | 无 `envp`/`PATH` | 环境继承、`execve` 栈、export/unset |
| Job control | 后台 fork 后不等待；Ctrl+Z 等价终止 | 进程组、STOPPED、SIGCONT、前台组 |
| 测试观测 | 大量 suite 读取 `0xB8000` | UART 结构化日志和 framebuffer screendump |

当前可复用的基础包括：

- 物理页分配、页表映射和内核堆；
- 用户态 `mmap`、malloc/realloc/free；
- `fork/execv/wait/pipe/dup2`；
- MyFS 目录、cwd、stat；
- TTY IPC 服务、键盘队列和多 console；
- ANSI SGR 子集；
- 统一 runner、QEMU monitor 和 artifact 收集。

---

## 3. 总体架构

```text
BIOS Loader / 后续 UEFI Loader
        │
        ├── memory map
        ├── kernel location
        └── framebuffer descriptor
                │
                ▼
          struct boot_info
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│ Kernel                                                     │
│                                                            │
│ framebuffer mapping ──> pixel backend ──> font renderer    │
│                                      ▲                     │
│ terminal model <── ANSI/UTF-8 parser ┘                     │
│       ▲                                                    │
│       │                                                    │
│ TTY service / line discipline <── PS/2 keyboard events     │
│       ▲                                                    │
│       └──────── read/write/ioctl ───────────────┐           │
└─────────────────────────────────────────────────┼───────────┘
                                                  │
                                                  ▼
┌────────────────────────────────────────────────────────────┐
│ Ring 3 orange-shell                                        │
│                                                            │
│ line editor ── lexer ── parser/AST ── expansion ── executor│
│     │                                          │            │
│     ├── history/autosuggest                   ├── fork/exec │
│     ├── syntax highlight                     ├── pipe/dup2 │
│     └── completion menu                       └── job table │
└────────────────────────────────────────────────────────────┘
```

核心边界：

1. framebuffer 驱动只处理显存映射和像素格式；
2. renderer 只处理矩形、glyph 和 dirty flush；
3. terminal 只处理字符网格、ANSI 状态和滚屏；
4. TTY 只处理终端 I/O、会话、前台进程组和输入模式；
5. Shell 负责语法、补全、历史和 job table；
6. 内核不得解析 Shell 命令。

---

## 4. 关键架构决策

### 4.1 启动路线

第一条交付路线继续保留当前自研 BIOS Loader，增加 VBE linear framebuffer。这样能延续当前学习价值，并在 QEMU `-vga std` 上快速形成稳定基线。

但不能直接在现有 Loader 上堆 framebuffer：必须先解除 188 扇区和固定 `0x1900` 内核窗口。

推荐顺序：

1. MBR 只加载 LBA 2..9 的 stage-2 Loader；
2. LBA 1 保存 512 字节 boot manifest；
3. Loader 在实模式完成 E820 和 VBE 查询；
4. 进入 32-bit protected mode 后，用 ATA PIO 把动态大小内核加载到 1 MiB；
5. 内核链接 LMA 改为 `0x00100000`；
6. Loader 建立临时页表并进入高半区内核；
7. 通过 `RDI` 传递只读 `struct boot_info*`。

后续再增加 UEFI GOP Loader。BIOS VBE 与 UEFI GOP 必须生成同一个 `struct boot_info`，内核不能根据固件类型分叉渲染代码。

### 4.2 显示路线

第一版采用：

- VBE/GOP 提供的线性 framebuffer；
- CPU 软件渲染；
- 32-bit framebuffer；
- PSF2 点阵字体；
- shadow buffer + dirty row；
- VGA fallback。

不建议第一版直接移植 FreeType。字体抗锯齿会同时引入字体解析、hinting、alpha blending、缓存和较大的第三方代码，容易掩盖终端模型本身的问题。

### 4.3 Shell 路线

不能继续在现有 `usr/shell.c` 中追加 `strchr()` 分支。应把 Shell 改造成独立用户程序目录：

```text
usr/orangesh/
├── main.c
├── editor.c
├── history.c
├── highlight.c
├── complete.c
├── lexer.c
├── parser.c
├── expand.c
├── execute.c
├── jobs.c
├── builtins.c
└── shell.h
```

执行顺序必须固定为：

```text
input bytes
  -> line editor
  -> lexer
  -> parser/AST
  -> variable/path expansion
  -> redirection planning
  -> process/pipeline launch
  -> foreground wait or background job registration
```

---

## 5. 核心接口与数据结构

### 5.1 Boot manifest

建议 LBA 1 使用：

```c
struct boot_manifest {
    uint32_t magic;          /* "OR64" */
    uint16_t version;
    uint16_t header_size;
    uint64_t kernel_lba;
    uint64_t kernel_bytes;
    uint64_t kernel_load_phys;
    uint64_t kernel_entry_offset;
    uint32_t kernel_crc32;
    uint32_t flags;
};
```

所有加法、扇区取整和加载范围都必须检查溢出。Loader 应拒绝：

- magic/version 不匹配；
- `kernel_bytes == 0`；
- 加载范围覆盖 Loader、boot info、临时页表或 BIOS 保留区；
- CRC 不匹配；
- entry 超出内核镜像。

### 5.2 Boot info

```c
struct framebuffer_info {
    uint64_t physical_address;
    uint64_t byte_size;
    uint32_t width;
    uint32_t height;
    uint32_t pitch;
    uint16_t bits_per_pixel;
    uint8_t red_shift, red_bits;
    uint8_t green_shift, green_bits;
    uint8_t blue_shift, blue_bits;
    uint8_t reserved_shift, reserved_bits;
};

struct boot_info {
    uint32_t magic;
    uint16_t version;
    uint16_t size;
    uint64_t kernel_phys_start;
    uint64_t kernel_phys_end;
    uint64_t memory_map_address;
    uint32_t memory_map_count;
    uint32_t memory_map_entry_size;
    struct framebuffer_info framebuffer;
    uint32_t boot_flags;
};
```

必须保留 `version` 和 `size`，避免 Loader 与内核结构体静默错位。

### 5.3 Terminal cell

```c
struct term_color {
    uint8_t red, green, blue, alpha;
};

struct term_cell {
    uint32_t codepoint;
    struct term_color foreground;
    struct term_color background;
    uint16_t attributes;
    uint8_t width;           /* 0 continuation, 1 normal, 2 wide */
    uint8_t dirty;
};
```

属性至少包括 bold、underline、inverse、dim。不要把 24-bit RGB 再压回 VGA attribute。

### 5.4 输入事件

```c
struct key_event {
    uint16_t keycode;
    uint16_t modifiers;
    uint32_t codepoint;
    uint8_t pressed;
    uint8_t repeated;
};
```

修饰键包括 Shift、Ctrl、Alt、Caps。键码包括 Left/Right/Up/Down、Home、End、Delete、Insert、PageUp/PageDown、Tab 和 F1..F12。

### 5.5 Shell AST

```c
enum ast_kind {
    AST_COMMAND,
    AST_PIPELINE,
    AST_AND,
    AST_OR,
    AST_SEQUENCE,
    AST_BACKGROUND
};

struct command_node {
    char** argv;
    struct redirection* redirections;
    uint32_t argc;
};
```

Parser 不允许修改原始输入后靠裸指针维持 AST。Token 文本和 AST 生命周期必须由 arena 统一管理，执行结束后一次释放。

### 5.6 Job table

```c
enum job_state { JOB_RUNNING, JOB_STOPPED, JOB_DONE };

struct shell_job {
    uint32_t job_id;
    int32_t process_group;
    enum job_state state;
    char* command_line;
    struct shell_job* next;
};
```

一个 pipeline 是一个 job，一个 job 对应一个进程组，而不是一个 PID。

---

## 6. 建议源文件布局

```text
boot/
├── mbr.S
├── loader.S
├── boot_manifest.inc
└── boot_info.inc

kernel/
├── boot_info.c/.h
├── uart.c/.h
├── framebuffer.c/.h
├── mmio.c/.h
├── font/
│   ├── psf2.c/.h
│   └── fallback_font.c
├── console/
│   ├── backend.h
│   ├── fb_backend.c
│   ├── vga_backend.c
│   ├── renderer.c/.h
│   ├── terminal.c/.h
│   ├── ansi.c/.h
│   └── utf8.c/.h
├── tty.c/.h
├── keyboard.c/.h
├── signal.c/.h
└── process_group.c/.h

usr/orangesh/
├── main.c
├── editor.c
├── history.c
├── highlight.c
├── complete.c
├── lexer.c
├── parser.c
├── expand.c
├── execute.c
├── jobs.c
├── builtins.c
└── shell.h

assets/fonts/
├── terminal.psf
├── LICENSE
└── README.md

tests/
├── host/
│   ├── test_ansi.c
│   ├── test_utf8.c
│   ├── test_shell_lexer.c
│   ├── test_shell_parser.c
│   └── test_line_editor.c
└── suites/
    ├── framebuffer.sh
    ├── terminal.sh
    ├── shell_editor.sh
    └── job_control.sh
```

---

## 7. 分阶段执行方案

### 阶段 0：冻结基线与迁移可观察性

目标：在停止依赖 `0xB8000` 前，建立不会随显示后端消失的测试通道。

任务：

- [ ] 保留当前 VGA 主题分支和完整 `make check-all` artifact；
- [ ] 记录当前 kernel.bin、启动时间、输入延迟和测试耗时；
- [ ] 实现 COM1 UART，内核日志同时镜像到串口；
- [ ] QEMU runner 使用 `-serial file:<artifact>/serial.log`；
- [ ] 统一 `[BOOT]`、`[TEST]`、`[RESOURCE]`、`[PANIC]` 事件；
- [ ] 迁移所有仅靠 `pmemsave 0xb8000` 判断 PASS 的断言；
- [ ] VGA snapshot 暂时保留为 UI 辅助证据，不再承担唯一结果判断；
- [ ] 增加 `DISPLAY_BACKEND=vga|framebuffer|auto` 构建配置；
- [ ] 增加 `make test CASE=console.serial`。

验收：

- 关闭 QEMU display 后完整测试仍能从 serial 判定结果；
- 测试失败包含 seed、case、串口日志和 QEMU 日志；
- VGA 后端行为不变。

建议提交边界：

```text
test(console): make serial events the display-independent oracle
```

### 阶段 1：解除固定内核加载窗口

目标：移除 188 扇区和 `0x1900` LMA，给 framebuffer/terminal 代码留下真实扩展空间。

任务：

- [ ] 新增生成 boot manifest 的宿主工具；
- [ ] LBA 1 写入 manifest，LBA 2..9 只保存 Loader；
- [ ] MBR 不再预读内核，只加载固定上限的 stage-2；
- [ ] Loader 验证 manifest magic、version、size、range、CRC；
- [ ] Loader 在 32-bit protected mode 读取内核到 1 MiB；
- [ ] ATA PIO 按单次命令上限分块读取，不能把大内核扇区数截断到 8 bit；
- [ ] Loader 的 LBA 2..9 大小上限由构建脚本强制检查；
- [ ] `kernel/linker.ld` 的 `KERNEL_LMA` 改为 `0x00100000`；
- [ ] 入口改为 `KERNEL_VMA + KERNEL_LMA + entry_offset`；
- [ ] 用 `RDI` 传递 boot info；
- [ ] 明确清零 `.bss`；
- [ ] PMM 保留实际内核物理区、boot info 和临时页表；
- [ ] `tests/check_build.sh` 删除 188-sector 限制，改查 manifest 与加载上限；
- [ ] 增加损坏 magic、超长 size、错误 CRC 和越界 entry 的启动失败测试。

验收：

- 生成一个大于 188 扇区的测试内核仍可启动；
- Loader 对损坏镜像稳定拒绝并通过 UART 报告原因；
- quiet/diagnostic 两种构建均通过；
- 内核物理范围不会被 PMM 再分配。

建议提交边界：

```text
boot: load a manifest-sized kernel at 1MiB
boot: pass versioned boot_info and reserve its ranges
```

### 阶段 2：VBE framebuffer 发现与映射

目标：得到可靠、经过验证的线性 framebuffer，但暂不替换完整 TTY。

Loader 任务：

- [ ] 在实模式调用 VBE controller info；
- [ ] controller/mode info buffer 固定放在 1 MiB 以下并避开 E820、Loader 和栈；
- [ ] 枚举 mode list，不写死 mode number；
- [ ] 只接受 supported、graphics、linear framebuffer 模式；
- [ ] 优先 32bpp，检查 memory model 和 RGB mask；
- [ ] 按配置的分辨率优先级选择模式；
- [ ] 使用 `INT 10h AX=4F02h` 设置 linear framebuffer bit；
- [ ] 把物理地址、pitch、分辨率、bpp 和 mask 写入 boot info；
- [ ] 查询失败时设置 `BOOT_FLAG_NO_FRAMEBUFFER`，进入 VGA fallback。

内核任务：

- [ ] 验证 `pitch >= width * bytes_per_pixel`；
- [ ] 验证 `pitch * height` 不溢出且不超过 boot info size；
- [ ] 新建固定虚拟窗口，例如 `0xFFFF900000000000`；
- [ ] 用 4 KiB 页映射 framebuffer 的完整物理范围；
- [ ] 第一版使用 PCD/PWT 保守映射，随后增加 PAT write-combining；
- [ ] 实现 pixel pack，支持 RGBX/BGRX 和非标准 mask；
- [ ] 实现 `put_pixel`、`fill_rect` 和 `blit_rect`；
- [ ] 用纯色条/渐变测试验证 channel 顺序和 pitch。

验收：

- `1920×1080×32` 下显示红、绿、蓝、白色条且无错色；
- QEMU 演示和测试显式使用已验证的 `-vga std` 配置；
- 1280×720 fallback 正常；
- 故意传入非法 pitch/mask 时拒绝使用 framebuffer；
- framebuffer 位于 1 GiB 以上仍可访问；
- VGA fallback 继续可启动。

建议提交边界：

```text
boot(vbe): publish a validated linear framebuffer descriptor
mm(fb): map high MMIO framebuffer ranges safely
```

### 阶段 3：字体、渲染器与 framebuffer console

目标：在 framebuffer 上显示可读、稳定、可滚动的高清文本。

任务：

- [ ] 实现 PSF2 header 校验；
- [ ] 第一版内置小型 ASCII fallback font；
- [ ] 正常字体从 MyFS `assets/fonts/terminal.psf` 加载；
- [ ] 字体资产附带来源、许可证和 SHA-256；
- [ ] 按实际 font width/height 计算 terminal rows/cols；
- [ ] 屏幕四周保留可配置 margin；
- [ ] 分配 shadow framebuffer；
- [ ] 实现 glyph mono bitmap 到 RGB 的绘制；
- [ ] 实现 background fill、underline、inverse、selection-ready 属性；
- [ ] dirty 标记以 row 为第一版粒度；
- [ ] 光标由 renderer 绘制，timer 负责闪烁；
- [ ] 测试模式固定光标为常亮，避免 screenshot 不确定；
- [ ] 滚屏只移动 terminal cell，不反复搬运整个物理 framebuffer；
- [ ] panic 使用内置字体直接写 framebuffer，不依赖 FS、堆或 TTY 服务。

推荐视觉参数：

```text
background  #1E1E2E 或现有深紫主题
foreground  #CDD6F4
muted       #6C7086
red         #F38BA8
green       #A6E3A1
yellow      #F9E2AF
blue        #89B4FA
cyan        #94E2D5
```

颜色应集中在一个主题结构体，不能散落为 magic constants。

验收：

- 1080p 下至少达到 120×33；使用 12×24 字体时达到约 160×45；
- 连续输出 10,000 行不越界、不撕裂、不泄漏；
- 每字符输出不执行 full-screen copy；
- `clear`、滚屏、三 console 切换和 panic 正常；
- QEMU screendump 自动验证尺寸、背景色、文字像素和边界。

建议提交边界：

```text
console(fb): render PSF2 glyphs into a shadow framebuffer
console(fb): add dirty-row flush, scrollback and software cursor
```

### 阶段 4：终端模型、UTF-8 与 ANSI 真彩

目标：把现有“字符直接写 cell”升级为有明确状态机的终端模拟器。

模块：

- UTF-8 decoder；
- ECMA-48 parser；
- terminal state/model；
- backend renderer。

ANSI 第一批必须支持：

```text
CSI A/B/C/D       cursor move
CSI H / f         cursor position
CSI J             erase display
CSI K             erase line
CSI m             SGR
CSI s / u         save/restore cursor
CSI ?25l / ?25h   hide/show cursor
CSI 38;2;r;g;b m  true-color foreground
CSI 48;2;r;g;b m  true-color background
```

第二批：

```text
scroll region
insert/delete character
insert/delete line
256-color 38;5 / 48;5
bracketed paste mode
alternate screen buffer
```

安全要求：

- parser 必须是有界状态机；
- 超长 CSI/OSC 必须丢弃并恢复 normal；
- 参数乘加检查溢出；
- 未知序列不得把 ESC 字节直接显示出来；
- 用户程序不能通过控制序列写越 terminal cell 数组。

UTF-8 顺序：

1. 严格解码，非法序列显示 U+FFFD；
2. ASCII 和 Latin 基础字形；
3. PSF2 Unicode table；
4. `wcwidth` 基础版本；
5. 双宽 CJK cell；
6. combining mark 作为后续增强。

验收：

- host 单元测试覆盖分片输入：一个 ANSI/UTF-8 序列可跨多次 write；
- 24-bit 前景和背景色截图正确；
- cursor movement、erase 和 redraw 不破坏其他 cell；
- 非法 UTF-8/ANSI fuzz 运行 100,000 次无崩溃、越界或卡死；
- VGA backend 可从 RGB 量化到 16 色，只作为 fallback。

建议提交边界：

```text
terminal: add bounded streaming UTF-8 and ECMA-48 parsers
terminal: support 24-bit SGR and framebuffer redraw
```

### 阶段 5：键盘事件与 TTY 模式

目标：为高级行编辑提供完整按键语义，同时不把 Shell 专用接口塞进内核。

任务：

- [ ] 键盘驱动从 char queue 改为 `key_event` queue；
- [ ] 完整解析 E0 扩展 scancode；
- [ ] 支持 press/release 和 modifiers；
- [ ] TTY 把特殊键编码为标准 ANSI input sequences；
- [ ] 增加 termios-like `ioctl`；
- [ ] 支持 canonical/raw、echo、ISIG；
- [ ] 增加 `TIOCGWINSZ` 返回动态 rows/cols；
- [ ] resize 时发送终端尺寸变化事件；
- [ ] 保留 Ctrl+C/Ctrl+\\/Ctrl+Z 的前台组信号路径；
- [ ] 输入队列满时优先保留控制键和 Enter 的策略继续生效。

建议最小 syscall：

```text
SYS_IOCTL
```

不要增加 `SYS_READ_KEY_FOR_SHELL` 之类专用 syscall。Shell 应像普通终端程序一样通过 fd 0 和 termios 使用终端。

验收：

- 方向键、Home/End/Delete/Tab 可被用户态识别；
- raw/canonical 切换后 echo 行为正确；
- console 切换、PageUp/PageDown 不泄漏成 Shell 文本；
- 10,000 次快速输入和特殊键混合无丢 Enter、无死锁。

### 阶段 6：Shell lexer、AST 与执行器重构

目标：先保证语义正确，再做视觉智能交互。

#### 6.1 Lexer

Token 至少包括：

```text
WORD | PIPE | REDIR_IN | REDIR_OUT | REDIR_APPEND
REDIR_ERR | AND_IF | OR_IF | SEMICOLON | AMPERSAND | END
```

状态包括 normal、single_quote、double_quote、escape。Lexer 必须保留“是否允许变量展开”的 quote metadata。

#### 6.2 Parser

建议优先级：

```text
command/redirection
pipeline
&& / ||
; / &
```

错误必须包含输入列号，例如：

```text
syntax error at column 17: expected command after '|'
```

#### 6.3 Expansion

第一批：

- `$NAME`、`${NAME}`；
- `$?`；
- `$$`；
- `~`；
- quote removal；
- PATH 查找。

第二批再实现 glob 和 command substitution。禁止用递归重新调用整个 Shell 字符串解释器完成第一版 expansion。

#### 6.4 Executor

- pipeline 的 N 个 command 全部先创建 pipe；
- 每个 child 只保留需要的 fd；
- `dup2` 后关闭原 pipe ends；
- parent 关闭全部 pipe ends；
- foreground pipeline 等待整个进程组；
- background pipeline 写入 job table，不阻塞 prompt；
- builtin 分为必须在 parent 执行的 `cd/export/unset/fg/bg` 和可在 child 执行的普通 builtin；
- 保存并恢复 stdin/stdout/stderr，禁止依赖“fd 为空时内核回退 TTY”的隐式行为。

#### 6.5 环境和 PATH

- 用户 `_start` 支持 `argc/argv/envp`；
- 新 Shell 通过现有 `crt0` 和用户态 libc 链接，使用 malloc/realloc 管理编辑器与 AST；
- ELF loader 提供多页初始用户栈和明确的 `ARG_MAX`，不再让复杂 argv/envp 共用单个 4 KiB 栈页；
- ELF loader 支持 `execve(path, argv, envp)` 栈布局；
- Shell 用用户态 hash table 保存环境；
- child 继承环境副本；
- 默认 `PATH=/:/bin:/usr/bin`；
- mkfs 支持把 ELF 安装到 `/bin`，Shell 不再自动拼接 `.elf`；
- 过渡期允许 PATH resolver 尝试 `name` 和 `name.elf`，最终删除后者。

验收：

```text
echo "a b" | cat
echo '$HOME'
echo "$HOME"
FOO=bar 或 export FOO=bar
echo one | cat | cat > out
cat < out
false && echo no
true || echo no
sleep 10 &
```

Host parser 测试至少覆盖 200 个表驱动 case，并单独做 malformed input。

建议提交边界：

```text
shell: replace separator scanning with a lexer and AST
shell: execute arbitrary pipelines with explicit fd restoration
exec: pass envp and resolve commands through PATH
```

### 阶段 7：Fish 级行编辑

目标：提供可感知的现代交互体验。

#### 7.1 编辑器数据模型

- 使用动态 gap buffer；
- `cursor` 使用 codepoint/cell 位置，不使用裸 byte offset 显示；
- 初始容量 256，可增长到配置上限，例如 16 KiB；
- 保存 prompt 宽度、终端宽度和当前 render rows；
- 每次编辑计算新 render model，再输出最小 ANSI 重绘序列。

支持按键：

```text
Left/Right          移动一个 codepoint
Ctrl+Left/Right     移动一个 word
Home/End            行首/行尾
Backspace/Delete    删除
Ctrl+A/E            行首/行尾
Ctrl+U/K/W          删除范围
Ctrl+L              清屏并重绘
Up/Down             历史
Ctrl+R              反向搜索
Tab/Shift+Tab       补全选择
Right/End           接受 ghost text
```

#### 7.2 历史与 autosuggestion

- 内存 ring 默认 1,000 条；
- 持久化到 `/home/orange/.orange_history`；
- 写入使用临时文件 + rename；若暂时无 rename，则 append 并做长度上限；
- 去除连续重复；
- ghost text 只从“当前 prefix 匹配且可执行”的历史项产生；
- ghost text 用 muted RGB，不进入真实 line buffer；
- Enter 只执行真实 buffer，Right/End 才接受 suggestion。

#### 7.3 实时语法高亮

颜色语义：

- 可执行命令：绿色；
- builtin：青色；
- 字符串：黄色；
- operator：紫色；
- 有效路径：蓝色；
- 不存在命令/未闭合 quote：红色或下划线；
- ghost text：暗灰色。

高亮使用与执行器同一个 lexer，禁止维护第二套不一致的语法规则。

#### 7.4 多列 Tab 补全

补全来源：

- builtin 表；
- PATH 下可执行项；
- 当前目录/目标目录文件；
- 环境变量；
- `jobs/fg/bg/kill` 的 job/PID；
- 后续命令特定 completion provider。

需要新增 path-aware 目录枚举接口，当前只列 cwd 的 `SYS_LIST` 不足。推荐实现 `getdents`/`readdir`，而不是增加 Shell 专用 completion syscall。

菜单规则：

- 候选唯一时直接补全；
- 多候选先补共同前缀；
- 再次 Tab 展示多列菜单；
- 菜单高度有上限，超出可翻页；
- 输入变化后关闭菜单并恢复 prompt；
- 菜单不得污染 scrollback 中的已提交命令。

验收：

- ghost text 不会被直接执行；
- 语法颜色在每次插入/删除后正确；
- 160 列和 80 列下菜单布局不越界；
- 长命令跨 3 行后光标定位正确；
- UTF-8 双宽字符前后移动不落到 continuation cell；
- history 文件损坏时 Shell 忽略坏行而不崩溃。

建议提交边界：

```text
shell(editor): add cursor-aware multiline editing and history
shell(editor): add shared-lexer highlighting and ghost suggestions
shell(editor): add multi-column command and path completion
```

### 阶段 8：真正的 Job Control

目标：让 `&`、Ctrl+Z、`jobs/fg/bg` 具备真实进程语义。

#### 8.1 内核进程模型

扩展：

- `PROCESS_STOPPED`；
- process group ID；
- session ID；
- controlling TTY；
- 删除 ELF 文件名为 `shell.elf` 才授予终端控制权的特判，改由 session/TTY API 明确建立控制会话；
- signal pending/mask/handler 基础结构；
- wait status 编码 stopped/continued/signaled/exited。

需要的 syscall/API：

```text
setpgid / getpgrp
setsid（可放第二批）
tcsetpgrp / tcgetpgrp
waitpid(pid_or_pgid, options)
kill(pid_or_negative_pgid, signal)
sigaction（最小版本）
```

信号第一批：

```text
SIGINT SIGQUIT SIGTSTP SIGSTOP SIGCONT SIGTERM SIGKILL SIGCHLD
```

#### 8.2 TTY 规则

- 每个 TTY 保存 `foreground_pgid`；
- Ctrl+C 向前台进程组发送 SIGINT；
- Ctrl+\\ 发送 SIGQUIT；
- Ctrl+Z 发送 SIGTSTP；
- 后台组尝试读取 controlling TTY 时至少返回明确错误，后续可实现 SIGTTIN；
- Shell 自身独立进程组，在等待前台 job 时不接收终端控制信号。

#### 8.3 Shell 规则

- pipeline 创建首个 child 后建立 PGID；
- 后续 child 加入相同 PGID；
- foreground 前调用 `tcsetpgrp`；
- wait 后无论退出或停止都把终端交还 Shell PGID；
- stopped job 留在 job table；
- `fg %N` 交还终端并 SIGCONT；
- `bg %N` SIGCONT 但不接管终端；
- 异步 SIGCHLD 只设置 flag，实际 job table 更新在安全点完成。

验收：

```text
sleep 100
Ctrl+Z
jobs
bg %1
fg %1
Ctrl+C
sleep 1 | cat &
jobs
```

资源门禁：完成后 process/thread/file/pipe/waiter 数量回到 baseline。

建议提交边界：

```text
process: add process groups, stopped state and group signals
tty: route control keys to the foreground process group
shell(jobs): implement jobs, fg, bg and terminal handoff
```

### 阶段 9：性能、兼容与 UEFI GOP

目标：把 QEMU 成功提升为稳定架构，而不是单一机器截图。

任务：

- [ ] PAT write-combining；
- [ ] glyph cache；
- [ ] dirty rectangle 合并；
- [ ] 批量 TTY write，不做每字符 IPC；
- [ ] 1080p、1440p、720p 测试矩阵；
- [ ] RGBX/BGRX 测试矩阵；
- [ ] 512 MiB/1 GiB 内存配置；
- [ ] UEFI Loader 获取 GOP framebuffer；
- [ ] BIOS VBE 与 UEFI GOP 共用 boot info contract；
- [ ] 无 framebuffer 时 VGA/serial fallback；
- [ ] 为字体、终端和 Shell parser 做 fuzz；
- [ ] 性能 counters 写入 artifact。

性能目标建议：

- 普通按键到显示完成：QEMU 中小于 50 ms；
- 输入一行时只刷新受影响行；
- 1080p 连续输出 10,000 行不出现秒级停顿；
- framebuffer + shadow buffer 总内存约 16–20 MiB；
- 无输出时不持续 full-screen flush；
- 光标闪烁不唤醒无关进程。

验收：

- BIOS 1080p、BIOS fallback、UEFI GOP 三条启动路径通过；
- 相同 terminal host tests 运行于 framebuffer 和 VGA backend；
- 完整 `make check-all` 不再依赖 VGA 文本显存；
- 截图、serial、环境、性能统计和资源差异统一保存。

### 阶段 10：演示与交付

目标：形成可重复的 10 分钟现场展示，而不是临时输入命令。

新增入口：

```bash
make console-showcase-prepare
make console-showcase
make test CASE=console.hd
make test CASE=shell.interactive
make test CASE=shell.jobs
```

演示脚本：

1. 1080p 启动，展示真实 framebuffer 信息；
2. 输入 `ec`，显示 `echo ...` ghost suggestion；
3. 展示命令/字符串/operator 实时高亮；
4. Tab 展示多列命令与文件补全；
5. 执行三段 pipeline 和重定向；
6. 展示 `$PATH`、`export` 和引号；
7. 启动后台任务，执行 `jobs`；
8. Ctrl+Z、`bg`、`fg`、Ctrl+C；
9. 展示持久化 history；
10. 用测试 artifact 证明功能不是预制动画。

---

## 8. 测试体系改造

### 8.1 Host 单元测试

可脱离 QEMU 的纯逻辑必须做宿主测试：

- UTF-8 decoder；
- ANSI parser；
- terminal cursor/erase model；
- PSF2 parser；
- shell lexer/parser/expansion；
- line editor buffer 和 cursor；
- completion 排序和共同前缀；
- job table 状态转换。

这些模块应避免直接依赖 `kmalloc`、端口 I/O 或 syscall，使用小型 adapter 注入依赖。

### 8.2 QEMU 功能测试

建议 manifest：

```text
console.serial       fast/full
boot.dynamic-kernel full
framebuffer.mode    full
framebuffer.fallback full
terminal.ansi       full
terminal.utf8       full
shell.parser        fast/full
shell.editor        full
shell.completion    full
shell.jobs          full/stress
console.showcase    showcase
```

### 8.3 截图测试

- 使用 QEMU `screendump`；
- 验证宽高不是 720×400；
- 检查背景色、主题色和非背景 glyph 像素；
- 关键区域用容差采样；
- 不做整个 PPM 的固定 hash；
- 测试模式关闭 cursor blink 或固定为可见；
- 保存 PPM、解析后的 mode、serial、QEMU log 和 result.env。

### 8.4 故障注入

- VBE 无目标 mode；
- framebuffer 地址越界；
- pitch 错误；
- PSF2 magic/size/glyph count 错误；
- shadow buffer 分配失败；
- ANSI 超长参数；
- UTF-8 截断；
- parser 未闭合引号；
- pipeline 中间 fork/pipe/dup2 失败；
- history 文件损坏；
- job 在 stop/continue/exit 交错时退出。

每条失败路径都必须落到 serial 并有稳定退出状态。

---

## 9. 阶段门禁与依赖关系

```text
阶段 0 serial oracle
   │
   ▼
阶段 1 dynamic kernel
   │
   ▼
阶段 2 framebuffer mapping
   │
   ▼
阶段 3 renderer/font
   │
   ▼
阶段 4 terminal/ANSI/UTF-8
   │
   ├───────────────┐
   ▼               ▼
阶段 5 input/TTY   阶段 6 shell AST/executor
   │               │
   └───────┬───────┘
           ▼
阶段 7 smart editor
           │
           ▼
阶段 8 job control
           │
           ▼
阶段 9 hardening/UEFI
           │
           ▼
阶段 10 showcase
```

禁止跨越的门禁：

- serial oracle 未完成，不得删除 VGA snapshot；
- 188-sector 未解除，不得把字体数组硬塞内核；
- framebuffer descriptor 未验证，不得写显存；
- ANSI parser 未有 host tests，不得替换当前 TTY parser；
- AST executor 未稳定，不得叠加 syntax highlighting；
- STOPPED/process group 未实现，不得把 Ctrl+Z 宣称为 job control。

---

## 10. 时间与人员估算

以一名熟悉项目的开发者、持续开发估算：

| 阶段 | 预计时间 |
|---|---:|
| 0：serial 与测试迁移 | 3–5 天 |
| 1：动态 Loader/内核布局 | 1–2 周 |
| 2：VBE framebuffer | 4–7 天 |
| 3：字体与 renderer | 1–2 周 |
| 4：ANSI/UTF-8 terminal | 1–2 周 |
| 5：输入与 TTY 模式 | 4–7 天 |
| 6：Shell parser/executor/env | 2–3 周 |
| 7：Fish 级行编辑 | 2–3 周 |
| 8：Job control | 2–4 周 |
| 9：性能/UEFI/硬化 | 2–4 周 |
| 10：演示交付 | 3–5 天 |

完整目标约 14–24 周。可以先在 4–6 周内交付一个可演示 MVP：

```text
dynamic loader
+ 1080p framebuffer
+ PSF2 font
+ true-color ANSI
+ cursor-aware editor
+ history/autosuggestion
+ basic completion
```

真正的 job control 不应为了赶 MVP 做成假状态。

---

## 11. 风险清单与回退方案

### 风险 1：启动修改导致系统完全无输出

回退：每个阶段保留 UART；Loader 用单字符错误码；保留 VGA fallback target。

### 风险 2：framebuffer 不在前 1 GiB

回退：不扩大 Loader 的 1 GiB identity map；由内核在 PMM 初始化后建立独立 MMIO 映射。

### 风险 3：字体使内核急剧变大

回退：内核只带最小 ASCII panic font，正常字体由 MyFS 加载并校验。

### 风险 4：全屏软件渲染太慢

回退：dirty row、glyph cache、shadow buffer、批量 flush，之后再做 PAT WC。

### 风险 5：Shell 高亮与执行语法不一致

回退：editor 和 executor 共享 lexer/token；高亮只读 parser 结果。

### 风险 6：Job control 引入进程回收泄漏

回退：每个状态转换后执行 runtime snapshot；前台 wait、后台 reap、stopped job 分套测试。

### 风险 7：当前 dirty worktree 被覆盖

回退：开始实现前先建立明确基线 commit/branch；禁止 reset、checkout 覆盖当前 VGA/runner/showcase WIP。

---

## 12. 每阶段统一完成标准

每个阶段结束必须同时满足：

- [ ] 功能测试通过；
- [ ] host 单元测试通过；
- [ ] `git diff --check` 通过；
- [ ] Shell 脚本 `bash -n` 通过；
- [ ] `make check` 通过；
- [ ] `make test-self` 通过；
- [ ] 目标 QEMU case 固定 seed 通过；
- [ ] 资源 snapshot 无新增泄漏；
- [ ] 文档与源码字段一致；
- [ ] 保存 serial/QEMU/screenshot/result artifacts；
- [ ] VGA fallback 或上一稳定后端仍可启动；
- [ ] 没有把 infrastructure error 计为内核失败。

阶段性提交必须按功能边界拆分，不把 Loader、renderer、Shell parser 和 job control 混在一个 commit。

---

## 13. 推荐的实际执行顺序

如果目标是尽快得到“看得见”的成果：

1. 阶段 0；
2. 阶段 1；
3. 阶段 2；
4. 阶段 3；
5. 阶段 4 的 ANSI 真彩子集；
6. 阶段 5 的方向键/raw mode；
7. 阶段 7 的基础行编辑、history 和 autosuggestion；
8. 返回阶段 6 完成完整 AST/pipeline/env；
9. 阶段 7 completion/highlight；
10. 阶段 8 job control；
11. 阶段 9/10。

这里允许“视觉 MVP”先于完整 Job Control，但不允许绕过动态 Loader、serial oracle 或 terminal parser 门禁。

---

## 14. 可直接使用的执行 Prompt

```text
请在 /home/orange/my_os 中严格按照
docs/modern-console-advanced-shell-execution-plan.md 实施 Orange/64 高清纯控制台
和高级 Shell。

开始前必须：
1. 阅读完整方案、git status、当前全部 diff 和 AGENTS.md。
2. 当前工作区已有 VGA theme、runner、showcase、ANSI 和 Shell WIP；禁止 reset、
   checkout 覆盖、clean、删除或整文件重写。
3. 记录 HEAD、工作区状态、make check、make check-all、kernel.bin 大小和现有 artifacts。
4. 只创建一个阶段 goal；不得在同一 goal 中跨多个大阶段。

严格从阶段 0 开始：先建立 COM1 serial 结构化测试 oracle，不得直接删除 VGA 输出。
阶段 1 必须解除 188-sector 和 0x1900 固定内核窗口；不得通过压缩现有代码或把
字体硬塞进剩余空间规避 Loader 改造。

framebuffer 要求：
- VBE 枚举 mode，不写死 mode number；
- boot_info 带 version/size 和 framebuffer masks；
- 验证 address/size/pitch/height 溢出；
- framebuffer 高物理地址由内核 MMIO 映射；
- 32bpp RGBX/BGRX；
- shadow buffer + dirty rows；
- PSF2 字体，panic 内置最小字体；
- VGA 只作为 fallback。

terminal 要求：
- model/parser/renderer 分层；
- streaming UTF-8 和 ECMA-48 状态机；
- 支持 cursor、erase、SGR、38;2/48;2 true color；
- parser 有界且有 host unit tests/fuzz；
- 测试模式固定 cursor，便于 screenshot。

Shell 要求：
- 拆分为 usr/orangesh 多模块；
- lexer -> AST -> expansion -> executor；
- parser 与 syntax highlighter 共享 token；
- 显式保存/恢复 0/1/2 fd；
- 支持多级 pipeline、引号、PATH、envp；
- editor 使用动态 gap buffer；
- history、ghost suggestion、实时高亮和多列补全；
- job control 必须基于 process group、STOPPED 和 controlling TTY，禁止把 fork 后
  不 wait 或 Ctrl+Z 终止伪装为 job control。

每完成一个小任务：
1. 先运行 host unit tests；
2. 再运行目标 QEMU case；
3. 检查 serial、screenshot、资源 snapshot；
4. 更新阶段文档；
5. 报告修改文件、测试 seed、artifact 和已知限制。

发生 QEMU Unix socket 沙箱错误时按权限流程重跑，并把它标记为
INFRASTRUCTURE_ERROR，不得修改内核来规避宿主沙箱。

本次只执行当前指定阶段；达到该阶段验收后停止并提交结果，不自动进入下一阶段。
```

---

## 15. 最终验收清单

### 显示

- [ ] 正常启动不再使用 VGA 80×25；
- [ ] 1080p/2K 可选择并有 fallback；
- [ ] 24-bit ANSI foreground/background 正确；
- [ ] 字体、cursor、scrollback、clear 和 console switch 正确；
- [ ] 无 framebuffer 时 serial/VGA 可诊断；
- [ ] panic 不依赖用户态、FS 或动态大字体。

### Shell 交互

- [ ] 行内移动、删除和多行重绘正确；
- [ ] 持久化 history；
- [ ] ghost-text 不污染真实 buffer；
- [ ] lexer 驱动的实时高亮；
- [ ] 多列 Tab completion；
- [ ] UTF-8 输入和双宽 cursor 基本正确。

### Shell 语义

- [ ] 引号、转义、变量和 PATH；
- [ ] 任意长度 pipeline；
- [ ] stdin/stdout/stderr 重定向；
- [ ] `&&`、`||`、`;`、`&`；
- [ ] envp 继承；
- [ ] jobs/fg/bg；
- [ ] 前台进程组信号；
- [ ] stopped/continued/exit wait 状态；
- [ ] 无 fd、pipe、process、thread 和 waiter 泄漏。

### 工程

- [ ] 动态内核加载，无 188-sector 限制；
- [ ] BIOS VBE 与 UEFI GOP 共用 boot info；
- [ ] 测试结果不依赖 `0xB8000`；
- [ ] host unit、QEMU、stress、fuzz 和 screenshot 均接入 runner；
- [ ] CI 保存 serial、PPM、JUnit、环境和失败 artifacts；
- [ ] 10 分钟演示可由一组稳定命令复现。
