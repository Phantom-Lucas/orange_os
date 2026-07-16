#!/bin/bash
set -e 

# ==========================================
# 0. 检查当前运行目录
# ==========================================
if [ ! -f "hd60M.img" ]; then
    echo "错误：请在项目根目录 (my_os) 下运行此脚本！"
    exit 1
fi

# 强行杀死卡在后台的旧 QEMU 进程，防止文件锁定
killall -9 qemu-system-x86_64 2>/dev/null || true

# 自动兼容 Linux (GNU) 和 macOS (BSD) 的文件大小获取函数
get_file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1"
}

# ==========================================
# 1. 自动清理旧的编译残留
# ==========================================
rm -f boot/*.bin kernel/*.o kernel/*.bin kernel/*.elf kernel/*.asm qemu.log

# ==========================================
# 2. 编译 MBR 与 Loader
# ==========================================
nasm -o boot/mbr.bin boot/mbr.S
nasm -o boot/loader.bin boot/loader.S

# ==========================================
# 3. 编译：循环独立编译 kernel/ 目录下的所有 C 文件
# ==========================================
# 修改 build.sh 中的 GCC 编译命令，加入 -fcf-protection=none
for file in kernel/*.c; do
    echo "Compiling $file..."
    gcc -m64 -ffreestanding -O2 -g -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -mno-80387 \
        -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables \
        -fcf-protection=none \
        -c "$file" -o "${file%.c}.o"
done

# ==========================================
# 4. 链接为 ELF 并提取 Flat Binary
#    - 链接时增加 --build-id=none 阻止生成构建签名段
#    - 提取时增加 -R 强制删除无用的 note/eh_frame 段
# ==========================================
OBJ_FILES=$(ls kernel/*.o)
echo "Linking object files: $OBJ_FILES"
ld -m elf_x86_64 -N -T kernel/linker.ld -no-pie --build-id=none -o kernel/kernel.elf $OBJ_FILES

# 反汇编内核以供核对
echo "Disassembling kernel for debugging..."
objdump -d kernel/kernel.elf > kernel/kernel.asm

echo "Extracting Flat Binary..."
objcopy -O binary \
    -R .note -R .comment -R .note.gnu.property -R .eh_frame -R .eh_frame_hdr \
    kernel/kernel.elf kernel/kernel.bin

# ==========================================
# 安全检查与文件体积输出（帮您直观排查零填充）
# ==========================================
LOADER_SIZE=$(get_file_size "boot/loader.bin")
KERNEL_SIZE=$(get_file_size "kernel/kernel.bin")

echo "--------------------------------------------------------"
echo "编译完成！当前核心二进制文件体积如下："
echo ">> boot/loader.bin 实际大小: $LOADER_SIZE 字节 (最大限制 4096 字节)"
echo ">> kernel/kernel.bin 实际大小: $KERNEL_SIZE 字节"
echo "--------------------------------------------------------"

if [ "$LOADER_SIZE" -gt 4096 ]; then
    echo "警告: Loader 超出 4096 字节，会覆盖 LBA 10 处的内核！"
    exit 1
fi

MAX_KERNEL_SIZE=$((42 * 512))
if [ "$KERNEL_SIZE" -gt "$MAX_KERNEL_SIZE" ]; then
    echo "警告: kernel.bin 大小 ($KERNEL_SIZE 字节) 超过了 MBR 默认读取的最大限制!"
    exit 1
fi

# ==========================================
# 5. 烧录到虚拟硬盘镜像 hd60M.img 中
# ==========================================
echo "Writing binary files to disk image..."
dd if=boot/mbr.bin of=hd60M.img bs=512 count=1 conv=notrunc,fdatasync
dd if=boot/loader.bin of=hd60M.img bs=512 seek=2 conv=notrunc,fdatasync
dd if=kernel/kernel.bin of=hd60M.img bs=512 seek=10 conv=notrunc,fdatasync

# ==========================================
# 6. 启动 QEMU 模拟器
# ==========================================
echo "Starting QEMU..."
qemu-system-x86_64 \
    -drive file=hd60M.img,format=raw,index=0,media=disk \
    -m 512M \
    -d int,cpu_reset \
    -D qemu.log \
    -no-reboot \
    -no-shutdown