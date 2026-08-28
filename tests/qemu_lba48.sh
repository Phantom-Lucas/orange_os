#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-qemu-lba48.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1

# Put the MyFS start exactly at the first sector above the old 28-bit LBA
# range.  The 256GiB image and sparse copy keep host storage consumption low;
# the kernel must nevertheless issue LBA48 commands for every filesystem I/O.
START_LBA=268435456
truncate -s 256G "$DISK_IMAGE"
make DISK_SIZE=256G FS_START_LBA="$START_LBA" \
    BOOT_DIAGNOSTIC=1 build >/dev/null
make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=256G FS_START_LBA="$START_LBA" \
    BOOT_DIAGNOSTIC=1 install-kernel >/dev/null

# MyFS metadata, the root directory, and all bundled test programs fit in
# this prefix.  Copying only it is sufficient because the rest of the fresh
# sparse disk is zero, and avoids scanning the complete 128GiB source image.
# 128GiB / 1MiB = 131072 blocks.
dd if=build/fs.img of="$DISK_IMAGE" bs=1M seek=131072 count=64 \
    conv=notrunc,fdatasync,sparse >/dev/null

qemu-system-x86_64 -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-512M}" -display none \
    -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown >/dev/null 2>&1 &
QEMU_PID=$!

for _ in $(seq 1 50); do
    [ -S "$MONITOR" ] && break
    sleep 0.1
done
[ -S "$MONITOR" ]
sleep "${QEMU_BOOT_WAIT:-20}"

printf 'pmemsave 0xb8000 0xfa0 "%s"\nquit\n' "$VGA_IMAGE" |
    nc -q 0 -U -w 3 "$MONITOR" >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""

output=$(od -An -v -w2 -tu1 "$VGA_IMAGE" |
    awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000')
if ! grep -Fq "fs demo PASSED" <<<"$output" ||
   ! grep -Fq "Orange/64 Terminal" <<<"$output"; then
    echo "[qemu-lba48] high-LBA filesystem boot failed" >&2
    printf '%s\n' "$output" >&2
    exit 1
fi

echo "[qemu-lba48] QEMU filesystem I/O above 128GiB: PASSED"
