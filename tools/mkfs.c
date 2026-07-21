// tools/mkfs.c
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define SECTOR_SIZE 512
#define BLOCK_SIZE 4096
#define SECTORS_PER_BLOCK (BLOCK_SIZE / SECTOR_SIZE)
#define FS_MAGIC 0x19980811
#define FS_SIZE_BLOCKS 4096 // 16MB 的文件系统 (4096 * 4096)

// 超级块 (占用 Block 1)
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

// 索引节点 (精准 64 字节)
struct inode {
    uint32_t size;              // 文件大小 (4B)
    uint16_t type;              // 1: 目录, 2: 文件 (2B)
    uint16_t link_count;        // 链接数 (2B)
    uint32_t direct_blocks[11]; // 11个直接指针 (44B)，支持 44KB
    uint32_t indirect_1;        // 一级间接指针 (4B)，支持额外 4MB
    uint32_t indirect_2;        // 二级间接指针 (4B)，支持额外 4GB
    uint32_t padding[2];        // 填充对齐 (8B)
};

// 目录项 (精准 64 字节)
struct dir_entry {
    uint32_t inode_nr;          // Inode 编号 (0表示空) (4B)
    char name[60];              // 文件名 (支持最长 59 字符) (60B)
};

uint8_t fs_image[FS_SIZE_BLOCKS * BLOCK_SIZE];

// 设置位图的某一位
void set_bit(uint8_t* bitmap, int index) {
    bitmap[index / 8] |= (1 << (index % 8));
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        printf("Usage: %s <output_fs.img> <input_hello.elf>\n", argv[0]);
        return 1;
    }

    memset(fs_image, 0, sizeof(fs_image));

    // 1. 初始化 Superblock (Block 1)
    struct super_block* sb = (struct super_block*)(fs_image + 1 * BLOCK_SIZE);
    sb->magic = FS_MAGIC;
    sb->block_size = BLOCK_SIZE;
    sb->total_inodes = 4096;
    sb->total_blocks = FS_SIZE_BLOCKS;
    sb->imap_blocks = 1;  // 1个 4KB Block 可管 32768 个 inode，够用了
    sb->bmap_blocks = 1;  // 1个 4KB Block 可管 32768 个 block (达 128MB)，够用了
    sb->inode_blocks = 64; // 4096 * 64B / 4096B = 64 个 Block
    // LBA 起始块计算：引导(1) + 超级块(1) + imap(1) + bmap(1) + inode(64) = 68
    sb->first_data_block = 68; 

    // 获取内存映射指针
    uint8_t* imap = fs_image + 2 * BLOCK_SIZE;
    uint8_t* bmap = fs_image + 3 * BLOCK_SIZE;
    struct inode* inodes = (struct inode*)(fs_image + 4 * BLOCK_SIZE);

    // 预留系统级的 Block
    for (int i = 0; i < sb->first_data_block; i++) set_bit(bmap, i);

    // 2. 创建根目录 Inode (固定为 Inode 1)
    set_bit(imap, 1);
    inodes[1].type = 1;
    inodes[1].size = BLOCK_SIZE; 
    inodes[1].direct_blocks[0] = sb->first_data_block;
    set_bit(bmap, sb->first_data_block);

    // 写入根目录数据 (在第一个数据块)
    struct dir_entry* root_dir = (struct dir_entry*)(fs_image + sb->first_data_block * BLOCK_SIZE);
    root_dir[0].inode_nr = 2; // 指向下一个文件的 Inode
    strcpy(root_dir[0].name, "hello.elf");

    // 3. 读取外部 ELF 文件并写入 MyFS
    FILE* f_in = fopen(argv[2], "rb");
    if (!f_in) {
        printf("Error: Cannot open %s\n", argv[2]);
        return 1;
    }
    fseek(f_in, 0, SEEK_END);
    uint32_t file_size = ftell(f_in);
    fseek(f_in, 0, SEEK_SET);

    // 配置文件的 Inode (Inode 2)
    set_bit(imap, 2);
    inodes[2].type = 2;
    inodes[2].size = file_size;

    uint32_t current_data_block = sb->first_data_block + 1;
    uint32_t bytes_read = 0;
    int block_idx = 0;

    // 分块拷贝文件内容到直接指针所指的 Block
    while (bytes_read < file_size) {
        if (block_idx >= 11) {
            printf("[WARNING] mkfs: File exceeds 44KB. Indirect pointers implementation needed in mkfs.\n");
            break;
        }
        inodes[2].direct_blocks[block_idx] = current_data_block;
        set_bit(bmap, current_data_block);
        
        uint32_t to_read = (file_size - bytes_read > BLOCK_SIZE) ? BLOCK_SIZE : (file_size - bytes_read);
        fread(fs_image + current_data_block * BLOCK_SIZE, 1, to_read, f_in);
        
        bytes_read += to_read;
        current_data_block++;
        block_idx++;
    }
    fclose(f_in);

    // 4. 将 16MB 的文件系统镜像刷入文件
    FILE* f_out = fopen(argv[1], "wb");
    fwrite(fs_image, 1, sizeof(fs_image), f_out);
    fclose(f_out);

    printf("[SUCCESS] MyFS (4KB Block) image '%s' created! Size: %d bytes.\n", argv[1], file_size);
    return 0;
}