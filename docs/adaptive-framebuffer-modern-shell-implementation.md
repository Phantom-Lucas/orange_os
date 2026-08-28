# 自适应 Framebuffer 与现代 Shell：当前实现

状态：已实施；最后更新：2026-08-20。

本文档是 framebuffer、现代 Shell 与显示性能的当前事实来源。设计取舍和未完成项见
[`adaptive-framebuffer-modern-shell-balanced-plan.md`](adaptive-framebuffer-modern-shell-balanced-plan.md)。

## 启动与回退

默认交互后端是 QEMU Standard VGA (`1234:1111`) 的 Bochs DISPI 线性 framebuffer，
使用 MyFS 内的 Terminus PSF2 12×24 字体、深紫配色和软件光标。首次启动或清理镜像后：

```bash
make bootstrap
make run
```

这会创建 256MiB 开发镜像，并在文件系统挂载后切换到图形 Shell；过渡阶段的启动文本
会被 framebuffer 初始化清除。VGA 文本模式不属于正常演示路径，只在诊断、自动测试或
显式回退时使用：

```bash
make CONSOLE_BACKEND=vga run
```

## 显示模式与终端几何

| `FB_MODE` | 终端几何 |
| --- | --- |
| `1024x768` | 81×30 |
| `1280x720`（默认） | 102×28 |
| `1440x900` | 116×35 |

模式在构建/启动时确定，不支持运行中的 QEMU 窗口 resize。独立展示镜像可用：

```bash
make FB_MODE=1280x720 fb-showcase-prepare
make fb-showcase
```

TTY 按当前 columns、visible rows 与 history rows 分配网格；PageUp/PageDown 按当前
可见行数滚动，不再依赖固定 80×25 网格。

## 2026-08-20：显示稳定性优化

早期 framebuffer renderer 在每次 TTY 输出时清除并重绘整屏。在默认 1280×720 模式下，
这会为一次普通按键写入约 2,856 个字符单元、约 3.3MiB 的未缓存 MMIO 像素，造成明显的
闪烁和输入卡顿。

现在 renderer 保存上一帧的可见字符网格，仅在下列情况绘制单元：

- 字符或颜色属性改变；
- 软件光标离开或进入该单元；
- 滚动、控制台切换或尺寸改变导致可见内容变化；
- framebuffer 首次启用（唯一的整屏清除场景）。

因此普通编辑通常只写变更字形及旧/新光标单元；滚动时仍会重绘受影响的可见行，但不再先
清屏。该策略消除了整屏清除带来的视觉闪烁，同时显著降低了键入路径的 MMIO 流量。

## Shell 交互

Shell 使用有界的 256 字节行缓冲和 64 条会话历史，支持：

- Left/Right/Home/End/Delete 与行中插入、删除；
- Up/Down 历史及草稿恢复；
- Ctrl+R 反向历史搜索；
- Ctrl+U、Ctrl+K、Ctrl+W 剪切与 Ctrl+Y kill-ring 粘贴；
- history prefix ghost suggestion，Right/End 接受建议；
- 内建命令的唯一或共同前缀 Tab 补全；
- 按当前终端可见行数翻页的 scrollback。

## 边界与回退

- framebuffer 初始化依赖 MyFS 中的 `terminal.psf`；失败时保留可诊断的 VGA TTY 回退。
- `BOOT_DIAGNOSTIC=1` 仍使用 VGA 后端，以满足固定 188-sector Loader 窗口内的详细诊断。
- 不支持宿主机剪贴板、鼠标选择、UTF-8/CJK、Job Control、持久化 history、多列补全菜单或实时语法高亮。
- framebuffer 不暴露给 Ring 3；用户态始终通过 TTY/syscall 输出。

## 验证记录

2026-08-20 的显示优化通过：

```text
make check
  kernel=95,372B / 96,256B Loader limit
make test CASE=framebuffer.core
make test CASE=shell.editor
git diff --check
```

测试运行器明确选择 VGA 回退作为文本快照 oracle；`framebuffer.core` 则以 QEMU screendump
校验图形模式、分辨率和深紫背景。镜像与测试产物的保留规则见
[`image-storage.md`](image-storage.md)。
