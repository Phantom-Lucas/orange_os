# Orange/64 一天版 QEMU Framebuffer 折中方案

状态：PROPOSED

日期：2026-08-19

时间预算：8–12 个 AI 执行小时，另保留最多 2 小时稳定性缓冲

目标：正常演示路径不再显示 VGA 80×25 文本画面，在不修改 BIOS Loader、内核物理布局和进程模型的前提下，交付一个 QEMU 专用 `1280×720×32` 软件 framebuffer 终端，并增加少量现代 Shell 交互。

---

## 1. 方案结论

可以不显示 VGA，但必须接受下面的折中：

- 只保证 QEMU 6.2 的 Standard VGA/Bochs VBE；
- 不承诺真实显卡、VirtualBox、VMware 或 UEFI GOP；
- 屏幕是 1280×720 的 32-bit framebuffer；
- 字体是真正的软件 PSF2 字体，不使用 VGA 字符 ROM；
- TTY 内部继续使用现有 80×25 cell/history 模型；
- 正常 framebuffer 演示不写可见 `0xB8000`；
- diagnostic 和旧测试仍可使用 VGA backend；
- framebuffer 测试可以选择隐藏的 VGA mirror 作为文本 oracle；
- 不改 MBR、Loader、linker、系统调用和进程状态机。

最终画面：

```text
QEMU 1280×720×32 图形模式
  └── 全屏深紫背景
      └── 12×24 Terminus 字体渲染的 80×25 终端区域
          ├── RGB 主题色
          ├── 软件块状光标
          ├── 当前 scrollback/console
          └── 用户态 Orange Shell
```

这已经不是 VGA 文本模式：QEMU 显示的是内核逐像素写入的线性 framebuffer。80×25 只作为本轮保留的逻辑网格，后续长期方案再升级为动态 rows/cols。

---

## 2. 为什么这条路线适合一天

当前环境已经具备关键条件：

- QEMU 为 `6.2.0`；
- `-vga std` 提供设备 `1234:1111`；
- 该设备位于 PCI `00:02.0`；
- BAR0 实际分配为 `0xFD000000..0xFDFFFFFF`，共 16 MiB；
- 1280×720×4 只需 3,686,400 字节；
- 内核 `map_page()` 可以把任意高物理地址映射到独立内核虚拟窗口；
- quiet 构建不执行 `kernel/test.c`，该目标文件约有 11.9 KiB text；
- 可以在 framebuffer quiet build 中不链接 kernel test code，为 renderer 腾出空间；
- 系统已安装 12×24 PSF2 字体：
  `/usr/share/consolefonts/Lat38-Terminus24x12.psf.gz`；
- 解压字体为 13,800 字节，PSF2 header 为 32 字节，256 glyph，每 glyph 48 字节，宽 12、高 24；
- 字体可以作为 MyFS 普通文件加载，不占 kernel.bin。

因此无需碰 Loader，就能在 188 扇区上限内放入小型 PCI/VBE/renderer 代码。

---

## 3. 明确范围

### 3.1 必须完成

- [ ] `FRAMEBUFFER_BACKEND=1` quiet 构建；
- [ ] 最小 PCI config-space 读取；
- [ ] 自动识别 QEMU Standard VGA `1234:1111`；
- [ ] 从 PCI BAR0 取得 framebuffer 物理地址，禁止把 `0xFD000000` 写死为唯一真值；
- [ ] 用 Bochs VBE DISPI 寄存器设置 `1280×720×32`；
- [ ] 把完整 framebuffer 映射到固定高半区虚拟窗口；
- [ ] PSF2 12×24 字体校验和加载；
- [ ] 80×25 cell 到 RGB 像素渲染；
- [ ] 深紫背景、柔和白字和当前 16 种语义色的 RGB 映射；
- [ ] 软件块状光标；
- [ ] TTY clear、scroll、console switch 可重绘；
- [ ] 独立 `fb-showcase-prepare` / `fb-showcase`；
- [ ] QEMU framebuffer screenshot 自动测试；
- [ ] VGA backend 旧测试无回归。

