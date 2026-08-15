#include "kalloc.h"
#include "memory.h"
#include "print.h"
#include "string.h"
#include "sync.h"
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#define HEAP_ARENA_MAGIC 0x4152454E41504D47ULL /* "ARENAPMG" */
#define HEAP_BLOCK_MAGIC 0x424C4F434B504D47ULL /* "BLOCKPMG" */
#define HEAP_ALIGNMENT   8ULL

/*
 * Arena 和 Block 都位于它们自己管理的内核堆页中。
 * 这里的指针全部是高半区虚拟地址；arena->paddr 才是对应的物理地址。
 */
struct HeapArena;

struct HeapBlock {
    uint64_t magic;
    size_t size;
    bool is_free;
    uint8_t reserved[7];
    struct HeapArena* arena;
    struct HeapBlock* prev;
    struct HeapBlock* next;
};

struct HeapArena {
    uint64_t magic;
    paddr_t paddr;
    uint32_t page_count;
    uint32_t reserved;
    size_t live_blocks;
    struct HeapArena* prev;
    struct HeapArena* next;
    struct HeapBlock* first;
};

static struct HeapArena* heap_arenas;
static bool heap_initialized;
static spinlock_t heap_lock;

static bool add_overflows(size_t left, size_t right)
{
    return right > SIZE_MAX - left;
}

static bool align_size(size_t size, size_t* aligned)
{
    if (add_overflows(size, HEAP_ALIGNMENT - 1)) {
        return false;
    }

    *aligned = (size + HEAP_ALIGNMENT - 1) & ~(HEAP_ALIGNMENT - 1);
    return true;
}

static void link_arena(struct HeapArena* arena)
{
    arena->prev = NULL;
    arena->next = heap_arenas;
    if (heap_arenas != NULL) {
        heap_arenas->prev = arena;
    }
    heap_arenas = arena;
}

static void unlink_arena(struct HeapArena* arena)
{
    if (arena->prev != NULL) {
        arena->prev->next = arena->next;
    } else {
        heap_arenas = arena->next;
    }

    if (arena->next != NULL) {
        arena->next->prev = arena->prev;
    }
}

static struct HeapArena* create_arena(size_t requested_size)
{
    size_t aligned_size;
    size_t overhead;
    size_t total_size;
    size_t pages_size;
    uint32_t page_count;
    paddr_t paddr;
    struct HeapArena* arena;
    struct HeapBlock* block;

    if (!align_size(requested_size, &aligned_size)) {
        return NULL;
    }

    overhead = sizeof(struct HeapArena) + sizeof(struct HeapBlock);
    if (add_overflows(overhead, aligned_size)) {
        return NULL;
    }

    total_size = overhead + aligned_size;
    if (add_overflows(total_size, PAGE_SIZE - 1)) {
        return NULL;
    }
    pages_size = (total_size + PAGE_SIZE - 1) / PAGE_SIZE;
    if (pages_size == 0 || pages_size > UINT32_MAX) {
        return NULL;
    }
    page_count = (uint32_t)pages_size;

    paddr = alloc_pages_owned(page_count, PAGE_OWNER_HEAP);
    if (paddr == 0) {
        return NULL;
    }

    /* 新 arena 不携带旧页内容，避免堆对象之间发生数据残留。 */
    memset(P2V(paddr), 0, pages_size * PAGE_SIZE);

    arena = (struct HeapArena*)P2V(paddr);
    block = (struct HeapBlock*)((uint8_t*)arena + sizeof(*arena));

    arena->magic = HEAP_ARENA_MAGIC;
    arena->paddr = paddr;
    arena->page_count = page_count;
    arena->reserved = 0;
    arena->live_blocks = 0;
    arena->first = block;

    block->magic = HEAP_BLOCK_MAGIC;
    block->size = pages_size * PAGE_SIZE - overhead;
    block->is_free = true;
    block->arena = arena;
    block->prev = NULL;
    block->next = NULL;

    link_arena(arena);
    return arena;
}

static void split_block(struct HeapBlock* block, size_t requested_size)
{
    size_t remaining;
    struct HeapBlock* new_block;

    if (block->size < requested_size) {
        return;
    }

    remaining = block->size - requested_size;
    if (remaining < sizeof(struct HeapBlock) + HEAP_ALIGNMENT) {
        return;
    }

    new_block = (struct HeapBlock*)((uint8_t*)block +
                                    sizeof(*block) + requested_size);
    new_block->magic = HEAP_BLOCK_MAGIC;
    new_block->size = remaining - sizeof(*block);
    new_block->is_free = true;
    new_block->arena = block->arena;
    new_block->prev = block;
    new_block->next = block->next;

    if (new_block->next != NULL) {
        new_block->next->prev = new_block;
    }
    block->next = new_block;
    block->size = requested_size;
}

