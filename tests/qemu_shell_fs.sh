#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-shell-fs-check.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
QEMU_KEY_DELAY="${QEMU_KEY_DELAY:-0.20}"
QEMU_MONITOR_TIMEOUT="${QEMU_MONITOR_TIMEOUT:-1}"
QEMU_SEND_TIMEOUT="${QEMU_SEND_TIMEOUT:-20}"
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
truncate -s 64M "$DISK_IMAGE"
make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=64M bootstrap >/dev/null
qemu-system-x86_64 -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-512M}" -display none \
    -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do [ -S "$MONITOR" ] && break; sleep .1; done
[ -S "$MONITOR" ]
sleep "${QEMU_BOOT_WAIT:-15}"

send_text() {
    local text=$1 ch key i
    {
    for ((i = 0; i < ${#text}; i++)); do
        ch=${text:i:1}
        case "$ch" in
            ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
            '>') key=shift-dot;; '<') key=shift-comma;; '|') key=shift-backslash;;
            *) key=$ch;;
        esac
        send_key "$key"
        # Keep a small delay so the monitor/keyboard path is exercised, while
        # allowing the complete interactive regression to finish promptly.
        sleep "$QEMU_KEY_DELAY"
    done
    send_key ret
    }
}

monitor_command() {
    local limit="${1:-$QEMU_MONITOR_TIMEOUT}"
    timeout --signal=TERM --kill-after=1 "$limit" \
        nc -q 0 -U -w 2 "$MONITOR"
}

send_stream() {
    timeout --signal=TERM --kill-after=1 "$QEMU_SEND_TIMEOUT" \
        nc -U -w 2 "$MONITOR"
}

send_key() {
    printf 'sendkey %s\n' "$1" | monitor_command >/dev/null
}

capture_vga() {
    printf 'pmemsave 0xb8000 0xfa0 "%s"\n' "$VGA_IMAGE" |
        monitor_command >/dev/null
    od -An -v -w2 -tu1 "$VGA_IMAGE" |
        awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000'
}

run_and_capture() {
    send_text "$1"
    sleep "${2:-1}"
    output+="$(capture_vga)\n"
}

output=""
run_and_capture "echo shellredirectok > shell-redir"
run_and_capture "echo shellappendok >> shell-redir"
run_and_capture "cat shell-redir"
run_and_capture "cat < shell-redir"
run_and_capture "echo shellpipeok | cat -" 2
run_and_capture "echo shellbackgroundok > bg-file &"
run_and_capture "cat bg-file" 2
run_and_capture "mkdir shell-dir"
run_and_capture "cd shell-dir"
run_and_capture "pwd"
run_and_capture "cd /"
run_and_capture "rm shell-redir"
run_and_capture "rm bg-file"
run_and_capture "rm shell-dir"
run_and_capture "echo clear-before"
send_text "clear"
sleep 1
after_clear=$(capture_vga)
output+="$after_clear\n"
run_and_capture "echo clear-after"
run_and_capture "echo scroll-marker"
for _ in 1 2 3; do
    run_and_capture "ls"
done
for _ in 1 2 3; do
    send_key pgup
    sleep .2
done
sleep 1
scrolled=$(capture_vga)
output+="$scrolled\n"
# 输入时不要求用户先按 PageDown：首个字符应自动退出历史查看模式，
# 恢复到当前 Shell 行并完整执行命令。
run_and_capture "echo input-after-scroll"
send_key pgdn
sleep 1
run_and_capture "echo scroll-after"

redirect_count=$(grep -o 'shellredirectok' <<<"$output" | wc -l)
append_count=$(grep -o 'shellappendok' <<<"$output" | wc -l)
pipe_count=$(grep -o 'shellpipeok' <<<"$output" | wc -l)
background_count=$(grep -o 'shellbackgroundok' <<<"$output" | wc -l)
if [ "$redirect_count" -lt 2 ] || [ "$append_count" -lt 2 ] ||
   [ "$pipe_count" -lt 2 ] || [ "$background_count" -lt 2 ] ||
   ! grep -Fq '/shell-dir' <<<"$output" ||
   grep -Fq 'clear-before' <<<"$after_clear" ||
   ! grep -Fq 'scroll-marker' <<<"$scrolled" ||
   ! grep -Fq 'input-after-scroll' <<<"$output" ||
   ! grep -Fq 'scroll-after' <<<"$output"; then
    printf '%s\n' "$output" >&2
    echo "[qemu-shell-fs] assertion failed: redirect=$redirect_count append=$append_count pipe=$pipe_count background=$background_count" >&2
    exit 1
fi
printf 'quit\n' | monitor_command >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
echo "[qemu-shell-fs] redirection, append, input, pipeline, background, cwd, clear and scrollback: PASSED"
