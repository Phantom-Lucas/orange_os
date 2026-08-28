# Orange/64 文档导航

## 当前使用与当前状态

| 文档 | 用途 |
| --- | --- |
| [项目总览](project-overview.md) | 功能边界、构建、启动与测试入口。 |
| [Framebuffer 与现代 Shell 当前实现](adaptive-framebuffer-modern-shell-implementation.md) | 默认图形 Shell、显示模式、显示性能和交互边界。 |
| [镜像与测试产物空间规范](image-storage.md) | 开发/测试镜像容量、位置和清理命令。 |
| [已知问题](known-issues.md) | 未关闭问题、复现方式和关闭条件。 |

## 设计与源码阅读

| 文档 | 用途 |
| --- | --- |
| [完整设计与实现](oranges-design-implementation.md) | 内核、用户态、文件系统和测试的详细设计。 |
| [源码阅读指南](project-code-reading-guide.md) | 按模块阅读源码的入口。 |
| [路线图](oranges-roadmap.md) | 中长期功能方向。 |

## 计划与历史记录

计划文档记录当时的取舍，不替代“当前使用与当前状态”中的操作说明：

- [自适应 framebuffer 与现代 Shell 平衡方案](adaptive-framebuffer-modern-shell-balanced-plan.md)
- [现代控制台与高级 Shell 长期方案](modern-console-advanced-shell-execution-plan.md)
- [QEMU framebuffer 折中方案](one-day-qemu-framebuffer-compromise-plan.md)
- [现代 Shell 一日行动计划](one-day-modern-shell-action-plan.md)
- [VGA 主题行动计划](vga-terminal-theme-action-plan.md)
- [执行路线图](roadmap-execution-plan.md)

历史测试证据位于 `baselines/` 与 `milestones/`；演示材料见
[presentation-demo.md](presentation-demo.md)。
