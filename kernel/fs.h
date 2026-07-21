// kernel/fs.h
#ifndef FS_H
#define FS_H
#include <stdint.h>

#define FS_MAGIC 0x19980811
#define FS_START_LBA 1000 // 我们在 start.sh 中指定的写入位置

// 超级块 (与宿主机 mkfs.c 保持完全一致)
struct super_block {
    uint32_t magic;
    uint32_t block_size;
    uint32_t total_inodes;
    uint32_t total_blocks;
    uint32_t imap_blocks;
    uint32_t bmap_blocks;
    uint32_t inode_blocks;
    uint32_t first_data_block;
};

// kernel/fs.h (追加以下内容)

// 索引节点 (精准 64 字节)
struct inode {
    uint32_t size;              // 文件大小 (字节)
    uint16_t type;              // 1: 目录, 2: 文件
    uint16_t link_count;        // 链接数
    uint32_t direct_blocks[11]; // 11个直接指针
    uint32_t indirect_1;        // 一级间接指针
    uint32_t indirect_2;        // 二级间接指针
    uint32_t padding[2];        // 填充对齐
};

// 目录项 (精准 64 字节)
struct dir_entry {
    uint32_t inode_nr;          // Inode 编号 (0表示空)
    char name[60];              // 文件名
};


// 初始化并挂载文件系统
void fs_init(void);

// 根据文件名在根目录中查找文件，返回该文件的 Inode 结构体
// 返回值: 1 表示成功，0 表示失败 (未找到)
int fs_find_file(const char* filename, struct inode* out_inode);

#endif