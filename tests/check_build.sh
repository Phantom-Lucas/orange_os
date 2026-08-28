#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 8 ]; then
    echo "usage: $0 <kernel-max-sectors> <kernel-load-limit> <mbr> <loader> <kernel.bin> <kernel.elf> <user.elf> <fs.img>" >&2
    exit 2
fi

kernel_max_sectors=$1
kernel_load_limit=$2
mbr=$3
loader=$4
kernel_bin=$5
kernel_elf=$6
user_elf=$7
fs_image=$8

size_of() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1"
}

test "$(size_of "$mbr")" -eq 512
test "$(size_of "$loader")" -le 4096
test "$(size_of "$kernel_bin")" -le $((kernel_max_sectors * 512))

kernel_phys_end_hex=$(LC_ALL=C nm -n "$kernel_elf" |
    awk '$3 == "__kernel_phys_end" { print $1 }')
test -n "$kernel_phys_end_hex"
kernel_phys_end=$((16#$kernel_phys_end_hex))
test "$kernel_phys_end" -le "$((kernel_load_limit))"

LC_ALL=C readelf -h "$kernel_elf" | grep -q 'Class:.*ELF64'
LC_ALL=C readelf -h "$user_elf" | grep -q 'Class:.*ELF64'
LC_ALL=C readelf -h "$user_elf" | grep -q 'Machine:.*Advanced Micro Devices X86-64'

# MyFS places its superblock at block 1 (offset 4096) and uses this magic.
magic=$(od -An -tx4 -j 4096 -N 4 "$fs_image" | tr -d '[:space:]')
test "$magic" = "19980811"

kernel_bytes=$(size_of "$kernel_bin")
kernel_sectors=$(((kernel_bytes + 511) / 512))
echo "[check] MBR=512B loader=$(size_of "$loader")B kernel=${kernel_bytes}B/${kernel_sectors} sectors (disk limit=${kernel_max_sectors} sectors, memory end=0x${kernel_phys_end_hex})"
echo "[check] ELF64 kernel/user images and MyFS superblock: OK"
