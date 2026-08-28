#!/usr/bin/env bash

set -u -o pipefail

monitor_send() {
    local socket=$1
    shift
    printf '%s\n' "$@" | timeout --signal=TERM --kill-after=1 "${QEMU_MONITOR_TIMEOUT:-3}" \
        nc -q 0 -U -w 3 "$socket" >/dev/null
}

monitor_decode_vga() {
    local image=$1
    od -An -v -w2 -tu1 "$image" |
        awk '{printf "%c", $1; if (NR % 80 == 0) printf "\n"}' |
        tr -d '\000'
}

monitor_screendump() {
    local socket=$1
    local image=$2
    monitor_send "$socket" "screendump \"$image\""
}

monitor_capture_vga_stopped() {
    local socket=$1
    local image=$2

    monitor_send "$socket" stop || return 1
    if ! monitor_send "$socket" "pmemsave 0xb8000 0xfa0 \"$image\""; then
        monitor_send "$socket" cont || true
        return 1
    fi
    monitor_send "$socket" cont || return 1
    monitor_decode_vga "$image"
}