### 3.2 有时间才做

按优先级：

1. Shell ANSI 彩色 Prompt 默认开启；
2. Left/Right 行内插入；
3. Up/Down 16 条会话历史；
4. Home/End/Delete；
5. `pw<Tab>` 这类唯一命令补全。

这些功能必须在 framebuffer 稳定后实施。ghost suggestion、实时高亮和多列菜单移出本轮。

### 3.3 本轮禁止

- 修改 `boot/mbr.S` 或 `boot/loader.S`；
- 修改 `kernel/linker.ld` 和 `KERNEL_LMA`；
- 解除 188 扇区限制；
- BIOS `INT 10h` VBE 调用；
- UEFI GOP、GRUB、Limine；
- 通用 PCI 子系统；
- virtio-gpu、virtio-vga 或 GPU 加速；
- 动态 terminal rows/cols；
- 24-bit ANSI parser；
- UTF-8/CJK；
- TTF/OTF 和抗锯齿；
- shadow framebuffer、dirty rectangle 和 glyph cache；
- 新 syscall；
- Shell AST、环境变量、PATH、真正 Job Control；
- 删除当前 VGA 后端和测试；
- reset、clean、checkout 覆盖、commit 或 tag。

---

## 4. 构建配置

新增配置：

```make
FRAMEBUFFER_BACKEND ?= 0
FRAMEBUFFER_VGA_MIRROR ?= 0
FRAMEBUFFER_WIDTH ?= 1280
FRAMEBUFFER_HEIGHT ?= 720
FRAMEBUFFER_BPP ?= 32
```

把这些值加入 `build/.boot-config`，防止不同后端复用旧对象。

构建策略：

```text
普通旧测试：
  BOOT_DIAGNOSTIC=0/1 FRAMEBUFFER_BACKEND=0

framebuffer showcase：
  BOOT_DIAGNOSTIC=0 FRAMEBUFFER_BACKEND=1 FRAMEBUFFER_VGA_MIRROR=0

framebuffer 自动测试：
  BOOT_DIAGNOSTIC=0 FRAMEBUFFER_BACKEND=1 FRAMEBUFFER_VGA_MIRROR=1
```

当 `BOOT_DIAGNOSTIC=0` 时，从 `KERNEL_C_SOURCES` 排除 `kernel/test.c`。`kernel/kernel.c` 中对测试函数的引用已经位于 `#if BOOT_DIAGNOSTIC`，quiet 链接不需要 stub。

当 `FRAMEBUFFER_BACKEND=0` 时，不编译/链接 framebuffer 和 PSF2 代码。

目标：

```bash
make fb-showcase-prepare
make fb-showcase
make test CASE=framebuffer.core SEED=20260819 KEEP_FAILED=1
```

原 `make showcase` 暂时不改变，等 framebuffer case 连续稳定后再决定是否转发到新入口。

---

## 5. 代码布局

新增：

```text
kernel/qemu_fb.c
kernel/qemu_fb.h
kernel/psf2.c
kernel/psf2.h
assets/fonts/terminal.psf
assets/fonts/README.md
assets/fonts/LICENSE
tests/suites/framebuffer.sh
```

修改：

```text
Makefile
kernel/kernel.c
kernel/memory.h       # 只补 PWT/PCD flag，若需要
kernel/tty.c
kernel/tty.h
kernel/print.c        # 只处理 backend active/panic fallback 时才修改
tests/manifest.sh
tests/lib/screenshot.sh
docs/presentation-demo.md
```

可选 Shell：

```text
kernel/keyboard.c
usr/shell.c
```

不建立通用 `drivers/pci` 层。本轮 PCI helper 保持为 `qemu_fb.c` 内部 static 函数，避免项目范围扩张。

---

## 6. QEMU framebuffer 初始化

### 6.1 PCI config-space

使用标准端口：

```text
0xCF8  CONFIG_ADDRESS
0xCFC  CONFIG_DATA
```

只扫描 bus 0、device 0..31、function 0，查找：

```text
vendor = 0x1234
device = 0x1111
class  = 0x03
```

