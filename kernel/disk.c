// kernel/disk.c
#include "disk.h"
#include "io.h"
#include "print.h"
#include "sync.h"

// ================= ATA PIO 寄存器 =================
#define ATA_DATA         0x1F0
#define ATA_ALT_STATUS   0x3F6
#define ATA_ERROR        0x1F1
#define ATA_SECTOR_COUNT 0x1F2
#define ATA_LBA_LOW      0x1F3
#define ATA_LBA_MID      0x1F4
#define ATA_LBA_HIGH     0x1F5
#define ATA_DRV_HEAD     0x1F6
#define ATA_COMMAND      0x1F7

// ================= ATA 状态/命令 =================
#define ATA_SR_ERR               0x01
#define ATA_SR_DRQ               0x08
#define ATA_SR_BSY               0x80
#define ATA_CMD_READ_SECTORS_EXT  0x24
#define ATA_CMD_WRITE_SECTORS_EXT 0x34
#define ATA_CMD_FLUSH_CACHE_EXT   0xEA
#define ATA_DEVICE_MASTER_LBA48   0x40
#define ATA_MAX_LBA48             0x0000FFFFFFFFFFFFULL
#define ATA_TIMEOUT               1000000U
#define ATA_MAX_SECTORS_PER_CMD  256U

static spinlock_t disk_lock;
static int disk_ready;

/* ATA 要求选择设备后至少等待约 400ns；连续访问状态寄存器也用它
   让 QEMU/真实控制器完成前一个 task-file 操作。 */
static void ata_io_wait(void) {
    (void)inb(ATA_ALT_STATUS);
    (void)inb(ATA_ALT_STATUS);
    (void)inb(ATA_ALT_STATUS);
    (void)inb(ATA_ALT_STATUS);
}

static void ata_soft_reset(void) {
    outb(ATA_ALT_STATUS, 0x04);
    ata_io_wait();
    outb(ATA_ALT_STATUS, 0x00);
    ata_io_wait();
}

static int ata_wait_busy(void) {
    for (uint32_t i = 0; i < ATA_TIMEOUT; i++) {
        uint8_t status = inb(ATA_COMMAND);
        if (!(status & ATA_SR_BSY)) return (status & ATA_SR_ERR) ? -1 : 0;
    }
    return -1;
}

static int ata_wait_drq(void) {
    for (uint32_t i = 0; i < ATA_TIMEOUT; i++) {
        uint8_t status = inb(ATA_COMMAND);
        if (status & ATA_SR_ERR) return -1;
        if (status & ATA_SR_DRQ) return 0;
    }
    return -1;
}

static int ata_select_lba48(void) {
    /* LBA48 的高地址不再放入 device/head；这里选择 master + LBA 模式，
       随后的 6 个 task-file 写入负责完整的 48 位地址。 */
    outb(ATA_DRV_HEAD, ATA_DEVICE_MASTER_LBA48);
    ata_io_wait();
    return ata_wait_busy();
}

static void ata_program_lba48(uint64_t lba, uint32_t sector_count) {
    /* ATA-6 要求高字节 task file 先写、低字节 task file 后写。一次命令
       最多传输 256 个扇区，计数寄存器中的 0 表示 256。 */
    outb(ATA_SECTOR_COUNT, (uint8_t)((sector_count >> 8) & 0xFF));
    outb(ATA_LBA_LOW,  (uint8_t)((lba >> 24) & 0xFF));
    outb(ATA_LBA_MID,  (uint8_t)((lba >> 32) & 0xFF));
    outb(ATA_LBA_HIGH, (uint8_t)((lba >> 40) & 0xFF));
    outb(ATA_SECTOR_COUNT, sector_count == 256 ? 0 : (uint8_t)sector_count);
    outb(ATA_LBA_LOW,  (uint8_t)(lba & 0xFF));
    outb(ATA_LBA_MID,  (uint8_t)((lba >> 8) & 0xFF));
    outb(ATA_LBA_HIGH, (uint8_t)((lba >> 16) & 0xFF));
}

