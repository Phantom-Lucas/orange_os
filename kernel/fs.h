// kernel/fs.h
#ifndef FS_H
#define FS_H
#include <stdint.h>

#define FS_MAGIC 0x19980811
#define FS_FORMAT_VERSION 4
#ifndef FS_START_LBA
#define FS_START_LBA 1000 // Makefile 传入的 MyFS 起始扇区
#endif
#define FS_ATA_LBA48_MAX 0x0000FFFFFFFFFFFFULL
#define FS_BLOCK_SIZE 4096
#define FS_SECTOR_SIZE 512
#define FS_SECTORS_PER_BLOCK (FS_BLOCK_SIZE / FS_SECTOR_SIZE)
#define FS_MAX_BLOCKS_LBA48 ((FS_ATA_LBA48_MAX - (uint64_t)FS_START_LBA + 1ULL) / \
                             FS_SECTORS_PER_BLOCK)
#define FS_ROOT_INODE 1
#define FS_NAME_MAX 60
#define FS_PATH_MAX 256
#define FS_DIRECT_BLOCKS 11
#define FS_INDIRECT_ENTRIES (FS_BLOCK_SIZE / sizeof(uint32_t))
#define FS_SINGLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES)
#define FS_DOUBLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES)
#define FS_TRIPLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES * \
                               FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES)
#define FS_MAX_FILE_BLOCKS ((uint64_t)FS_DIRECT_BLOCKS + \
                            FS_SINGLE_FILE_BLOCKS + FS_DOUBLE_FILE_BLOCKS + \
                            FS_TRIPLE_FILE_BLOCKS)
#define FS_MAX_FILE_SIZE (FS_MAX_FILE_BLOCKS * FS_BLOCK_SIZE)
#define FS_TYPE_DIRECTORY 1
#define FS_TYPE_FILE 2

enum fs_request_operation {
    FS_REQUEST_OPEN = 1,
    FS_REQUEST_READ,
    FS_REQUEST_WRITE,
    FS_REQUEST_UNLINK,
    FS_REQUEST_LIST,
    FS_REQUEST_STAT,
    FS_REQUEST_MKDIR,
    FS_REQUEST_CHDIR,
    FS_REQUEST_GETCWD,
    FS_REQUEST_RELEASE,
};

/* 只在内核地址空间流转；buffer 指向系统调用层分配的内核暂存区。 */
struct fs_request {
    uint32_t operation;
    uint32_t flags;
    uint64_t offset;
    uint32_t length;
    uint8_t* buffer;
    int32_t result;
    char name[FS_PATH_MAX];
    char cwd_path[FS_PATH_MAX];
    uint32_t cwd_inode;
    uint32_t inode_nr;
    uint32_t result_type;
    uint64_t stat_size;
    uint32_t stat_links;
    uint32_t result_inode;
    char result_path[FS_PATH_MAX];
};

// 超级块 (与宿主机 mkfs.c 保持完全一致)。所有区域位置都记录在盘上，
// 内核不得再假定 inode bitmap/data bitmap/inode table 固定为 2/3/4 块。
struct super_block {
    uint32_t magic;
    uint32_t version;
    uint32_t block_size;
    uint32_t flags;
    uint32_t total_inodes;
    uint32_t total_blocks;

    uint32_t imap_start;
    uint32_t imap_blocks;

    uint32_t bmap_start;
    uint32_t bmap_blocks;

    uint32_t inode_start;
    uint32_t inode_blocks;
    uint32_t first_data_block;
};

// kernel/fs.h (追加以下内容)

// 索引节点：磁盘格式固定为 72 字节。inode 表按 4KiB 块存放，块尾
// 不足一个完整 inode 的空间保留不用；宿主机 mkfs.c 必须保持同一布局。
struct inode {
    uint64_t size;              // 文件大小 (字节)
    uint16_t type;              // 1: 目录, 2: 文件
    uint16_t link_count;        // 链接数
    uint32_t direct_blocks[11]; // 11个直接指针
    uint32_t indirect_1;        // 一级间接指针
    uint32_t indirect_2;        // 二级间接指针
    uint32_t indirect_3;        // 三级间接指针
    uint32_t flags;             // 保留，保持磁盘格式 8 字节对齐
};

typedef char fs_inode_must_be_72_bytes[(sizeof(struct inode) == 72) ? 1 : -1];

// 目录项 (精准 64 字节)
struct dir_entry {
    uint32_t inode_nr;          // Inode 编号 (0表示空)
    char name[60];              // 文件名
};


// 初始化并挂载文件系统
/* 返回 0 表示成功挂载，负值表示磁盘或超级块不可用。 */
int fs_init(void);
void fs_service_init(void);
int fs_service_call(struct fs_request* request);

// 根据文件名在根目录中查找文件，返回该文件的 Inode 结构体
// 返回值: 1 表示成功，0 表示失败 (未找到)
int fs_find_file(const char* filename, struct inode* out_inode);

int fs_create_file(const char* filename);
int fs_read_file(const char* filename, uint64_t offset, void* buffer, uint32_t length);
int fs_write_file(const char* filename, uint64_t offset, const void* buffer, uint32_t length);
int fs_unlink_file(const char* filename);
int fs_list_root(char* buffer, uint32_t length);
int fs_lookup_path(const char* path, uint32_t cwd_inode, uint32_t* out_inode,
                   struct inode* out_info);
int fs_create_path(const char* path, uint32_t cwd_inode, uint16_t type,
                   uint32_t* out_inode);
int fs_read_inode(uint32_t inode_nr, uint64_t offset, void* buffer,
                  uint32_t length);
int fs_write_inode(uint32_t inode_nr, uint64_t offset, const void* buffer,
                   uint32_t length);
void fs_release_inode(uint32_t inode_nr);
int fs_unlink_path(const char* path, uint32_t cwd_inode);
int fs_list_path(const char* path, uint32_t cwd_inode, char* buffer,
                 uint32_t length);
int fs_stat_path(const char* path, uint32_t cwd_inode, struct inode* out_inode,
                 uint32_t* out_inode_nr);
void fs_run_self_test(void);
int fs_persistence_verified(void);

#endif
