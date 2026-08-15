// tools/mkfs.c
//
// MyFS 格式化工具。文件系统镜像不再固定为 16MiB，而是根据 QEMU
// 磁盘大小计算可用块数。输出仍然是“只包含 MyFS 区域”的稀疏镜像，
// Makefile 的 format-fs 再把它写入 FS_START_LBA。
#define _FILE_OFFSET_BITS 64

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>

#define SECTOR_SIZE 512ULL
#define BLOCK_SIZE 4096ULL
#define SECTORS_PER_BLOCK (BLOCK_SIZE / SECTOR_SIZE)
#define ATA_LBA48_MAX 0x0000FFFFFFFFFFFFULL
#define FS_MAGIC 0x19980811U
#define FS_FORMAT_VERSION 4U
#define FS_ROOT_INODE 1U
#define FS_TYPE_DIRECTORY 1U
#define FS_TYPE_FILE 2U
#define FS_DIRECT_BLOCKS 11U
#define FS_INDIRECT_ENTRIES (BLOCK_SIZE / sizeof(uint32_t))
#define FS_SINGLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES)
#define FS_DOUBLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES)
#define FS_TRIPLE_FILE_BLOCKS ((uint64_t)FS_INDIRECT_ENTRIES * \
                               FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES)
#define FS_MAX_FILE_BLOCKS ((uint64_t)FS_DIRECT_BLOCKS + \
                            FS_SINGLE_FILE_BLOCKS + FS_DOUBLE_FILE_BLOCKS + \
                            FS_TRIPLE_FILE_BLOCKS)
#define FS_MAX_FILE_SIZE (FS_MAX_FILE_BLOCKS * BLOCK_SIZE)
#define BITMAP_BITS_PER_BLOCK (BLOCK_SIZE * 8ULL)
#define INODES_PER_BLOCK (BLOCK_SIZE / sizeof(struct inode))
#define MIN_INODES 4096ULL
#define MAX_INODES 262144ULL

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

struct inode {
    uint64_t size;
    uint16_t type;
    uint16_t link_count;
    uint32_t direct_blocks[11];
    uint32_t indirect_1;
    uint32_t indirect_2;
    uint32_t indirect_3;
    uint32_t flags;
};

typedef char mkfs_inode_must_be_72_bytes[(sizeof(struct inode) == 72) ? 1 : -1];

static struct inode* inode_at(uint8_t* inode_table, uint32_t inode_nr)
{
    uint32_t block = inode_nr / INODES_PER_BLOCK;
    uint32_t slot = inode_nr % INODES_PER_BLOCK;
    return (struct inode*)(inode_table + (uint64_t)block * BLOCK_SIZE +
                           (uint64_t)slot * sizeof(struct inode));
}

struct dir_entry {
    uint32_t inode_nr;
    char name[60];
};

typedef char mkfs_dir_entry_must_be_64_bytes[(sizeof(struct dir_entry) == 64) ? 1 : -1];

static uint64_t divide_round_up(uint64_t value, uint64_t divisor)
{
    if (divisor == 0) return 0;
    return value / divisor + ((value % divisor) != 0);
}

static int parse_size(const char* text, uint64_t* out)
{
    char* end;
    unsigned long long value;
    uint64_t multiplier = 1;

    if (text == 0 || out == 0 || *text == '\0') return -1;
    errno = 0;
    value = strtoull(text, &end, 0);
    if (errno != 0 || end == text) return -1;
    if (*end != '\0') {
        if (end[1] != '\0') return -1;
        switch (*end) {
        case 'k': case 'K': multiplier = 1024ULL; break;
        case 'm': case 'M': multiplier = 1024ULL * 1024ULL; break;
        case 'g': case 'G': multiplier = 1024ULL * 1024ULL * 1024ULL; break;
        case 't': case 'T': multiplier = 1024ULL * 1024ULL * 1024ULL * 1024ULL; break;
        default: return -1;
        }
    }
    if ((uint64_t)value > UINT64_MAX / multiplier) return -1;
    *out = (uint64_t)value * multiplier;
    return 0;
}

static void set_bit(uint8_t* bitmap, uint64_t bit)
{
    bitmap[bit / 8] |= (uint8_t)(1U << (bit % 8));
}

static int write_at(FILE* output, uint64_t offset, const void* data, size_t length)
{
    if (output == 0 || data == 0 || fseeko(output, (off_t)offset, SEEK_SET) != 0)
        return -1;
    return fwrite(data, 1, length, output) == length ? 0 : -1;
}

