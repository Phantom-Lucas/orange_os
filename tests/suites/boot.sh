#!/usr/bin/env bash

suite_boot_quiet() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local previous=""
    local stable=0

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=0 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3

    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-1G}" -smp "${QEMU_CPUS:-1}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    # QEMU can still be updating adjacent VGA cells after the first shell
    # prompt appears.  A 20-second default leaves the stable-snapshot loop
    # outside that boot-time write window; callers may override it explicitly.
    sleep "${QEMU_BOOT_WAIT:-20}"

    local attempt
    for ((attempt = 0; attempt < 30; attempt++)); do
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        output=$(monitor_decode_vga "$vga_image") || return 5
        if grep -Fq '[BOOT] kernel ready' <<<"$output" &&
           grep -Fq '[BOOT] storage ready' <<<"$output" &&
           grep -Fq '[BOOT] shell ready' <<<"$output" &&
           grep -Fq 'orange:/$' <<<"$output"; then
            if [ "$output" = "$previous" ]; then
                stable=1
                break
            fi
            previous=$output
        fi
        sleep 0.2
    done

    if [ "$stable" -ne 1 ]; then
        printf '%s\n' "$output" >&2
        return 1
    fi
    if grep -Eq '\[RUNTIME\]|\[ELF\] Attempting|ATA (read|write) timeout|MBR Magic' <<<"$output"; then
        printf '%s\n' "$output" >&2
        return 1
    fi
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[boot.quiet] stable VGA startup snapshot: PASSED\n'
}
