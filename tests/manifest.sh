#!/usr/bin/env bash

source "$ROOT_DIR/tests/suites/build.sh"
source "$ROOT_DIR/tests/suites/mkfs.sh"
source "$ROOT_DIR/tests/suites/boot.sh"
source "$ROOT_DIR/tests/suites/lba48.sh"
source "$ROOT_DIR/tests/suites/vm.sh"
source "$ROOT_DIR/tests/suites/sync.sh"
source "$ROOT_DIR/tests/suites/userland.sh"
source "$ROOT_DIR/tests/suites/fs.sh"
source "$ROOT_DIR/tests/suites/tty.sh"
source "$ROOT_DIR/tests/suites/input.sh"
source "$ROOT_DIR/tests/suites/integration.sh"
source "$ROOT_DIR/tests/suites/showcase.sh"
source "$ROOT_DIR/tests/suites/framebuffer.sh"
source "$ROOT_DIR/tests/suites/shell_editor.sh"
source "$ROOT_DIR/tests/suites/legacy.sh"

register_case build artifacts fast 120 suite_build_artifacts
register_case mkfs index fast 120 suite_mkfs_index
register_case mkfs lba48 full 180 suite_mkfs_lba48
register_case boot quiet full 120 suite_boot_quiet
register_case boot dynamic-loader full 150 suite_boot_dynamic_loader
register_case lba48 boot full 360 suite_lba48_boot
register_case fs service full 300 suite_fs_service
register_case tty shell full 360 suite_tty_shell
register_case userland core full 300 suite_userland_core
register_case input stress full 300 suite_input_stress
register_case sync core full 360 suite_sync_core
register_case sync stress stress 1800 suite_sync_stress
register_case vm cow full 240 suite_vm_cow
register_case integration smoke full 1200 suite_integration_smoke
register_case showcase core full 360 suite_showcase_core
register_case framebuffer core full 180 suite_framebuffer_core
register_case shell editor full 240 suite_shell_editor
