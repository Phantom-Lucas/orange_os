suite_shell_editor() {
    local disk_image="$TEST_WORK_DIR/disk.img" monitor_socket vga="$TEST_WORK_DIR/vga.bin"
    local output="" key_delay=${QEMU_KEY_DELAY:-0.12} key ch i
    cd "$ROOT_DIR" || return 3
    BOOT_DIAGNOSTIC=0 make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-8}"
    send_key() { monitor_send "$monitor_socket" "sendkey $1" || return 5; sleep "$key_delay"; }
    type_text() {
        local text=$1
        for ((i=0; i<${#text}; i++)); do
            ch=${text:i:1}; case "$ch" in ' ') key=spc;; '-') key=minus;; '/') key=slash;; *) key=$ch;; esac
            send_key "$key" || return $?
        done
    }
    capture() { monitor_send "$monitor_socket" "pmemsave 0xb8000 0xfa0 \"$vga\"" || return 5; monitor_decode_vga "$vga"; }
    type_text 'echo ac' || return $?
    send_key left || return $?
    send_key b || return $?
    send_key ret || return $?
    sleep 1
    output+="$(capture)"$'\n'
    send_key up || return $?
    send_key ret || return $?
    sleep 1
    output+="$(capture)"$'\n'
    type_text 'pw' || return $?
    send_key tab || return $?
    send_key ret || return $?
    sleep 1
    output+="$(capture)"$'\n'
    type_text 'echo search-token' || return $?
    send_key ret || return $?
    sleep 1
    send_key ctrl-r || return $?
    type_text search || return $?
    send_key ret || return $?
    send_key ret || return $?
    sleep 1
    output+="$(capture)"$'\n'
    grep -Fq 'abc' <<<"$output" && grep -Fq 'search-token' <<<"$output" || return 1
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
}
