#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-mkfs-lba48.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

# 0x10000000 sectors is exactly the 128GiB boundary.  Leave a 128GiB
# filesystem region after it, so the image ends at 256GiB.  The output is
# sparse; this test does not reserve 256GiB of host storage.
START_LBA=0x10000000
DISK_SIZE=256G
IMAGE="$TMP_DIR/fs.img"

"$ROOT_DIR/build/mkfs" "$IMAGE" --disk-size "$DISK_SIZE" \
    --start-lba "$START_LBA" "$ROOT_DIR/build/hello.elf" >"$TMP_DIR/mkfs.log"

grep -Fq "MyFS v4" "$TMP_DIR/mkfs.log"

# The image contains only the MyFS region, therefore its superblock starts at
# relative block 1.  128GiB / 4KiB = 33,554,432 blocks.  The old LBA28
# implementation rejected this start/size combination; LBA48 must accept it.
fs_blocks=$(od -An -j 4116 -N 4 -tu4 "$IMAGE" | tr -d ' ')
[ "$fs_blocks" -eq 33554432 ]

echo "[mkfs-lba48] 256GiB image, 128GiB LBA48 start and 33,554,432 blocks: PASSED"
