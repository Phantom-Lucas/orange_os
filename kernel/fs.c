#include "fs.h"

#include "disk.h"
#include "print.h"
#include "string.h"
#include "ipc.h"
#include "thread.h"
#include "kalloc.h"

/*
 * MyFS 保持原有的 4 KiB 块格式。这里增加的是访问层：所有元数据和数据
 * 块先经过小型 write-back buffer cache，FS 服务线程串行化磁盘结构修改。
 * 因而调用者不会在持有 PMM/地址空间锁时进入磁盘，也不会并发修改同一
 * 个 inode。每个请求完成前同步脏块，当前阶段优先保证重启后的持久性。
 */
static struct super_block g_sb;
static int fs_mounted;
static struct thread* fs_service_task;
static uint32_t* g_open_refs;
static int persistence_verified;

#define FS_CACHE_ENTRIES 16
#define FS_MESSAGE_REQUEST 0x46530101U
#define FS_MESSAGE_REPLY   0x46530102U

struct cache_entry {
    uint32_t block;
    uint32_t age;
    uint8_t valid;
    uint8_t dirty;
    /* inode/index block access uses uint32_t/uint64_t pointers. */
    uint8_t data[FS_BLOCK_SIZE] __attribute__((aligned(8)));
};

static struct cache_entry cache[FS_CACHE_ENTRIES];
static uint32_t cache_age;

static uint64_t block_lba(uint32_t block) {
    return (uint64_t)FS_START_LBA +
           (uint64_t)block * FS_SECTORS_PER_BLOCK;
}

static int cache_flush_entry(struct cache_entry* entry) {
    if (entry == 0 || !entry->valid || !entry->dirty) return 0;
    if (disk_write_sector_checked(block_lba(entry->block), entry->data,
                                  FS_SECTORS_PER_BLOCK) != 0) return -1;
    entry->dirty = 0;
    return 0;
}

static uint8_t* cache_get(uint32_t block, int write) {
    struct cache_entry* victim = 0;
    uint32_t oldest = UINT32_MAX;
    if (block >= g_sb.total_blocks) return 0;
    for (uint32_t i = 0; i < FS_CACHE_ENTRIES; i++) {
        if (cache[i].valid && cache[i].block == block) {
            cache[i].age = ++cache_age;
            if (write) cache[i].dirty = 1;
            return cache[i].data;
        }
        if (!cache[i].valid || cache[i].age < oldest) {
            victim = &cache[i];
            oldest = cache[i].age;
        }
    }
    if (victim == 0 || cache_flush_entry(victim) != 0) return 0;
    if (disk_read_sector_checked(block_lba(block), victim->data,
                                 FS_SECTORS_PER_BLOCK) != 0) return 0;
    victim->block = block;
    victim->valid = 1;
    victim->dirty = write ? 1 : 0;
    victim->age = ++cache_age;
    return victim->data;
}

static int cache_sync(void) {
    for (uint32_t i = 0; i < FS_CACHE_ENTRIES; i++) {
        if (cache_flush_entry(&cache[i]) != 0) return -1;
    }
    return 0;
}

static void cache_drop(void) {
    memset(cache, 0, sizeof(cache));
    cache_age = 0;
}

static uint32_t inode_block(uint32_t inode_nr) {
    return g_sb.inode_start + inode_nr / (FS_BLOCK_SIZE / sizeof(struct inode));
}

static int valid_inode(uint32_t inode_nr) {
    return inode_nr > 0 && inode_nr < g_sb.total_inodes;
}

static int fs_get_inode(uint32_t inode_nr, struct inode* inode) {
    uint8_t* block;
    if (!valid_inode(inode_nr) || inode == 0) return -1;
    block = cache_get(inode_block(inode_nr), 0);
    if (block == 0) return -1;
    *inode = ((struct inode*)block)[inode_nr % (FS_BLOCK_SIZE / sizeof(struct inode))];
    return 0;
}

static int fs_put_inode(uint32_t inode_nr, const struct inode* inode) {
    uint8_t* block;
    if (!valid_inode(inode_nr) || inode == 0) return -1;
    block = cache_get(inode_block(inode_nr), 1);
    if (block == 0) return -1;
    ((struct inode*)block)[inode_nr % (FS_BLOCK_SIZE / sizeof(struct inode))] = *inode;
    return 0;
}

static int bitmap_allocate(uint32_t bitmap_block, uint32_t first, uint32_t limit) {
    uint8_t* block;
    uint32_t capacity = g_sb.block_size * 8;
    for (uint32_t bit = first; bit < limit; bit++) {
        block = cache_get(bitmap_block + bit / capacity, 1);
        if (block == 0) return -1;
        uint32_t in = bit % capacity;
        if (!(block[in / 8] & (1U << (in % 8)))) {
            block[in / 8] |= (uint8_t)(1U << (in % 8));
            return (int)bit;
        }
    }
    return -1;
}

static void bitmap_free(uint32_t bitmap_block, uint32_t bit) {
    uint8_t* block = cache_get(bitmap_block + bit / (g_sb.block_size * 8), 1);
    if (block != 0) {
        uint32_t in = bit % (g_sb.block_size * 8);
        block[in / 8] &= (uint8_t)~(1U << (in % 8));
    }
}

static int alloc_data_block(void) {
    int block = bitmap_allocate(g_sb.bmap_start, g_sb.first_data_block,
                                g_sb.total_blocks);
    uint8_t* data;
    if (block < 0) return -1;
    data = cache_get((uint32_t)block, 1);
    if (data == 0) {
        bitmap_free(g_sb.bmap_start, (uint32_t)block);
        return -1;
    }
    memset(data, 0, FS_BLOCK_SIZE);
    return block;
}

