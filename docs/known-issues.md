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
状态: RESOLVED（2026-08-15；Shell 启动前完成内核标记输出，启动后终端只由 TTY/Shell 更新）
类型: flaky-test
首次发现版本: ca8b1cc（全部 dirty worktree 修改纳入后的初始基线提交）
影响 suite/case: boot.quiet；`make check-all` 中 `qemu-lba48` 后的 `qemu-boot-check`
最小复现命令: `make qemu-lba48-check` 后执行 `bash -x tests/qemu_boot.sh`（需允许 QEMU Unix monitor socket）
期望结果: VGA 快照分别包含独占一行的 `[BOOT] launching shell`、`Orange/64 Terminal`，以及 `orange@orange-os:/$`
实际结果: 偶尔在屏幕更新中间态读取 VGA，`[BOOT] shell ready` 被拆行并与 Shell 欢迎语交错，导致 grep 失败；独立重复 boot 可通过
artifacts 路径: `build/baseline/2026-08/check-all-logs/06-boot-quiet.log`、`build/baseline/2026-08/check-all-logs-rerun/06-boot-quiet.log`、`build/baseline/2026-08/frozen-check-all/20260815-101349-176348-20260815/boot/quiet/1/`
临时规避方式: 保留失败日志并单独重跑；不得用无限重试将其标记为通过
关闭条件: 已满足；除使用 `monitor_capture_vga_stopped` 获取稳定快照外，内核现在于 `execute_elf("shell.elf")` 前输出 `[BOOT] launching shell`，成功启动后不再与用户 Shell 竞争 TTY 光标；boot 测试同时断言启动标记和欢迎标题各自独占一行

ID: FLAKY-002
状态: RESOLVED（2026-08-15；等待 `run: child completed` 后再取资源快照）
类型: flaky-test
首次发现版本: ca8b1cc（全部 dirty worktree 修改纳入后的初始基线提交）
影响 suite/case: integration；`qemu_smoke.sh` 的 sync-demo 回收断言
最小复现命令: `QEMU_BOOT_WAIT=20 make qemu-check`（需允许 QEMU Unix monitor socket）
期望结果: sync-demo 完成后资源快照包含 `processes=2 threads=5`
实际结果: `sync demo PASSED` 已出现，但紧邻的 `after-wait` 快照偶尔仍为 `processes=3 threads=6`；集成脚本以固定等待时间替代稳定的退出/回收事件，随后断言失败
artifacts 路径: `build/baseline/2026-08/check-all-logs-stabilized/13-integration.log`
临时规避方式: 保留失败现场；增加等待时间只能用于诊断，不能当作关闭条件
关闭条件: 已满足；`QEMU_BOOT_WAIT=20 make qemu-check`、统一 `integration.smoke` 和完整 runner 矩阵均通过，并保留该事件等待语义

阶段 0 已冻结为可检出的 `baseline/2026-08` 分支和 `baseline-2026-08` annotated tag；source、environment、产物哈希和完整测试结果均已更新到冻结证据。
