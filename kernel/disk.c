// kernel/disk.c
#include "disk.h"
#include "io.h"
#include "print.h"

// ================= ATA PIO 寄存器端口 =================
#define ATA_DATA         0x1F0  // 数据寄存器 (16-bit)
#define ATA_ERROR        0x1F1  // 错误寄存器
#define ATA_SECTOR_COUNT 0x1F2  // 扇区数寄存器
#define ATA_LBA_LOW      0x1F3  // LBA 0~7 位
#define ATA_LBA_MID      0x1F4  // LBA 8~15 位
#define ATA_LBA_HIGH     0x1F5  // LBA 16~23 位
#define ATA_DRV_HEAD     0x1F6  // 驱动器/磁头寄存器 (及 LBA 24~27 位)
#define ATA_COMMAND      0x1F7  // 命令寄存器 (写) / 状态寄存器 (读)

// ================= ATA 状态位 =================
#define ATA_SR_ERR  0x01    // 错误位 (Error)
#define ATA_SR_DRQ  0x08    // 数据请求位 (Data Request)
#define ATA_SR_BSY  0x80    // 忙碌位 (Busy)

// 等待磁盘解除忙碌状态
static void ata_wait_busy(void) {
    while (inb(ATA_COMMAND) & ATA_SR_BSY) {
        // 无限循环等待 BSY 位清零
    }
}

// 等待磁盘准备好数据传输
static void ata_wait_drq(void) {
    while (!(inb(ATA_COMMAND) & ATA_SR_DRQ)) {
        // 判断是否发生错误
        if (inb(ATA_COMMAND) & ATA_SR_ERR) {
            print_error("[DISK] ATA Read Error!\n");
            return;
        }
    }
}

void disk_init(void) {
    // 可以在这里发送 IDENTIFY 命令 (0xEC) 获取硬盘参数。
    // 为了当前阶段的简洁，我们假设默认挂载的 master 磁盘支持 LBA 模式。
    print_info("[DISK] ATA PIO Disk Driver Initialized.\n");
}

void disk_read_sector(uint32_t lba, uint8_t* buffer, uint32_t sector_count) {
    // 1. 等待磁盘空闲
    ata_wait_busy();

    // 2. 选择驱动器与 LBA 最高4位 (0xE0 表示：LBA 模式，Master 驱动器)
    outb(ATA_DRV_HEAD, 0xE0 | ((lba >> 24) & 0x0F));

    // 3. 写入要读取的扇区数量 (0 表示 256 个扇区)
    outb(ATA_SECTOR_COUNT, sector_count);

    // 4. 写入 LBA 的低中高三段 8 位地址
    outb(ATA_LBA_LOW,  (uint8_t)(lba & 0xFF));
    outb(ATA_LBA_MID,  (uint8_t)((lba >> 8) & 0xFF));
    outb(ATA_LBA_HIGH, (uint8_t)((lba >> 16) & 0xFF));

    // 5. 发送读取命令 (0x20: Read Sectors with Retry)
    outb(ATA_COMMAND, 0x20);

    // 6. 循环读取请求的扇区
    uint16_t* ptr = (uint16_t*)buffer;
    for (uint32_t i = 0; i < sector_count; i++) {
        // 每个扇区准备读取前，都要等待 BSY 清零，且 DRQ 置位
        ata_wait_busy();
        ata_wait_drq();
        
        // 每次读取 256 个 16-bit 的字 = 512 字节
        for (int j = 0; j < 256; j++) {
            *ptr = inw(ATA_DATA);
            ptr++;
        }
    }
}