# Known Issues

本文档登记阶段基线和后续回归中发现、尚未关闭的问题。每个条目必须使用唯一 ID，并保留最小复现命令和 artifacts 路径；没有证据的失败不得标记为已知问题后忽略。

## 状态约定

- `BUG-*`：已有能力偏离既定行为，阻止对应阶段通过。
- `LIMIT-*`：尚未承诺实现的能力。
- `FLAKY-*`：相同 commit 和 seed 下结果不稳定。
- `DOC-*`：文档与源码或测试不一致。

## 条目模板

```text
ID: BUG-xxx 或 LIMIT-xxx
类型: regression | known-limitation | flaky-test | documentation
首次发现版本: commit ID
影响 suite/case:
最小复现命令:
期望结果:
实际结果:
artifacts 路径:
临时规避方式:
关闭条件:
```

## 当前登记

ID: FLAKY-001
状态: MITIGATED（统一 runner/兼容 Make 入口已稳定；legacy 直接脚本仍保留原 VGA 快照实现）
类型: flaky-test
首次发现版本: 7f228c3dfbe229194e4f1a186032c90afb25f639（工作树 dirty）
影响 suite/case: boot.quiet；`make check-all` 中 `qemu-lba48` 后的 `qemu-boot-check`
最小复现命令: `make qemu-lba48-check` 后执行 `bash -x tests/qemu_boot.sh`（需允许 QEMU Unix monitor socket）
期望结果: VGA 快照同时包含 `[BOOT] kernel ready`、`[BOOT] storage ready`、`[BOOT] shell ready` 和 `orange:/$`
实际结果: 偶尔在屏幕更新中间态读取 VGA，`[BOOT] shell ready` 被拆行并与 Shell 欢迎语交错，导致 grep 失败；独立重复 boot 可通过
artifacts 路径: `build/baseline/2026-08/check-all-logs/06-boot-quiet.log`、`build/baseline/2026-08/check-all-logs-rerun/06-boot-quiet.log`
临时规避方式: 保留失败日志并单独重跑；不得用无限重试将其标记为通过
关闭条件: 统一 runner 使用稳定事件/串口或旧 VGA 读取具备稳定快照后，在相同 commit 和 seed 下完成 full 回归

ID: FLAKY-002
状态: RESOLVED（2026-08-15；等待 `run: child completed` 后再取资源快照）
类型: flaky-test
首次发现版本: 7f228c3dfbe229194e4f1a186032c90afb25f639（工作树 dirty）
影响 suite/case: integration；`qemu_smoke.sh` 的 sync-demo 回收断言
最小复现命令: `QEMU_BOOT_WAIT=20 make qemu-check`（需允许 QEMU Unix monitor socket）
期望结果: sync-demo 完成后资源快照包含 `processes=2 threads=5`
实际结果: `sync demo PASSED` 已出现，但紧邻的 `after-wait` 快照偶尔仍为 `processes=3 threads=6`；集成脚本以固定等待时间替代稳定的退出/回收事件，随后断言失败
artifacts 路径: `build/baseline/2026-08/check-all-logs-stabilized/13-integration.log`
临时规避方式: 保留失败现场；增加等待时间只能用于诊断，不能当作关闭条件
关闭条件: 已满足；`QEMU_BOOT_WAIT=20 make qemu-check`、统一 `integration.smoke` 和完整 runner 矩阵均通过，并保留该事件等待语义

阶段 0 当前仍未冻结为可检出的 commit/tag；维护者确认纳入范围后需重新采集 source、environment 和完整测试结果。
