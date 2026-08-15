#!/usr/bin/env bash

suite_mkfs_index() {
    cd "$ROOT_DIR"
    bash tests/mkfs_index.sh
}

suite_mkfs_lba48() {
    cd "$ROOT_DIR"
    bash tests/mkfs_lba48.sh
}
