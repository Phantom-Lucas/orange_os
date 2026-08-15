# 阶段 0 测试摘要

- 代码/测试冻结点：`e07f6a019c45df5e6268d5213985cddc7a4ec184`
- 基线分支：`baseline/2026-08`
- 最终 tag：`baseline-2026-08`（带注释，指向最终元数据提交）
- 工作树：代码/测试冻结时 clean
- 采集日期：2026-08-15（Asia/Shanghai）
- 构建警告：`kernel/shell.c:191` 的故意除零测试触发 GCC `-Wdiv-by-zero`，不影响 `make check`

## 结果

| Command | Result | Artifacts |
| --- | --- | --- |
| `make clean && make check` | PASS | 无独立日志；产物见 `artifacts.sha256` |
| `make check-all`（受限环境首次运行） | BLOCKED | `build/baseline/2026-08/check-all-logs/05-qemu-lba48.log`；QEMU monitor socket 被 sandbox 拒绝 |
| `make check-all`（受控权限） | FAIL / flaky | `build/baseline/2026-08/check-all-logs/06-boot-quiet.log` |
| 独立 `bash -x tests/qemu_boot.sh` | PASS | 复现输出显示四条启动断言均通过 |
| LBA48 后顺序执行 `bash -x tests/qemu_boot.sh` | FAIL / flaky | VGA 快照抓到屏幕更新中间态 |
| `make check-all` 重跑（受控权限） | FAIL / flaky | `build/baseline/2026-08/check-all-logs-rerun/06-boot-quiet.log` |
| `QEMU_BOOT_WAIT=20 make check-all`（受控权限） | FAIL / flaky | build、LBA48、boot、filesystem、shell-tty、userland、input-stress、sync、VM 通过；`build/baseline/2026-08/check-all-logs-stabilized/13-integration.log` |
| `QEMU_BOOT_WAIT=20 make qemu-check`（修复后） | PASS | integration smoke 全链路通过 |
| `QEMU_BOOT_WAIT=20 make check-all`（修复后） | PASS | `build/baseline/2026-08/check-all-logs-final/` |
| `make qemu-sync-check`（child-reap 修复后） | PASS | sync demo、reap 和资源基线均通过 |
| `make check-all`（默认参数，最终） | PASS | `build/baseline/2026-08/check-all-logs-final2/` |

## 冻结提交最终验证

在 `e07f6a0` 上使用 seed `20260815` 执行统一 runner full profile，12/12
case 全部 PASS：

```text
ARTIFACTS_DIR=build/baseline/2026-08/frozen-check-all-final2 \
  ./tests/run.sh --profile full --seed 20260815 --keep-failed
PASS all selected cases
```

最终 artifacts：
`build/baseline/2026-08/frozen-check-all-final2/20260815-101753-178844-20260815/`。
冻结前的 boot VGA 交错快照失败保留在
`build/baseline/2026-08/frozen-check-all/20260815-101349-176348-20260815/boot/quiet/1/`，
并由 `e07f6a0` 的 stop/pmemsave/cont 原子快照修复。

## 失败分析

`qemu-lba48` 在受控权限下通过。随后 `qemu_boot.sh` 偶尔从 VGA 文本显存读取到交错内容：`[BOOT] shell ready` 被拆分为 `[BOOTOrange'S user shell ready...` 和后续的 `] shell ready`，因此逐行 `grep` 失败。独立 boot 测试通过，当前登记为 `FLAKY-001`，不将其当作已证明的内核启动回归。

在提高 boot 等待时间后，完整矩阵曾在 integration 暴露 `processes=3 threads=6`；随后增加 `run: child completed` 回收事件等待，单独 qemu-check 与完整矩阵均通过。该历史失败保留在 `check-all-logs-stabilized/13-integration.log`，当前按 `FLAKY-002` RESOLVED 处理。

阶段 1 统一 runner 验证：`./tests/selftest_runner.sh`、`make test-fast`、迁移后的 `integration.smoke`、`lba48.boot` 和默认完整 `--profile full` 均 PASS；历史完整 runner artifact 位于 `test-all-final/20260815-024249-125464-20260815/`，冻结提交的最终 artifact 位于 `frozen-check-all-final2/20260815-101753-178844-20260815/`。full profile 包含原 `check-all` 的 stress case。

最终兼容门禁：`ARTIFACTS_DIR=build/baseline/2026-08/check-all-runner-final make check-all` PASS；artifact 位于 `check-all-runner-final/20260815-031259-144988-1786601191/`。

默认参数的完整矩阵已在修复 boot 快照和 child-reap 等待后通过。维护者已确认纳入全部 dirty worktree 修改，并完成基线分支、commit 和 annotated tag。
