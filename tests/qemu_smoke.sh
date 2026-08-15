#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-qemu-check.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
QEMU_MEMORY="${QEMU_MEMORY:-512M}"
QEMU_MONITOR_TIMEOUT="${QEMU_MONITOR_TIMEOUT:-1}"
# 用户进程退出后，Shell 还需要完成 wait、重绘提示符并消费最后一个
# 键盘事件。1 秒在重复 fork/exec 后偶发地把下一条命令送入旧状态；3 秒
# 仍不会改变内核语义，但能让集成测试默认稳定，不依赖外部环境变量。
QEMU_COMMAND_SETTLE="${QEMU_COMMAND_SETTLE:-3}"

cleanup() {
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

monitor() {
    printf '%s\n' "$@" |
        timeout --signal=TERM --kill-after=1 "$QEMU_MONITOR_TIMEOUT" \
            nc -N -U -w 2 "$MONITOR" >/dev/null
}

start_qemu() {
    rm -f "$MONITOR" "$VGA_IMAGE"
    qemu-system-x86_64 \
        -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
        -m "$QEMU_MEMORY" -display none \
        -monitor "unix:$MONITOR,server,nowait" \
        -no-reboot -no-shutdown >/dev/null 2>&1 &
    QEMU_PID=$!

    for _ in $(seq 1 50); do
        [ -S "$MONITOR" ] && break
        sleep 0.1
    done
    [ -S "$MONITOR" ] || { echo "[qemu-check] monitor did not start" >&2; exit 1; }
    # 内核启动阶段还包含用户态文件系统验收，等待其完成后再检查 Shell。
    sleep "${QEMU_BOOT_WAIT:-15}"
}

send_text() {
    local text=$1
    local i ch key
    for ((i = 0; i < ${#text}; i++)); do
        ch=${text:i:1}
        case "$ch" in
            ' ') key=spc ;;
            '.') key=dot ;;
            '-') key=minus ;;
            *) key=$ch ;;
        esac
        monitor "sendkey $key"
        # 8042 控制器只有极小的输入缓冲；逐键留出处理时间，避免把
        # "persist" 之类的命令截断成前几个字符。
        sleep 0.35
    done
    monitor "sendkey ret"
    # After a long-running user process exits, let the Shell redraw its prompt
    # and let the monitor finish the final keyboard event before the next
    # command is injected.
    sleep "$QEMU_COMMAND_SETTLE"
}

decode_vga() {
    od -An -v -w2 -tu1 "$VGA_IMAGE" |
        awk '{printf "%c", $1; if (NR % 80 == 0) printf "\n"}' |
        tr -d '\000'
}

capture_vga() {
    monitor "pmemsave 0xb8000 0xfa0 \"$VGA_IMAGE\""
    decode_vga
}

capture_and_stop() {
    monitor "pmemsave 0xb8000 0xfa0 \"$VGA_IMAGE\"" "quit"
    wait "$QEMU_PID"
    QEMU_PID=""
    decode_vga
}

wait_for_vga_contains() {
    local expected=$1
    local timeout=${2:-60}
    local deadline=$((SECONDS + timeout))
    local output=""

    while (( SECONDS < deadline )); do
        output=$(capture_vga)
        if grep -Fq "$expected" <<<"$output"; then
            printf '%s\n' "$output"
            return 0
        fi
        if grep -Fq "sync demo FAILED" <<<"$output" ||
           grep -Fq "[VM] COW/mmap demo FAILED" <<<"$output"; then
            printf '%s\n' "$output" >&2
            return 1
        fi
        sleep 1
    done

    printf '%s\n' "$output" >&2
    echo "[qemu-check] timed out waiting for: $expected" >&2
    return 1
}

assert_contains() {
    local output=$1
    local expected=$2
    if ! grep -Fq "$expected" <<<"$output"; then
        echo "[qemu-check] missing: $expected" >&2
        echo "$output" >&2
        exit 1
    fi
}

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
make -B SYNC_TEST_ROUNDS="${SYNC_TEST_ROUNDS:-100}" \
    SYNC_WORKER_ROUNDS="${SYNC_WORKER_ROUNDS:-20000}" \
    VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" check >/dev/null
# 超级块位于 MyFS 相对块 1，total_blocks 是其中第 6 个 uint32_t（偏移
# 4096+20）。直接检查本次构建产物，避免启动后 VGA 最后一屏已滚过容量日志。
fs_blocks=$(od -An -j 4116 -N 4 -tu4 "$ROOT_DIR/build/fs.img" | tr -d ' ')
if [ "$fs_blocks" != "2097027" ]; then
    echo "[qemu-check] unexpected default MyFS block count: $fs_blocks" >&2
    exit 1