不能只写死 `00:02.0`，但找到其他厂商 VGA 也不能误用 Bochs 寄存器。

BAR0 处理：

- 读取 BAR0；
- 要求 memory BAR；
- 要求 32-bit BAR；
- 清除低 attribute bits 得到物理 base；
- 临时写 `0xFFFFFFFF` 探测 size，再恢复原 BAR；
- 验证 size 至少覆盖 `width * height * 4`；
- 验证 base 非 0、非全 1、页对齐后范围不溢出；
- 确保 PCI command 的 memory-space enable bit 已置位。

本机预期日志：

```text
[FB] qemu stdvga 1234:1111 BAR0=0xfd000000 size=16MiB
```

实际代码仍必须读 PCI，不依赖这条预期地址。

### 6.2 Bochs VBE DISPI

端口：

```text
index 0x01CE
data  0x01CF
```

寄存器：

```text
0 ID
1 XRES
2 YRES
3 BPP
4 ENABLE
6 VIRT_WIDTH
```

顺序：

1. 读取 ID，只接受 Bochs VBE 支持范围；
2. `ENABLE=0`；
3. 写 `XRES=1280`；
4. 写 `YRES=720`；
5. 写 `BPP=32`；
6. 写 `VIRT_WIDTH=1280`；
7. 写 `ENABLE = ENABLED | LFB_ENABLED`；
8. 回读 XRES/YRES/BPP；
9. 不匹配则立即报告失败。

切换前必须完成 PCI/BAR/size 验证。否则模式已经进入图形态但 framebuffer 不可写，会失去所有可见诊断。

---

## 7. Framebuffer 映射

使用独立虚拟窗口：

```c
#define QEMU_FB_VADDR 0xFFFF900000000000ULL
```

需要新增页表 flag：

```c
#define PTE_PWT 0x08
#define PTE_PCD 0x10
```

第一版按 4 KiB 映射：

```text
physical: BAR0 + page_offset
virtual:  QEMU_FB_VADDR + page_offset
flags:    PTE_RW | PTE_PWT | PTE_PCD
PML4:     BOOT_KERNEL_PML4_PADDR
```

映射范围为对齐后的 `1280 * 720 * 4`，不是整个 16 MiB BAR。

要求：

- 所有乘法和加法检查溢出；
- 失败时不留下半初始化 active backend；
- 只在 PMM 初始化后调用，因为 `map_page()` 可能分配页表页；
- active flag 最后设置；
- 不把 MMIO BAR 登记成 PMM 普通内存；
- framebuffer 不暴露给 Ring 3；
- 暂不实现 PAT write-combining。

---

## 8. PSF2 字体

### 8.1 资产

本轮使用本机已有：

```text
/usr/share/consolefonts/Lat38-Terminus24x12.psf.gz
```

构建准备阶段解压并 vendor 为：

```text
assets/fonts/terminal.psf
```

已观测格式：

```text
magic       0x864AB572
header size 32
flags       1
glyph count 256
glyph bytes 48
height      24
width       12
file bytes  13,800
```

必须同时保存字体来源、软件包名 `console-setup-linux`、许可证文本和 SHA-256。不得只复制二进制而遗漏许可证。

### 8.2 放入 MyFS

让 `build/fs.img` 依赖字体资产，并把它作为普通文件加入 mkfs：

```text
terminal.psf
```

字体不进入 kernel.bin。

### 8.3 加载与校验

在 `fs_service_init()` 后、启动 `shell.elf` 前读取字体。

严格验证：

- magic；
- header size；
- glyph count；
- bytes per glyph；
- width/height；
- `header + glyph_count * glyph_bytes <= file_size`；
- 每行字节数满足 `(width + 7) / 8`；
- 本轮要求 width=12、height=24；
- 只索引 0..255 glyph，超范围使用 `?`。

字体加载失败时不得进入图形模式，继续 VGA fallback 并输出明确错误。这保证错误仍可诊断。

---

## 9. 80×25 Cell 的软件渲染

### 9.1 布局

字体 cell 正好为 12×24：

