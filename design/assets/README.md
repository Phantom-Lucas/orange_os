# 答辩图片放置说明

该目录只放最终答辩使用的真实运行截图或本人绘制的架构图，不放 AI 生成的“运行效果图”。

建议从最终 tag 的测试 artifact 导出并重命名：

```text
01-framebuffer-terminal.png
02-guided-tour-pass.png
03-architecture.png          # 若 PPT 工具不能直接渲染 Mermaid
04-cow-flow.png              # 可选
```

当前候选 PPM 来源：

```text
build/baseline/2026-08/final-current/20260821-015007-212744-20260821/
  framebuffer/core/1/framebuffer-1280x720.ppm
  showcase/core/1/terminal-theme.ppm
```

提交前从最终 commit/tag 重跑测试，复制新 artifact 的截图并转换为 PNG；截图角注写明
case、seed、commit/tag。不要把 `build/` 整体放进提交压缩包。

