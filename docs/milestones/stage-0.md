# Stage 0 验收记录

- Commit：`7f228c3dfbe229194e4f1a186032c90afb25f639`
- Branch：`dev0714`
- Tag：未创建（当前工作树 dirty，等待维护者确认纳入范围）
- Date：2026-08-15（Asia/Shanghai）
- 状态：VERIFYING；测试和文档交付完成，源码冻结待人工确认

## 交付物

- [x] 工具链采集：`docs/baselines/2026-08/environment.txt`
- [x] 源码状态与产物摘要：`docs/baselines/2026-08/source.txt`、`artifacts.sha256`
- [x] 基线测试报告：`docs/baselines/2026-08/test-summary.md`
- [x] 缺陷登记：`docs/known-issues.md`
- [x] 统一 112/188、COW、回收语义和测试入口的文档事实来源已核对
- [x] 默认 `make check-all` 全部通过
- [ ] 维护者确认脏工作树纳入范围
- [ ] 创建可检出的基线分支、commit 和带注释 tag

## 最终验证

```text
make clean && make check                         PASS
make check-all                                   PASS
ARTIFACTS_DIR=build/baseline/2026-08/check-all-runner-final make check-all  PASS
./tests/collect_env.sh build/test-artifacts/environment-audit              PASS
```

历史完整回归日志：`build/baseline/2026-08/check-all-logs-final2/`。
最终统一 runner 门禁：`build/baseline/2026-08/check-all-runner-final/20260815-031259-144988-1786601191/`。
环境复核 artifact：`build/test-artifacts/environment-audit/environment.txt`。
QEMU 运行需要允许创建 Unix monitor socket；构建中的既有 `-Wdiv-by-zero` 警告来自故意的 fault 测试。

## 回退点

阶段 0 没有修改内核行为。源码冻结前不得执行 reset、checkout 或无差别提交；若需要回退测试基础设施，可使用保留的 legacy 脚本和旧 Make target。
