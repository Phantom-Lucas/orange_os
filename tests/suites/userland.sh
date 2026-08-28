#!/usr/bin/env bash

suite_userland_core() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local command_text ch key i

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-10}"

    for command_text in \
        'libc-demo' \
        'libc-test' \
        'echo.elf argv-one argv-two' \
        'ps.elf' \
        'sleep.elf 5' \
        'ls'; do
        for ((i = 0; i < ${#command_text}; i++)); do
            ch=${command_text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '&') key=shift-7;;
                *) key=$ch;;
            esac
            monitor_send "$monitor_socket" "sendkey $key" || return 5
            sleep 0.25
        done
        monitor_send "$monitor_socket" 'sendkey ret' || return 5
        sleep 2
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        output+="$(monitor_decode_vga "$vga_image")\n"
    done

    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%b\n' "$output"
    if ! grep -Fq 'libc-demo: allocator, strings, formatting passed' <<<"$output" ||
       ! grep -Fq 'libc-test: 13 passed, 0 failed' <<<"$output" ||
       ! grep -Fq 'argv-one argv-two' <<<"$output" ||
       ! grep -Fq 'PID  PPID STATE THREADS NAME USERPAGES' <<<"$output" ||
       ! grep -Fq 'libc-demo.elf' <<<"$output"; then
        printf '%s\n' "$output" >&2
        return 1
    fi
    printf '[userland.core] crt0/argv/libc/external commands: PASSED\n'
}
