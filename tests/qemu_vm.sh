#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-qemu-vm.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""

cleanup() {
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    if [ "${KEEP_VM_TMP:-0}" != 1 ]; then rm -rf "$TMP_DIR"; else echo "[qemu-vm] artifacts=$TMP_DIR" >&2; fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
make -B VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" \
    DISK_IMAGE="$DISK_IMAGE" bootstrap >/dev/null
qemu-system-x86_64 \
    -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-512M}" -display none \
    -monitor "unix:$MONITOR,server,nowait" \
    -no-reboot -no-shutdown -d int,cpu_reset -D "$TMP_DIR/qemu.log" >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do
    [ -S "$MONITOR" ] && break
    sleep 0.1
done
sleep 6

send_key() {
    printf 'sendkey %s\n' "$1" | nc -q 0 -U -w 2 "$MONITOR" >/dev/null
}

for ch in r u n spc v m minus d e m o dot e l f; do
    send_key "$ch"
    sleep 0.35
done
send_key ret
sleep "${VM_WAIT_SECONDS:-8}"
printf 'pmemsave 0xb8000 0xfa0 "%s"\nquit\n' "$VGA_IMAGE" |
    nc -q 0 -U -w 2 "$MONITOR" >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
output=$(od -An -v -w2 -tu1 "$VGA_IMAGE" |
    awk '{printf "%c", $1; if (NR % 80 == 0) printf "\n"}' | tr -d '\000')
printf '%s\n' "$output"
grep -Fq "[VM] COW/mmap demo PASSED" <<<"$output"
grep -Fq "futex_waiters=0" <<<"$output"
# Shell/FS 的永久内核对象允许保留；VM 子进程结束后用户映射引用必须回到
# 启动基线（当前扩展后的 Shell ELF 为 7 个用户映射页）。
grep -Fq "processes=2 threads=5" <<<"$output"
grep -Fq "user_mapped=7 user_refs=7" <<<"$output"
echo "[qemu-vm] PASSED"
