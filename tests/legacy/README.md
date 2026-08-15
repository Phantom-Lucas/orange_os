# Legacy test scripts

阶段 1 迁移期间保留旧的 `tests/check_*.sh`、`tests/mkfs_*.sh` 和
`tests/qemu_*.sh` 脚本，保证直接调用方式和迁移对照点不变。

统一 runner 的 manifest 已为它们提供稳定的 suite/case 名称。所有当前
`qemu-*-check` 和 `mkfs-*-check` Make target 已转发到对应的
`tests/run.sh --case suite.case`；旧脚本仍可直接执行，用于比较断言和退出码。
