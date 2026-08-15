// kernel/disk.h
#ifndef DISK_H
#define DISK_H
#include <stdint.h>

// 初始化磁盘驱动
void disk_init(void);

/* 返回 0 表示完整成功；负值表示参数、超时或 ATA 错误。
   LBA 使用 64 位类型，驱动实际按 ATA LBA48 发出 EXT 命令。 */
int disk_read_sector_checked(uint64_t lba, uint8_t* buffer,
                             uint32_t sector_count);
int disk_write_sector_checked(uint64_t lba, const uint8_t* buffer,
                              uint32_t sector_count);

// LBA48 轮询阻塞读取扇区
// lba: 逻辑块地址 (扇区号)
// buffer: 接收数据的缓冲区地址
// sector_count: 要读取的扇区数量
void disk_read_sector(uint64_t lba, uint8_t* buffer, uint32_t sector_count);

// LBA48 轮询阻塞写入扇区。
void disk_write_sector(uint64_t lba, const uint8_t* buffer, uint32_t sector_count);

#endif
