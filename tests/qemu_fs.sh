#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-fs-check.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
truncate -s 64M "$DISK_IMAGE"
make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=64M bootstrap >/dev/null

boot_once() {
    rm -f "$MONITOR" "$VGA_IMAGE"
    qemu-system-x86_64 -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
        -m "${QEMU_MEMORY:-512M}" -display none \
        -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown >/dev/null 2>&1 &
    QEMU_PID=$!
    for _ in $(seq 1 50); do [ -S "$MONITOR" ] && break; sleep .1; done
    [ -S "$MONITOR" ]
    sleep "${QEMU_BOOT_WAIT:-15}"
    printf 'pmemsave 0xb8000 0xfa0 "%s"\nquit\n' "$VGA_IMAGE" | nc -q 0 -U -w 3 "$MONITOR" >/dev/null
    wait "$QEMU_PID" || true
    QEMU_PID=""
    od -An -v -w2 -tu1 "$VGA_IMAGE" | awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000'
}

assert_contains() {
    local output=$1 expected=$2 label=$3
    local compact=${output//$'\n'/}
    if ! grep -Fq "$expected" <<<"$output" &&
       ! grep -Fq "$expected" <<<"$compact"; then
        echo "[qemu-fs] missing $label: $expected" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
}

first=$(boot_once)
assert_contains "$first" "fs demo PASSED" first-demo
assert_contains "$first" "Orange/64 Terminal" first-shell
assert_contains "$first" "file_objects=0 pipe_objects=0" first-files
# MyFS v4 按实际 inode 数量保留一个永久 inode 引用表；它属于文件系统
# 常驻对象，不是用户操作泄漏。64MiB 测试镜像的 4096 个 inode 使用
# 一个 16KiB heap block，前后都必须保持一致。
assert_contains "$first" "heap_blocks=1" first-heap-blocks
assert_contains "$first" "heap_bytes=16384" first-heap-bytes
assert_contains "$first" "user_refs=0" first-user-refs

second=$(boot_once)
assert_contains "$second" "[FS] Reboot persistence state verified." second-persistence
assert_contains "$second" "fs demo PASSED" second-demo
assert_contains "$second" "file_objects=0 pipe_objects=0" second-files
assert_contains "$second" "heap_blocks=1" second-heap-blocks
assert_contains "$second" "heap_bytes=16384" second-heap-bytes
assert_contains "$second" "user_refs=0" second-user-refs
echo "[qemu-fs] persistence, directories, cwd, stat, dup and pipe: PASSED"
