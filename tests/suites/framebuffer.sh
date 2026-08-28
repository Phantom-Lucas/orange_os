suite_framebuffer_core() {
    local mode=${FB_TEST_MODE:-1280x720}
    local width=${mode%x*} height=${mode#*x}
    local disk_image="$TEST_WORK_DIR/disk.img"
    local monitor_socket image="$TEST_CASE_DIR/framebuffer-${mode}.ppm"
    cd "$ROOT_DIR" || return 3
    CONSOLE_BACKEND=qemu-fb FB_MODE="$mode" BOOT_DIAGNOSTIC=0 \
        make DISK_IMAGE="$disk_image" DISK_SIZE=64M bootstrap || return 3
    monitor_socket=$(qemu_socket_path "$TEST_WORK_DIR/monitor.sock")
    qemu_start "$monitor_socket" -vga std \
        -drive "file=$disk_image,format=raw,index=0,media=disk" \
        -m "${QEMU_MEMORY:-512M}" -display none
    trap 'qemu_stop' EXIT
    qemu_wait_ready "$monitor_socket" || return 5
    sleep "${QEMU_BOOT_WAIT:-8}"
    monitor_screendump "$monitor_socket" "$image" || return 5
    check_framebuffer_screenshot "$image" "$width" "$height" || return 1
    monitor_send "$monitor_socket" quit || return 5
    qemu_wait_exit
}
