#!/bin/bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
TMP_DIR=$(mktemp -d /tmp/oranges-userland-check.XXXXXX)
DISK_IMAGE="$TMP_DIR/disk.img"
MONITOR="$TMP_DIR/monitor.sock"
VGA_IMAGE="$TMP_DIR/vga.bin"
QEMU_PID=""
trap 'if [ -n "$QEMU_PID" ]; then kill "$QEMU_PID" 2>/dev/null || true; wait "$QEMU_PID" 2>/dev/null || true; fi; rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"
export BOOT_DIAGNOSTIC=1
truncate -s 64M "$DISK_IMAGE"
make DISK_IMAGE="$DISK_IMAGE" DISK_SIZE=64M bootstrap >/dev/null
qemu-system-x86_64 -drive file="$DISK_IMAGE",format=raw,index=0,media=disk \
    -m "${QEMU_MEMORY:-512M}" -display none \
    -monitor "unix:$MONITOR,server,nowait" -no-reboot -no-shutdown >/dev/null 2>&1 &
QEMU_PID=$!
for _ in $(seq 1 50); do [ -S "$MONITOR" ] && break; sleep .1; done
[ -S "$MONITOR" ]
sleep "${QEMU_BOOT_WAIT:-10}"

send_text() {
    local text=$1 ch key i
    {
    for ((i = 0; i < ${#text}; i++)); do
        ch=${text:i:1}
        case "$ch" in
            ' ') key=spc;; '.') key=dot;; '-') key=minus;; '&') key=shift-7;;
            *) key=$ch;;
        esac
        printf 'sendkey %s\n' "$key"
        sleep .25
    done
    printf 'sendkey ret\n'
    } | nc -q 0 -U -w 2 "$MONITOR" >/dev/null
}

capture_vga() {
    local image=$1
    printf 'pmemsave 0xb8000 0xfa0 "%s"\n' "$image" |
        nc -q 0 -U -w 3 "$MONITOR" >/dev/null
    od -An -v -w2 -tu1 "$image" |
        awk '{printf "%c",$1;if(NR%80==0)printf "\n"}' | tr -d '\000'
}

output=""
for command in \
    "libc-demo" \
    "libc-test" \
    "echo.elf argv-one argv-two" \
    "ps.elf" \
    "sleep.elf 5" \
    "ls"; do
    send_text "$command"
    sleep 2
    output+="$(capture_vga "$VGA_IMAGE")\n"
done

printf 'quit\n' |
    nc -q 0 -U -w 3 "$MONITOR" >/dev/null
wait "$QEMU_PID" || true
QEMU_PID=""
printf '%s\n' "$output"
if ! grep -Fq "libc-demo: allocator, strings, formatting passed" <<<"$output" ||
   ! grep -Fq "libc-test: 13 passed, 0 failed" <<<"$output" ||
   ! grep -Fq "argv-one argv-two" <<<"$output" ||
   ! grep -Fq "PID  PPID STATE THREADS NAME" <<<"$output" ||
   ! grep -Fq "libc-demo.elf" <<<"$output"; then
    printf '%s\n' "$output" >&2
    echo "[qemu-userland] assertion failed" >&2
    exit 1
fi
echo "[qemu-userland] crt0/argv/libc/external commands/ps/sleep/background: PASSED"
