#!/usr/bin/env bash

set -u -o pipefail

QEMU_PID=${QEMU_PID:-}
QEMU_MONITOR_SOCKET=${QEMU_MONITOR_SOCKET:-}
QEMU_ARGS=()

qemu_socket_path() {
    local requested=$1
    if [ "${#requested}" -gt 90 ]; then
        printf '/tmp/oranges-qemu-%s-%s.sock\n' "$$" "$RANDOM"
    else
        printf '%s\n' "$requested"
    fi
}

qemu_add_arg() {
    QEMU_ARGS+=("$1")
}

qemu_start() {
    local monitor_socket=$1
    shift
    local qemu_binary=${QEMU_BINARY:-qemu-system-x86_64}
    require_command "$qemu_binary"
    QEMU_MONITOR_SOCKET=$monitor_socket
    rm -f -- "$QEMU_MONITOR_SOCKET"
    "$qemu_binary" "$@" -monitor "unix:$monitor_socket,server,nowait" \
        -no-reboot -no-shutdown >>"${TEST_CASE_DIR:-.}/qemu.log" 2>&1 &
    QEMU_PID=$!
}

qemu_wait_ready() {
    local monitor_socket=$1
    local attempts=${2:-50}
    local attempt
    for ((attempt = 0; attempt < attempts; attempt++)); do
        [ -S "$monitor_socket" ] && return 0
        sleep 0.1
    done
    return 1
}

qemu_is_alive() {
    [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null
}

qemu_wait_exit() {
    local pid=$QEMU_PID
    wait "$pid" 2>/dev/null
    QEMU_EXIT_CODE=$?
    QEMU_PID=
    if [ -n "${TEST_CASE_DIR:-}" ]; then
        printf 'qemu_exit_code=%s\n' "$QEMU_EXIT_CODE" >"$TEST_CASE_DIR/qemu-exit.env"
    fi
    return 0
}

qemu_stop() {
    if qemu_is_alive; then
        kill "$QEMU_PID" 2>/dev/null || true
        wait "$QEMU_PID" 2>/dev/null || true
        QEMU_EXIT_CODE=$?
    fi
    QEMU_PID=
    if [ -n "$QEMU_MONITOR_SOCKET" ]; then
        rm -f -- "$QEMU_MONITOR_SOCKET"
    fi
    QEMU_MONITOR_SOCKET=
}