static int inode_data_block(struct inode* inode, uint64_t index, int create,
                            uint32_t* out_block) {
    uint32_t* indirect;
    uint32_t* root;
    uint32_t* leaf;
    uint64_t first;
    uint64_t second;
    int new_block;

    if (inode == 0 || out_block == 0 || index >= FS_MAX_FILE_BLOCKS) return -1;
    *out_block = 0;
    if (index < FS_DIRECT_BLOCKS) {
        if (inode->direct_blocks[index] == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            inode->direct_blocks[index] = (uint32_t)new_block;
        }
        *out_block = inode->direct_blocks[index];
        return 0;
    }

    index -= FS_DIRECT_BLOCKS;
    if (index < FS_SINGLE_FILE_BLOCKS) {
        if (inode->indirect_1 == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            inode->indirect_1 = (uint32_t)new_block;
        }
        if (inode->indirect_1 == 0) return 0;
        indirect = (uint32_t*)cache_get(inode->indirect_1, create);
        if (indirect == 0) return -1;
        if (indirect[index] == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            indirect[index] = (uint32_t)new_block;
        }
        *out_block = indirect[index];
        return 0;
    }

    index -= FS_SINGLE_FILE_BLOCKS;
    if (index < FS_DOUBLE_FILE_BLOCKS) {
        if (inode->indirect_2 == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            inode->indirect_2 = (uint32_t)new_block;
        }
        if (inode->indirect_2 == 0) return 0;

        root = (uint32_t*)cache_get(inode->indirect_2, create);
        if (root == 0) return -1;
        first = index / FS_INDIRECT_ENTRIES;
        second = index % FS_INDIRECT_ENTRIES;
        if (root[first] == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            root[first] = (uint32_t)new_block;
        }
        if (root[first] == 0) return 0;
        leaf = (uint32_t*)cache_get(root[first], create);
        if (leaf == 0) return -1;
        if (leaf[second] == 0 && create) {
            new_block = alloc_data_block();
            if (new_block < 0) return -1;
            leaf[second] = (uint32_t)new_block;
        }
        *out_block = leaf[second];
        return 0;
    }

    index -= FS_DOUBLE_FILE_BLOCKS;
    if (index >= FS_TRIPLE_FILE_BLOCKS) return -1;
    if (inode->indirect_3 == 0 && create) {
        new_block = alloc_data_block();
        if (new_block < 0) return -1;
        inode->indirect_3 = (uint32_t)new_block;
    }
    if (inode->indirect_3 == 0) return 0;

    /* 三级索引：root[first] 是二级索引块，二级索引块的
       second 项是一级索引块，一级索引块的 third 项才是数据块。 */
    root = (uint32_t*)cache_get(inode->indirect_3, create);
    if (root == 0) return -1;
    first = index / FS_DOUBLE_FILE_BLOCKS;
    second = (index / FS_INDIRECT_ENTRIES) % FS_INDIRECT_ENTRIES;
    uint64_t third = index % FS_INDIRECT_ENTRIES;
    if (root[first] == 0 && create) {
        new_block = alloc_data_block();
        if (new_block < 0) return -1;
        root[first] = (uint32_t)new_block;
    }
    if (root[first] == 0) return 0;
    leaf = (uint32_t*)cache_get(root[first], create);
    if (leaf == 0) return -1;
    if (leaf[second] == 0 && create) {
        new_block = alloc_data_block();
        if (new_block < 0) return -1;
        leaf[second] = (uint32_t)new_block;
    }
    if (leaf[second] == 0) return 0;
    indirect = (uint32_t*)cache_get(leaf[second], create);
    if (indirect == 0) return -1;
    if (indirect[third] == 0 && create) {
        new_block = alloc_data_block();
        if (new_block < 0) return -1;
        indirect[third] = (uint32_t)new_block;
    }
    *out_block = indirect[third];
    return 0;
}

static void free_single_index_block(uint32_t index_block) {
    if (index_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t* indirect = (uint32_t*)cache_get(index_block, 0);
        uint32_t data_block = indirect == 0 ? 0 : indirect[i];
        if (data_block != 0) bitmap_free(g_sb.bmap_start, data_block);
    }
    bitmap_free(g_sb.bmap_start, index_block);
}

static void free_double_index_tree(uint32_t root_block) {
    if (root_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t* root = (uint32_t*)cache_get(root_block, 0);
        uint32_t child = root == 0 ? 0 : root[i];
        if (child != 0) free_single_index_block(child);
    }
    bitmap_free(g_sb.bmap_start, root_block);
}

static void free_triple_index_tree(uint32_t root_block) {
    if (root_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t* root = (uint32_t*)cache_get(root_block, 0);
        uint32_t child = root == 0 ? 0 : root[i];
        if (child != 0) free_double_index_tree(child);
    }
    bitmap_free(g_sb.bmap_start, root_block);
}

static void free_inode_blocks(struct inode* inode) {
    if (inode == 0) return;
    for (uint32_t i = 0; i < FS_DIRECT_BLOCKS; i++) {
        if (inode->direct_blocks[i] != 0)
            bitmap_free(g_sb.bmap_start, inode->direct_blocks[i]);
    }
    free_single_index_block(inode->indirect_1);
    free_double_index_tree(inode->indirect_2);
    free_triple_index_tree(inode->indirect_3);
}

static int truncate_inode(uint32_t inode_nr, struct inode* inode) {
    if (inode == 0 || inode->type != FS_TYPE_FILE) return -1;
    free_inode_blocks(inode);
    memset(inode->direct_blocks, 0, sizeof(inode->direct_blocks));
    inode->indirect_1 = 0;
    inode->indirect_2 = 0;
    inode->indirect_3 = 0;
    inode->size = 0;
    return fs_put_inode(inode_nr, inode);
}

