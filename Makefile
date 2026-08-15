SHELL := /bin/bash

BUILD_DIR := build
KERNEL_BUILD_DIR := $(BUILD_DIR)/kernel
USER_RUNTIME_DIR := $(BUILD_DIR)/user
BUILD_STAMP := $(BUILD_DIR)/.dir
BOOT_CONFIG_STAMP := $(BUILD_DIR)/.boot-config
FS_CONFIG_STAMP := $(BUILD_DIR)/.fs-config

DISK_IMAGE ?= hd8G.img
DISK_SIZE ?= 8G
FS_START_LBA ?= 1000
QEMU_MEMORY ?= 1G
QEMU_CPUS ?= 1
BOOT_DIAGNOSTIC ?= 0
KERNEL_MAX_SECTORS := 188
SYNC_TEST_ROUNDS ?= 100
SYNC_WORKER_ROUNDS ?= 20000
VM_TEST_ROUNDS ?= 32

MBR_BIN := $(BUILD_DIR)/mbr.bin
LOADER_BIN := $(BUILD_DIR)/loader.bin
KERNEL_ELF := $(KERNEL_BUILD_DIR)/kernel.elf
KERNEL_BIN := $(KERNEL_BUILD_DIR)/kernel.bin
KERNEL_ASM := $(KERNEL_BUILD_DIR)/kernel.asm
MKFS := $(BUILD_DIR)/mkfs
USER_HELLO := $(BUILD_DIR)/hello.elf
USER_SHELL := $(BUILD_DIR)/shell.elf
USER_FAULT := $(BUILD_DIR)/fault.elf
USER_IPC_DEMO := $(BUILD_DIR)/ipc-demo.elf
USER_EXEC_DEMO := $(BUILD_DIR)/exec-demo.elf
USER_UACCESS := $(BUILD_DIR)/uaccess-demo.elf
USER_THREAD_DEMO := $(BUILD_DIR)/thread-demo.elf
USER_SYNC_DEMO := $(BUILD_DIR)/sync-demo.elf
USER_VM_DEMO := $(BUILD_DIR)/vm-demo.elf
USER_FS_DEMO := $(BUILD_DIR)/fs-demo.elf
USER_LIBC_DEMO := $(BUILD_DIR)/libc-demo.elf
USER_LIBC_TEST := $(BUILD_DIR)/libc-test.elf
USER_LS := $(BUILD_DIR)/ls.elf
USER_CAT := $(BUILD_DIR)/cat.elf
USER_ECHO := $(BUILD_DIR)/echo.elf
USER_MKDIR := $(BUILD_DIR)/mkdir.elf
USER_RM := $(BUILD_DIR)/rm.elf
USER_PWD := $(BUILD_DIR)/pwd.elf
USER_PS := $(BUILD_DIR)/ps.elf
USER_SLEEP := $(BUILD_DIR)/sleep.elf
USER_KILL := $(BUILD_DIR)/kill.elf
USER_CRT0 := $(USER_RUNTIME_DIR)/crt0.o
USER_LIBC := $(USER_RUNTIME_DIR)/libc.o
USER_LIBC_APPS := $(USER_LIBC_DEMO) $(USER_LIBC_TEST) $(USER_LS) $(USER_CAT) $(USER_ECHO) \
	$(USER_MKDIR) $(USER_RM) $(USER_PWD) $(USER_PS) $(USER_SLEEP) $(USER_KILL)
USER_APPS := $(USER_HELLO) $(USER_SHELL) $(USER_FAULT) $(USER_IPC_DEMO) $(USER_EXEC_DEMO) $(USER_UACCESS) $(USER_THREAD_DEMO) $(USER_SYNC_DEMO) $(USER_VM_DEMO) $(USER_FS_DEMO) $(USER_LIBC_APPS)
FS_IMAGE := $(BUILD_DIR)/fs.img

