// kernel/disk.h
#ifndef DISK_H
#define DISK_H
#include <stdint.h>

// 初始化磁盘驱动
void disk_init(void);

// LBA28 轮询阻塞读取扇区
// lba: 逻辑块地址 (扇区号)
// buffer: 接收数据的缓冲区地址
// sector_count: 要读取的扇区数量
void disk_read_sector(uint32_t lba, uint8_t* buffer, uint32_t sector_count);

#endif