static uint32_t index_entry(uint32_t index_block, uint32_t index) {
    uint32_t* entries = (uint32_t*)cache_get(index_block, 0);
    return entries == 0 ? 0 : entries[index];
}

static void rollback_single_added(uint32_t old_block, uint32_t new_block) {
    if (old_block == 0 && new_block != 0) {
        free_single_index_block(new_block);
        return;
    }
    if (old_block == 0 || new_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t old_data = index_entry(old_block, i);
        uint32_t new_data = index_entry(new_block, i);
        if (old_data == 0 && new_data != 0)
            bitmap_free(g_sb.bmap_start, new_data);
    }
}

static void rollback_double_added(uint32_t old_block, uint32_t new_block) {
    if (old_block == 0 && new_block != 0) {
        free_double_index_tree(new_block);
        return;
    }
    if (old_block == 0 || new_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t old_leaf = index_entry(old_block, i);
        uint32_t new_leaf = index_entry(new_block, i);
        rollback_single_added(old_leaf, new_leaf);
    }
}

static void rollback_triple_added(uint32_t old_block, uint32_t new_block) {
    if (old_block == 0 && new_block != 0) {
        free_triple_index_tree(new_block);
        return;
    }
    if (old_block == 0 || new_block == 0) return;
    for (uint32_t i = 0; i < FS_INDIRECT_ENTRIES; i++) {
        uint32_t old_double = index_entry(old_block, i);
        uint32_t new_double = index_entry(new_block, i);
        rollback_double_added(old_double, new_double);
    }
}

static void rollback_new_blocks(const struct inode* old, const struct inode* now) {
    if (old == 0 || now == 0) return;
    for (uint32_t i = 0; i < FS_DIRECT_BLOCKS; i++) {
        if (old->direct_blocks[i] == 0 && now->direct_blocks[i] != 0)
            bitmap_free(g_sb.bmap_start, now->direct_blocks[i]);
    }
    rollback_single_added(old->indirect_1, now->indirect_1);
    rollback_double_added(old->indirect_2, now->indirect_2);
    rollback_triple_added(old->indirect_3, now->indirect_3);
}

static int name_equal(const char* a, const char* b) {
    return a != 0 && b != 0 && strlen(a) < FS_NAME_MAX && strcmp(a, b) == 0;
}

static int dir_find(uint32_t dir_nr, const char* name, uint32_t* out_inode,
                    uint32_t* out_block, uint32_t* out_index) {
    struct inode dir;
    struct dir_entry* entries;
    if (fs_get_inode(dir_nr, &dir) != 0 || dir.type != FS_TYPE_DIRECTORY) return 0;
    uint64_t blocks = (dir.size + FS_BLOCK_SIZE - 1) / FS_BLOCK_SIZE;
    if (blocks == 0) blocks = 1;
    for (uint64_t b = 0; b < blocks; b++) {
        uint32_t data_block;
        if (inode_data_block(&dir, b, 0, &data_block) != 0 || data_block == 0) continue;
        entries = (struct dir_entry*)cache_get(data_block, 0);
        if (entries == 0) return 0;
        for (uint32_t i = 0; i < FS_BLOCK_SIZE / sizeof(struct dir_entry); i++) {
            if (entries[i].inode_nr != 0 && name_equal(entries[i].name, name)) {
                if (out_inode) *out_inode = entries[i].inode_nr;
                if (out_block) *out_block = data_block;
                if (out_index) *out_index = i;
                return 1;
            }
        }
    }
    return 0;
}

static int dir_add(uint32_t dir_nr, const char* name, uint32_t inode_nr) {
    struct inode dir;
    struct dir_entry* entries;
    uint64_t blocks;
    if (name == 0 || strlen(name) == 0 || strlen(name) >= FS_NAME_MAX ||
        dir_find(dir_nr, name, 0, 0, 0) || fs_get_inode(dir_nr, &dir) != 0 ||
        dir.type != FS_TYPE_DIRECTORY) return 0;
    blocks = (dir.size + FS_BLOCK_SIZE - 1) / FS_BLOCK_SIZE;
    if (blocks == 0) blocks = 1;
    for (uint64_t b = 0; b <= blocks; b++) {
        uint32_t data_block;
        if (b == blocks) {
            if (inode_data_block(&dir, b, 1, &data_block) != 0) return 0;
            dir.size = (b + 1) * (uint64_t)FS_BLOCK_SIZE;
            if (fs_put_inode(dir_nr, &dir) != 0) return 0;
        } else if (inode_data_block(&dir, b, 0, &data_block) != 0 || data_block == 0) {
            continue;
        }
        entries = (struct dir_entry*)cache_get(data_block, 1);
        if (entries == 0) return 0;
        for (uint32_t i = 0; i < FS_BLOCK_SIZE / sizeof(struct dir_entry); i++) {
            if (entries[i].inode_nr == 0) {
                entries[i].inode_nr = inode_nr;
                memset(entries[i].name, 0, FS_NAME_MAX);
                memcpy(entries[i].name, name, strlen(name));
                return 1;
            }
        }
    }
    return 0;
}

static int dir_empty(uint32_t dir_nr) {
    struct inode dir;
    struct dir_entry* entries;
    if (fs_get_inode(dir_nr, &dir) != 0) return 0;
    uint64_t blocks = (dir.size + FS_BLOCK_SIZE - 1) / FS_BLOCK_SIZE;
    for (uint64_t b = 0; b < blocks; b++) {
        uint32_t data_block;
        if (inode_data_block(&dir, b, 0, &data_block) != 0 || data_block == 0) continue;
        entries = (struct dir_entry*)cache_get(data_block, 0);
        if (entries == 0) return 0;
        for (uint32_t i = 0; i < FS_BLOCK_SIZE / sizeof(struct dir_entry); i++)
            if (entries[i].inode_nr != 0 && strcmp(entries[i].name, ".") != 0 &&
                strcmp(entries[i].name, "..") != 0) return 0;
    }
    return 1;
}

