#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-qemu-sync.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""

cleanup() {
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
    fi
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
SYNC_ROUNDS="${SYNC_TEST_ROUNDS:-1}"
SYNC_WORK="${SYNC_WORKER_ROUNDS:-2000}"
make -B SYNC_TEST_ROUNDS="$SYNC_ROUNDS" SYNC_WORKER_ROUNDS="$SYNC_WORK" \
    DISK_IMAGE="$DISK_IMAGE" bootstrap >/dev/null
qemu-system-x86_64 \
    -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m 512M -display none -monitor "unix:$MONITOR,server,nowait" \
    -no-reboot -no-shutdown >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do
    [ -S "$MONITOR" ] && break
    sleep 0.1
done
sleep 6

send_key() {
    printf 'sendkey %s\n' "$1" | nc -q 0 -U -w 2 "$MONITOR" >/dev/null
}

for ch in r u n spc s y n c minus d e m o dot e l f; do
    send_key "$ch"
    sleep 0.35
done
send_key ret

decode_vga() {
    od -An -v -w2 -tu1 "$VGA_IMAGE" |
        awk '{printf "%c", $1; if (NR % 80 == 0) printf "\n"}' |
        tr -d '\000'
}

output=""
deadline=$((SECONDS + ${SYNC_WAIT_SECONDS:-900}))
while (( SECONDS < deadline )); do
    printf 'pmemsave 0xb8000 0xfa0 "%s"\n' "$VGA_IMAGE" |
        nc -q 0 -U -w 2 "$MONITOR" >/dev/null
    output=$(decode_vga)
    if grep -Fq "sync demo PASSED" <<<"$output"; then
        break
    fi
    if grep -Fq "sync demo FAILED" <<<"$output"; then
        printf '%s\n' "$output" >&2
        exit 1
    fi
    sleep 1
done
if ! grep -Fq "sync demo PASSED" <<<"$output"; then
    printf '%s\n' "$output" >&2
    echo "[qemu-sync] timed out waiting for sync demo" >&2
    exit 1
fi
# sync-demo 自身完成不代表 Shell 已经完成外层 wait/reap；等待明确的
# child-completed 输出和资源回到启动基线，避免固定 sleep 造成竞态误报。
reap_deadline=$((SECONDS + ${SYNC_REAP_WAIT_SECONDS:-30}))
while (( SECONDS < reap_deadline )); do
    compact=${output//$'\n'/}
    if grep -Fq "run: child completed" <<<"$output" &&
       grep -Fq "processes=2 threads=5" <<<"$compact" &&
       grep -Fq "user_mapped=7 user_refs=7" <<<"$compact"; then
        break
    fi
    printf 'pmemsave 0xb8000 0xfa0 "%s"\n' "$VGA_IMAGE" |
        nc -q 0 -U -w 2 "$MONITOR" >/dev/null
    output=$(decode_vga)
    sleep 1
done
compact=${output//$'\n'/}
if ! grep -Fq "run: child completed" <<<"$output" ||
   ! grep -Fq "processes=2 threads=5" <<<"$compact" ||
   ! grep -Fq "user_mapped=7 user_refs=7" <<<"$compact"; then
    printf '%s\n' "$output" >&2
    echo "[qemu-sync] timed out waiting for sync child reap" >&2
    exit 1
fi
printf 'pmemsave 0xb8000 0xfa0 "%s"\nquit\n' "$VGA_IMAGE" |
    nc -q 0 -U -w 2 "$MONITOR" >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
output=$(od -An -v -w2 -tu1 "$VGA_IMAGE" |
    awk '{printf "%c", $1; if (NR % 80 == 0) printf "\n"}' | tr -d '\000')
printf '%s\n' "$output"
grep -Fq "sync demo PASSED" <<<"$output"
grep -Fq "futex_waiters=0" <<<"$output"
grep -Fq "processes=2 threads=5" <<<"$output"
# Shell 当前版本的稳定基线为 7 个用户映射页；user_refs 必须逐页一致。
grep -Fq "user_mapped=7 user_refs=7" <<<"$output"
echo "[qemu-sync] PASSED"