fi
make DISK_IMAGE="$DISK_IMAGE" bootstrap >/dev/null

# 首次启动会运行 fork/exit/wait 自检；通过后才会进入用户态 Shell。
start_qemu
first_boot=$(capture_and_stop)
assert_contains "$first_boot" "Orange'S user shell ready"

# 写入文件后重启，确认 MyFS 真实持久化而不是仅内存缓存。
start_qemu
send_text "write persist persist-hello"
sleep 2
capture_and_stop >/dev/null

start_qemu
send_text "cat persist"
sleep 1
persistence_boot=$(capture_vga)
assert_contains "$persistence_boot" "persist-hello"

# 在同一轮 Shell 中反复验证 fork/exit/wait，观察每轮结束后的资源是否回收。
for _ in 1 2 3; do
    send_text "run hello.elf"
    sleep 2
done

# exec-demo 先由 Shell spawn，再以 SYS_EXEC 装载 hello.elf；重复执行成功
# 路径，并用不存在的文件覆盖失败路径。
for _ in 1 2; do
    send_text "run exec-demo.elf"
    sleep 2
done
send_text "exec missing.elf"
sleep 1
exec_boot=$(capture_vga)
assert_contains "$exec_boot" "exec demo: replacing image through FS service"
assert_contains "$exec_boot" "exec: executable not found"

# 验证 Ring 3 同步 IPC：父进程先发送并阻塞，子进程接收后唤醒父进程。
send_text "run ipc-demo.elf"
sleep 2

# 验证所有用户指针都经过完整范围检查：低地址、跨页、非法字符串，
# 以及可能阻塞的 TTY/FS/IPC 输出缓冲区。
send_text "run uaccess-demo.elf"
sleep 3
pre_thread_boot=$(capture_vga)
assert_contains "$pre_thread_boot" "IPC user demo PASSED"
assert_contains "$pre_thread_boot" "uaccess demo PASSED"

# 验证同一用户进程的独立用户栈、共享数据、thread_join、重复创建回收，
# 以及多线程 fork/exec 拒绝和最后线程/进程级清理路径。
for _ in 1 2; do
    send_text "run thread-demo.elf"
    sleep 4
done
pre_sync_boot=$(capture_vga)
assert_contains "$pre_sync_boot" "thread demo PASSED"

# 用户态同步验收：程序内部连续运行 100 轮，覆盖 1/2/4/8/16 线程
# mutex 竞争、条件变量、TLS、detach 自动回收和非法 futex 地址。
send_text "run sync-demo.elf"
sync_boot=$(wait_for_vga_contains "sync demo PASSED" "${SYNC_WAIT_SECONDS:-900}")
assert_contains "$sync_boot" "sync demo PASSED"
wait_for_vga_contains "run: child completed" "${SYNC_REAP_WAIT_SECONDS:-30}" >/dev/null
sync_reaped=$(capture_vga)
assert_contains "$sync_reaped" "sync demo PASSED"
assert_contains "$sync_reaped" "futex_waiters=0"
assert_contains "$sync_reaped" "processes=2 threads=5"
# 当前 Shell ELF 扩展后基线为 7 个用户映射页；引用数必须逐页一致，
# 这比沿用旧版 Shell 的 6 页基线更能直接发现 COW/refcount 泄漏。
assert_contains "$sync_reaped" "user_mapped=7 user_refs=7"

# COW fork、匿名 mmap/部分 munmap 和用户栈按需增长回归。
send_text "run vm-demo.elf"
vm_boot=$(wait_for_vga_contains "[VM] COW/mmap demo PASSED" "${VM_WAIT_SECONDS:-120}")
assert_contains "$vm_boot" "[VM] COW/mmap demo PASSED"
# The VM demo reports success immediately before its parent Shell reaps it.
# Wait for that reap/prompt transition before injecting the next command.
wait_for_vga_contains "run: child completed" "${VM_REAP_WAIT_SECONDS:-30}" >/dev/null

# 验证用户态页错误只会结束子进程，Shell 和内核都能继续运行。
send_text "run fault.elf"
sleep 2
verification_boot=$(capture_and_stop)
assert_contains "$verification_boot" "run: child completed"
assert_contains "$verification_boot" "processes=2 threads=5"
assert_contains "$verification_boot" "user_mapped=7 user_refs=7"
assert_contains "$verification_boot" "[Ring 3] deliberate page fault"
assert_contains "$verification_boot" "run: child terminated by exception"

echo "[qemu-check] boot, fork, persistence, shell, spawn/wait, user IPC, fault isolation: PASSED"
