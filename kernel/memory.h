// kernel/memory.h

#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>
#include <stddef.h>

#define PAGE_SIZE       4096ULL
#define PAGE_SHIFT      12
#define PAGE_OFFSET     0xFFFF800000000000ULL

/* loader.S 使用的启动页表和 E820/位图保留区。 */
#define BOOT_KERNEL_PML4_PADDR 0x00070000ULL
#define MEMORY_BITMAP_PADDR    0x00200000ULL
#define BOOT_RESERVED_END      0x00200000ULL

/*
 * 当前内核使用 48 位规范虚拟地址，并把物理内存做高半区直映射。
 * PAGE_OFFSET + paddr 必须仍然是规范地址，因此上限是 128 TiB。
 */
#define DIRECT_MAP_MAX_PHYS (1ULL << 47)

typedef uint64_t paddr_t;
typedef uint64_t vaddr_t;

/*
 * 物理页 owner 记录的是“当前谁拥有这页”，不是页表层级。
 * PAGE_OWNER_ANY 只允许用于兼容旧调用方的无类型释放接口。
 */
typedef enum {
    PAGE_OWNER_FREE = 0,
    PAGE_OWNER_GENERIC,
    PAGE_OWNER_PAGE_TABLE,
    PAGE_OWNER_KERNEL,
    PAGE_OWNER_HEAP,
    PAGE_OWNER_USER,
    PAGE_OWNER_THREAD,
    PAGE_OWNER_PROCESS,
    PAGE_OWNER_TTY,
    PAGE_OWNER_TEST,
    PAGE_OWNER_RESERVED,
    PAGE_OWNER_COUNT,
    PAGE_OWNER_ANY = 0xFF
} page_owner_t;

// 物理地址转虚拟地址 (Physical to Virtual)
#define P2V(paddr) ((void*)((uint64_t)(paddr) + PAGE_OFFSET))

// 虚拟地址转物理地址 (Virtual to Physical)
#define V2P(vaddr) ((paddr_t)((uint64_t)(vaddr) - PAGE_OFFSET))

// 页表属性标志位
#define PTE_P    0x01    // Present: 存在位 (1表示在物理内存中)
#define PTE_RW   0x02    // Read/Write: 读写位 (1表示可读写)
#define PTE_US   0x04    // User/Supervisor: 用户态位 (1表示Ring 3平民可访问)
#define PTE_PS   (1ULL << 7)
/* 软件位：硬件忽略，表示该用户页是写时复制页。 */
#define PTE_COW  (1ULL << 9)
// 四级页表的索引提取宏
// 64位虚拟地址的 39~47 位是 PML4 的索引 (共 9 位，最大 511)
#define PML4_INDEX(vaddr) (((vaddr) >> 39) & 0x1FF)
// 30~38 位是 PDPT 的索引
#define PDPT_INDEX(vaddr) (((vaddr) >> 30) & 0x1FF)
// 21~29 位是 PD 的索引
#define PD_INDEX(vaddr)   (((vaddr) >> 21) & 0x1FF)
// 12~20 位是 PT 的索引
#define PT_INDEX(vaddr)   (((vaddr) >> 12) & 0x1FF)

// 地址掩码，用于抹除低 12 位的属性标志，提取纯净的物理基址
#define PTE_ADDR_MASK     (~0xFFFULL)
// 强制编译器按 1 字节对齐，绝不允许私自加空白填充！
struct ARDS {
    uint64_t base_addr;  // 这块内存的起始物理地址 (8字节)
    uint64_t length;     // 这块内存的大小 (8字节)
    uint32_t type;       // 这块内存的类型 (4字节)
} __attribute__((packed));

/*
 * allocated_bits: 1 表示 PMM 已将页面交给某个拥有者。
 * reserved_bits:  1 表示页面属于内核/启动结构，永远不能分配。
 *
 * 这不是页表。页表描述虚拟地址映射，这个结构描述物理页生命周期。
 */
typedef struct {
    uint8_t* bits;
    uint8_t* reserved_bits;
    uint8_t* owners;
    uint32_t* refcounts;
    uint64_t page_count;
    uint64_t bmap_bytes;
} Bitmap;

