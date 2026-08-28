#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-boot-check.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
# 启动后的第一次 monitor 请求可能与 BIOS/Loader 的最后一次磁盘访问
# 竞争；给 pmemsave/quit 留出少量余量，避免 check-all 的偶发时序失败。
QEMU_MONITOR_TIMEOUT="${QEMU_MONITOR_TIMEOUT:-3}"
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
BOOT_DIAGNOSTIC=0 make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=64M bootstrap >/dev/null
qemu-system-x86_64 \
    -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-1G}" -smp "${QEMU_CPUS:-1}" -display none \
    -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown \
    >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do [ -S "$MONITOR" ] && break; sleep .1; done
[ -S "$MONITOR" ]
sleep "${QEMU_BOOT_WAIT:-15}"
printf 'pmemsave 0xb8000 0xfa0 "%s"\nquit\n' "$VGA_IMAGE" |
    timeout --signal=TERM --kill-after=1 "$QEMU_MONITOR_TIMEOUT" \
        nc -q 0 -U -w 3 "$MONITOR" >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
output=$(od -An -v -w2 -tu1 "$VGA_IMAGE" |
    awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000')

grep -Fq "[BOOT] kernel ready" <<<"$output"
grep -Fq "[BOOT] storage ready" <<<"$output"
grep -Eq '^\[BOOT\] launching shell[[:space:]]*$' <<<"$output"
grep -Eq '^Orange/64 Terminal[[:space:]]*$' <<<"$output"
grep -Fq "orange@orange-os:/$" <<<"$output"
if grep -Eq '\[RUNTIME\]|\[ELF\] Attempting|ATA (read|write) timeout|MBR Magic' <<<"$output"; then
    printf '%s\n' "$output" >&2
    echo "[qemu-boot] quiet startup leaked diagnostic output or storage errors" >&2
    exit 1
fi
echo "[qemu-boot] quiet startup, storage gate and shell handoff: PASSED"
