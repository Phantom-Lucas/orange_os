#!/usr/bin/env bash

suite_input_stress() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local key_delay=${QEMU_KEY_DELAY:-0.35}
    local command_delay=${QEMU_COMMAND_DELAY:-1}
    local text ch key i j
    local output

    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=1 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-15}"

    send_key() {
        monitor_send "$monitor_socket" "sendkey $1"
    }

    capture_vga() {
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        monitor_decode_vga "$vga_image"
    }

    send_text_slow() {
        text=$1
        for ((i = 0; i < ${#text}; i++)); do
            ch=${text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
                *) key=$ch;;
            esac
            send_key "$key" || return 5
            sleep "$key_delay"
        done
        send_key ret || return 5
    }

    wait_for_output() {
        local expected=$1
        local timeout_seconds=${2:-60}
        local deadline=$((SECONDS + timeout_seconds))
        local current=""
        while (( SECONDS < deadline )); do
            current=$(capture_vga) || return 5
            if grep -Fq "$expected" <<<"$current" &&
               grep -Fq 'orange:/$' <<<"$current"; then
                printf '%s\n' "$current"
                return 0
            fi
            if grep -Fq 'KERNEL PANIC' <<<"$current" ||
               grep -Fq 'System Halted' <<<"$current"; then
                printf '%s\n' "$current" >&2
                return 1
            fi
            sleep 1
        done
        printf '%s\n' "$current" >&2
        return 1
    }

    send_key ctrl-c || return 5
    sleep 1
    output=$(capture_vga) || return $?
    if ! grep -Fq '^C' <<<"$output" || ! grep -Fq 'orange:/$' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf '[input.stress] idle Ctrl+C assertion failed\n' >&2
        return 1
    fi

    send_text_slow 'run sleep.elf 1000' || return $?
    sleep 1
    send_key ctrl-c || return 5
    sleep 2
    output=$(capture_vga) || return $?
    if ! grep -Fq 'run: child terminated by exception' <<<"$output" ||
       ! grep -Fq 'orange:/$' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf '[input.stress] foreground sleep Ctrl+C assertion failed\n' >&2
        return 1
    fi

    send_text_slow 'run sync-demo.elf' || return $?
    sleep 2
    send_key ctrl-c || return 5
    sleep 2
    output=$(capture_vga) || return $?
    if ! grep -Fq 'run: child terminated by exception' <<<"$output" ||
       ! grep -Fq 'orange:/$' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf '[input.stress] foreground sync Ctrl+C assertion failed\n' >&2
        return 1
    fi

    for i in $(seq 1 20); do
        if [ "$i" -eq 20 ]; then
            text='echo stress-20'
        else
            text='echo x'
        fi
        for ((j = 0; j < ${#text}; j++)); do
            ch=${text:j:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
                *) key=$ch;;
            esac
            send_key "$key" || return 5
            sleep "$key_delay"
        done
        send_key ret || return 5
        sleep "$command_delay"
    done

    output=$(wait_for_output stress-20 90) || return $?
    if ! grep -Fq 'stress-20' <<<"$output" || ! grep -Fq 'orange:/$' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf '[input.stress] fast input batch assertion failed\n' >&2
        return 1
    fi
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[input.stress] Ctrl+C and 20-command fast input pressure: PASSED\n'
}
