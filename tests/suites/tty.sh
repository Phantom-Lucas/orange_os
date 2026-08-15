#!/usr/bin/env bash

suite_tty_shell() {
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket
    local vga_image="$TEST_WORK_DIR/vga.bin"
    local output=""
    local after_clear scrolled command_text ch key i
    local key_delay=${QEMU_KEY_DELAY:-0.20}

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

    send_text() {
        local text=$1
        for ((i = 0; i < ${#text}; i++)); do
            ch=${text:i:1}
            case "$ch" in
                ' ') key=spc;; '.') key=dot;; '-') key=minus;; '/') key=slash;;
                '>') key=shift-dot;; '<') key=shift-comma;; '|') key=shift-backslash;;
                *) key=$ch;;
            esac
            send_key "$key" || return 5
            sleep "$key_delay"
        done
        send_key ret || return 5
    }

    capture_vga() {
        monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga_image\"" || return 5
        monitor_decode_vga "$vga_image"
    }

    run_and_capture() {
        send_text "$1" || return $?
        sleep "${2:-1}"
        output+="$(capture_vga)"$'\n'
    }

    run_and_capture 'echo shellredirectok > shell-redir' || return $?
    run_and_capture 'echo shellappendok >> shell-redir' || return $?
    run_and_capture 'cat shell-redir' || return $?
    run_and_capture 'cat < shell-redir' || return $?
    run_and_capture 'echo shellpipeok | cat -' 2 || return $?
    run_and_capture 'echo shellbackgroundok > bg-file &' || return $?
    run_and_capture 'cat bg-file' 2 || return $?
    run_and_capture 'mkdir shell-dir' || return $?
    run_and_capture 'cd shell-dir' || return $?
    run_and_capture 'pwd' || return $?
    run_and_capture 'cd /' || return $?
    run_and_capture 'rm shell-redir' || return $?
    run_and_capture 'rm bg-file' || return $?
    run_and_capture 'rm shell-dir' || return $?
    run_and_capture 'echo clear-before' || return $?
    send_text clear || return $?
    sleep 1
    after_clear=$(capture_vga) || return $?
    output+="$after_clear"$'\n'
    run_and_capture 'echo clear-after' || return $?
    run_and_capture 'echo scroll-marker' || return $?
    for _ in 1 2 3; do
        run_and_capture ls || return $?
    done
    for _ in 1 2 3; do
        send_key pgup || return $?
        sleep 0.2
    done
    sleep 1
    scrolled=$(capture_vga) || return $?
    output+="$scrolled"$'\n'
    run_and_capture 'echo input-after-scroll' || return $?
    send_key pgdn || return $?
    sleep 1
    run_and_capture 'echo scroll-after' || return $?

    local redirect_count append_count pipe_count background_count
    redirect_count=$(grep -o 'shellredirectok' <<<"$output" | wc -l)
    append_count=$(grep -o 'shellappendok' <<<"$output" | wc -l)
    pipe_count=$(grep -o 'shellpipeok' <<<"$output" | wc -l)
    background_count=$(grep -o 'shellbackgroundok' <<<"$output" | wc -l)
    if [ "$redirect_count" -lt 2 ] || [ "$append_count" -lt 2 ] ||
       [ "$pipe_count" -lt 2 ] || [ "$background_count" -lt 2 ] ||
       ! grep -Fq '/shell-dir' <<<"$output" ||
       grep -Fq 'clear-before' <<<"$after_clear" ||
       ! grep -Fq 'scroll-marker' <<<"$scrolled" ||
       ! grep -Fq 'input-after-scroll' <<<"$output" ||
       ! grep -Fq 'scroll-after' <<<"$output"; then
        printf '%s\n' "$output" >&2
        printf '[tty.shell] assertion failed: redirect=%s append=%s pipe=%s background=%s\n' \
            "$redirect_count" "$append_count" "$pipe_count" "$background_count" >&2
        return 1
    fi
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
    printf '%s\n' "$output"
    printf '[tty.shell] redirection, pipeline, cwd, clear and scrollback: PASSED\n'
}
