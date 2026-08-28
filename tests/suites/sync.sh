#!/usr/bin/env bash

suite_sync_core() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local previous=""
    local stable=0
    local retried=0
    local key
    local sync_rounds=${SYNC_TEST_ROUNDS:-10}
    local sync_work=${SYNC_WORKER_ROUNDS:-20000}

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make -B SYNC_TEST_ROUNDS="$sync_rounds" \
        SYNC_WORKER_ROUNDS="$sync_work" DISK_IMAGE="$disk_image" \
        DISK_SIZE="${TEST_DISK_SIZE:-64M}" bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep 6

    send_sync_command() {
        for key in r u n spc s y n c minus d e m o dot e l f; do
            monitor_send "$monitor_socket" "sendkey $key" || return 5
            sleep 0.35
        done
        monitor_send "$monitor_socket" 'sendkey ret'
    }
    send_sync_command || return $?

    local deadline=$((SECONDS + ${SYNC_WAIT_SECONDS:-900}))
    while (( SECONDS < deadline )); do
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        output=$(monitor_decode_vga "$vga_image") || return 5
        # A busy first ELF load is an observed QEMU/ATA startup flake.  The
        # Shell remains healthy, so retry exactly once rather than spending the
        # full pressure timeout polling an impossible success marker.
        if [ "$retried" -eq 0 ] &&
           grep -Fq 'run: executable not found' <<<"$output"; then
            retried=1
            send_sync_command || return $?
            sleep 1
            continue
        fi
        if grep -Fq 'sync demo FAILED' <<<"$output"; then
            printf '%s\n' "$output" >&2
            return 1
        fi
        if grep -Fq 'sync demo PASSED' <<<"$output" &&
           grep -Fq 'futex_waiters=0' <<<"$output" &&
           grep -Fq 'processes=2 threads=5' <<<"$output" &&
           # The modern Shell history/editor deliberately lives in BSS rather
           # than on its one-page user stack.  Its five additional user pages
           # are a stable baseline, not a leaked sync-demo allocation.
           grep -Fq 'user_mapped=12 user_refs=12' <<<"$output"; then
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
    printf '[sync.core] stable VGA sync/resource snapshot: PASSED\n'
}

suite_sync_stress() {
    # Keep the long soak reproducible but out of the normal release gate.  A
    # caller may override either variable for capacity/performance studies.
    SYNC_TEST_ROUNDS="${SYNC_STRESS_ROUNDS:-${SYNC_TEST_ROUNDS:-100}}" \
        SYNC_WORKER_ROUNDS="${SYNC_STRESS_WORKER_ROUNDS:-${SYNC_WORKER_ROUNDS:-20000}}" \
        suite_sync_core
}