static int next_component(const char** cursor, char* component) {
    const char* p = *cursor;
    uint32_t n = 0;
    while (*p == '/') p++;
    if (*p == '\0') { *cursor = p; return 0; }
    while (*p != '\0' && *p != '/') {
        if (n + 1 >= FS_NAME_MAX) return -1;
        component[n++] = *p++;
    }
    component[n] = '\0';
    *cursor = p;
    return 1;
}

int fs_lookup_path(const char* path, uint32_t cwd_inode, uint32_t* out_inode,
                   struct inode* out_info) {
    const char* cursor;
    char component[FS_NAME_MAX];
    uint32_t current = path != 0 && path[0] == '/' ? FS_ROOT_INODE : cwd_inode;
    struct inode info;
    if (!fs_mounted || path == 0 || path[0] == '\0' || !valid_inode(current)) return 0;
    cursor = path;
    while (1) {
        int state = next_component(&cursor, component);
        if (state < 0) return 0;
        if (state == 0) break;
        if (strcmp(component, ".") == 0) continue;
        if (dir_find(current, component, &current, 0, 0) == 0) {
            if (strcmp(component, "..") == 0 && current == FS_ROOT_INODE) continue;
            return 0;
        }
        if (fs_get_inode(current, &info) != 0) return 0;
        if (*cursor != '\0' && info.type != FS_TYPE_DIRECTORY) return 0;
    }
    if (fs_get_inode(current, &info) != 0) return 0;
    if (out_inode) *out_inode = current;
    if (out_info) *out_info = info;
    return 1;
}

static int path_parent(const char* path, uint32_t cwd_inode, uint32_t* parent,
                       char* leaf) {
    char copy[FS_PATH_MAX];
    uint32_t length;
    int slash = -1;
    if (path == 0 || strlen(path) >= FS_PATH_MAX) return 0;
    strcpy(copy, path);
    length = (uint32_t)strlen(copy);
    while (length > 0 && copy[length - 1] == '/') copy[--length] = '\0';
    if (length == 0) return 0;
    for (uint32_t i = 0; i < length; i++) if (copy[i] == '/') slash = (int)i;
    if (slash < 0) {
        strcpy(leaf, copy);
        return fs_lookup_path(".", cwd_inode, parent, 0);
    }
    strcpy(leaf, copy + slash + 1);
    if (slash == 0) {
        copy[1] = '\0';
    } else {
        copy[slash] = '\0';
    }
    return fs_lookup_path(copy, cwd_inode, parent, 0);
}

int fs_create_path(const char* path, uint32_t cwd_inode, uint16_t type,
                   uint32_t* out_inode) {
    uint32_t parent_nr, inode_nr;
    char leaf[FS_NAME_MAX];
    struct inode inode = {0};
    if (!path_parent(path, cwd_inode, &parent_nr, leaf) ||
        strcmp(leaf, ".") == 0 || strcmp(leaf, "..") == 0 ||
        dir_find(parent_nr, leaf, 0, 0, 0)) return 0;
    int allocated = bitmap_allocate(g_sb.imap_start, FS_ROOT_INODE + 1,
                                    g_sb.total_inodes);
    if (allocated < 0) return 0;
    inode_nr = (uint32_t)allocated;
    inode.type = type;
    inode.link_count = 1;
    if (type == FS_TYPE_DIRECTORY) {
        int block = alloc_data_block();
        if (block < 0) {
            bitmap_free(g_sb.imap_start, inode_nr);
            return 0;
        }
        inode.size = FS_BLOCK_SIZE;
        inode.direct_blocks[0] = (uint32_t)block;
        struct dir_entry* entries = (struct dir_entry*)cache_get((uint32_t)block, 1);
        if (entries == 0) {
            bitmap_free(g_sb.bmap_start, (uint32_t)block);
            bitmap_free(g_sb.imap_start, inode_nr);
            return 0;
        }
        entries[0].inode_nr = inode_nr; strcpy(entries[0].name, ".");
        entries[1].inode_nr = parent_nr; strcpy(entries[1].name, "..");
    }
    if (fs_put_inode(inode_nr, &inode) != 0 || !dir_add(parent_nr, leaf, inode_nr)) {
        free_inode_blocks(&inode);
        bitmap_free(g_sb.imap_start, inode_nr);
        return 0;
    }
    if (type == FS_TYPE_DIRECTORY) {
        struct inode parent;
        if (fs_get_inode(parent_nr, &parent) == 0) { parent.link_count++; fs_put_inode(parent_nr, &parent); }
    }
    if (out_inode) *out_inode = inode_nr;
    return 1;
}

int fs_read_inode(uint32_t inode_nr, uint64_t offset, void* buffer, uint32_t length) {
    struct inode inode;
    uint8_t* output = (uint8_t*)buffer;
    if (buffer == 0 || fs_get_inode(inode_nr, &inode) != 0 || inode.type != FS_TYPE_FILE) return -1;
    if (offset >= inode.size || length == 0) return 0;
    if (inode.size - offset < length) length = (uint32_t)(inode.size - offset);
    uint32_t done = 0;
    if (offset > UINT64_MAX - length) return -1;
    while (done < length) {
        uint32_t block_nr;
        uint64_t file_offset = offset + done;
        uint32_t chunk = FS_BLOCK_SIZE - (uint32_t)(file_offset % FS_BLOCK_SIZE);
        if (chunk > length - done) chunk = length - done;
        if (inode_data_block(&inode, file_offset / FS_BLOCK_SIZE, 0, &block_nr) != 0) return -1;
        if (block_nr == 0) memset(output + done, 0, chunk);
        else memcpy(output + done, cache_get(block_nr, 0) + file_offset % FS_BLOCK_SIZE, chunk);
        done += chunk;
    }
    return (int)done;
}

