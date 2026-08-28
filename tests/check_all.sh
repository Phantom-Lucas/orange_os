#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG_DIR=${CHECK_LOG_DIR:-"$ROOT_DIR/build/check-all-logs"}
CHECK_STEP_TIMEOUT="${CHECK_STEP_TIMEOUT:-300}"
mkdir -p "$LOG_DIR"
cd "$ROOT_DIR"

step=0
run_step() {
    local name=$1
    local step_timeout="${CHECK_STEP_TIMEOUT}"
    shift
    step=$((step + 1))
    local log="$LOG_DIR/$(printf '%02d' "$step")-$name.log"
    # 默认 full 同步矩阵是 10 轮、每轮 20,000 次操作；100 轮 soak 已
    # 独立进入 test-stress。集成还包含同步与 VM 回归，保留独立上限。
    case "$name" in
        sync) step_timeout="${SYNC_CHECK_TIMEOUT:-900}" ;;
        integration) step_timeout="${INTEGRATION_CHECK_TIMEOUT:-1200}" ;;
    esac
    printf '[check-all] %-28s ... ' "$name"
    if timeout --signal=TERM --kill-after=10 "$step_timeout" "$@" >"$log" 2>&1; then
        echo PASSED
    else
        echo FAILED
        tail -80 "$log" >&2
        echo "[check-all] full log: $log" >&2
        exit 1
    fi
}

run_step build-quiet env BOOT_DIAGNOSTIC=0 make -B check
run_step build-diagnostic env BOOT_DIAGNOSTIC=1 make -B check
run_step mkfs-index make mkfs-index-check
run_step mkfs-lba48 make mkfs-lba48-check
run_step qemu-lba48 make qemu-lba48-check
run_step boot-quiet make qemu-boot-check
run_step filesystem make qemu-fs-check
run_step shell-tty make qemu-shell-fs-check
run_step userland make qemu-userland-check
run_step input-stress make qemu-input-stress-check
run_step sync env SYNC_TEST_ROUNDS="${SYNC_TEST_ROUNDS:-10}" \
    SYNC_WORKER_ROUNDS="${SYNC_WORKER_ROUNDS:-20000}" make qemu-sync-check
run_step virtual-memory env VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" make qemu-vm-check
run_step integration env SYNC_TEST_ROUNDS="${SYNC_TEST_ROUNDS:-10}" \
    SYNC_WORKER_ROUNDS="${SYNC_WORKER_ROUNDS:-20000}" \
    VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" make qemu-check

echo "[check-all] all checks passed; logs=$LOG_DIR"
