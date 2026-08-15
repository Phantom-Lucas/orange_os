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