static int write_block(FILE* output, uint32_t block, const void* data)
{
    return write_at(output, (uint64_t)block * BLOCK_SIZE, data, BLOCK_SIZE);
}

static int read_block(FILE* input, uint32_t block, void* data)
{
    if (input == 0 || data == 0 ||
        fseeko(input, (off_t)((uint64_t)block * BLOCK_SIZE), SEEK_SET) != 0)
        return -1;
    return fread(data, 1, BLOCK_SIZE, input) == BLOCK_SIZE ? 0 : -1;
}

static int alloc_image_block(FILE* output, uint8_t* bmap, uint32_t* next_block,
                             uint32_t total_blocks, uint32_t* out_block)
{
    uint8_t zero[BLOCK_SIZE] = {0};
    if (output == 0 || bmap == 0 || next_block == 0 || out_block == 0 ||
        *next_block >= total_blocks)
        return -1;
    *out_block = (*next_block)++;
    set_bit(bmap, *out_block);
    return write_block(output, *out_block, zero);
}

static int set_index_entry(FILE* output, uint32_t index_block, uint32_t index,
                           uint32_t value)
{
    uint32_t entries[FS_INDIRECT_ENTRIES];
    if (index >= FS_INDIRECT_ENTRIES || read_block(output, index_block, entries) != 0)
        return -1;
    entries[index] = value;
    return write_block(output, index_block, entries);
}

static int get_index_entry(FILE* input, uint32_t index_block, uint32_t index,
                           uint32_t* out_value)
{
    uint32_t entries[FS_INDIRECT_ENTRIES];
    if (out_value == 0 || index >= FS_INDIRECT_ENTRIES ||
        read_block(input, index_block, entries) != 0)
        return -1;
    *out_value = entries[index];
    return 0;
}

static int ensure_index_entry(FILE* output, uint8_t* bmap, uint32_t* next_block,
                              uint32_t total_blocks, uint32_t index_block,
                              uint32_t index, uint32_t* out_value)
{
    uint32_t value;
    if (out_value == 0 || get_index_entry(output, index_block, index, &value) != 0)
        return -1;
    if (value == 0) {
        if (alloc_image_block(output, bmap, next_block, total_blocks, &value) != 0 ||
            set_index_entry(output, index_block, index, value) != 0)
            return -1;
    }
    *out_value = value;
    return 0;
}

static int inode_data_block(FILE* output, uint8_t* bmap, uint32_t* next_block,
                            uint32_t total_blocks, struct inode* inode,
                            uint64_t index, uint32_t* out_block)
{
    uint64_t first;
    uint64_t second;
    uint64_t third;
    uint32_t child;

    if (output == 0 || bmap == 0 || next_block == 0 || inode == 0 ||
        out_block == 0 || index >= FS_MAX_FILE_BLOCKS)
        return -1;
    if (index < FS_DIRECT_BLOCKS) {
        if (inode->direct_blocks[index] == 0 &&
            alloc_image_block(output, bmap, next_block, total_blocks,
                              &inode->direct_blocks[index]) != 0)
            return -1;
        *out_block = inode->direct_blocks[index];
        return 0;
    }

    index -= FS_DIRECT_BLOCKS;
    if (index < FS_SINGLE_FILE_BLOCKS) {
        if (inode->indirect_1 == 0 &&
            alloc_image_block(output, bmap, next_block, total_blocks,
                              &inode->indirect_1) != 0)
            return -1;
        if (ensure_index_entry(output, bmap, next_block, total_blocks,
                               inode->indirect_1, (uint32_t)index, &child) != 0)
            return -1;
        *out_block = child;
        return 0;
    }

    index -= FS_SINGLE_FILE_BLOCKS;
    if (index < FS_DOUBLE_FILE_BLOCKS) {
        if (inode->indirect_2 == 0 &&
            alloc_image_block(output, bmap, next_block, total_blocks,
                              &inode->indirect_2) != 0)
            return -1;
        first = index / FS_INDIRECT_ENTRIES;
        second = index % FS_INDIRECT_ENTRIES;
        if (ensure_index_entry(output, bmap, next_block, total_blocks,
                               inode->indirect_2, (uint32_t)first, &child) != 0 ||
            ensure_index_entry(output, bmap, next_block, total_blocks,
                               child, (uint32_t)second, &child) != 0)
            return -1;
        *out_block = child;
        return 0;
    }

    index -= FS_DOUBLE_FILE_BLOCKS;
    if (index >= FS_TRIPLE_FILE_BLOCKS) return -1;
    if (inode->indirect_3 == 0 &&
        alloc_image_block(output, bmap, next_block, total_blocks,
                          &inode->indirect_3) != 0)
        return -1;
    first = index / FS_DOUBLE_FILE_BLOCKS;
    second = (index / FS_INDIRECT_ENTRIES) % FS_INDIRECT_ENTRIES;
    third = index % FS_INDIRECT_ENTRIES;
    if (ensure_index_entry(output, bmap, next_block, total_blocks,
                           inode->indirect_3, (uint32_t)first, &child) != 0 ||
        ensure_index_entry(output, bmap, next_block, total_blocks,
                           child, (uint32_t)second, &child) != 0 ||
        ensure_index_entry(output, bmap, next_block, total_blocks,
                           child, (uint32_t)third, &child) != 0)
        return -1;
    *out_block = child;
    return 0;
}

