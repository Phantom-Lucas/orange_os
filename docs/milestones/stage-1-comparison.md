# Stage 1 旧入口与统一 runner 对照

对照原则：旧脚本的历史完整回归日志作为迁移前证据；统一 runner 在相同
内核源码 HEAD 和相同测试语义下重新执行。比较最终断言集合和退出码，不要求
日志文本逐字一致。旧脚本仍保留，可直接复现；Make target 已转发到右侧 case。

| 旧脚本 / Make target | runner case | 旧 PASS 证据 | 新 PASS 证据 |
| --- | --- | --- | --- |
| `check_build.sh` / `make check` | `build.artifacts` | `check-all-logs-final2/01-build-quiet.log`、`02-build-diagnostic.log` | `check-all-runner-final/20260815-031259-144988-1786601191/build/artifacts/1/` |
| `mkfs_index.sh` / `make mkfs-index-check` | `mkfs.index` | `check-all-logs-final2/03-mkfs-index.log` | `.../mkfs/index/1/` |
| `mkfs_lba48.sh` / `make mkfs-lba48-check` | `mkfs.lba48` | `check-all-logs-final2/04-mkfs-lba48.log` | `.../mkfs/lba48/1/` |
| `qemu_lba48.sh` / `make qemu-lba48-check` | `lba48.boot` | `check-all-logs-final2/05-qemu-lba48.log` | `.../lba48/boot/1/` |
| `qemu_boot.sh` / `make qemu-boot-check` | `boot.quiet` | `check-all-logs-final2/06-boot-quiet.log` | `.../boot/quiet/1/` |
| `qemu_fs.sh` / `make qemu-fs-check` | `fs.service` | `check-all-logs-final2/07-filesystem.log` | `.../fs/service/1/` |
| `qemu_shell_fs.sh` / `make qemu-shell-fs-check` | `tty.shell` | `check-all-logs-final2/08-shell-tty.log` | `.../tty/shell/1/` |
| `qemu_userland.sh` / `make qemu-userland-check` | `userland.core` | `check-all-logs-final2/09-userland.log` | `.../userland/core/1/` |
| `qemu_input_stress.sh` / `make qemu-input-stress-check` | `input.stress` | `check-all-logs-final2/10-input-stress.log` | `.../input/stress/1/` |
| `qemu_sync.sh` / `make qemu-sync-check` | `sync.core` | `check-all-logs-final2/11-sync.log` | `.../sync/core/1/` |
| `qemu_vm.sh` / `make qemu-vm-check` | `vm.cow` | `check-all-logs-final2/12-virtual-memory.log` | `.../vm/cow/1/` |
| `qemu_smoke.sh` / `make qemu-check` | `integration.smoke` | `check-all-logs-final2/13-integration.log` | `.../integration/smoke/1/` |

其中 `.../` 均展开为：

```text
build/baseline/2026-08/check-all-runner-final/20260815-031259-144988-1786601191/
```

最终兼容入口 `make check-all` 已实际执行并返回 0；12 个 `result.env` 均为
`status=PASS`。runner artifacts 还记录 suite、case、seed、timeout、环境、
命令和 QEMU 退出码，旧脚本的失败现场则保留在 baseline 日志目录。
