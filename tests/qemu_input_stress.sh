#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-input-stress.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
QEMU_KEY_DELAY="${QEMU_KEY_DELAY:-0.35}"
QEMU_MONITOR_TIMEOUT="${QEMU_MONITOR_TIMEOUT:-1}"
QEMU_SEND_TIMEOUT="${QEMU_SEND_TIMEOUT:-20}"
QEMU_COMMAND_DELAY="${QEMU_COMMAND_DELAY:-1}"
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
truncate -s 64M "$DISK_IMAGE"
make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=64M bootstrap >/dev/null
qemu-system-x86_64 -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-512M}" -display none \
    -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown \
    >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do [ -S "$MONITOR" ] && break; sleep .1; done
[ -S "$MONITOR" ]
sleep "${QEMU_BOOT_WAIT:-15}"

send_text_slow() {
    local text=$1 ch key i
    {
        for ((i = 0; i < ${#text}; i++)); do
            ch=${text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
                *) key=$ch;;
            esac
            send_key "$key"
            # 启动 Ctrl+C 被测任务时先使用可靠的 PS/2 注入节奏；后面的
            # 连续命令仍使用快速压力路径。
            sleep "$QEMU_KEY_DELAY"
        done
        send_key ret
    }
}

monitor_command() {
    local limit="${1:-$QEMU_MONITOR_TIMEOUT}"
    timeout --signal=TERM --kill-after=1 "$limit" \
        nc -q 0 -U -w 3 "$MONITOR"
}

send_stream() {
    timeout --signal=TERM --kill-after=1 "$QEMU_SEND_TIMEOUT" \
        nc -U -w 3 "$MONITOR"
}

send_key() {
    printf 'sendkey %s\n' "$1" | monitor_command >/dev/null
}

send_fast_echo_batch() {
    local i ch key text j
    for i in $(seq 1 20); do
        if [ "$i" -eq 20 ]; then text="echo stress-20"; else text="echo x"; fi
        for ((j = 0; j < ${#text}; j++)); do
            ch=${text:j:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
                *) key=$ch;;
            esac
            send_key "$key"
            # The paced per-key path is deliberate: it exercises the real
            # keyboard queue without letting QEMU monitor batching drop keys.
            sleep "$QEMU_KEY_DELAY"
        done
        send_key ret
        # Let the Shell consume the complete line and return to its prompt
        # before injecting the next line; this still creates repeated input
        # pressure without racing command execution itself.
        sleep "$QEMU_COMMAND_DELAY"
    done
}

capture_vga() {
    printf 'pmemsave 0xb8000 0xfa0 "%s"\n' "$VGA_IMAGE" |
    monitor_command >/dev/null
    od -An -v -w2 -tu1 "$VGA_IMAGE" |
        awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000'
}

wait_for_output() {
    local expected=$1
    local timeout_seconds=${2:-60}
    local deadline=$((SECONDS + timeout_seconds))
    local output=""
    while (( SECONDS < deadline )); do
        output=$(capture_vga)
        if grep -Fq "$expected" <<<"$output" &&
           grep -Fq "orange:/$" <<<"$output"; then
            printf '%s\n' "$output"
            return 0
        fi
        if grep -Fq "KERNEL PANIC" <<<"$output" ||
           grep -Fq "System Halted" <<<"$output"; then
            printf '%s\n' "$output" >&2
            return 1
        fi
        sleep 1
    done
    printf '%s\n' "$output" >&2
    return 1
}

# 空闲 Shell 上先验证 Ctrl+C 的扫描码和行编辑路径；有前台任务时同一个
# 控制键应转而终止目标进程而不进入 Shell 输入队列。
printf 'sendkey ctrl-c\n' | monitor_command >/dev/null
sleep 1
idle_control_output=$(capture_vga)
if ! grep -Fq "^C" <<<"$idle_control_output" ||
   ! grep -Fq "orange:/$" <<<"$idle_control_output"; then
    echo "$idle_control_output" >&2
    echo "[qemu-input-stress] Ctrl+C scan code was not handled by the Shell" >&2
    exit 1
fi

send_text_slow "run sleep.elf 1000"
sleep 1
printf 'sendkey ctrl-c\n' | monitor_command >/dev/null
sleep 2
control_output=$(capture_vga)
if ! grep -Fq "run: child terminated by exception" <<<"$control_output" ||
   ! grep -Fq "orange:/$" <<<"$control_output"; then
    echo "$control_output" >&2
    echo "[qemu-input-stress] Ctrl+C did not return to the Shell" >&2
    exit 1
fi

# 多线程前台进程内部也会 fork/wait；这些嵌套 wait 不能清空 Shell 的
# foreground_pid，否则 Ctrl+C 会退化成仅向输入队列投递字符。
send_text_slow "run sync-demo.elf"
sleep 2
printf 'sendkey ctrl-c\n' | monitor_command >/dev/null
sleep 2
sync_control_output=$(capture_vga)
if ! grep -Fq "run: child terminated by exception" <<<"$sync_control_output" ||
   ! grep -Fq "orange:/$" <<<"$sync_control_output"; then
    echo "$sync_control_output" >&2
    echo "[qemu-input-stress] Ctrl+C did not terminate multi-threaded foreground task" >&2
    exit 1
fi

send_fast_echo_batch
stress_output=$(wait_for_output "stress-20" 90)
if ! grep -Fq "stress-20" <<<"$stress_output" ||
   ! grep -Fq "orange:/$" <<<"$stress_output"; then
    echo "$stress_output" >&2
    echo "[qemu-input-stress] fast input batch was lost or Shell stopped" >&2
    exit 1
fi

printf 'quit\n' | monitor_command >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
echo "[qemu-input-stress] Ctrl+C and 20-command fast input pressure: PASSED"
