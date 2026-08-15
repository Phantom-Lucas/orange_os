# 2026-08 基线

这是阶段 0 的工作区基线记录。源码基线指向当前 `HEAD`，但工作树在采集时是脏的；路线图要求的基线分支、提交和 tag 未在没有维护者确认的情况下创建。

## 采集内容

- [source.txt](source.txt)：commit、branch、tag 和工作树状态。
- [environment.txt](environment.txt)：工具链版本和仓库元数据。
- [artifacts.sha256](artifacts.sha256)：构建产物大小与 SHA-256。
- [test-summary.md](test-summary.md)：静态检查、完整回归和已知失败。
- [known-issues.md](../../known-issues.md)：失败项登记。

## 复现命令

```bash
make clean
make check
CHECK_LOG_DIR=build/baseline/2026-08/check-all-logs make check-all
```

完整回归需要允许 QEMU 创建 Unix monitor socket。所有完整回归日志保存在 `build/baseline/2026-08/`，没有复制大段日志进文档。
