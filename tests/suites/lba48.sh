#!/usr/bin/env bash

suite_lba48_boot() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output
    local start_lba=268435456

    cd "$ROOT_DIR" || return 3
    truncate -s 256G "$disk_image" || return 3
    BOOT_DIAGNOSTIC=1 make -B DISK_SIZE=256G FS_START_LBA="$start_lba" build || return 3
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" DISK_SIZE=256G \
        FS_START_LBA="$start_lba" install-kernel || return 3

    # The metadata, root directory, and bundled programs fit in this prefix;
    # leave the remaining high-LBA filesystem region sparse.
    dd if=build/fs.img of="$disk_image" bs=1M seek=131072 count=64 \
        conv=notrunc,fdatasync,sparse || return 3

    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-20}"
    monitor_send "$monitor_socket" \
        "pmemsave 0xb8000 0xfa0 \"$vga_image\"" quit || return 5
    qemu_wait_exit
    output=$(monitor_decode_vga "$vga_image") || return 5
    assert_contains "$output" 'fs demo PASSED' || return $?
    assert_contains "$output" "Orange'S user shell ready" || return $?
    printf '%s\n' "$output"
    printf '[lba48.boot] filesystem I/O above 128GiB: PASSED\n'
}