int fs_write_inode(uint32_t inode_nr, uint64_t offset, const void* buffer, uint32_t length) {
    struct inode old_inode, inode;
    const uint8_t* input = (const uint8_t*)buffer;
    if (buffer == 0 || fs_get_inode(inode_nr, &old_inode) != 0 ||
        old_inode.type != FS_TYPE_FILE || offset > FS_MAX_FILE_SIZE ||
        (uint64_t)length > FS_MAX_FILE_SIZE - offset ||
        offset > UINT64_MAX - length) return -1;
    inode = old_inode;
    uint32_t done = 0;
    while (done < length) {
        uint32_t block_nr;
        uint64_t file_offset = offset + done;
        uint32_t chunk = FS_BLOCK_SIZE - (uint32_t)(file_offset % FS_BLOCK_SIZE);
        if (chunk > length - done) chunk = length - done;
        if (inode_data_block(&inode, file_offset / FS_BLOCK_SIZE, 1, &block_nr) != 0 ||
            block_nr == 0 || cache_get(block_nr, 1) == 0) {
            rollback_new_blocks(&old_inode, &inode); fs_put_inode(inode_nr, &old_inode); return -1;
        }
        memcpy(cache_get(block_nr, 1) + file_offset % FS_BLOCK_SIZE,
               input + done, chunk);
        done += chunk;
    }
    if (offset + done > inode.size) inode.size = offset + done;
    if (fs_put_inode(inode_nr, &inode) != 0 || cache_sync() != 0) {
        rollback_new_blocks(&old_inode, &inode); fs_put_inode(inode_nr, &old_inode); return -1;
    }
    return (int)done;
}

int fs_stat_path(const char* path, uint32_t cwd_inode, struct inode* out_inode,
                 uint32_t* out_inode_nr) {
    return fs_lookup_path(path, cwd_inode, out_inode_nr, out_inode);
}

int fs_unlink_path(const char* path, uint32_t cwd_inode) {
    uint32_t parent_nr, inode_nr, block_nr, index;
    char leaf[FS_NAME_MAX];
    struct inode inode, parent;
    if (!path_parent(path, cwd_inode, &parent_nr, leaf) ||
        strcmp(leaf, ".") == 0 || strcmp(leaf, "..") == 0 ||
        !dir_find(parent_nr, leaf, &inode_nr, &block_nr, &index) ||
        fs_get_inode(inode_nr, &inode) != 0) return 0;
    if (inode.type == FS_TYPE_DIRECTORY && !dir_empty(inode_nr)) return 0;
    struct dir_entry* entry = (struct dir_entry*)cache_get(block_nr, 1);
    if (entry == 0) return 0;
    memset(&entry[index], 0, sizeof(struct dir_entry));
    if (fs_get_inode(parent_nr, &parent) == 0 && inode.type == FS_TYPE_DIRECTORY &&
        parent.link_count > 0) { parent.link_count--; fs_put_inode(parent_nr, &parent); }
    inode.link_count = 0;
    if (g_open_refs[inode_nr] == 0) {
        free_inode_blocks(&inode);
        memset(&inode, 0, sizeof(inode));
        bitmap_free(g_sb.imap_start, inode_nr);
    }
    if (fs_put_inode(inode_nr, &inode) != 0) return 0;
    return cache_sync() == 0;
}

static void release_inode(uint32_t inode_nr) {
    if (!valid_inode(inode_nr) || g_open_refs[inode_nr] == 0) return;
    g_open_refs[inode_nr]--;
    if (g_open_refs[inode_nr] == 0) {
        struct inode inode;
        if (fs_get_inode(inode_nr, &inode) == 0 && inode.link_count == 0) {
            free_inode_blocks(&inode); memset(&inode, 0, sizeof(inode));
            fs_put_inode(inode_nr, &inode);
            bitmap_free(g_sb.imap_start, inode_nr);
            (void)cache_sync();
        }
    }
}

void fs_release_inode(uint32_t inode_nr) {
    release_inode(inode_nr);
    (void)cache_sync();
}

static int list_inode(uint32_t inode_nr, char* buffer, uint32_t length) {
    struct inode dir;
    if (fs_get_inode(inode_nr, &dir) != 0 || dir.type != FS_TYPE_DIRECTORY || buffer == 0) return -1;
    uint32_t done = 0;
    uint64_t blocks = (dir.size + FS_BLOCK_SIZE - 1) / FS_BLOCK_SIZE;
    for (uint64_t b = 0; b < blocks; b++) {
        uint32_t data_block;
        if (inode_data_block(&dir, b, 0, &data_block) != 0 || data_block == 0) continue;
        struct dir_entry* entries = (struct dir_entry*)cache_get(data_block, 0);
        if (entries == 0) return -1;
        for (uint32_t i = 0; i < FS_BLOCK_SIZE / sizeof(struct dir_entry); i++) {
            if (entries[i].inode_nr == 0 || done >= length) continue;
            uint32_t n = (uint32_t)strlen(entries[i].name);
            if (n + 1 > length - done) return (int)done;
            memcpy(buffer + done, entries[i].name, n); done += n; buffer[done++] = '\n';
        }
    }
    return (int)done;
}

int fs_list_path(const char* path, uint32_t cwd_inode, char* buffer, uint32_t length) {
    uint32_t inode_nr;
    if (!fs_lookup_path(path == 0 || path[0] == '\0' ? "." : path,
                        cwd_inode, &inode_nr, 0)) return -1;
    return list_inode(inode_nr, buffer, length);
}

