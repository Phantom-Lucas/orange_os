# Stage 1 进展记录：统一测试 runner

- Commit：`7f228c3dfbe229194e4f1a186032c90afb25f639`（工作树 dirty）
- Date：2026-08-15（Asia/Shanghai）
- Test protocol：runner manifest v1（结构化事件仍待阶段 2）
- 状态：DONE；统一 runner、全部 suite 迁移、兼容入口和最终门禁均已通过

## 已交付

- `tests/run.sh`：list、suite/case 过滤、repeat、seed、profile、timeout、artifacts 和统一退出码。
- `tests/manifest.sh`：12 个 suite/case 声明，重复 ID、非法 profile/timeout 和空 manifest 会返回配置错误。
- `tests/lib/`：common、QEMU 生命周期、monitor/VGA、image、assertions、artifacts 和事件接口。
- `tests/selftest_runner.sh`：list 不执行、过滤、超时=4、失败现场、重复 manifest 和 SIGTERM cleanup 自测通过。
- `make test-list`、`make test-fast`、`make test-all`、`make test`、`make test-self`。
- build、mkfs、boot、LBA48、VM、sync、userland、FS、TTY、input 和 integration 已使用公共 runner 实现。
- 所有旧 `qemu-*-check`、`mkfs-*-check` 入口保留并转发到对应 runner case；旧脚本保留在原位置，便于逐项对照。
- `qemu_smoke.sh` 和统一 integration suite 的 sync 回收断言均等待明确的 child-completed 事件，关闭 `FLAKY-002`。
- `test-fast`、runner selftest、独立迁移 case 和完整 `test-all` 均有独立 PASS 证据。
- 旧脚本与新 case 的逐项断言/退出码对照见 [`stage-1-comparison.md`](stage-1-comparison.md)。

## 验证证据

```text
./tests/selftest_runner.sh                                      PASS
make test-fast                                                   PASS
make qemu-boot-check                                             PASS
tests/run.sh --case boot.quiet                                  PASS
tests/run.sh --case vm.cow                                      PASS
tests/run.sh --case userland.core                               PASS
tests/run.sh --case fs.service                                  PASS
SYNC_TEST_ROUNDS=1 SYNC_WORKER_ROUNDS=2000 tests/run.sh ...     PASS
SYNC_TEST_ROUNDS=100 SYNC_WORKER_ROUNDS=20000 tests/run.sh ...   PASS
./tests/run.sh --case integration.smoke                         PASS
./tests/run.sh --case lba48.boot                                PASS
ARTIFACTS_DIR=... ./tests/run.sh --profile full                 PASS
ARTIFACTS_DIR=... make check-all                                PASS
```

完整 QEMU 命令均在受控权限下运行，以允许 Unix monitor socket。每个 case 的详细日志和镜像位于对应 `build/test-artifacts/<run-id>/` 目录。

## 待办与门禁

- [x] 迁移 tty/shell 交互、input stress 和 integration smoke，去掉 runner 内重复的 QEMU/monitor 实现。
- [x] 为旧入口逐项建立新旧断言对照记录。
- [x] 让 `make check-all` 在稳定周期后转发到 `test-all`。
- [x] 解决 `FLAKY-002` 的固定 sleep/回收时序问题。
- [x] 阶段完成前运行完整 `make check-all`，确认没有减少断言。

旧脚本完整回归证据保留在 `build/baseline/2026-08/check-all-logs-final2/`；统一 runner 的完整矩阵通过，日志和现场位于
`build/baseline/2026-08/test-all-final/20260815-024249-125464-20260815/`。最终兼容入口
`make check-all` 也已通过，artifact 位于
`build/baseline/2026-08/check-all-runner-final/20260815-031259-144988-1786601191/`。
迁移前后的对照以相同 suite/case 断言和退出码为准，旧日志作为参照，新 runner artifact 记录 seed、timeout、环境和 QEMU 退出码。

## 回退点

所有未迁移的旧脚本和旧 Make target 仍保留；若 runner case 有问题，可直接执行相应 legacy 脚本对照，不需要修改内核或磁盘格式。