```text
terminal width  = 80 * 12 = 960
terminal height = 25 * 24 = 600
screen          = 1280 * 720
left margin     = 160
top margin      = 60
```

整个 1280×720 先填深紫背景，终端区域居中。这样虽然逻辑仍是 80×25，但画面是宽屏、高分辨率、由字体位图软件渲染的终端，而不是粗大的 VGA glyph。

### 9.2 主题色

把 VGA attribute 的 foreground/background index 映射到 RGB：

```text
0  #300A24  background
7  #C8C8C8  normal gray
8  #707070  muted
9  #5F87FF  blue
10 #5FD75F  green
11 #5FD7D7  cyan
12 #FF5F5F  red
13 #D75FD7  magenta
14 #FFD75F  yellow
15 #F2F2F2  bright foreground
```

物理像素格式按 QEMU stdvga 32-bit BGRX 写入。用红/绿/蓝色条测试确认 channel，不能仅凭肉眼猜测。

### 9.3 渲染函数

```c
int qemu_fb_is_active(void);
int qemu_fb_initialize(const void* psf, uint64_t psf_size);
void qemu_fb_render_cells(const uint16_t* cells,
                          uint32_t cursor,
                          int cursor_visible);
void qemu_fb_clear(uint32_t rgb);
```

第一版每次 TTY flush 重画完整 80×25：

- 2,000 cells；
- 每 cell 12×24；
- 约 576,000 像素；
- 约 2.3 MiB framebuffer 写入。

这不够高效，但在 QEMU 演示中可接受，也能避免 dirty tracking 重构。性能不满足时先减少无意义的分段 write，不能在当天临时加入复杂 shadow buffer。

### 9.4 软件光标

- 不再使用 VGA CRTC cursor；
- 在当前 cell 底部绘制 2–3 像素高横条，或绘制整块反色；
- 测试模式固定可见；
- 本轮不做定时闪烁，避免 timer/截图不确定性。

---

## 10. TTY 接入

保持 `struct tty_console`、history、ANSI parser、输入服务和三 console 不变。

只改最终 flush：

```text
if framebuffer active:
    qemu_fb_render_cells(...)
    if FRAMEBUFFER_VGA_MIRROR:
        flush 0xB8000 mirror
else:
    existing VGA flush
```

`tty_init()` 仍在图形模式切换前运行，并把早期 VGA 启动信息复制到 console 0。字体和 framebuffer 初始化完成后执行一次完整 flush，把已有启动内容重绘到图形界面。

正常 framebuffer showcase：

```text
FRAMEBUFFER_VGA_MIRROR=0
```

自动测试：

```text
FRAMEBUFFER_VGA_MIRROR=1
```

mirror 只用于 `pmemsave 0xB8000` 文本断言，QEMU 实际窗口已经处于 framebuffer 图形模式。

必须验证：

- clear；
- newline 和 scroll；
- PageUp/PageDown；
- F1/F2/F3 console switch；
- ANSI 16 色；
- prompt cursor；
- panic 前后端 fallback 不死锁。

---

## 11. Kernel 初始化顺序

保持现有早期启动，新增位置在 FS/TTY 已可用后：

```text
print_init
memory / heap
tty_init
keyboard / thread / syscall
disk_init
fs_init
fs_service_init
load terminal.psf
qemu_fb_initialize
tty_redraw_active
launch shell.elf
```

注意：

- 字体校验成功后才设置图形模式；
- framebuffer active 后，内核不得再直接通过 `_put_char()` 写 VGA；
- print 路径已经在 TTY 初始化后走 TTY，应保持；
- framebuffer 初始化失败不能阻止 Shell 启动；
- fallback 状态必须打印 `[FB] fallback=vga reason=...`。

---

## 12. 可选 Shell 小增强

只有 framebuffer 核心和测试全部通过后执行。

### 12.1 彩色 Prompt

把交互 `style_enabled` 默认设为 1。现有 pipe/redirection 路径继续临时关闭 style，确保文件不含 ESC。

### 12.2 Left/Right 与历史

复用一天版 Shell 方案的最小子集：