static int canonicalize(const char* path, const char* cwd, char* out) {
    char parts[32][FS_NAME_MAX];
    uint32_t count = 0, out_len = 0;
    const char* sources[2] = {cwd, path};
    for (uint32_t s = 0; s < 2; s++) {
        const char* p = sources[s]; char component[FS_NAME_MAX];
        if (s == 0 && (path == 0 || path[0] == '/')) continue;
        while (p != 0) {
            int state = next_component(&p, component);
            if (state <= 0) break;
            if (strcmp(component, ".") == 0) continue;
            if (strcmp(component, "..") == 0) { if (count > 0) count--; continue; }
            if (count >= 32) return 0;
            strcpy(parts[count++], component);
        }
    }
    if (count == 0) { strcpy(out, "/"); return 1; }
    out[out_len++] = '/';
    for (uint32_t i = 0; i < count; i++) {
        uint32_t n = (uint32_t)strlen(parts[i]);
        if (out_len + n + 1 >= FS_PATH_MAX) return 0;
        memcpy(out + out_len, parts[i], n); out_len += n;
        if (i + 1 < count) out[out_len++] = '/';
    }
    out[out_len] = '\0';
    return 1;
}

int fs_init(void) {
    uint8_t sector[FS_SECTOR_SIZE];
    uint64_t inode_capacity;
    uint64_t bitmap_capacity;
    uint64_t layout_end;
    print_debug("[FS] Initializing MyFS (4KB Block)...\n");
    cache_drop();
    fs_mounted = 0;
    if (disk_read_sector_checked(block_lba(1), sector, 1) != 0) return -1;
    memset(&g_sb, 0, sizeof(g_sb));
    memcpy(&g_sb, sector, sizeof(g_sb));

    inode_capacity = (uint64_t)FS_BLOCK_SIZE / sizeof(struct inode);
    bitmap_capacity = (uint64_t)FS_BLOCK_SIZE * 8;
    layout_end = (uint64_t)g_sb.inode_start + g_sb.inode_blocks;
    fs_mounted = g_sb.magic == FS_MAGIC &&
                 g_sb.version == FS_FORMAT_VERSION &&
                 g_sb.block_size == FS_BLOCK_SIZE &&
                 g_sb.total_inodes > FS_ROOT_INODE &&
                 g_sb.total_blocks > g_sb.first_data_block &&
                 (uint64_t)g_sb.total_blocks <= FS_MAX_BLOCKS_LBA48 &&
                 g_sb.imap_start >= 2 &&
                 (uint64_t)g_sb.imap_start + g_sb.imap_blocks <= g_sb.bmap_start &&
                 (uint64_t)g_sb.bmap_start + g_sb.bmap_blocks <= g_sb.inode_start &&
                 layout_end <= g_sb.first_data_block &&
                 g_sb.first_data_block < g_sb.total_blocks &&
                 g_sb.imap_blocks >= ((uint64_t)g_sb.total_inodes + bitmap_capacity - 1) /
                                      bitmap_capacity &&
                 g_sb.bmap_blocks >= ((uint64_t)g_sb.total_blocks + bitmap_capacity - 1) /
                                      bitmap_capacity &&
                 g_sb.inode_blocks >= ((uint64_t)g_sb.total_inodes + inode_capacity - 1) /
                                      inode_capacity;
    if (!fs_mounted) {
        print_error("[FS] invalid or unsupported MyFS superblock/layout.\n");
        return -1;
    }

    if (g_open_refs != 0) {
        kfree(g_open_refs);
        g_open_refs = 0;
    }
    if ((uint64_t)g_sb.total_inodes > SIZE_MAX / sizeof(*g_open_refs)) {
        print_error("[FS] inode reference table size overflow.\n");
        return -1;
    }
    g_open_refs = (uint32_t*)kmalloc((size_t)g_sb.total_inodes *
                                     sizeof(*g_open_refs));
    if (g_open_refs == 0) {
        print_error("[FS] unable to allocate inode reference table.\n");
        return -1;
    }
    memset(g_open_refs, 0,
           (size_t)g_sb.total_inodes * sizeof(*g_open_refs));

#if BOOT_DIAGNOSTIC
    print_debug("[FS] MyFS v");
    print_int((long)g_sb.version);
    print_string(" mounted; blocks=");
    print_int((long)g_sb.total_blocks);
    print_string(" inodes=");
    print_int((long)g_sb.total_inodes);
    print_string(" data_start=");
    print_int((long)g_sb.first_data_block);
    print_string("\n");
#endif
    return fs_mounted ? 0 : -1;
}

