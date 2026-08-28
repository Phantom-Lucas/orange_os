# 镜像与测试产物空间规范

所有镜像均为可再生成产物，不能作为源码或唯一证据保存。

## 当前维护记录

- 2026-08-20：清理根目录遗留镜像、`build/` 历史镜像、测试产物和无界增长的 `qemu.log`，
  释放约 7.3GiB 空间；默认运行不再启用 QEMU 指令跟踪日志。
- 默认开发镜像固定为 256MiB，常规 QEMU 回归固定为 64MiB；只有 LBA48 专项允许创建
  256GiB 稀疏镜像。

| 场景 | 路径 | 逻辑容量 | 保留规则 |
| --- | --- | ---: | --- |
| 日常开发 | `build/images/orange-dev.img` | 256MiB | 默认镜像；`make clean-images` 可删除并由 `make bootstrap` 重建。 |
| 展示 | `build/images/orange-showcase.img` | 64MiB | 仅由 `make showcase-prepare` 或 `make fb-showcase-prepare` 创建。 |
| 常规 QEMU 回归 | `build/test-artifacts/.../work/disk.img` | 64MiB | 成功用例自动删除工作盘；失败用例保留以便诊断，问题处理后执行 `make clean-artifacts`。 |
| LBA48 专项 | `build/test-artifacts/.../lba48/.../disk.img` | 256GiB（稀疏） | 只允许 LBA48 测试创建；不作为默认开发盘或展示盘。 |

`build/fs.img` 与当前 `DISK_SIZE` 同步生成，且是稀疏文件。改变 `DISK_SIZE` 时必须使用新的 `DISK_IMAGE` 并运行 `make bootstrap`，避免把不同容量的 MyFS 写入同一镜像。

日常清理使用：

```bash
make clean-images
```

该命令只删除 `build/` 下可再生成的磁盘镜像、测试产物和根目录 `qemu.log`，不会删除 `kernel/`、`usr/`、`boot/`、`tools/`、`tests/` 或 `docs/` 中的代码与文档。需要只清理失败现场时使用 `make clean-artifacts`。
