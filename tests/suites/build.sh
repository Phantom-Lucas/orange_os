#!/usr/bin/env bash

suite_build_artifacts() {
    cd "$ROOT_DIR"
    BOOT_DIAGNOSTIC=0 make -B check || return 3
    BOOT_DIAGNOSTIC=1 make -B check || return 3
}
