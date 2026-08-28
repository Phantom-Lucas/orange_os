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
    sleep "${QEMU_BOOT_WAIT:-15}"

    local attempt
    for ((attempt = 0; attempt < 30; attempt++)); do
        output=$(monitor_capture_vga_stopped "$monitor_socket" "$vga_image") || return 5
        if grep -Fq '[BOOT] kernel ready' <<<"$output" &&
           grep -Fq '[BOOT] storage ready' <<<"$output" &&
           grep -Eq '^\[BOOT\] launching shell[[:space:]]*$' <<<"$output" &&
           grep -Eq '^Orange/64 Terminal[[:space:]]*$' <<<"$output" &&
           grep -Fq 'orange@orange-os:/$' <<<"$output"; then
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

suite_boot_dynamic_loader() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local padded_kernel="$TEST_WORK_DIR/kernel-300-sectors.bin"
    local dynamic_loader="$TEST_WORK_DIR/loader-300-sectors.bin"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local padded_sectors=300

    cd "$ROOT_DIR" || return 3
    require_command nasm
    BOOT_DIAGNOSTIC=0 CONSOLE_BACKEND=vga make build || return 3

    # 300 sectors makes the loader read a 258-sector tail in two ATA commands
    # (255 + 3).  The added bytes are zero and overlap only .bss, which the
    # kernel now explicitly clears before consulting global state.
    cp --sparse=always build/kernel/kernel.bin "$padded_kernel" || return 3
    truncate -s "$((padded_sectors * 512))" "$padded_kernel" || return 3
    nasm -D KERNEL_SECTORS="$padded_sectors" -o "$dynamic_loader" \
        boot/loader.S || return 3
    [ "$(stat -c%s "$dynamic_loader")" -le 4096 ] || return 1

    truncate -s 64M "$disk_image" || return 3
    dd if=build/mbr.bin of="$disk_image" bs=512 count=1 conv=notrunc || return 3
    dd if="$dynamic_loader" of="$disk_image" bs=512 seek=2 conv=notrunc || return 3
    dd if="$padded_kernel" of="$disk_image" bs=512 seek=10 conv=notrunc || return 3
    dd if=build/fs.img of="$disk_image" bs=512 seek=1000 \
        conv=notrunc,sparse || return 3

    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-1G}" -smp 1 -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-15}"

    local attempt
    for ((attempt = 0; attempt < 30; attempt++)); do
        output=$(monitor_capture_vga_stopped "$monitor_socket" "$vga_image") || return 5
        if grep -Fq '[BOOT] kernel ready' <<<"$output" &&
           grep -Fq '[BOOT] storage ready' <<<"$output" &&
           grep -Fq 'orange@orange-os:/$' <<<"$output"; then
            break
        fi
        sleep 0.2
    done
    assert_contains "$output" '[BOOT] kernel ready' || return 1
    assert_contains "$output" '[BOOT] storage ready' || return 1
    assert_contains "$output" 'orange@orange-os:/$' || return 1
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[boot.dynamic-loader] 300-sector kernel, 255+3 tail reads: PASSED\n'
}