KERNEL_C_SOURCES := $(wildcard kernel/*.c)
KERNEL_C_OBJECTS := $(patsubst kernel/%.c,$(KERNEL_BUILD_DIR)/%.o,$(KERNEL_C_SOURCES))
KERNEL_ASM_OBJECTS := $(KERNEL_BUILD_DIR)/switch.o \
	$(KERNEL_BUILD_DIR)/gdt_flush.o \
	$(KERNEL_BUILD_DIR)/usermode.o \
	$(KERNEL_BUILD_DIR)/syscall_entry.o
KERNEL_OBJECTS := $(KERNEL_C_OBJECTS) $(KERNEL_ASM_OBJECTS)

KERNEL_CFLAGS := -m64 -mcmodel=large -ffreestanding -O2 -g \
	-DBOOT_DIAGNOSTIC=$(BOOT_DIAGNOSTIC) \
	-DFS_START_LBA=$(FS_START_LBA) \
	-mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mno-80387 \
	-fno-pic -fno-pie -fno-stack-protector \
	-fno-asynchronous-unwind-tables -fcf-protection=none -MMD -MP
KERNEL_DEP_FILES := $(KERNEL_C_OBJECTS:.o=.d)

-include $(KERNEL_DEP_FILES)

.PHONY: all build check check-all test-list test-fast test-all test test-self mkfs-index-check mkfs-lba48-check qemu-boot-check qemu-check qemu-fs-check qemu-shell-fs-check qemu-input-stress-check qemu-userland-check qemu-sync-check qemu-vm-check qemu-lba48-check FORCE \
	install-kernel format-fs bootstrap run debug clean help

all: build

build: $(MBR_BIN) $(LOADER_BIN) $(KERNEL_BIN) $(USER_APPS) $(MKFS) $(FS_IMAGE)

$(BUILD_STAMP):
	mkdir -p $(KERNEL_BUILD_DIR) $(USER_RUNTIME_DIR)
	touch $@

FORCE:

$(BOOT_CONFIG_STAMP): FORCE | $(BUILD_STAMP)
	@desired='BOOT_DIAGNOSTIC=$(BOOT_DIAGNOSTIC) FS_START_LBA=$(FS_START_LBA)'; \
	if [ ! -f "$@" ] || ! grep -Fxq "$$desired" "$@"; then \
		printf '%s\n' "$$desired" > "$@"; \
	fi

$(FS_CONFIG_STAMP): FORCE | $(BUILD_STAMP)
	@desired='DISK_SIZE=$(DISK_SIZE) FS_START_LBA=$(FS_START_LBA)'; \
	if [ ! -f "$@" ] || ! grep -Fxq "$$desired" "$@"; then \
		printf '%s\n' "$$desired" > "$@"; \
	fi

$(MBR_BIN): boot/mbr.S | $(BUILD_STAMP)
	nasm -o $@ $<

$(LOADER_BIN): boot/loader.S | $(BUILD_STAMP)
	nasm -o $@ $<

# BOOT_DIAGNOSTIC 改变时必须重编译，而不是只保证目录/标记文件存在；
# 否则 quiet/diagnostic 两种内核会因增量构建复用错误配置的目标文件。
$(KERNEL_BUILD_DIR)/%.o: kernel/%.c $(BUILD_STAMP) $(BOOT_CONFIG_STAMP)
	gcc $(KERNEL_CFLAGS) -c $< -o $@

# thread.c 同时包含进程生命周期和调度回收路径；以大小优化，确保启动
# Loader 的固定内核窗口仍有余量，不改变其 ABI 或运行时语义。
$(KERNEL_BUILD_DIR)/thread.o: kernel/thread.c $(BUILD_STAMP) $(BOOT_CONFIG_STAMP)
	gcc $(KERNEL_CFLAGS) -Os -c $< -o $@

$(KERNEL_BUILD_DIR)/process.o: kernel/process.c $(BUILD_STAMP) $(BOOT_CONFIG_STAMP)
	gcc $(KERNEL_CFLAGS) -Os -c $< -o $@

# 系统调用分发器包含用户边界检查和线程生命周期路径；以大小优化，
# 保持 loader 的固定 188 扇区内核加载窗口，同时不改变调用约定。
$(KERNEL_BUILD_DIR)/syscall.o: kernel/syscall.c $(BUILD_STAMP) $(BOOT_CONFIG_STAMP)
	gcc $(KERNEL_CFLAGS) -Os -c $< -o $@

$(KERNEL_BUILD_DIR)/switch.o: kernel/switch.S | $(BUILD_STAMP)
	nasm -f elf64 $< -o $@

$(KERNEL_BUILD_DIR)/gdt_flush.o: kernel/gdt_flush.S | $(BUILD_STAMP)
	gcc -m64 -mcmodel=large -c $< -o $@

$(KERNEL_BUILD_DIR)/usermode.o: kernel/usermode.S | $(BUILD_STAMP)
	gcc -m64 -mcmodel=large -c $< -o $@

$(KERNEL_BUILD_DIR)/syscall_entry.o: kernel/syscall_entry.S | $(BUILD_STAMP)
	gcc -m64 -mcmodel=large -c $< -o $@

$(KERNEL_ELF): $(KERNEL_OBJECTS) kernel/linker.ld
	ld -m elf_x86_64 -N -T kernel/linker.ld -no-pie --build-id=none -o $@ $(KERNEL_OBJECTS)

$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary -R .note -R .comment -R .note.gnu.property \
		-R .eh_frame -R .eh_frame_hdr $< $@

$(KERNEL_ASM): $(KERNEL_ELF)
	objdump -d $< > $@

$(MKFS): tools/mkfs.c | $(BUILD_STAMP)
	gcc $< -o $@

$(USER_HELLO): usr/hello.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_SHELL): usr/shell.c usr/syscall.h | $(BUILD_STAMP)
	 gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_FAULT): usr/fault.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_IPC_DEMO): usr/ipc_demo.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_EXEC_DEMO): usr/exec_demo.c usr/syscall.h | $(BUILD_STAMP)
	 gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_UACCESS): usr/uaccess_demo.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_THREAD_DEMO): usr/thread_demo.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_SYNC_DEMO): usr/sync_demo.c usr/thread_runtime.h usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie -O2 \
		-mno-red-zone -DSYNC_TEST_ROUNDS=$(SYNC_TEST_ROUNDS) \
		-DSYNC_WORKER_ROUNDS=$(SYNC_WORKER_ROUNDS) -e _start -o $@ $<

$(USER_VM_DEMO): usr/vm_demo.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -DVM_TEST_ROUNDS=$(VM_TEST_ROUNDS) \
		-e _start -o $@ $<

$(USER_FS_DEMO): usr/fs_demo.c usr/syscall.h | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $<

$(USER_CRT0): usr/crt0.S | $(BUILD_STAMP)
	mkdir -p $(USER_RUNTIME_DIR)
	gcc -m64 -ffreestanding -fno-pic -fno-pie -mno-red-zone -c $< -o $@

$(USER_LIBC): usr/libc.c usr/libc.h usr/syscall.h usr/thread_runtime.h | $(BUILD_STAMP)
	mkdir -p $(USER_RUNTIME_DIR)
	gcc -m64 -ffreestanding -fno-builtin -fno-stack-protector \
		-fno-pic -fno-pie -mno-red-zone -c $< -o $@

$(USER_LIBC_DEMO): usr/libc_demo.c usr/libc.h usr/syscall.h usr/thread_runtime.h \
		$(USER_CRT0) $(USER_LIBC) | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $(USER_CRT0) $(USER_LIBC) usr/libc_demo.c

$(USER_LIBC_TEST): usr/libc_test.c usr/test.h usr/libc.h usr/syscall.h \
		usr/thread_runtime.h $(USER_CRT0) $(USER_LIBC) | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $@ $(USER_CRT0) $(USER_LIBC) usr/libc_test.c

define build_libc_app
$(1): usr/$(2).c usr/libc.h usr/syscall.h usr/thread_runtime.h \
		$(USER_CRT0) $(USER_LIBC) | $(BUILD_STAMP)
	gcc -m64 -ffreestanding -nostdlib -fno-pic -fno-pie -no-pie \
		-mno-red-zone -e _start -o $$@ $(USER_CRT0) $(USER_LIBC) $$<
endef

$(eval $(call build_libc_app,$(USER_LS),ls))
$(eval $(call build_libc_app,$(USER_CAT),cat))
$(eval $(call build_libc_app,$(USER_ECHO),echo))
$(eval $(call build_libc_app,$(USER_MKDIR),mkdir))
$(eval $(call build_libc_app,$(USER_RM),rm))
$(eval $(call build_libc_app,$(USER_PWD),pwd))
$(eval $(call build_libc_app,$(USER_PS),ps))
$(eval $(call build_libc_app,$(USER_SLEEP),sleep))
$(eval $(call build_libc_app,$(USER_KILL),kill))

$(FS_IMAGE): $(MKFS) $(USER_APPS) $(FS_CONFIG_STAMP)
	$(MKFS) $@ --disk-size $(DISK_SIZE) --start-lba $(FS_START_LBA) $(USER_APPS)

$(DISK_IMAGE):
	truncate -s $(DISK_SIZE) $@

check: build
	./tests/check_build.sh $(KERNEL_MAX_SECTORS) $(MBR_BIN) $(LOADER_BIN) $(KERNEL_BIN) $(KERNEL_ELF) $(USER_HELLO) $(FS_IMAGE)

check-all:
	$(MAKE) test-all

test-list:
	bash ./tests/run.sh --list

test-fast:
	bash ./tests/run.sh --profile fast

test-all:
	bash ./tests/run.sh --profile full

test-self:
	bash ./tests/selftest_runner.sh

test:
	bash ./tests/run.sh \
		$(if $(SUITE),--suite $(SUITE),) \
		$(if $(CASE),--case $(CASE),) \
		$(if $(REPEAT),--repeat $(REPEAT),) \
		$(if $(SEED),--seed $(SEED),) \
		$(if $(PROFILE),--profile $(PROFILE),) \
		$(if $(TIMEOUT),--timeout $(TIMEOUT),) \
		$(if $(KEEP_FAILED),--keep-failed,)

mkfs-index-check: build
	bash ./tests/run.sh --case mkfs.index

mkfs-lba48-check: build
	bash ./tests/run.sh --case mkfs.lba48

qemu-boot-check:
	bash ./tests/run.sh --case boot.quiet

qemu-check:
	bash ./tests/run.sh --case integration.smoke

qemu-fs-check:
	bash ./tests/run.sh --case fs.service

qemu-shell-fs-check:
	bash ./tests/run.sh --case tty.shell

qemu-input-stress-check:
	bash ./tests/run.sh --case input.stress

qemu-userland-check:
	bash ./tests/run.sh --case userland.core

qemu-sync-check:
	bash ./tests/run.sh --case sync.core

qemu-vm-check:
	bash ./tests/run.sh --case vm.cow

qemu-lba48-check:
	bash ./tests/run.sh --case lba48.boot

install-kernel: $(DISK_IMAGE) $(MBR_BIN) $(LOADER_BIN) $(KERNEL_BIN)
	dd if=$(MBR_BIN) of=$(DISK_IMAGE) bs=512 count=1 conv=notrunc,fdatasync
	dd if=$(LOADER_BIN) of=$(DISK_IMAGE) bs=512 seek=2 conv=notrunc,fdatasync
	dd if=$(KERNEL_BIN) of=$(DISK_IMAGE) bs=512 seek=10 conv=notrunc,fdatasync

# This target intentionally overwrites the MyFS area. Use it only when a fresh
# filesystem image or a new bundled user program is desired.
format-fs: $(DISK_IMAGE) $(FS_IMAGE)
	# MyFS 镜像是稀疏文件；保留空洞，否则 8GB 测试会把宿主机空间
	# 错误地消耗完，同时失去大容量磁盘的快速创建优势。
	dd if=$(FS_IMAGE) of=$(DISK_IMAGE) bs=512 seek=$(FS_START_LBA) conv=notrunc,fdatasync,sparse

bootstrap: install-kernel format-fs

run: install-kernel
	qemu-system-x86_64 -drive file=$(DISK_IMAGE),format=raw,index=0,media=disk \
		-m $(QEMU_MEMORY) -smp $(QEMU_CPUS) -d int,cpu_reset -D qemu.log -no-reboot -no-shutdown

debug: install-kernel
	qemu-system-x86_64 -drive file=$(DISK_IMAGE),format=raw,index=0,media=disk \
		-m $(QEMU_MEMORY) -smp $(QEMU_CPUS) -S -s -no-reboot -no-shutdown

clean:
	rm -rf $(BUILD_DIR)

help:
	@printf '%s\n' \
		'make build          Build all binaries into build/.' \
		'make check          Build and validate boot/kernel/ELF/MyFS artifacts.' \
		'make check-all       Run quiet/diagnostic builds and the complete QEMU test matrix.' \
		'make test-list       List unified suite/case/profile/timeout entries.' \
		'make test-fast       Run the unified fast profile.' \
		'make test-all        Run the unified full profile.' \
		'make test-self       Run runner self-tests without QEMU.' \
		'make test CASE=vm.cow SEED=123 REPEAT=20 KEEP_FAILED=1  Run selected cases.' \
		'make qemu-boot-check Verify concise startup, disk gate, and Shell readiness.' \
		'make qemu-check     Run QEMU boot, TTY/FS services, fork, persistence, IPC, spawn/exec, and fault tests.' \
		'make qemu-fs-check  Run filesystem reboot, directory, dup, pipe, and resource tests.' \
		'make qemu-shell-fs-check  Run shell redirection and pipeline tests.' \
		'make qemu-input-stress-check  Run Ctrl+C and fast keyboard input pressure tests.' \
		'make qemu-userland-check  Run crt0/libc/argv/external-command tests.' \
		'make qemu-sync-check  Run user mutex/condvar/futex/TLS/thread lifecycle tests.' \
		'make qemu-vm-check    Run COW/mmap/page-fault tests.' \
		'make qemu-lba48-check Boot a sparse 256GiB image with MyFS above 128GiB.' \
		'make mkfs-lba48-check Verify formatting beyond the old LBA28 boundary.' \
		'make BOOT_DIAGNOSTIC=1 run  Run with full kernel startup diagnostics.' \
		'make install-kernel Write only MBR, loader, and kernel to $(DISK_IMAGE).' \
		'make format-fs      Explicitly replace the MyFS area of $(DISK_IMAGE).' \
		'make DISK_SIZE=128M bootstrap  Create a new 128MiB disk image.' \
		'make QEMU_MEMORY=2G QEMU_CPUS=1 run  Run QEMU with 2GiB memory.' \
		'make bootstrap      Install kernel and format a fresh MyFS image.' \
		'make run            Install kernel and launch QEMU.' \
		'make debug          Launch QEMU paused for gdb on tcp:1234.'
