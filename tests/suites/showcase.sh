suite_showcase_core() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local theme_ppm="$TEST_CASE_DIR/terminal-theme.ppm"
    local vga_artifact="$TEST_CASE_DIR/vga.bin"
    local vga_text_artifact="$TEST_CASE_DIR/vga.txt"
    local output=""
    local first_boot second_boot
    local key ch i
    local key_delay=${QEMU_KEY_DELAY:-0.10}

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")

    send_text() {
        local text=$1
        for ((i = 0; i < ${#text}; i++)); do
            ch=${text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '/') key=slash;;
                '-') key=minus;; *) key=$ch;;
            esac
            monitor_send "$monitor_socket" "sendkey $key" || return 5
            sleep "$key_delay"
        done
        monitor_send "$monitor_socket" 'sendkey ret' || return 5
    }

    capture_vga() {
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        monitor_decode_vga "$vga_image"
    }

    wait_for_marker_and_prompt() {
        local marker=$1
        local attempts=${2:-80}
        local snapshot seen=0
        for ((i = 0; i < attempts; i++)); do
            snapshot=$(capture_vga) || return 5
            if grep -Fq -- "$marker" <<<"$snapshot"; then seen=1; fi
            if [ "$seen" -eq 1 ] && grep -Fq 'orange@orange-os:/$' <<<"$snapshot"; then
                printf '%s\n' "$snapshot"
                return 0
            fi
            sleep 0.25
        done
        return 1
    }

    boot_once() {
        qemu_start "$monitor_socket" \
            -drive "file=$disk_image,format=raw,index=0,media=disk" \
            -m "${QEMU_MEMORY:-512M}" -display none
        qemu_wait_ready "$monitor_socket" || return 5
        sleep "${QEMU_BOOT_WAIT:-15}"
    }

    trap 'qemu_stop' EXIT
    boot_once || return $?
    send_text demo || return $?
    first_boot=$(wait_for_marker_and_prompt 'RESULT 6 passed 0 failed' 80) || {
        printf '[showcase.core] demo did not restore prompt\n' >&2
        return 1
    }
    monitor_screendump "$monitor_socket" "$theme_ppm" || return 5
    cp -- "$vga_image" "$vga_artifact" || return 3
    printf '%s\n' "$first_boot" >"$vga_text_artifact"
    check_terminal_theme_screenshot "$theme_ppm" || return 1

    # The tour is intentionally around two screens. Capture the live bottom
    # and bounded history windows through the existing monitor/VGA library.
    output="$first_boot"
    for _ in 1 2 3 4; do
        monitor_send "$monitor_socket" 'sendkey pgup' || return 5
        sleep 0.2
        output+=$'\n'"$(capture_vga)"
    done
    printf '%s\n' "$output" >"$TEST_WORK_DIR/showcase-first.txt"
    assert_contains "$output" '[1/6] SYSTEM' || return 1
    assert_contains "$output" '[2/6] PROCESS + COW' || return 1
    assert_contains "$output" '[3/6] IPC' || return 1
    assert_contains "$output" '[4/6] THREADS' || return 1
    assert_contains "$output" '[5/6] FILESYSTEM' || return 1
    assert_contains "$output" '[6/6] FAULT ISOLATION' || return 1
    assert_contains "$output" 'RESULT 6 passed 0 failed' || return 1
    assert_contains "$output" 'orange@orange-os:/$' || return 1

    monitor_send "$monitor_socket" 'sendkey pgdn' || return 5
    send_text 'cat demo-proof.txt' || return $?
    first_boot=$(wait_for_marker_and_prompt 'ORANGE/64 showcase proof v1' 40) || return 1
    assert_contains "$first_boot" 'ORANGE/64 showcase proof v1' || return 1
    printf '%s\n' "$first_boot" >"$TEST_WORK_DIR/proof-first.txt"
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit

    rm -f -- "$monitor_socket" "$vga_image"
    boot_once || return $?
    send_text 'cat demo-proof.txt' || return $?
    second_boot=$(wait_for_marker_and_prompt 'ORANGE/64 showcase proof v1' 40) || return 1
    assert_contains "$second_boot" 'ORANGE/64 showcase proof v1' || return 1
    printf '%s\n' "$second_boot" >"$TEST_WORK_DIR/proof-second.txt"
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[showcase.core] guided tour, prompt recovery, proof file and reboot persistence: PASSED\n'
}