struct pmm_stats {
    uint64_t free_pages;
    uint64_t allocated_pages;
    uint64_t reserved_pages;
    uint64_t owner_pages[PAGE_OWNER_COUNT];
    uint64_t user_mapped_pages;
    uint64_t user_mapping_refs;
};

extern Bitmap phy_mem_map;

/*
 * 锁与调用约束：地址空间操作由调用方保证串行化；若同时持有多类锁，
 * 顺序必须是 address-space -> heap -> PMM。PMM 锁只保护位图、owner 和
 * 页清零，临界区内不能调用 kmalloc、打印或页表创建。当前中断处理程序
 * 不调用 PMM/kmalloc；spinlock 还会关闭本地中断，防止同 CPU 重入。
 */

/* 从 loader 保存的 E820 表初始化 PMM，并扩展内核高半区直映射。 */
int init_phy_mem_map(void);

void set_bit(Bitmap* bitmap, uint64_t index, uint8_t value);
uint8_t get_bit(Bitmap* bitmap, uint64_t index);

paddr_t alloc_pages(uint32_t page_count);
paddr_t alloc_page(void);
paddr_t alloc_pages_owned(uint32_t page_count, page_owner_t owner);
paddr_t alloc_page_owned(page_owner_t owner);
/* 仅供内核回归测试注入下一次 PMM 分配失败。 */
void pmm_test_inject_alloc_failure_once(void);
int free_page(paddr_t paddr);
int free_pages(paddr_t paddr, uint32_t page_count);
int free_page_owned(paddr_t paddr, page_owner_t expected_owner);
int free_pages_owned(paddr_t paddr, uint32_t page_count,
                     page_owner_t expected_owner);

/*
 * 用户页映射引用计数。引用计数只描述“用户 PTE 映射”，不替代 owner：
 * 页表、内核堆和线程对象的生命周期仍由 owner 规则管理。
 */
uint32_t pmm_page_refcount(paddr_t paddr);
int pmm_acquire_user_mapping(paddr_t paddr);
int pmm_release_user_mapping(paddr_t paddr);

/* 快照不持有内部锁；调用方可以安全地在打印或分析时使用快照。 */
void pmm_get_stats(struct pmm_stats* stats);
void pmm_dump_stats(const char* tag);

/* 创建一个复制了共享内核高半区的新 PML4，返回其物理地址。 */
paddr_t create_page_dir(void);

/* map_page 不覆盖已有映射；需要覆盖时必须显式调用 remap_page。 */
int map_page(paddr_t pml4_paddr, vaddr_t vaddr, paddr_t paddr, uint64_t flags);
int remap_page(paddr_t pml4_paddr, vaddr_t vaddr, paddr_t paddr, uint64_t flags);
uint64_t* get_user_pte(paddr_t pml4_paddr, vaddr_t vaddr);
int handle_cow_page_fault(paddr_t pml4_paddr, vaddr_t vaddr);
int unmap_user_page(paddr_t pml4_paddr, vaddr_t vaddr,
                    page_owner_t expected_owner);

// 检查一个低半区用户地址范围是否被当前用户页表以 user 权限完整映射。
int user_range_is_readable(paddr_t pml4_paddr, vaddr_t vaddr, uint64_t length);

// 检查用户地址范围是否同时具备写权限；read(2) 会向这个范围写入数据。
int user_range_is_writable(paddr_t pml4_paddr, vaddr_t vaddr, uint64_t length);

/*
 * 当前活动地址空间的用户内存复制接口。
 * 返回 0 表示成功，返回负值表示地址越界、未映射或权限不足。
 * 调用者不得在复制接口外直接解引用用户虚拟地址。
 */
int copy_from_user(void* kernel_dst, vaddr_t user_src, size_t length);
int copy_to_user(vaddr_t user_dst, const void* kernel_src, size_t length);
int copy_string_from_user(char* kernel_dst, vaddr_t user_src,
                          size_t max_length);

// 释放一个进程低半区的用户页及其四级页表；不会触碰共享的内核高半区映射。
void destroy_user_address_space(paddr_t pml4_paddr);

uint64_t get_free_page_count(void);
#endif