- keyboard 将箭头编码为 `ESC[A/B/C/D`；
- Shell 流式解码，允许序列跨 `sys_read()`；
- 固定 128-byte line；
- cursor index；
- 中间插入和 Backspace；
- 16 条 session history；
- 不做 ghost、高亮和多列菜单。

### 12.3 唯一 Tab 补全

只对 command word 做静态表唯一补全：

```text
pw<Tab> -> pwd
```

多个候选时只保持输入不变，不展示菜单。

---

## 13. 逐小时计划

### T0：基线和尺寸（0.5 小时）

- [ ] 记录 HEAD/dirty files；
- [ ] `make check`；
- [ ] `make test-self`；
- [ ] 记录 quiet/diagnostic kernel.bin；
- [ ] 保存 boot/tty/showcase 基线 screenshot；
- [ ] 不修改历史。

### T1：构建隔离和字体资产（1 小时）

- [ ] 增加 framebuffer config stamp；
- [ ] quiet 排除 `kernel/test.c`；
- [ ] framebuffer 源文件只在配置开启时链接；
- [ ] vendor PSF2 和许可证；
- [ ] 把字体加入 fs.img；
- [ ] 验证 VGA 构建结果不变。

### T2：PCI/BAR/VBE/映射（2 小时）

- [ ] PCI config helper；
- [ ] 识别 1234:1111；
- [ ] BAR0 和 size 验证；
- [ ] 4 KiB MMIO mapping；
- [ ] Bochs VBE mode set/readback；
- [ ] RGB color bar smoke；
- [ ] 失败回退 VGA。

### T3：PSF2 与 renderer（2.5 小时）

- [ ] 读取/校验字体；
- [ ] glyph bit iterator；
- [ ] attribute 到 RGB；
- [ ] 80×25 centered layout；
- [ ] 全屏 render；
- [ ] 软件 cursor；
- [ ] screenshot 人工复核。

### T4：TTY backend 接入（1.5 小时）

- [ ] flush backend 分支；
- [ ] mirror 配置；
- [ ] clear/scroll/console switch；
- [ ] boot logs 重绘；
- [ ] prompt 后不再竞争 cursor；
- [ ] framebuffer 失败回退。

### T5：QEMU 入口和自动化（2 小时）

- [ ] `fb-showcase-prepare`；
- [ ] `fb-showcase` 固定 `-vga std`；
- [ ] runner `framebuffer.core`；
- [ ] screendump 验证 1280×720；
- [ ] 背景、RGB 条、glyph、cursor 像素检查；
- [ ] mirror 文本断言；
- [ ] VGA 完整目标回归。

### T6：Shell 小增强与演示（1.5 小时，可裁剪）

- [ ] style 开启；
- [ ] Left/Right；
- [ ] Up/Down history；
- [ ] 可选唯一 Tab；
- [ ] 更新 help 和演示文档；
- [ ] 最终 screenshot/artifacts。

### 缓冲（最多 2 小时）

只处理：

- BAR/mode/mapping 错误；
- kernel size；
- PSF2 边界；
- cursor/scroll 显示；
- QEMU screenshot 竞态；
- 原测试回归。

---

## 14. 尺寸门禁

Loader 上限保持：

```text
188 * 512 = 96,256 bytes
```

规则：

- VGA diagnostic kernel 必须继续小于等于 96,256；
- framebuffer quiet kernel 也必须小于等于 96,256；
- 字体不得编译进 kernel.bin；
- quiet 通过排除 kernel test code 获得约 11.9 KiB text 预算；
- framebuffer/PSF2/TTY 新代码总 text 目标不超过 10 KiB；
- framebuffer 源文件使用 `-Os`；
- 若仍超限，先删除 Shell 内核侧可选代码和非必要日志；
- 禁止为了过尺寸门禁修改 Loader。

每轮：

```bash
make check
wc -c build/kernel/kernel.bin
```

并分别记录 VGA diagnostic 与 framebuffer quiet 尺寸，不能只测一个配置。

---

## 15. 测试方案

### 15.1 新增 framebuffer.core

构建：

