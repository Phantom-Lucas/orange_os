#!/usr/bin/env bash

suite_fs_service() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local first second first_compact second_compact boot_index=0 boot_status

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")

    boot_once() {
        boot_index=$((boot_index + 1))
        rm -f "$monitor_socket" "$vga_image"
        qemu_start "$monitor_socket" \
            -drive "file=$disk_image,format=raw,index=0,media=disk" \
            -m "${QEMU_MEMORY:-512M}" -display none
        qemu_wait_ready "$monitor_socket" || {
            printf '[fs.service] monitor did not become ready: %s\n' "$monitor_socket" >&2
            return 5
        }
        sleep "${QEMU_BOOT_WAIT:-15}"
        monitor_send "$monitor_socket" \
            "pmemsave 0xb8000 0xfa0 \"$vga_image\"" quit || {
            printf '[fs.service] monitor capture failed: %s\n' "$monitor_socket" >&2
            return 5
        }
        qemu_wait_exit
        monitor_decode_vga "$vga_image" >"$TEST_WORK_DIR/boot-$boot_index.txt"
    }

    trap 'qemu_stop' EXIT
    boot_once
    boot_status=$?
    [ "$boot_status" -eq 0 ] || return "$boot_status"
    first=$(<"$TEST_WORK_DIR/boot-1.txt")
    first_compact=${first//$'\n'/}
    grep -Fq 'fs demo PASSED' <<<"$first" || grep -Fq 'fs demo PASSED' <<<"$first_compact" || { echo '[fs.service] first fs demo missing' >&2; return 1; }
    grep -Fq "Orange/64 Terminal" <<<"$first" || grep -Fq "Orange/64 Terminal" <<<"$first_compact" || { echo '[fs.service] first shell missing' >&2; return 1; }
    grep -Fq 'file_objects=0 pipe_objects=0' <<<"$first" || grep -Fq 'file_objects=0 pipe_objects=0' <<<"$first_compact" || { echo '[fs.service] first file baseline missing' >&2; return 1; }
    grep -Fq 'heap_blocks=1' <<<"$first" || grep -Fq 'heap_blocks=1' <<<"$first_compact" || { echo '[fs.service] first heap block baseline missing' >&2; return 1; }
    grep -Fq 'heap_bytes=16384' <<<"$first" || grep -Fq 'heap_bytes=16384' <<<"$first_compact" || { echo '[fs.service] first heap byte baseline missing' >&2; return 1; }
    grep -Fq 'user_refs=0' <<<"$first" || grep -Fq 'user_refs=0' <<<"$first_compact" || { echo '[fs.service] first user ref baseline missing' >&2; return 1; }

    boot_once
    boot_status=$?
    [ "$boot_status" -eq 0 ] || return "$boot_status"
    second=$(<"$TEST_WORK_DIR/boot-2.txt")
    second_compact=${second//$'\n'/}
    grep -Fq '[FS] Reboot persistence state verified.' <<<"$second" || grep -Fq '[FS] Reboot persistence state verified.' <<<"$second_compact" || return 1
    grep -Fq 'fs demo PASSED' <<<"$second" || grep -Fq 'fs demo PASSED' <<<"$second_compact" || return 1
    grep -Fq 'file_objects=0 pipe_objects=0' <<<"$second" || grep -Fq 'file_objects=0 pipe_objects=0' <<<"$second_compact" || return 1
    grep -Fq 'heap_blocks=1' <<<"$second" || grep -Fq 'heap_blocks=1' <<<"$second_compact" || return 1
    grep -Fq 'heap_bytes=16384' <<<"$second" || grep -Fq 'heap_bytes=16384' <<<"$second_compact" || return 1
    grep -Fq 'user_refs=0' <<<"$second" || grep -Fq 'user_refs=0' <<<"$second_compact" || return 1
    printf '%s\n%s\n' "$first" "$second"
    printf '[fs.service] persistence/resource snapshot: PASSED\n'
}
