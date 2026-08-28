# Orange/64 VGA 终端现场演示脚本

这份脚本面向 10 分钟的 VGA 文本模式演示。它不需要图形终端，也不依赖默认的
100 轮同步压力测试；`demo` 自己只运行短小、确定性的用户态场景。

## 演示前准备

在仓库根目录执行：

```bash
git status --short --branch
make check
make showcase-prepare
```

确认 `make check` 输出的 `kernel.bin` 小于 `96256B`。第一次 `showcase-prepare` 会
格式化演示盘并写入用户程序；之后只用 `make showcase`，不要再次执行
`make showcase-prepare`，这样才能看到 proof 文件的持久化效果。

## 逐分钟脚本

### 00:00-01:00 - 启动与终端主题

```bash
make SHOWCASE_MEMORY=512M showcase
```

预期先看到深紫底、柔和白字的 VGA 文本、启动摘要和：

```text
Orange/64 Terminal
Type 'help' to list commands.

orange@orange-os:/$
```

窗口标题应为 `Orange/64 Terminal`；窗口边框和关闭按钮由宿主机提供，Guest 仍是
80x25 VGA 文本模式。

### 01:00-02:00 - help 与 Prompt

```text
help
```

指出 Commands 和 Keyboard 两组纵向列表均不超过 80 列。可见 Prompt 是
`orange@orange-os:/$`；输入 `cd /` 后 Prompt 不应改变可见语义。

### 02:00-03:00 - about 与系统观察

```text
about
ps
```

`about` 清屏并重绘简洁欢迎页；`ps` 的最后一列是 `USERPAGES`，原有 PID、PPID、
STATE、THREADS、NAME 列仍保留。

### 03:00-05:00 - 一键 guided tour

```text
demo
```

等待程序返回 prompt。预期结构为：

```text
ORANGE/64 GUIDED TOUR
[1/6] SYSTEM
[2/6] PROCESS + COW
[3/6] IPC
[4/6] THREADS
[5/6] FILESYSTEM
[6/6] FAULT ISOLATION
RESULT 6 passed 0 failed
orange@orange-os:/$
```

每一步还会打印 input、actual、expect 和 PASS/FAIL。PID、ticks、TID、页数和 fault
退出状态是动态值；固定检查点是六个步骤、COW 的 `0x1111/0x2222`、IPC 的
`0xC0DE`、最终汇总和 prompt 恢复。

### 05:00-06:00 - 查看保留文件

```text
cat demo-proof.txt
```

预期内容：

```text
ORANGE/64 showcase proof v1
```

这个文件由 showcase 成功创建或截断后保留，不要删除它。

### 06:00-07:00 - 终端控制与重绘

```text
about
help
```

演示 Ctrl+L 清屏、Ctrl+U 清空当前行、Ctrl+W 删除前一个单词；可用 F1/F2/F3
切换三个文本 console，再用 PageUp/PageDown 查看历史。不要在演示中发送 Unicode 或
图形字符，系统明确只支持 ASCII VGA 文本。

### 07:00-08:00 - 故障隔离备份

若希望单独展示异常隔离：

```text
run fault.elf
```

预期看到 Ring 3 page fault 的子进程退出，随后 Shell 重新显示 prompt，而不是内核
panic 或 QEMU 重启。

### 08:00-09:00 - 重启持久化

退出 QEMU 后再次启动：

```bash
make showcase
```

进入 Shell 后执行：

```text
cat demo-proof.txt
```

仍应得到 `ORANGE/64 showcase proof v1`。这一步证明 `demo-proof.txt` 来自 MyFS
磁盘，而不是只存在于上一次内核的内存中。

### 09:00-10:00 - 收尾与限制

展示 `help` 或 `about`，总结：用户态 showcase 复用了现有 syscall，主题使用 VGA DAC
而不是 framebuffer；没有 GUI、Unicode、动态字体或展示专用内核 syscall。最后说明
Loader 的内核窗口仍固定为 188 sectors / 96,256B，默认 full 压力同步测试在较慢
宿主机上可能达到 900 秒门限，不能把低轮次回归当作 full PASS。

## 自动化复核与失败备份

可在另一终端执行完整 showcase 验收：

```bash
make test CASE=showcase.core SEED=20260815 KEEP_FAILED=1
```

它会使用公共 runner/QEMU/monitor 库，自动检查六个步骤、`RESULT 6 passed 0 failed`、
Prompt、proof 内容、重启持久化和真实颜色。artifact 保存在 `build/test-artifacts/`
下对应的 run 目录，PPT 截图为其中的 `terminal-theme.ppm`；本轮示例路径为
`build/test-artifacts/20260815-180436-12425-1786775869/showcase/core/1/terminal-theme.ppm`。

如果 `demo` 某一步失败，保留现场后依次运行：

```text
run vm-demo.elf
run ipc-demo.elf
run thread-demo.elf
run fs-demo.elf
run fault.elf
```

如果只有 proof 文件缺失，可手工执行 `write demo-proof.txt ORANGE/64 showcase proof v1`
展示文件 API，然后用 `cat` 验证；这只能作为文件系统展示备份，不能替代六步 showcase
的 PASS。若自动化 runner 报 `INFRASTRUCTURE_ERROR`，先保留 artifact 并确认 Unix
monitor socket 权限；不要把它记为内核失败，也不要把未完成的低轮次结果改写成 full
PASS。
