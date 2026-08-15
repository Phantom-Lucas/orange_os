#!/usr/bin/env bash

set -u -o pipefail

artifacts_init_case() {
    local case_dir=$1
    mkdir -p "$case_dir"
    : >"$case_dir/result.env"
    : >"$case_dir/command.txt"
    : >"$case_dir/environment.txt"
}

artifacts_record_environment() {
    local case_dir=$1
    {
        printf 'commit=%s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
        printf 'suite=%s\n' "${TEST_SUITE:-unknown}"
        printf 'case=%s\n' "${TEST_CASE:-unknown}"
        printf 'iteration=%s\n' "${TEST_ITERATION:-unknown}"
        printf 'seed=%s\n' "${TEST_SEED:-unknown}"
        printf 'timeout=%s\n' "${TEST_TIMEOUT:-unknown}"
        printf 'profile=%s\n' "${TEST_PROFILE:-unknown}"
        if [ -f "$case_dir/qemu-exit.env" ]; then
            sed -n 's/^qemu_exit_code=/qemu_exit_code=/p' "$case_dir/qemu-exit.env"
        else
            printf 'qemu_exit_code=%s\n' "${QEMU_EXIT_CODE:-unknown}"
        fi
        printf 'runner_pid=%s\n' "$$"
        printf 'date=%s\n' "$(date -Is 2>/dev/null || date)"
        printf 'git_status=\n'
        git -C "$ROOT_DIR" status --short 2>/dev/null || true
    } >"$case_dir/environment.txt"
}

artifacts_record_result() {
    local case_dir=$1
    local status=$2
    local exit_code=$3
    {
        printf 'suite=%s\n' "${TEST_SUITE:-unknown}"
        printf 'case=%s\n' "${TEST_CASE:-unknown}"
        printf 'iteration=%s\n' "${TEST_ITERATION:-unknown}"
        printf 'seed=%s\n' "${TEST_SEED:-unknown}"
        printf 'timeout=%s\n' "${TEST_TIMEOUT:-unknown}"
        if [ -f "$case_dir/qemu-exit.env" ]; then
            sed -n 's/^qemu_exit_code=/qemu_exit_code=/p' "$case_dir/qemu-exit.env"
        else
            printf 'qemu_exit_code=%s\n' "${QEMU_EXIT_CODE:-unknown}"
        fi
        printf 'status=%s\n' "$status"
        printf 'exit_code=%s\n' "$exit_code"
    } >"$case_dir/result.env"
}