static void fs_service_handle(struct fs_request* request) {
    char canonical[FS_PATH_MAX];
    struct inode inode;
    uint32_t inode_nr;
    request->result = -1;
    if (!fs_mounted || request == 0) return;
    if (!canonicalize(request->name, request->cwd_path, canonical)) return;
    strcpy(request->result_path, canonical);
    switch (request->operation) {
    case FS_REQUEST_OPEN:
        if (!fs_stat_path(canonical, FS_ROOT_INODE, &inode, &inode_nr)) {
            if (!(request->flags & 0x01) || !fs_create_path(canonical, FS_ROOT_INODE,
                                                             FS_TYPE_FILE, &inode_nr) ||
                fs_get_inode(inode_nr, &inode) != 0) return;
        }
        if (inode.type != FS_TYPE_FILE) return;
        if ((request->flags & 0x02U) != 0 &&
            truncate_inode(inode_nr, &inode) != 0) return;
        g_open_refs[inode_nr]++; request->inode_nr = inode_nr;
        request->result_inode = inode_nr; request->result_type = inode.type;
        request->stat_size = inode.size; request->result = 0; break;
    case FS_REQUEST_RELEASE: release_inode(request->inode_nr); request->result = 0; break;
    case FS_REQUEST_READ:
        inode_nr = request->inode_nr;
        if (inode_nr == 0 && !fs_stat_path(canonical, FS_ROOT_INODE, &inode, &inode_nr)) return;
        request->result = fs_read_inode(inode_nr, request->offset, request->buffer, request->length); break;
    case FS_REQUEST_WRITE:
        inode_nr = request->inode_nr;
        if (inode_nr == 0) {
            if (!fs_stat_path(canonical, FS_ROOT_INODE, &inode, &inode_nr)) {
                if (!fs_create_path(canonical, FS_ROOT_INODE, FS_TYPE_FILE, &inode_nr)) return;
            }
        }
        request->result = fs_write_inode(inode_nr, request->offset, request->buffer, request->length); break;
    case FS_REQUEST_UNLINK: request->result = fs_unlink_path(canonical, FS_ROOT_INODE) ? 0 : -1; break;
    case FS_REQUEST_LIST: request->result = fs_list_path(canonical, FS_ROOT_INODE,
                                                         (char*)request->buffer, request->length); break;
    case FS_REQUEST_STAT:
        if (!fs_stat_path(canonical, FS_ROOT_INODE, &inode, &inode_nr)) return;
        request->result_inode = inode_nr; request->stat_size = inode.size;
        request->stat_links = inode.link_count; request->result_type = inode.type;
        request->result = 0; break;
    case FS_REQUEST_MKDIR:
        request->result = fs_create_path(canonical, FS_ROOT_INODE, FS_TYPE_DIRECTORY,
                                         &request->result_inode) ? 0 : -1; break;
    case FS_REQUEST_CHDIR:
        if (!fs_stat_path(canonical, FS_ROOT_INODE, &inode, &inode_nr) ||
            inode.type != FS_TYPE_DIRECTORY) return;
        request->result_inode = inode_nr; request->result = 0; break;
    case FS_REQUEST_GETCWD:
        if (request->buffer == 0 || request->length == 0 ||
            strlen(request->cwd_path) + 1 > request->length) return;
        strcpy((char*)request->buffer, request->cwd_path[0] ? request->cwd_path : "/");
        request->result = (int32_t)strlen((char*)request->buffer); break;
    default: break;
    }
    if (request->operation != FS_REQUEST_READ && request->operation != FS_REQUEST_GETCWD)
        (void)cache_sync();
}

static void fs_service_main(void) {
    while (1) {
        struct message message;
        if (ipc_receive(IPC_ANY, &message) != 0 || message.type != FS_MESSAGE_REQUEST ||
            message.value == 0) continue;
        struct fs_request* request = (struct fs_request*)message.value;
        fs_service_handle(request);
        struct thread* client = thread_find_by_pid(message.source_pid);
        struct message reply = {0, FS_MESSAGE_REPLY, 0};
        if (client != 0 && client->status != TASK_ZOMBIE && client->status != TASK_DEAD)
            (void)ipc_send(client, &reply);
    }
}

void fs_service_init(void) {
    if (!fs_mounted || fs_service_task != 0) return;
    fs_service_task = thread_create(fs_service_main, 5);
    if (fs_service_task != 0) thread_append(fs_service_task);
}

int fs_service_call(struct fs_request* request) {
    if (!request || !fs_service_task || fs_service_task->status == TASK_ZOMBIE ||
        fs_service_task->status == TASK_DEAD || fs_service_task->process == 0) return -1;
    struct message message = {0, FS_MESSAGE_REQUEST, (uint64_t)request};
    struct message reply;
    if (ipc_send(fs_service_task, &message) != 0 ||
        ipc_receive((int32_t)fs_service_task->process->pid, &reply) != 0 ||
        reply.type != FS_MESSAGE_REPLY) return -1;
    return request->result;
}

int fs_find_file(const char* filename, struct inode* out_inode) {
    uint32_t inode_nr;
    return fs_stat_path(filename, FS_ROOT_INODE, out_inode, &inode_nr) &&
           out_inode->type == FS_TYPE_FILE;
}

int fs_create_file(const char* filename) {
    return fs_create_path(filename, FS_ROOT_INODE, FS_TYPE_FILE, 0);
}

int fs_read_file(const char* filename, uint64_t offset, void* buffer, uint32_t length) {
    uint32_t inode_nr;
    struct inode inode;
    if (!fs_stat_path(filename, FS_ROOT_INODE, &inode, &inode_nr) || inode.type != FS_TYPE_FILE) return -1;
    return fs_read_inode(inode_nr, offset, buffer, length);
}

int fs_write_file(const char* filename, uint64_t offset, const void* buffer, uint32_t length) {
    uint32_t inode_nr;
    struct inode inode;
    if (!fs_stat_path(filename, FS_ROOT_INODE, &inode, &inode_nr)) {
        if (!fs_create_file(filename) || !fs_stat_path(filename, FS_ROOT_INODE, &inode, &inode_nr)) return -1;
    }
    return fs_write_inode(inode_nr, offset, buffer, length);
}

int fs_unlink_file(const char* filename) { return fs_unlink_path(filename, FS_ROOT_INODE); }
int fs_list_root(char* buffer, uint32_t length) { return fs_list_path("/", FS_ROOT_INODE, buffer, length); }

