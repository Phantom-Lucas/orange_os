#!/usr/bin/env bash

suite_integration_smoke() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local qemu_memory=${QEMU_MEMORY:-512M}
    local command_settle=${QEMU_COMMAND_SETTLE:-3}
    local output first_boot persistence_boot exec_boot pre_thread_boot pre_sync_boot
    local sync_boot sync_reaped vm_boot verification_boot
    local text ch key i

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make -B \
        SYNC_TEST_ROUNDS="${SYNC_TEST_ROUNDS:-100}" \
        SYNC_WORKER_ROUNDS="${SYNC_WORKER_ROUNDS:-20000}" \
        VM_TEST_ROUNDS="${VM_TEST_ROUNDS:-32}" check || return 3
    local fs_blocks
    fs_blocks=$(od -An -j 4116 -N 4 -tu4 "$ROOT_DIR/build/fs.img" | tr -d ' ')
    [ "$fs_blocks" = 2097027 ] || {
        printf '[integration.smoke] unexpected default MyFS block count: %s\n' "$fs_blocks" >&2
        return 1
    }
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" bootstrap || return 3
    trap 'qemu_stop' EXIT

    send_text() {
        text=$1
        for ((i = 0; i < ${#text}; i++)); do
            ch=${text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;;
                *) key=$ch;;
            esac
            monitor_send "$monitor_socket" "sendkey $key" || return 5
            sleep 0.35
        done
        monitor_send "$monitor_socket" 'sendkey ret' || return 5
        sleep "$command_settle"
    }

    capture_vga() {
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        monitor_decode_vga "$vga_image"
    }

    start_qemu() {
        rm -f "$vga_image"
        qemu_start "$monitor_socket" \
            -drive "file=$disk_image,format=raw,index=0,media=disk" \
            -m "$qemu_memory" -display none
        qemu_wait_ready "$monitor_socket" || return 5
        sleep "${QEMU_BOOT_WAIT:-15}"
    }

    capture_and_stop() {
        monitor_send "$monitor_socket" \
            "pmemsave 0xb8000 0xfa0 \"$vga_image\"" quit || return 5
        qemu_wait_exit
        monitor_decode_vga "$vga_image"
    }

    wait_for_vga_contains() {
        local expected=$1
        local wait_seconds=${2:-60}
        local deadline=$((SECONDS + wait_seconds))
        local current=""
        while (( SECONDS < deadline )); do
            current=$(capture_vga) || return 5
            if grep -Fq "$expected" <<<"$current"; then
                printf '%s\n' "$current"
                return 0
            fi
            if grep -Fq 'sync demo FAILED' <<<"$current" ||
               grep -Fq '[VM] COW/mmap demo FAILED' <<<"$current"; then
                printf '%s\n' "$current" >&2
                return 1
            fi
            sleep 1
        done
        printf '%s\n' "$current" >&2
        printf '[integration.smoke] timed out waiting for: %s\n' "$expected" >&2
        return 1
    }

    assert_contains() {
        local actual=$1 expected=$2
        grep -Fq "$expected" <<<"$actual" || {
            printf '[integration.smoke] missing: %s\n' "$expected" >&2
            printf '%s\n' "$actual" >&2
            return 1
        }
    }

    start_qemu || return $?
    capture_and_stop >"$TEST_WORK_DIR/first-boot.txt" || return $?
    first_boot=$(<"$TEST_WORK_DIR/first-boot.txt")
    assert_contains "$first_boot" "Orange'S user shell ready" || return $?

    start_qemu || return $?
    send_text 'write persist persist-hello' || return $?
    sleep 2
    capture_and_stop >"$TEST_WORK_DIR/persistence-write.txt" || return $?

    start_qemu || return $?
    send_text 'cat persist' || return $?
    sleep 1
    persistence_boot=$(capture_vga) || return $?
    assert_contains "$persistence_boot" 'persist-hello' || return $?

    for _ in 1 2 3; do
        send_text 'run hello.elf' || return $?
        sleep 2
    done

    for _ in 1 2; do
        send_text 'run exec-demo.elf' || return $?
        sleep 2
    done
    send_text 'exec missing.elf' || return $?
    sleep 1
    exec_boot=$(capture_vga) || return $?
    assert_contains "$exec_boot" 'exec demo: replacing image through FS service' || return $?
    assert_contains "$exec_boot" 'exec: executable not found' || return $?

    send_text 'run ipc-demo.elf' || return $?
    sleep 2
    send_text 'run uaccess-demo.elf' || return $?
    sleep 3
    pre_thread_boot=$(capture_vga) || return $?
    assert_contains "$pre_thread_boot" 'IPC user demo PASSED' || return $?
    assert_contains "$pre_thread_boot" 'uaccess demo PASSED' || return $?

    for _ in 1 2; do
        send_text 'run thread-demo.elf' || return $?
        sleep 4
    done
    pre_sync_boot=$(capture_vga) || return $?
    assert_contains "$pre_sync_boot" 'thread demo PASSED' || return $?

    send_text 'run sync-demo.elf' || return $?
    sync_boot=$(wait_for_vga_contains 'sync demo PASSED' "${SYNC_WAIT_SECONDS:-900}") || return $?
    assert_contains "$sync_boot" 'sync demo PASSED' || return $?
    wait_for_vga_contains 'run: child completed' "${SYNC_REAP_WAIT_SECONDS:-30}" >/dev/null || return $?
    sync_reaped=$(capture_vga) || return $?
    assert_contains "$sync_reaped" 'sync demo PASSED' || return $?
    assert_contains "$sync_reaped" 'futex_waiters=0' || return $?
    assert_contains "$sync_reaped" 'processes=2 threads=5' || return $?
    assert_contains "$sync_reaped" 'user_mapped=7 user_refs=7' || return $?

    send_text 'run vm-demo.elf' || return $?
    vm_boot=$(wait_for_vga_contains '[VM] COW/mmap demo PASSED' "${VM_WAIT_SECONDS:-120}") || return $?
    assert_contains "$vm_boot" '[VM] COW/mmap demo PASSED' || return $?
    wait_for_vga_contains 'run: child completed' "${VM_REAP_WAIT_SECONDS:-30}" >/dev/null || return $?

    send_text 'run fault.elf' || return $?
    sleep 2
    capture_and_stop >"$TEST_WORK_DIR/verification-boot.txt" || return $?
    verification_boot=$(<"$TEST_WORK_DIR/verification-boot.txt")
    assert_contains "$verification_boot" 'run: child completed' || return $?
    assert_contains "$verification_boot" 'processes=2 threads=5' || return $?
    assert_contains "$verification_boot" 'user_mapped=7 user_refs=7' || return $?
    assert_contains "$verification_boot" '[Ring 3] deliberate page fault' || return $?
    assert_contains "$verification_boot" 'run: child terminated by exception' || return $?
    printf '[integration.smoke] boot, fork, persistence, IPC, sync, VM and fault isolation: PASSED\n'
}
