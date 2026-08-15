#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-mkfs-index.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

# 5MiB 超过 11 个直接块和 1024 个一级索引项，必须同时经过一级、二级
# 索引；使用稀疏输入文件不会把测试变成宿主机的大量 IO。
truncate -s 5M "$TMP_DIR/large.bin"
"$ROOT_DIR/build/mkfs" "$TMP_DIR/fs.img" --disk-size 64M --start-lba 1000 \
    "$TMP_DIR/large.bin" >"$TMP_DIR/mkfs.log"
grep -Fq "Added large.bin (5242880 bytes)" "$TMP_DIR/mkfs.log"

# MyFS 超级块的 inode_start 位于相对块 1 的偏移 40；inode 2 位于 inode
# 表的第 3 个 72B 槽位。inode 中 indirect_1/2/3 的偏移分别为 56/60/64。
inode_start=$(od -An -j 4136 -N 4 -tu4 "$TMP_DIR/fs.img" | tr -d ' ')
inode_offset=$((inode_start * 4096 + 2 * 72))
size=$(od -An -j "$inode_offset" -N 8 -tu8 "$TMP_DIR/fs.img" | tr -d ' ')
indirect_1=$(od -An -j $((inode_offset + 56)) -N 4 -tu4 "$TMP_DIR/fs.img" | tr -d ' ')
indirect_2=$(od -An -j $((inode_offset + 60)) -N 4 -tu4 "$TMP_DIR/fs.img" | tr -d ' ')
indirect_3=$(od -An -j $((inode_offset + 64)) -N 4 -tu4 "$TMP_DIR/fs.img" | tr -d ' ')

[ "$size" = 5242880 ]
[ "$indirect_1" -ne 0 ]
[ "$indirect_2" -ne 0 ]
[ "$indirect_3" -eq 0 ]
echo "[mkfs-index] 64-bit size, single and double indirect image: PASSED"