static struct HeapBlock* find_block(void* ptr)
{
    for (struct HeapArena* arena = heap_arenas;
         arena != NULL;
         arena = arena->next) {
        if (arena->magic != HEAP_ARENA_MAGIC) {
            continue;
        }

        for (struct HeapBlock* block = arena->first;
             block != NULL;
             block = block->next) {
            if (block->magic == HEAP_BLOCK_MAGIC &&
                (void*)((uint8_t*)block + sizeof(*block)) == ptr) {
                return block;
            }
        }
    }
    return NULL;
}

static void merge_with_next(struct HeapBlock* block)
{
    struct HeapBlock* next = block->next;

    if (next == NULL || !next->is_free ||
        (uint8_t*)block + sizeof(*block) + block->size !=
            (uint8_t*)next) {
        return;
    }

    block->size += sizeof(*block) + next->size;
    block->next = next->next;
    if (block->next != NULL) {
        block->next->prev = block;
    }
}

static void reclaim_empty_arena(struct HeapArena* arena)
{
    if (arena == NULL || arena->live_blocks != 0) {
        return;
    }

    /* 没有活动 block 时，链表中所有空间都已经合并为空闲块。 */
    unlink_arena(arena);
    if (free_pages_owned(arena->paddr, arena->page_count,
                         PAGE_OWNER_HEAP) != 0) {
        /* 释放失败时恢复链表，避免丢失这块 arena 的所有权。 */
        link_arena(arena);
        print_error("[KALLOC] failed to reclaim empty arena.\n");
    }
}

void kmalloc_init(void)
{
    spinlock_init(&heap_lock);
    heap_arenas = NULL;
    heap_initialized = true;
    print_debug("[INFO] Kernel heap allocator initialized.\n");
}

void* kmalloc(size_t size)
{
    size_t aligned_size;

    if (!heap_initialized || size == 0 ||
        !align_size(size, &aligned_size)) {
        return NULL;
    }

    spinlock_acquire(&heap_lock);

    for (;;) {
        for (struct HeapArena* arena = heap_arenas;
             arena != NULL;
             arena = arena->next) {
            for (struct HeapBlock* block = arena->first;
                 block != NULL;
                 block = block->next) {
                if (block->is_free && block->size >= aligned_size) {
                    split_block(block, aligned_size);
                    block->is_free = false;
                    arena->live_blocks++;
                    void* result = (uint8_t*)block + sizeof(*block);
                    spinlock_release(&heap_lock);
                    return result;
                }
            }
        }

        /* 没有可复用的 block，创建一个新的页后再循环查找。 */
        if (create_arena(aligned_size) == NULL) {
            spinlock_release(&heap_lock);
            print_error("[KALLOC] out of kernel heap memory.\n");
            return NULL;
        }
    }
}

int kfree(void* ptr)
{
    struct HeapBlock* block;
    struct HeapArena* arena;

    if (ptr == NULL) {
        return 0;
    }

    spinlock_acquire(&heap_lock);

    /* 遍历已知 block，避免对任意 ptr 直接回退 header 并解引用。 */
    block = find_block(ptr);
    if (block == NULL || block->is_free) {
        spinlock_release(&heap_lock);
        return -1;
    }

    arena = block->arena;
    if (arena->live_blocks == 0) {
        spinlock_release(&heap_lock);
        return -1;
    }
    block->is_free = true;
    arena->live_blocks--;

    merge_with_next(block);
    if (block->prev != NULL && block->prev->is_free) {
        block = block->prev;
        merge_with_next(block);
    }

    reclaim_empty_arena(arena);
    spinlock_release(&heap_lock);
    return 0;
}

void kalloc_get_stats(struct kalloc_stats* stats)
{
    if (stats == NULL) {
        return;
    }

    memset(stats, 0, sizeof(*stats));
    if (!heap_initialized) {
        return;
    }

    spinlock_acquire(&heap_lock);
    for (struct HeapArena* arena = heap_arenas;
         arena != NULL;
         arena = arena->next) {
        stats->arenas++;
        stats->arena_pages += arena->page_count;
        for (struct HeapBlock* block = arena->first;
             block != NULL;
             block = block->next) {
            if (block->is_free) {
                stats->free_bytes += block->size;
            } else {
                stats->active_blocks++;
                stats->allocated_bytes += block->size;
            }
        }
    }
    spinlock_release(&heap_lock);
}

void kalloc_dump_stats(const char* tag)
{
    struct kalloc_stats stats;

    kalloc_get_stats(&stats);
    print_info("[KALLOC] stats: ");
    if (tag != NULL) {
        print_string(tag);
        print_string(" ");
    }
    print_string("arenas=");
    print_int((long)stats.arenas);
    print_string(" pages=");
    print_int((long)stats.arena_pages);
    print_string(" active-blocks=");
    print_int((long)stats.active_blocks);
    print_string(" allocated-bytes=");
    print_int((long)stats.allocated_bytes);
    print_string(" free-bytes=");
    print_int((long)stats.free_bytes);
    print_string("\n");
}