static int size_sparse_file(FILE* output, uint64_t bytes)
{
    if (bytes == 0 || bytes - 1 > (uint64_t)INT64_MAX ||
        fseeko(output, (off_t)(bytes - 1), SEEK_SET) != 0 ||
        fputc(0, output) == EOF || fflush(output) != 0) return -1;
    return 0;
}

static void usage(const char* program)
{
    fprintf(stderr,
            "Usage: %s <output_fs.img> --disk-size <size> "
            "--start-lba <lba> <input_elf> [more_elfs...]\n",
            program);
}

int main(int argc, char* argv[])
{
    const char* output_name;
    const char* input_names[64];
    uint32_t input_count = 0;
    uint64_t disk_size = 0;
    uint64_t start_lba = 0;
    uint64_t fs_bytes;
    uint64_t total_blocks64;
    uint64_t max_blocks_lba48;
    uint64_t total_inodes64;
    uint64_t imap_blocks64;
    uint64_t bmap_blocks64;
    uint64_t inode_blocks64;
    uint64_t first_data64;
    uint64_t imap_bytes;
    uint64_t bmap_bytes;
    uint64_t inode_bytes;
    struct super_block sb;
    uint8_t* imap = 0;
    uint8_t* bmap = 0;
    uint8_t* inode_table = 0;
    uint8_t root_data[BLOCK_SIZE];
    FILE* output = 0;
    uint32_t current_data_block;
    int result = 1;

    if (argc < 6) {
        usage(argv[0]);
        return 1;
    }
    output_name = argv[1];

    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--disk-size") == 0 && i + 1 < argc) {
            if (parse_size(argv[++i], &disk_size) != 0) {
                fprintf(stderr, "mkfs: invalid disk size: %s\n", argv[i]);
                goto cleanup;
            }
        } else if (strcmp(argv[i], "--start-lba") == 0 && i + 1 < argc) {
            char* end;
            unsigned long long parsed = strtoull(argv[++i], &end, 0);
            if (*argv[i] == '\0' || *end != '\0') {
                fprintf(stderr, "mkfs: invalid start LBA: %s\n", argv[i]);
                goto cleanup;
            }
            start_lba = parsed;
        } else if (argv[i][0] == '-') {
            fprintf(stderr, "mkfs: unknown option: %s\n", argv[i]);
            goto cleanup;
        } else if (input_count < 64) {
            input_names[input_count++] = argv[i];
        } else {
            fprintf(stderr, "mkfs: too many input files\n");
            goto cleanup;
        }
    }

    if (disk_size == 0 || input_count == 0 ||
        start_lba > UINT64_MAX / SECTOR_SIZE ||
        disk_size <= start_lba * SECTOR_SIZE) {
        usage(argv[0]);
        goto cleanup;
    }

    fs_bytes = disk_size - start_lba * SECTOR_SIZE;
    fs_bytes -= fs_bytes % BLOCK_SIZE;
    total_blocks64 = fs_bytes / BLOCK_SIZE;
    if (start_lba > ATA_LBA48_MAX ||
        ATA_LBA48_MAX - start_lba + 1 < SECTORS_PER_BLOCK) {
        fprintf(stderr, "mkfs: FS start LBA is outside ATA LBA48 range\n");
        goto cleanup;
    }
    max_blocks_lba48 = (ATA_LBA48_MAX - start_lba + 1) / SECTORS_PER_BLOCK;
    if (total_blocks64 < 128 || total_blocks64 > UINT32_MAX ||
        total_blocks64 > max_blocks_lba48) {
        fprintf(stderr, "mkfs: unsupported filesystem size: %llu blocks\n",
                (unsigned long long)total_blocks64);
        goto cleanup;
    }

    /* 约每 64KiB 的文件系统空间准备一个 inode，同时保留教学镜像的
       最小 inode 数量，并设置上限避免一次挂载分配过大的引用表。 */
    total_inodes64 = total_blocks64 / 16;
    if (total_inodes64 < MIN_INODES) total_inodes64 = MIN_INODES;
    if (total_inodes64 > MAX_INODES) total_inodes64 = MAX_INODES;
    imap_blocks64 = divide_round_up(total_inodes64, BITMAP_BITS_PER_BLOCK);
    bmap_blocks64 = divide_round_up(total_blocks64, BITMAP_BITS_PER_BLOCK);
    /* inode 不是 2 的幂大小。每个磁盘块只能放下整数个 inode，块尾
       的剩余空间必须保留，不能按紧密数组的总字节数向上取整。 */
    inode_blocks64 = divide_round_up(total_inodes64, INODES_PER_BLOCK);
    first_data64 = 2 + imap_blocks64 + bmap_blocks64 + inode_blocks64;
    if (first_data64 + 1 >= total_blocks64 ||
        total_inodes64 > UINT32_MAX || imap_blocks64 > UINT32_MAX ||
        bmap_blocks64 > UINT32_MAX || inode_blocks64 > UINT32_MAX ||
        first_data64 > UINT32_MAX) {
        fprintf(stderr, "mkfs: metadata does not fit in filesystem\n");
        goto cleanup;
    }

    memset(&sb, 0, sizeof(sb));
    sb.magic = FS_MAGIC;
    sb.version = FS_FORMAT_VERSION;
    sb.block_size = BLOCK_SIZE;
    sb.total_inodes = (uint32_t)total_inodes64;
    sb.total_blocks = (uint32_t)total_blocks64;
    sb.imap_start = 2;
    sb.imap_blocks = (uint32_t)imap_blocks64;
    sb.bmap_start = sb.imap_start + sb.imap_blocks;
    sb.bmap_blocks = (uint32_t)bmap_blocks64;
    sb.inode_start = sb.bmap_start + sb.bmap_blocks;
    sb.inode_blocks = (uint32_t)inode_blocks64;
    sb.first_data_block = (uint32_t)first_data64;

    imap_bytes = imap_blocks64 * BLOCK_SIZE;
    bmap_bytes = bmap_blocks64 * BLOCK_SIZE;
    inode_bytes = inode_blocks64 * BLOCK_SIZE;
    imap = (uint8_t*)calloc(1, (size_t)imap_bytes);
    bmap = (uint8_t*)calloc(1, (size_t)bmap_bytes);
    inode_table = (uint8_t*)calloc(1, (size_t)inode_bytes);
    if (imap == 0 || bmap == 0 || inode_table == 0) {
        fprintf(stderr, "mkfs: unable to allocate metadata buffers\n");
        goto cleanup;
    }
    memset(root_data, 0, sizeof(root_data));

    output = fopen(output_name, "wb+");
    if (output == 0) {
        fprintf(stderr, "mkfs: cannot create %s\n", output_name);
        goto cleanup;
    }
    if (size_sparse_file(output, fs_bytes) != 0) {
        fprintf(stderr, "mkfs: cannot size %s\n", output_name);
        goto cleanup;
    }

    /* Block 0 是文件系统相对区域的保留块；超级块、两类位图和 inode
       表也必须在数据位图中标记为已使用。 */
    for (uint32_t block = 0; block < sb.first_data_block; block++)
        set_bit(bmap, block);
    set_bit(imap, FS_ROOT_INODE);

    struct inode* root_inode = inode_at(inode_table, FS_ROOT_INODE);
    root_inode->type = FS_TYPE_DIRECTORY;
    root_inode->link_count = 1;
    root_inode->size = BLOCK_SIZE;
    root_inode->direct_blocks[0] = sb.first_data_block;
    set_bit(bmap, sb.first_data_block);

    struct dir_entry* root_dir = (struct dir_entry*)root_data;
    root_dir[0].inode_nr = FS_ROOT_INODE;
    strcpy(root_dir[0].name, ".");
    root_dir[1].inode_nr = FS_ROOT_INODE;
    strcpy(root_dir[1].name, "..");

    current_data_block = sb.first_data_block + 1;
    for (uint32_t input_index = 0; input_index < input_count; input_index++) {
        const char* input_name = input_names[input_index];
        const char* filename = strrchr(input_name, '/');
        filename = filename ? filename + 1 : input_name;
        FILE* input;
        off_t file_size;
        uint32_t inode_nr = input_index + 2;
        uint32_t entry_nr = input_index + 2;
        uint64_t bytes_read = 0;
        uint64_t block_index = 0;

        if (strlen(filename) >= sizeof(root_dir[0].name) ||
            inode_nr >= sb.total_inodes || entry_nr >= BLOCK_SIZE / sizeof(struct dir_entry)) {
            fprintf(stderr, "mkfs: root directory is full or filename is too long: %s\n", filename);
            goto cleanup;
        }
        input = fopen(input_name, "rb");
        if (input == 0) {
            fprintf(stderr, "mkfs: cannot open %s\n", input_name);
            goto cleanup;
        }
        if (fseeko(input, 0, SEEK_END) != 0 || (file_size = ftello(input)) < 0 ||
            fseeko(input, 0, SEEK_SET) != 0) {
            fclose(input);
            fprintf(stderr, "mkfs: cannot inspect %s\n", input_name);
            goto cleanup;
        }
        if ((uint64_t)file_size > FS_MAX_FILE_SIZE) {
            fprintf(stderr, "mkfs: %s exceeds the indexed file size limit\n", filename);
            fclose(input);
            goto cleanup;
        }

        set_bit(imap, inode_nr);
        struct inode* inode = inode_at(inode_table, inode_nr);
        inode->type = FS_TYPE_FILE;
        inode->link_count = 1;
        inode->size = (uint64_t)file_size;
        root_dir[entry_nr].inode_nr = inode_nr;
        strcpy(root_dir[entry_nr].name, filename);

        while (bytes_read < (uint64_t)file_size) {
            uint32_t to_read = (uint32_t)((uint64_t)file_size - bytes_read);
            if (to_read > BLOCK_SIZE) to_read = BLOCK_SIZE;
            uint8_t data[BLOCK_SIZE] = {0};
            uint32_t data_block;
            if (fread(data, 1, to_read, input) != to_read ||
                inode_data_block(output, bmap, &current_data_block, sb.total_blocks,
                                 inode, block_index++, &data_block) != 0 ||
                write_block(output, data_block, data) != 0) {
                fclose(input);
                fprintf(stderr, "mkfs: failed to write %s\n", filename);
                goto cleanup;
            }
            bytes_read += to_read;
        }
        fclose(input);
        printf("[SUCCESS] Added %s (%lld bytes)\n", filename, (long long)file_size);
    }

    uint8_t super_block_data[BLOCK_SIZE] = {0};
    memcpy(super_block_data, &sb, sizeof(sb));
    if (write_block(output, 1, super_block_data) != 0 ||
        write_block(output, sb.imap_start, imap) != 0) {
        fprintf(stderr, "mkfs: failed to write superblock/inode bitmap\n");
        goto cleanup;
    }
    for (uint32_t i = 0; i < sb.bmap_blocks; i++) {
        if (write_block(output, sb.bmap_start + i,
                        bmap + (uint64_t)i * BLOCK_SIZE) != 0) {
            fprintf(stderr, "mkfs: failed to write data bitmap\n");
            goto cleanup;
        }
    }
    for (uint32_t i = 0; i < sb.inode_blocks; i++) {
        if (write_block(output, sb.inode_start + i,
                        inode_table + (uint64_t)i * BLOCK_SIZE) != 0) {
            fprintf(stderr, "mkfs: failed to write inode table\n");
            goto cleanup;
        }
    }
    if (write_block(output, sb.first_data_block, root_data) != 0 || fflush(output) != 0) {
        fprintf(stderr, "mkfs: failed to write root directory\n");
        goto cleanup;
    }

    printf("[SUCCESS] MyFS v%u: %u blocks, %u inodes, %llu bytes, data starts at block %u\n",
           sb.version, sb.total_blocks, sb.total_inodes,
           (unsigned long long)fs_bytes, sb.first_data_block);
    result = 0;

cleanup:
    if (output != 0) fclose(output);
    free(imap);
    free(bmap);
    free(inode_table);
    return result;
}
