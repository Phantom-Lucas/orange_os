# 2026-08 基线

这是阶段 0 的可检出基线记录。代码/测试冻结点为
`e07f6a019c45df5e6268d5213985cddc7a4ec184`，分支为
`baseline/2026-08`，最终元数据提交打上 `baseline-2026-08` annotated tag。

## 采集内容

- [source.txt](source.txt)：commit、branch、tag 和工作树状态。
- [environment.txt](environment.txt)：工具链版本和仓库元数据。
- [artifacts.sha256](artifacts.sha256)：构建产物大小与 SHA-256。
- [test-summary.md](test-summary.md)：静态检查、完整回归和已知失败。
- [known-issues.md](../../known-issues.md)：失败项登记。

## 复现命令

```bash
make check
ARTIFACTS_DIR=build/baseline/2026-08/frozen-check-all-final2 \
  ./tests/run.sh --profile full --seed 20260815
```

完整回归需要允许 QEMU 创建 Unix monitor socket。所有完整回归日志保存在 `build/baseline/2026-08/`，没有复制大段日志进文档。