void fs_run_self_test(void) {
    static const char name[] = "fs-selftest";
    static const char data[] = "MyFS persistent read/write test";
    static const char persistence_name[] = "fs-persistence";
    static const char persistence_data[] = "MyFS survives a reboot";
    char readback[sizeof(data)] = {0};
    fs_unlink_file(name);
    int written = fs_write_file(name, 0, data, sizeof(data) - 1);
    int read = fs_read_file(name, 0, readback, sizeof(readback) - 1);
    if (written == (int)(sizeof(data) - 1) && read == written && strcmp(data, readback) == 0 && fs_unlink_file(name))
        print_success("[FS] Create/read/write/unlink self-test PASSED.\n");
    else print_error("[FS] Create/read/write/unlink self-test FAILED.\n");
    char persisted[sizeof(persistence_data)] = {0};
    int persistence_read = fs_read_file(persistence_name, 0, persisted, sizeof(persistence_data) - 1);
    if (persistence_read == (int)(sizeof(persistence_data) - 1) &&
        strcmp(persisted, persistence_data) == 0) {
        persistence_verified = 1;
        print_success("[FS] Persistence check PASSED.\n");
    } else if (fs_write_file(persistence_name, 0, persistence_data,
                             sizeof(persistence_data) - 1) ==
               (int)(sizeof(persistence_data) - 1))
        print_info("[FS] Persistence marker created.\n");
    else print_error("[FS] Persistence check FAILED.\n");

    /* 目录、相对层级和多级间接块回归；失败时立即清理已经创建的项。 */
    static const char dir_name[] = "/fs-self-dir";
    static const char child_name[] = "/fs-self-dir/note";
    uint32_t dir_inode, child_inode;
    char small[8] = {0};
    int directory_ok = fs_create_path(dir_name, FS_ROOT_INODE, FS_TYPE_DIRECTORY,
                                      &dir_inode) &&
                       fs_create_path(child_name, FS_ROOT_INODE, FS_TYPE_FILE,
                                      &child_inode) &&
                       fs_write_inode(child_inode, 0, "dir", 3) == 3 &&
                       fs_read_inode(child_inode, 0, small, 3) == 3 &&
                       small[0] == 'd' && fs_unlink_path(child_name, FS_ROOT_INODE) &&
                       fs_unlink_path(dir_name, FS_ROOT_INODE);
    if (directory_ok) print_success("[FS] Directory/path self-test PASSED.\n");
    else print_error("[FS] Directory/path self-test FAILED.\n");

    static uint8_t indirect_data[512];
    memset(indirect_data, 0x5A, sizeof(indirect_data));
    int large_ok = fs_write_file("fs-indirect", FS_DIRECT_BLOCKS * FS_BLOCK_SIZE,
                                 indirect_data, sizeof(indirect_data)) == (int)sizeof(indirect_data);
    memset(indirect_data, 0, sizeof(indirect_data));
    large_ok = large_ok && fs_read_file("fs-indirect", FS_DIRECT_BLOCKS * FS_BLOCK_SIZE,
                                        indirect_data, sizeof(indirect_data)) == (int)sizeof(indirect_data) &&
               indirect_data[0] == 0x5A && fs_unlink_file("fs-indirect");
    static const uint64_t double_offset =
        ((uint64_t)FS_DIRECT_BLOCKS + FS_INDIRECT_ENTRIES) * FS_BLOCK_SIZE;
    static const uint64_t double_offsets[] = {
        double_offset,
        double_offset + (uint64_t)FS_INDIRECT_ENTRIES * FS_BLOCK_SIZE
    };
    int double_ok = 1;
    for (uint32_t i = 0; i < sizeof(double_offsets) / sizeof(double_offsets[0]); i++) {
        memset(indirect_data, (int)(0xA5 + i), sizeof(indirect_data));
        if (fs_write_file("fs-double-indirect", double_offsets[i], indirect_data,
                          sizeof(indirect_data)) != (int)sizeof(indirect_data)) {
            double_ok = 0;
            continue;
        }
        memset(indirect_data, 0, sizeof(indirect_data));
        if (fs_read_file("fs-double-indirect", double_offsets[i], indirect_data,
                         sizeof(indirect_data)) != (int)sizeof(indirect_data) ||
            indirect_data[0] != (uint8_t)(0xA5 + i))
            double_ok = 0;
    }
    if (!fs_unlink_file("fs-double-indirect")) double_ok = 0;
    static const uint64_t triple_offset =
        ((uint64_t)FS_DIRECT_BLOCKS + FS_INDIRECT_ENTRIES +
         (uint64_t)FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES) * FS_BLOCK_SIZE;
    static const uint64_t triple_offsets[] = {
        triple_offset,
        triple_offset + (uint64_t)FS_INDIRECT_ENTRIES * FS_BLOCK_SIZE,
        triple_offset + (uint64_t)FS_INDIRECT_ENTRIES * FS_INDIRECT_ENTRIES *
                        FS_BLOCK_SIZE
    };
    int triple_ok = 1;
    for (uint32_t i = 0; i < sizeof(triple_offsets) / sizeof(triple_offsets[0]); i++) {
        memset(indirect_data, (int)(0x3C + i), sizeof(indirect_data));
        if (fs_write_file("fs-triple-indirect", triple_offsets[i], indirect_data,
                          sizeof(indirect_data)) != (int)sizeof(indirect_data)) {
            triple_ok = 0;
            continue;
        }
        memset(indirect_data, 0, sizeof(indirect_data));
        if (fs_read_file("fs-triple-indirect", triple_offsets[i], indirect_data,
                         sizeof(indirect_data)) != (int)sizeof(indirect_data) ||
            indirect_data[0] != (uint8_t)(0x3C + i))
            triple_ok = 0;
    }
    if (!fs_unlink_file("fs-triple-indirect")) triple_ok = 0;
    if (large_ok && double_ok && triple_ok)
        print_success("[FS] Single/double/triple indirect self-test PASSED.\n");
    else
        print_error("[FS] Single/double/triple indirect self-test FAILED.\n");
}

int fs_persistence_verified(void) { return persistence_verified; }
