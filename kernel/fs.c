// kernel/fs.c 
#include "fs.h"
#include "disk.h"
#include "print.h"
#include "string.h" // 如果你没有 strcmp，下面的代码中我手写了字符串比对

// 全局保存挂载的超级块
static struct super_block g_sb;
static int fs_mounted = 0;

void fs_init(void) {
    print_info("[FS] Initializing MyFS (4KB Block)...\n");
    uint32_t sb_lba = FS_START_LBA + (4096 / 512); 
    uint8_t buffer[512] = {0};
    disk_read_sector(sb_lba, buffer, 1);
    
    struct super_block* sb = (struct super_block*)buffer;
    if (sb->magic == FS_MAGIC) {
        g_sb = *sb; 
        fs_mounted = 1;
        print_success("[FS] Phase 2 PASSED: MyFS Mounted Successfully!\n");
        // 我帮你把多余的 0x 去掉了
        print_string("     -> Magic Number: 0x");
        print_hex(g_sb.magic); 
        print_string("\n");
    } else {
        print_error("[FS] MyFS Mount Failed!\n");
    }
}

// 内部辅助函数：根据 inode 编号从磁盘读取 inode 结构体
static void fs_get_inode(uint32_t inode_nr, struct inode* out_inode) {
    // 根据我们 mkfs 的布局：
    // Block 0=Boot, Block 1=SB, Block 2=IMAP, Block 3=BMAP, Block 4 开始是 Inode 数组
    // LBA 起点 = 1000 + (4 * 8) = 1032
    uint32_t inode_base_lba = FS_START_LBA + 32; 
    
    // 1 个 512B 扇区可以装 8 个 64B 的 Inode
    uint32_t sector_offset = inode_nr / 8;
    uint32_t byte_offset   = (inode_nr % 8) * sizeof(struct inode);
    
    uint8_t buffer[512];
    disk_read_sector(inode_base_lba + sector_offset, buffer, 1);
    
    // 将磁盘里读出的数据拷贝给调用者
    struct inode* target = (struct inode*)(buffer + byte_offset);
    *out_inode = *target;
}

// 核心查找逻辑
int fs_find_file(const char* filename, struct inode* out_inode) {
    if (!fs_mounted) return 0;

    // 1. 获取根目录的 Inode (固定为 1)
    struct inode root_inode;
    fs_get_inode(1, &root_inode);

    if (root_inode.type != 1) { // 必须是目录类型
        return 0; 
    }

    // 2. 获取根目录的数据块物理 LBA
    // root_inode.direct_blocks[0] 保存着根目录数据的 Block 号 (68)
    // 1 Block = 8 扇区
    uint32_t root_data_lba = FS_START_LBA + root_inode.direct_blocks[0] * 8;

    // 3. 读取该数据块的第一个扇区 (为了简单，假设根目录条目不多，1个扇区足够装8个文件)
    uint8_t buffer[512];
    disk_read_sector(root_data_lba, buffer, 1);

    // 4. 遍历扇区中的目录项 (dir_entry)
    struct dir_entry* entries = (struct dir_entry*)buffer;
    for (int i = 0; i < 8; i++) {
        if (entries[i].inode_nr != 0) {
            // 手动实现字符串比对，防止 Freestanding 环境缺失 strcmp
            int match = 1;
            for (int j = 0; j < 60; j++) {
                if (entries[i].name[j] != filename[j]) {
                    match = 0; break;
                }
                if (filename[j] == '\0') break;
            }

            if (match) {
                // 找到了！通过查到的 Inode 号提取文件的真身
                fs_get_inode(entries[i].inode_nr, out_inode);
                return 1;
            }
        }
    }
    return 0; // 未找到
}