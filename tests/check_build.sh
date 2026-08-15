#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 7 ]; then
    echo "usage: $0 <kernel-max-sectors> <mbr> <loader> <kernel.bin> <kernel.elf> <user.elf> <fs.img>" >&2
    exit 2
fi

kernel_max_sectors=$1
mbr=$2
loader=$3
kernel_bin=$4
kernel_elf=$5
user_elf=$6
fs_image=$7

size_of() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1"
}

test "$(size_of "$mbr")" -eq 512
test "$(size_of "$loader")" -le 4096
test "$(size_of "$kernel_bin")" -le $((kernel_max_sectors * 512))

LC_ALL=C readelf -h "$kernel_elf" | grep -q 'Class:.*ELF64'
LC_ALL=C readelf -h "$user_elf" | grep -q 'Class:.*ELF64'
LC_ALL=C readelf -h "$user_elf" | grep -q 'Machine:.*Advanced Micro Devices X86-64'

# MyFS places its superblock at block 1 (offset 4096) and uses this magic.
magic=$(od -An -tx4 -j 4096 -N 4 "$fs_image" | tr -d '[:space:]')
test "$magic" = "19980811"

echo "[check] MBR=512B loader=$(size_of "$loader")B kernel=$(size_of "$kernel_bin")B (limit=$((kernel_max_sectors * 512))B)"
echo "[check] ELF64 kernel/user images and MyFS superblock: OK"