void disk_init(void) {
    /* 当前阶段固定使用 QEMU/ATA master；LBA48 命令不依赖 IDENTIFY
       的容量字段，但设备必须实现 ATA-6 EXT PIO 命令。 */
    spinlock_init(&disk_lock);
    disk_ready = 1;
    print_debug("[DISK] ATA PIO LBA48 Disk Driver Initialized.\n");
}

static int disk_read_sector_once(uint64_t lba, uint8_t* buffer,
                                 uint32_t sector_count) {
    if (!disk_ready || buffer == 0 || sector_count == 0 ||
        sector_count > ATA_MAX_SECTORS_PER_CMD || lba > ATA_MAX_LBA48 ||
        (uint64_t)(sector_count - 1) > ATA_MAX_LBA48 - lba)
        return -1;

    spinlock_acquire(&disk_lock);
    if (ata_select_lba48() != 0) goto fail;
    ata_program_lba48(lba, sector_count);
    outb(ATA_COMMAND, ATA_CMD_READ_SECTORS_EXT);
    ata_io_wait();

    uint16_t* ptr = (uint16_t*)buffer;
    for (uint32_t i = 0; i < sector_count; i++) {
        if (ata_wait_busy() != 0 || ata_wait_drq() != 0) goto fail;
        for (int j = 0; j < 256; j++) *ptr++ = inw(ATA_DATA);
    }
    spinlock_release(&disk_lock);
    return 0;

fail:
    ata_soft_reset();
    spinlock_release(&disk_lock);
    return -1;
}

int disk_read_sector_checked(uint64_t lba, uint8_t* buffer,
                             uint32_t sector_count) {
    for (uint32_t retry = 0; retry < 3; retry++) {
        if (disk_read_sector_once(lba, buffer, sector_count) == 0) return 0;
    }
    return -1;
}

static int disk_write_sector_once(uint64_t lba, const uint8_t* buffer,
                                  uint32_t sector_count) {
    if (!disk_ready || buffer == 0 || sector_count == 0 ||
        sector_count > ATA_MAX_SECTORS_PER_CMD || lba > ATA_MAX_LBA48 ||
        (uint64_t)(sector_count - 1) > ATA_MAX_LBA48 - lba)
        return -1;

    spinlock_acquire(&disk_lock);
    if (ata_select_lba48() != 0) goto fail;
    ata_program_lba48(lba, sector_count);
    outb(ATA_COMMAND, ATA_CMD_WRITE_SECTORS_EXT);
    ata_io_wait();

    const uint16_t* ptr = (const uint16_t*)buffer;
    for (uint32_t i = 0; i < sector_count; i++) {
        if (ata_wait_busy() != 0 || ata_wait_drq() != 0) goto fail;
        for (int j = 0; j < 256; j++) outw(ATA_DATA, *ptr++);
    }
    outb(ATA_COMMAND, ATA_CMD_FLUSH_CACHE_EXT);
    if (ata_wait_busy() != 0) goto fail;
    spinlock_release(&disk_lock);
    return 0;

fail:
    ata_soft_reset();
    spinlock_release(&disk_lock);
    return -1;
}

int disk_write_sector_checked(uint64_t lba, const uint8_t* buffer,
                              uint32_t sector_count) {
    for (uint32_t retry = 0; retry < 3; retry++) {
        if (disk_write_sector_once(lba, buffer, sector_count) == 0) return 0;
    }
    return -1;
}

void disk_read_sector(uint64_t lba, uint8_t* buffer, uint32_t sector_count) {
    (void)disk_read_sector_checked(lba, buffer, sector_count);
}

void disk_write_sector(uint64_t lba, const uint8_t* buffer, uint32_t sector_count) {
    (void)disk_write_sector_checked(lba, buffer, sector_count);
}