```text
BOOT_DIAGNOSTIC=0
FRAMEBUFFER_BACKEND=1
FRAMEBUFFER_VGA_MIRROR=1
DISK_SIZE=64M
```

QEMU：

```text
-vga std
-m 512M
-display none
-monitor unix:...
```

断言：

- serial/隐藏 VGA mirror 包含 framebuffer 初始化成功；
- framebuffer device 为 1234:1111；
- BAR size >= mode bytes；
- mode 为 1280×720×32；
- Prompt 恢复；
- `screendump` 为 1280×720 P6 PPM；
- 背景区域接近主题深紫；
- glyph 区域包含非背景像素；
- 红/绿/蓝 channel 测试正确；
- cursor 区域存在；
- qemu_exit_code=0。

artifacts：

```text
terminal-fb.ppm
vga-mirror.bin
vga-mirror.txt
qemu.log
result.env
environment.txt
mode.env
```

### 15.2 fallback case

用不匹配设备或 `FRAMEBUFFER_BACKEND=0` 启动：

- Shell 仍能进入；
- VGA 文本正常；
- 日志说明 fallback 原因；
- 不产生 page fault。

### 15.3 回归矩阵

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
```

最后尝试 `make check-all`。现有 full profile 保持 VGA backend，不能因为 framebuffer 新增而改变旧 suite 的判定语义。

---

## 16. 演示方式

准备：

```bash
make fb-showcase-prepare
```

启动：

```bash
make fb-showcase
```

Make target 应展开为类似：

```bash
qemu-system-x86_64 \
  -name "Orange/64 Framebuffer Terminal" \
  -vga std \
  -drive file=build/fb-showcase-demo.img,format=raw,index=0,media=disk \
  -m 512M -smp 1 -no-reboot -no-shutdown
```

现场展示：

```text
1. 启动画面直接切换为 1280×720 深紫 framebuffer
2. 执行 about/help，展示 12×24 字体与 RGB 主题
3. 执行 ps
4. 执行 echo pipeline-ok | cat
5. 执行 echo saved > demo-file
6. 执行 cat demo-file
7. 执行 demo
8. 若 T6 完成，展示 Left/Right 和 Up/Down history
```

讲解口径：

```text
“这是 QEMU Standard VGA 提供的线性 framebuffer，但系统没有使用 VGA 文本
模式显示字符。内核通过 PCI BAR 映射显存，用 PSF2 字体逐像素渲染现有 TTY
cell；为了把改动控制在一天内，逻辑网格暂时仍是 80×25，通用 VBE/GOP、
动态行列和完整高级 Shell 放在下一阶段。”
```

---

## 17. 限制必须如实说明

- 仅支持 QEMU stdvga `1234:1111`；
- 不是通用 VBE BIOS 实现；
- 不支持 UEFI GOP；
- framebuffer 模式固定 1280×720×32；
- 内部仍是 80×25 cell；
- 只有 16 个终端颜色索引映射到 RGB，不是 24-bit ANSI；
- PSF2 只使用 0..255 glyph；
- 不支持 UTF-8/CJK；
- 每次 flush 全屏重绘，性能不是最终架构；
- panic/fallback 仍保留 VGA；
- 自动测试可启用隐藏 VGA mirror；
- Shell 高级交互只做 T6 的最小子集；
- 真实硬件支持属于长期方案。

---

## 18. 停止与裁剪条件

出现以下任一情况，立即停止增加 Shell 功能：

- framebuffer quiet kernel 超过 96,256 字节；
- diagnostic VGA kernel 回归；
- BAR 探测或模式切换不稳定；
- framebuffer page fault；
- fallback 失去输出；
- clear/scroll/console switch 错误；
- screenshot 尺寸或颜色不确定；
- 剩余时间小于 2 小时且 framebuffer.core 未通过。

裁剪顺序：

```text
Tab 补全
→ Home/End/Delete
→ Shell history
→ Left/Right
→ 非必要视觉装饰
```

必须保留的最小结果：

```text
1280×720×32 QEMU framebuffer
+ PSF2 12×24 字体
+ 现有 Shell/TTY 功能
+ VGA fallback
+ framebuffer screenshot test
```

---

## 19. 一天版完成标准

- [ ] 正常 `fb-showcase` 的 QEMU 窗口不显示 VGA 文本终端；
- [ ] mode 为 1280×720×32；
- [ ] framebuffer base 从 PCI BAR 获得；
- [ ] framebuffer 高物理地址被单独映射；
- [ ] PSF2 字体不进入 kernel.bin；
- [ ] 80×25 内容以 12×24 glyph 软件渲染；
- [ ] RGB 主题、clear、scroll、cursor 和 console switch 正常；
- [ ] framebuffer 失败可回退 VGA；
- [ ] quiet/diagnostic kernel 均满足 188 扇区上限；
- [ ] 旧 VGA suite 全部保持通过；
- [ ] framebuffer.core 通过并保存 1280×720 screenshot；
- [ ] QEMU-only、80×25、16 色和 full redraw 限制写入文档；
- [ ] 未修改 Loader、linker、syscall 和 process model。

---

## 20. 可直接执行的 Prompt

```text
请在 /home/orange/my_os 中严格按照
docs/one-day-qemu-framebuffer-compromise-plan.md 实施一天版 QEMU framebuffer。

