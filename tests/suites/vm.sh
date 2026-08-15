#!/usr/bin/env bash

suite_vm_cow() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local previous=""
    local stable=0
    local key

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make -B VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" \
        DISK_IMAGE="$disk_image" bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none \
        -d int,cpu_reset -D "$TEST_CASE_DIR/qemu-debug.log"
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep 6

    for key in r u n spc v m minus d e m o dot e l f; do
        monitor_send "$monitor_socket" "sendkey $key" || return 5
        sleep 0.35
    done
    monitor_send "$monitor_socket" 'sendkey ret' || return 5

    local deadline=$((SECONDS + ${VM_WAIT_SECONDS:-120}))
    local attempt
    while (( SECONDS < deadline )); do
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        output=$(monitor_decode_vga "$vga_image") || return 5
        if grep -Fq '[VM] COW/mmap demo PASSED' <<<"$output" &&
           grep -Fq 'futex_waiters=0' <<<"$output" &&
           grep -Fq 'processes=2 threads=5' <<<"$output" &&
           grep -Fq 'user_mapped=7 user_refs=7' <<<"$output"; then
            if [ "$output" = "$previous" ]; then
                stable=1
                break
            fi
            previous=$output
        fi
        sleep 1
    done

    [ "$stable" -eq 1 ] || {
        printf '%s\n' "$output" >&2
        return 1
    }
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[vm.cow] stable VGA VM snapshot: PASSED\n'
}