本任务目标是 8–12 个 AI 小时内让正常演示完全不显示 VGA 文本模式，同时避免
Loader、linker、syscall、进程模型和 TTY 架构大修。

开始前：
1. 阅读完整方案、git status、当前所有 diff 和适用 AGENTS.md。
2. 当前 dirty worktree 属于用户；禁止 reset、checkout 覆盖、clean、删除、提交或 tag。
3. 记录 HEAD、quiet/diagnostic kernel.bin、make check、test-self、boot.quiet、
   tty.shell、input.stress 和 showcase.core artifacts。
4. 创建单独的本阶段 goal，不自动进入长期 framebuffer/高级 Shell 方案。

严格约束：
- 不修改 boot/mbr.S、boot/loader.S、kernel/linker.ld；
- 不新增 syscall；
- 不改变 struct process/thread；
- 只支持 QEMU stdvga 1234:1111；
- PCI BAR 必须读取和验证，不能只写死 0xFD000000；
- 固定 1280×720×32；
- 映射到独立高半区虚拟窗口；
- PSF2 字体从 MyFS 加载，不编译进 kernel.bin；
- 字体失败时在切换图形模式前回退 VGA；
- TTY cell/history/ANSI 保持不变；
- framebuffer active 时由软件 renderer 绘制 80×25 cells 和 cursor；
- 自动测试可启用隐藏 VGA mirror，正常 showcase mirror 必须关闭；
- 旧 suite 默认继续用 VGA backend。

按 T0 到 T5 实施。只有 framebuffer.core 和 VGA 回归全部通过后才能执行 T6 的
Shell 小增强。T6 最多包含彩色 Prompt、Left/Right、session history 和唯一 Tab；
不得加入 ghost、多列菜单、AST、PATH 或 Job Control。

尺寸门禁：
- 两种 kernel.bin 均不得超过 96,256 字节；
- BOOT_DIAGNOSTIC=0 可不链接 kernel/test.c；
- framebuffer 源使用 -Os；
- 字体必须留在 MyFS；
- 超限时裁剪功能，不修改 Loader。

最低验证：
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
- 最后尝试 make check-all

QEMU Unix socket 被沙箱拒绝时按权限流程重跑，标记为 INFRASTRUCTURE_ERROR，
不得修改 OS 规避宿主沙箱。

完成后报告：
1. PCI device、BAR base/size、mode 和 framebuffer virtual window；
2. PSF2 header、字体 SHA-256 和许可证；
3. quiet/diagnostic kernel.bin 前后大小；
4. 修改文件；
5. VGA fallback 和 mirror 行为；
6. 测试 seed/artifacts/screenshot；
7. 启动命令；
8. QEMU-only、80×25、16 色、full redraw 和 Shell 限制。

达到一天版完成标准后停止，不自动实现通用 VBE/GOP 或长期高级 Shell。
```
