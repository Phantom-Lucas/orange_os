// kernel/memory.c

#include "memory.h"
#include "string.h"
#include "sync.h"
#include "print.h"
#include "thread.h"
#include <stddef.h>

// 全局位图实例，用于管理物理内存
Bitmap phy_mem_map;

static uint64_t managed_end_paddr;
static spinlock_t pmm_lock;
static int pmm_ready;
static uint32_t pmm_fail_allocations;

/* PMM 的 owner 字节只能反映最后一次记账；调度器中的线程对象和内核栈
 * 还必须有一个实时别名检查，防止错误回滚把仍在运行的线程页清零。 */
static int live_thread_owns_page(paddr_t paddr)
{
    struct thread* thread;
    if (current_thread == 0) return 0;
    thread = current_thread;
    do {
        if (thread->object_paddr == paddr ||
            (thread->stack_base != 0 && V2P(thread->stack_base) == paddr)) {
            return 1;
        }
        thread = thread->next;
    } while (thread != 0 && thread != current_thread);
    return 0;
}

static void reserve_physical_range(uint64_t start, uint64_t end)
{
    uint64_t first_page;
    uint64_t last_page;

    if (start >= end || start >= managed_end_paddr) {
        return;
    }

    if (end > managed_end_paddr) {
        end = managed_end_paddr;
    }

    first_page = start / PAGE_SIZE;
    last_page = (end + PAGE_SIZE - 1) / PAGE_SIZE;

    for (uint64_t page = first_page; page < last_page; page++) {
        set_bit(&phy_mem_map, page, 1);
        if (phy_mem_map.owners != NULL) {
            phy_mem_map.owners[page] = PAGE_OWNER_RESERVED;
        }
        if (phy_mem_map.reserved_bits != NULL) {
            uint64_t byte_index = page / 8;
            uint8_t bit_index = page % 8;
            phy_mem_map.reserved_bits[byte_index] |=
                (uint8_t)(1U << bit_index);
        }
    }
}

/*
 * 用当前 loader 页表作为起点，扩展 PAGE_OFFSET 下的物理内存直映射。
 * loader 只准备了 0~1GiB；这里按 E820 最高地址补齐更多 PDPT/PD。
 * 页表页本身从低地址可访问的物理页中分配，因此扩展过程中不会
 * 依赖尚未建立的高地址映射。
 */
static int build_kernel_direct_map(uint64_t max_phys_addr)
{
    uint64_t* pml4 = (uint64_t*)P2V(BOOT_KERNEL_PML4_PADDR);
    uint64_t mapped_end = (max_phys_addr + (1ULL << 21) - 1) &
                          ~((1ULL << 21) - 1);
    uint64_t max_pml4_index = PML4_INDEX(PAGE_OFFSET + mapped_end - 1);

    if (max_phys_addr == 0 || max_phys_addr > DIRECT_MAP_MAX_PHYS ||
        max_pml4_index >= 512) {
        return -1;
    }

    for (uint64_t pml4_index = PML4_INDEX(PAGE_OFFSET);
         pml4_index <= max_pml4_index;
         pml4_index++) {
        uint64_t* pdpt;

        if (!(pml4[pml4_index] & PTE_P)) {
            paddr_t pdpt_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);
            if (pdpt_paddr == 0) {
                return -1;
            }

            memset(P2V(pdpt_paddr), 0, PAGE_SIZE);
            pml4[pml4_index] = pdpt_paddr | PTE_P | PTE_RW;
        }

        pdpt = (uint64_t*)P2V(pml4[pml4_index] & PTE_ADDR_MASK);

        for (uint64_t pdpt_index = 0; pdpt_index < 512; pdpt_index++) {
            uint64_t phys_base =
                ((pml4_index - PML4_INDEX(PAGE_OFFSET)) * 512ULL +
                 pdpt_index) * (1ULL << 30);

            if (phys_base >= mapped_end) {
                break;
            }

            /* loader 已经建立的第一块 2MiB 页表可以直接复用。 */
            if (!(pdpt[pdpt_index] & PTE_P)) {
                paddr_t pd_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);
                if (pd_paddr == 0) {
                    return -1;
                }

                memset(P2V(pd_paddr), 0, PAGE_SIZE);
                pdpt[pdpt_index] = pd_paddr | PTE_P | PTE_RW;
            }

            uint64_t* pd = (uint64_t*)P2V(pdpt[pdpt_index] & PTE_ADDR_MASK);
            for (uint64_t pd_index = 0; pd_index < 512; pd_index++) {
                uint64_t page_phys = phys_base + pd_index * (1ULL << 21);
                if (page_phys >= mapped_end) {
                    break;
                }

                if (!(pd[pd_index] & PTE_P)) {
                    pd[pd_index] = page_phys | PTE_P | PTE_RW | PTE_PS;
                }
            }
        }
    }

    /* 新增映射后刷新当前地址空间的 TLB。 */
    __asm__ volatile("mov %%cr3, %%rax\n\t"
                     "mov %%rax, %%cr3\n\t"
                     ::: "rax", "memory");
    return 0;
}

// 初始化物理页状态并建立完整的内核高半区直映射。
int init_phy_mem_map(void)
{
    uint32_t ards_count = *((uint32_t*)P2V(0x500));
    struct ARDS* ards_array = (struct ARDS*)P2V(0x504);

    uint64_t max_phy_addr = 0; // 用来记录内存的最高天花板

    spinlock_init(&pmm_lock);
    pmm_ready = 0;
    pmm_fail_allocations = 0;
    
    // 遍历获取最高地址
    for (uint32_t i = 0; i < ards_count; i++) {
        // 只要是可用内存，我们就看看它是不是伸得最远的
        if (ards_array[i].type == 1 &&
            ards_array[i].length <= UINT64_MAX - ards_array[i].base_addr) {
            uint64_t current_end = ards_array[i].base_addr +
                                   ards_array[i].length;
            if (current_end > max_phy_addr) {
                max_phy_addr = current_end;
            }
        }
    }

    if (max_phy_addr == 0 || max_phy_addr > DIRECT_MAP_MAX_PHYS) {
        return -1;
    }

    managed_end_paddr = (max_phy_addr + PAGE_SIZE - 1) &
                        ~(PAGE_SIZE - 1);
    phy_mem_map.page_count = managed_end_paddr / PAGE_SIZE;
    phy_mem_map.bmap_bytes = (phy_mem_map.page_count + 7) / 8;
    phy_mem_map.bits = (uint8_t*)P2V(MEMORY_BITMAP_PADDR);
    phy_mem_map.reserved_bits =
        (uint8_t*)P2V(MEMORY_BITMAP_PADDR + phy_mem_map.bmap_bytes);
    phy_mem_map.owners =
        (uint8_t*)P2V(MEMORY_BITMAP_PADDR + 2 * phy_mem_map.bmap_bytes);
    phy_mem_map.refcounts =
        (uint32_t*)P2V(MEMORY_BITMAP_PADDR + 2 * phy_mem_map.bmap_bytes +
                       phy_mem_map.page_count);

    uint64_t metadata_bytes = 2 * phy_mem_map.bmap_bytes +
                              phy_mem_map.page_count +
                              phy_mem_map.page_count * sizeof(uint32_t);
    if (MEMORY_BITMAP_PADDR > managed_end_paddr ||
        metadata_bytes > managed_end_paddr - MEMORY_BITMAP_PADDR) {
        return -1;
    }

    /* allocated=0 表示可分配候选，reserved=1 表示永远不能分配。 */
    memset(phy_mem_map.bits, 0, phy_mem_map.bmap_bytes);
    memset(phy_mem_map.reserved_bits, 0xFF, phy_mem_map.bmap_bytes);
    /* owner 是每页一个字节，长度必须是 page_count，而不是 bmap_bytes。 */
    memset(phy_mem_map.owners, PAGE_OWNER_RESERVED, phy_mem_map.page_count);
    memset(phy_mem_map.refcounts, 0,
           phy_mem_map.page_count * sizeof(uint32_t));

    /* 第一遍释放 E820 的可用区。 */
    for (uint32_t i = 0; i < ards_count; i++)
    {
        struct ARDS* entry = &ards_array[i];

        if (entry->type != 1) {
            continue;
        }

        if (entry->length > UINT64_MAX - entry->base_addr) {
            continue;
        }

        uint64_t start_addr = entry->base_addr;
        uint64_t end_addr = entry->base_addr + entry->length;

        uint64_t start_page =
            (start_addr + 4095ULL) / 4096ULL;

        uint64_t end_page =
            end_addr / 4096ULL;

        for (uint64_t page = start_page;
            page < end_page;
            page++)
        {
            if (page < phy_mem_map.page_count) {
                uint64_t byte_index = page / 8;
                uint8_t bit_index = page % 8;
                phy_mem_map.reserved_bits[byte_index] &=
                    (uint8_t)~(1U << bit_index);
                phy_mem_map.owners[page] = PAGE_OWNER_FREE;
            }
        }
    }

    /* 第二遍重新保留所有非可用 E820 区域，避免重叠记录误放行。 */
    for (uint32_t i = 0; i < ards_count; i++) {
        struct ARDS* entry = &ards_array[i];
        if (entry->type == 1 ||
            entry->length > UINT64_MAX - entry->base_addr) {
            continue;
        }
        reserve_physical_range(entry->base_addr,
                               entry->base_addr + entry->length);
    }

    /* 启动阶段结构和位图不能被 PMM 重新分配。 */
    reserve_physical_range(0, BOOT_RESERVED_END);
    reserve_physical_range(MEMORY_BITMAP_PADDR,
                           MEMORY_BITMAP_PADDR + metadata_bytes);

    /* 直映射扩展需要从 PMM 申请新的页表页。 */
    pmm_ready = 1;

    if (build_kernel_direct_map(managed_end_paddr) != 0) {
        pmm_ready = 0;
        return -1;
    }

    return 0;
}

// 设置位图中某一位的值
void set_bit(Bitmap* bitmap, uint64_t index, uint8_t value)
{
    if (bitmap == NULL || bitmap->bits == NULL) {
        return;
    }

    if (index >= bitmap->page_count) {
        return;
    }

    uint64_t byte_index = index / 8ULL;
    uint8_t bit_index = index % 8ULL;
    uint8_t mask = (uint8_t)(1U << bit_index);

    if (value) {
        bitmap->bits[byte_index] |= mask;
    } else {
        bitmap->bits[byte_index] &= (uint8_t)~mask;
    }
}

// 获取位图中某一位的值
uint8_t get_bit(Bitmap* bitmap, uint64_t index)
{
    if (bitmap == NULL || bitmap->bits == NULL) {
        return 1;
    }

    if (index >= bitmap->page_count) {
        return 1;
    }

    uint64_t byte_index = index / 8ULL;
    uint8_t bit_index = index % 8ULL;

    return (bitmap->bits[byte_index] >> bit_index) & 1U;
}

static int valid_alloc_owner(page_owner_t owner)
{
    return owner > PAGE_OWNER_FREE && owner < PAGE_OWNER_COUNT &&
           owner != PAGE_OWNER_RESERVED;
}

/* PMM 内部查找逻辑要求调用者已经持有 pmm_lock。 */
static paddr_t alloc_pages_owned_locked(uint32_t page_count,
                                        page_owner_t owner)
{
    uint64_t consecutive_free = 0;
    uint64_t start_page = 0;

    for (uint64_t i = 0; i < phy_mem_map.page_count; i++) {
        uint8_t reserved =
            (phy_mem_map.reserved_bits[i / 8] >> (i % 8)) & 1U;

        if (get_bit(&phy_mem_map, i) == 0 && !reserved) {
            if (live_thread_owns_page((paddr_t)i * PAGE_SIZE)) {
                consecutive_free = 0;
                continue;
            }
            if (consecutive_free == 0) {
                start_page = i;
            }
            consecutive_free++;

            if (consecutive_free == page_count) {
                for (uint64_t j = 0; j < page_count; j++) {
                    uint64_t page = start_page + j;
                    set_bit(&phy_mem_map, page, 1);
                    phy_mem_map.owners[page] = owner;
                    phy_mem_map.refcounts[page] = 0;
                }
                return (paddr_t)start_page * PAGE_SIZE;
            }
        } else {
            consecutive_free = 0;
        }
    }

    return 0;
}

paddr_t alloc_pages_owned(uint32_t page_count, page_owner_t owner)
{
    paddr_t result;

    if (!pmm_ready || page_count == 0 || !valid_alloc_owner(owner)) {
        return 0;
    }

    spinlock_acquire(&pmm_lock);
    if (pmm_fail_allocations != 0) {
        pmm_fail_allocations--;
        result = 0;
    } else {
        result = alloc_pages_owned_locked(page_count, owner);
    }
    spinlock_release(&pmm_lock);
    return result;
}

paddr_t alloc_page_owned(page_owner_t owner)
{
    return alloc_pages_owned(1, owner);
}

void pmm_test_inject_alloc_failure_once(void)
{
    spinlock_acquire(&pmm_lock);
    pmm_fail_allocations = 1;
    spinlock_release(&pmm_lock);
}

paddr_t alloc_pages(uint32_t page_count)
{
    return alloc_pages_owned(page_count, PAGE_OWNER_GENERIC);
}

paddr_t alloc_page(void)
{
    return alloc_page_owned(PAGE_OWNER_GENERIC);
}

int free_pages_owned(paddr_t paddr, uint32_t page_count,
                     page_owner_t expected_owner)
{
    uint64_t start_page;

    if (!pmm_ready || paddr == 0 || page_count == 0 ||
        (paddr & (PAGE_SIZE - 1)) != 0) {
        return -1;
    }

    start_page = paddr / PAGE_SIZE;
    spinlock_acquire(&pmm_lock);

    if (start_page >= phy_mem_map.page_count ||
        page_count > phy_mem_map.page_count - start_page) {
        spinlock_release(&pmm_lock);
        return -1;
    }

    for (uint64_t i = 0; i < page_count; i++) {
        uint64_t page = start_page + i;
        if (live_thread_owns_page((paddr_t)page * PAGE_SIZE)) {
            spinlock_release(&pmm_lock);
            return -1;
        }
        uint8_t reserved =
            (phy_mem_map.reserved_bits[page / 8] >> (page % 8)) & 1U;

        if (get_bit(&phy_mem_map, page) == 0 || reserved ||
            phy_mem_map.refcounts[page] != 0 ||
            (expected_owner != PAGE_OWNER_ANY &&
             phy_mem_map.owners[page] != expected_owner)) {
            spinlock_release(&pmm_lock);
            return -1;
        }
    }

    for (uint64_t i = 0; i < page_count; i++) {
        uint64_t page = start_page + i;
        memset(P2V(paddr + i * PAGE_SIZE), 0, PAGE_SIZE);
        set_bit(&phy_mem_map, page, 0);
        phy_mem_map.owners[page] = PAGE_OWNER_FREE;
        phy_mem_map.refcounts[page] = 0;
    }

    spinlock_release(&pmm_lock);
    return 0;
}

int free_page_owned(paddr_t paddr, page_owner_t expected_owner)
{
    return free_pages_owned(paddr, 1, expected_owner);
}

int free_pages(paddr_t paddr, uint32_t page_count)
{
    return free_pages_owned(paddr, page_count, PAGE_OWNER_ANY);
}

int free_page(paddr_t paddr)
{
    return free_page_owned(paddr, PAGE_OWNER_ANY);
}

uint32_t pmm_page_refcount(paddr_t paddr)
{
    uint64_t page;
    uint32_t result = 0;

    if (!pmm_ready || (paddr & (PAGE_SIZE - 1)) != 0) return 0;
    page = paddr / PAGE_SIZE;
    spinlock_acquire(&pmm_lock);
    if (page < phy_mem_map.page_count && get_bit(&phy_mem_map, page) != 0) {
        result = phy_mem_map.refcounts[page];
    }
    spinlock_release(&pmm_lock);
    return result;
}

int pmm_acquire_user_mapping(paddr_t paddr)
{
    uint64_t page;
    int result = -1;

    if (!pmm_ready || paddr == 0 || (paddr & (PAGE_SIZE - 1)) != 0) {
        return -1;
    }
    page = paddr / PAGE_SIZE;
    spinlock_acquire(&pmm_lock);
    if (page < phy_mem_map.page_count &&
        get_bit(&phy_mem_map, page) != 0 &&
        phy_mem_map.owners[page] == PAGE_OWNER_USER &&
        phy_mem_map.refcounts[page] != UINT32_MAX) {
        phy_mem_map.refcounts[page]++;
        result = 0;
    }
    spinlock_release(&pmm_lock);
    return result;
}

int pmm_release_user_mapping(paddr_t paddr)
{
    uint64_t page;
    int result = -1;

    if (!pmm_ready || paddr == 0 || (paddr & (PAGE_SIZE - 1)) != 0) {
        return -1;
    }
    page = paddr / PAGE_SIZE;
    spinlock_acquire(&pmm_lock);
    if (page < phy_mem_map.page_count &&
        get_bit(&phy_mem_map, page) != 0 &&
        phy_mem_map.owners[page] == PAGE_OWNER_USER &&
        phy_mem_map.refcounts[page] != 0) {
        phy_mem_map.refcounts[page]--;
        if (phy_mem_map.refcounts[page] == 0) {
            memset(P2V(paddr), 0, PAGE_SIZE);
            set_bit(&phy_mem_map, page, 0);
            phy_mem_map.owners[page] = PAGE_OWNER_FREE;
        }
        result = 0;
    }
    spinlock_release(&pmm_lock);
    return result;
}

 paddr_t create_page_dir(void) {
    /* PML4 本身属于新地址空间，失败时由调用方看到 0。 */
    paddr_t pml4_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);
    if (!pml4_paddr) return 0;
    
    // 2. 转换为高半区虚拟地址以便 C 语言操作
    uint64_t* new_pml4_vaddr = (uint64_t*)P2V(pml4_paddr);
    
    // 3. 彻底清零！这等同于【清空了新进程的低半区映射】
    memset(new_pml4_vaddr, 0, PAGE_SIZE);
    
    // 4. 复制内核的高半区映射
    // 我们在 loader.S 中把内核初始 PML4 建立在了物理地址 0x70000 处
    uint64_t* kernel_pml4_vaddr =
        (uint64_t*)P2V(BOOT_KERNEL_PML4_PADDR);
    
    // PML4 有 512 个项，0~255 是低半区，256~511 是高半区
    // 我们只把 256 到 511 项（内核空间）复制过来，保证内核在新页表下不死机
    for (int i = 256; i < 512; i++) {
        new_pml4_vaddr[i] = kernel_pml4_vaddr[i];
    }
    
    // 5. CR3 寄存器只认物理地址，所以返回物理地址
    return pml4_paddr;
}


// 终极页表映射函数：将物理地址 paddr 挂载到指定的 cr3(pml4_paddr) 的虚拟地址 vaddr 处
int map_page(paddr_t pml4_paddr, vaddr_t vaddr, paddr_t paddr, uint64_t flags)
{
    if (pml4_paddr == 0) {
        return -1;
    }

    if ((vaddr & 0xFFFULL) != 0 ||
        (paddr & 0xFFFULL) != 0) {
        return -1;
    }

    uint64_t table_flags = PTE_P | PTE_RW;

    if (flags & PTE_US) {
        table_flags |= PTE_US;
    }

    uint64_t* pml4 = (uint64_t*)P2V(pml4_paddr);
    uint32_t pml4_idx = PML4_INDEX(vaddr);
    paddr_t new_pdpt_paddr = 0;
    paddr_t new_pd_paddr = 0;
    paddr_t new_pt_paddr = 0;
    int created_pdpt = 0;
    int created_pd = 0;
    int created_pt = 0;

    /*
     * 创建 PDPT。
     */
    if (!(pml4[pml4_idx] & PTE_P)) {
        new_pdpt_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);

        if (new_pdpt_paddr == 0) {
            return -1;
        }

        created_pdpt = 1;

        memset(P2V(new_pdpt_paddr), 0, 4096);

        pml4[pml4_idx] =
            (uint64_t)new_pdpt_paddr | table_flags;
    } else if (flags & PTE_US) {

        pml4[pml4_idx] |= PTE_US;
    }

    uint64_t pdpt_paddr =
        pml4[pml4_idx] & PTE_ADDR_MASK;

    uint64_t* pdpt =
        (uint64_t*)P2V(pdpt_paddr);

    uint32_t pdpt_idx = PDPT_INDEX(vaddr);

    if (!(pdpt[pdpt_idx] & PTE_P)) {
        new_pd_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);

        if (new_pd_paddr == 0) {
            if (created_pdpt) {
                pml4[pml4_idx] = 0;
                free_page_owned(new_pdpt_paddr, PAGE_OWNER_PAGE_TABLE);
            }
            return -1;
        }

        created_pd = 1;

        memset(P2V(new_pd_paddr), 0, 4096);

        pdpt[pdpt_idx] =
            (uint64_t)new_pd_paddr | table_flags;
    } else if (flags & PTE_US) {
        pdpt[pdpt_idx] |= PTE_US;
    }

    uint64_t pd_paddr =
        pdpt[pdpt_idx] & PTE_ADDR_MASK;

    uint64_t* pd =
        (uint64_t*)P2V(pd_paddr);

    uint32_t pd_idx = PD_INDEX(vaddr);

    if (!(pd[pd_idx] & PTE_P)) {
        new_pt_paddr = alloc_page_owned(PAGE_OWNER_PAGE_TABLE);

        if (new_pt_paddr == 0) {
            if (created_pd) {
                pdpt[pdpt_idx] = 0;
                free_page_owned(new_pd_paddr, PAGE_OWNER_PAGE_TABLE);
            }
            if (created_pdpt) {
                pml4[pml4_idx] = 0;
                free_page_owned(new_pdpt_paddr, PAGE_OWNER_PAGE_TABLE);
            }
            return -1;
        }

        memset(P2V(new_pt_paddr), 0, 4096);
        created_pt = 1;

        pd[pd_idx] =
            (uint64_t)new_pt_paddr | table_flags;
    } else if (flags & PTE_US) {
        pd[pd_idx] |= PTE_US;
    }

    uint64_t pt_paddr =
        pd[pd_idx] & PTE_ADDR_MASK;

    uint64_t* pt =
        (uint64_t*)P2V(pt_paddr);

    uint32_t pt_idx = PT_INDEX(vaddr);

    if (pt[pt_idx] & PTE_P) {
        return -2;
    }

    pt[pt_idx] =
        (paddr & PTE_ADDR_MASK)
        | flags
        | PTE_P;

    /* 用户 PTE 必须指向 USER 页；映射成功后才拥有一个引用。 */
    if ((flags & PTE_US) && pmm_acquire_user_mapping(paddr) != 0) {
        pt[pt_idx] = 0;
        if (created_pt) {
            pd[pd_idx] = 0;
            free_page_owned(new_pt_paddr, PAGE_OWNER_PAGE_TABLE);
        }
        if (created_pd) {
            pdpt[pdpt_idx] = 0;
            free_page_owned(new_pd_paddr, PAGE_OWNER_PAGE_TABLE);
        }
        if (created_pdpt) {
            pml4[pml4_idx] = 0;
            free_page_owned(new_pdpt_paddr, PAGE_OWNER_PAGE_TABLE);
        }
        return -1;
    }

    return 0;
}

/* 查找已有的普通 4KiB PTE，不创建任何页表页。 */
uint64_t* get_user_pte(paddr_t pml4_paddr, vaddr_t vaddr)
{
    uint64_t* pml4;
    uint64_t pml4e;
    uint64_t* pdpt;
    uint64_t pdpte;
    uint64_t* pd;
    uint64_t pde;

    if (pml4_paddr == 0 || (vaddr & (PAGE_SIZE - 1)) != 0) {
        return NULL;
    }

    pml4 = (uint64_t*)P2V(pml4_paddr);
    pml4e = pml4[PML4_INDEX(vaddr)];
    if (!(pml4e & PTE_P)) return NULL;

    pdpt = (uint64_t*)P2V(pml4e & PTE_ADDR_MASK);
    pdpte = pdpt[PDPT_INDEX(vaddr)];
    if (!(pdpte & PTE_P) || (pdpte & PTE_PS)) return NULL;

    pd = (uint64_t*)P2V(pdpte & PTE_ADDR_MASK);
    pde = pd[PD_INDEX(vaddr)];
    if (!(pde & PTE_P) || (pde & PTE_PS)) return NULL;

    return &((uint64_t*)P2V(pde & PTE_ADDR_MASK))[PT_INDEX(vaddr)];
}

/* 显式覆盖已有 4KiB 映射；旧物理页由调用方负责释放。 */
int remap_page(paddr_t pml4_paddr, vaddr_t vaddr,
               paddr_t paddr, uint64_t flags)
{
    uint64_t* pte;

    if (paddr == 0 || (paddr & (PAGE_SIZE - 1)) != 0) {
        return -1;
    }

    pte = get_user_pte(pml4_paddr, vaddr);
    if (pte == NULL || !(*pte & PTE_P)) {
        return -1;
    }

    paddr_t old_page = *pte & PTE_ADDR_MASK;
    int old_user = (*pte & PTE_US) != 0;
    int new_user = (flags & PTE_US) != 0;

    if (old_page == paddr) {
        *pte = (paddr & PTE_ADDR_MASK) | flags | PTE_P;
    } else {
        if (new_user && pmm_acquire_user_mapping(paddr) != 0) return -1;
        *pte = (paddr & PTE_ADDR_MASK) | flags | PTE_P;
        if (old_user) (void)pmm_release_user_mapping(old_page);
    }
    __asm__ volatile("invlpg (%0)" :: "r"((void*)vaddr) : "memory");
    return 0;
}

/*
 * 删除一个已经存在的用户页映射，并按 owner 释放对应物理页。
 * 线程退出只会调用它释放自己的用户栈；进程最终销毁仍由
 * destroy_user_address_space 统一回收其余用户页和页表页。
 */
int unmap_user_page(paddr_t pml4_paddr, vaddr_t vaddr,
                    page_owner_t expected_owner)
{
    uint64_t* pte;
    uint64_t* pml4;
    uint64_t* pdpt;
    uint64_t* pd;
    uint64_t* pt;
    uint64_t* pml4e;
    uint64_t* pdpte;
    uint64_t* pde;
    paddr_t page;

    if ((vaddr & (PAGE_SIZE - 1)) != 0) return -1;
    pte = get_user_pte(pml4_paddr, vaddr);
    if (pte == NULL || !(*pte & PTE_P) || !(*pte & PTE_US)) return -1;
    page = *pte & PTE_ADDR_MASK;
    *pte = 0;
    __asm__ volatile("invlpg (%0)" :: "r"((void*)vaddr) : "memory");
    if (expected_owner == PAGE_OWNER_USER) {
        if (pmm_release_user_mapping(page) != 0) return -1;
    } else if (free_page_owned(page, expected_owner) != 0) {
        return -1;
    }

    /* 删除空的 PT/PD/PDPT，保证 mmap 回滚不会遗留页表页。 */
    pml4 = (uint64_t*)P2V(pml4_paddr);
    pml4e = &pml4[PML4_INDEX(vaddr)];
    pdpt = (uint64_t*)P2V(*pml4e & PTE_ADDR_MASK);
    pdpte = &pdpt[PDPT_INDEX(vaddr)];
    pd = (uint64_t*)P2V(*pdpte & PTE_ADDR_MASK);
    pde = &pd[PD_INDEX(vaddr)];
    pt = (uint64_t*)P2V(*pde & PTE_ADDR_MASK);
    int empty = 1;
    for (uint32_t i = 0; i < 512; i++) {
        if (pt[i] & PTE_P) { empty = 0; break; }
    }
    if (empty) {
        paddr_t pt_page = *pde & PTE_ADDR_MASK;
        *pde = 0;
        (void)free_page_owned(pt_page, PAGE_OWNER_PAGE_TABLE);
        empty = 1;
        for (uint32_t i = 0; i < 512; i++) {
            if (pd[i] & PTE_P) { empty = 0; break; }
        }
        if (empty) {
            paddr_t pd_page = *pdpte & PTE_ADDR_MASK;
            *pdpte = 0;
            (void)free_page_owned(pd_page, PAGE_OWNER_PAGE_TABLE);
            empty = 1;
            for (uint32_t i = 0; i < 512; i++) {
                if (pdpt[i] & PTE_P) { empty = 0; break; }
            }
            if (empty) {
                paddr_t pdpt_page = *pml4e & PTE_ADDR_MASK;
                *pml4e = 0;
                (void)free_page_owned(pdpt_page, PAGE_OWNER_PAGE_TABLE);
            }
        }
    }
    return 0;
}

/*
 * 处理一个已经存在的 COW 用户页写故障。调用者负责确认 fault 来自用户态
 * 写访问；这里在地址空间锁保护下重新检查 PTE，避免把普通只读页误升级。
 */
int handle_cow_page_fault(paddr_t pml4_paddr, vaddr_t vaddr)
{
    uint64_t* pte;
    uint64_t entry;
    paddr_t old_page;
    paddr_t new_page;
    uint32_t refs;

    vaddr &= PTE_ADDR_MASK;
    pte = get_user_pte(pml4_paddr, vaddr);
    if (pte == NULL || ((*pte & (PTE_P | PTE_US | PTE_COW)) !=
                        (PTE_P | PTE_US | PTE_COW))) return -1;

    entry = *pte;
    old_page = entry & PTE_ADDR_MASK;
    refs = pmm_page_refcount(old_page);
    if (refs == 0) return -1;

    if (refs == 1) {
        *pte = entry | PTE_RW;
        *pte &= ~PTE_COW;
        __asm__ volatile("invlpg (%0)" :: "r"((void*)vaddr) : "memory");
        return 0;
    }

    new_page = alloc_page_owned(PAGE_OWNER_USER);
    if (new_page == 0) return -1;
    memcpy(P2V(new_page), P2V(old_page), PAGE_SIZE);
    if (pmm_acquire_user_mapping(new_page) != 0) {
        free_page_owned(new_page, PAGE_OWNER_USER);
        return -1;
    }

    *pte = (new_page & PTE_ADDR_MASK) | PTE_P | PTE_US | PTE_RW;
    (void)pmm_release_user_mapping(old_page);
    __asm__ volatile("invlpg (%0)" :: "r"((void*)vaddr) : "memory");
    return 0;
}

static int user_page_has_access(paddr_t pml4_paddr,
                                vaddr_t vaddr,
                                uint64_t required)
{
    if (pml4_paddr == 0) {
        return 0;
    }

    /*
     * 不管调用者有没有传 PTE_P，
     * 都必须要求页面实际存在。
     */
    required |= PTE_P;

    uint64_t* pml4 =
        (uint64_t*)P2V(pml4_paddr);

    uint64_t pml4e =
        pml4[PML4_INDEX(vaddr)];

    if ((pml4e & required) != required) {
        return 0;
    }

    uint64_t* pdpt =
        (uint64_t*)P2V(pml4e & PTE_ADDR_MASK);

    uint64_t pdpte =
        pdpt[PDPT_INDEX(vaddr)];

    if ((pdpte & required) != required) {
        return 0;
    }

    /*
     * PDPTE 的 PS 位为 1 时，
     * 它直接映射 1GB 大页，不再指向 PD。
     *
     * 当前代码只支持普通 4KB 页，
     * 所以直接判定为不支持。
     */
    if (pdpte & PTE_PS) {
        return 0;
    }

    uint64_t* pd =
        (uint64_t*)P2V(pdpte & PTE_ADDR_MASK);

    uint64_t pde =
        pd[PD_INDEX(vaddr)];

    if ((pde & required) != required) {
        return 0;
    }

    /*
     * PDE 的 PS 位为 1 时，
     * 它直接映射 2MB 大页，不再指向 PT。
     */
    if (pde & PTE_PS) {
        return 0;
    }

    uint64_t* pt =
        (uint64_t*)P2V(pde & PTE_ADDR_MASK);

    uint64_t pte =
        pt[PT_INDEX(vaddr)];

    return (pte & required) == required;
}

static int user_range_has_access(paddr_t pml4_paddr, vaddr_t vaddr,
                                 uint64_t length, uint64_t required) {
    const uint64_t user_top = 0x00007FFFFFFFFFFFULL;

    if (length == 0) return 1;
    if (vaddr == 0 || vaddr > user_top) return 0;
    if (length - 1 > user_top - vaddr) return 0;

    uint64_t page = vaddr & PTE_ADDR_MASK;
    uint64_t last_page = (vaddr + length - 1) & PTE_ADDR_MASK;
    while (1) {
        if (!user_page_has_access(pml4_paddr, page, required)) return 0;
        if (page == last_page) return 1;
        page += 4096;
    }
}

int user_range_is_readable(paddr_t pml4_paddr, vaddr_t vaddr, uint64_t length) {
    return user_range_has_access(pml4_paddr, vaddr, length, PTE_P | PTE_US);
}

static int user_range_has_write_access(paddr_t pml4_paddr,
                                       vaddr_t vaddr, uint64_t length)
{
    const uint64_t user_top = 0x00007FFFFFFFFFFFULL;
    uint64_t page;
    uint64_t last_page;

    if (length == 0) return 1;
    if (vaddr == 0 || vaddr > user_top ||
        length - 1 > user_top - vaddr) return 0;
    page = vaddr & PTE_ADDR_MASK;
    last_page = (vaddr + length - 1) & PTE_ADDR_MASK;
    while (1) {
        uint64_t* pte = get_user_pte(pml4_paddr, page);
        if (pte == NULL || (*pte & (PTE_P | PTE_US)) !=
                           (PTE_P | PTE_US) ||
            (*pte & (PTE_RW | PTE_COW)) == 0) return 0;
        if (page == last_page) return 1;
        page += PAGE_SIZE;
    }
}

int user_range_is_writable(paddr_t pml4_paddr, vaddr_t vaddr, uint64_t length) {
    /* COW 页对用户语义仍是可写页，真正写入前由 copy_to_user/COW fault
       完成私有化；只读代码页仍然不满足此检查。 */
    return user_range_has_write_access(pml4_paddr, vaddr, length);
}

static paddr_t active_cr3(void)
{
    paddr_t cr3;

    __asm__ volatile("mov %%cr3, %0" : "=r"(cr3));
    return cr3 & PTE_ADDR_MASK;
}

int copy_from_user(void* kernel_dst, vaddr_t user_src, size_t length)
{
    uint8_t* destination = (uint8_t*)kernel_dst;
    uint64_t source = user_src;
    size_t remaining = length;

    if (length == 0) return 0;
    if (kernel_dst == NULL ||
        !user_range_is_readable(active_cr3(), user_src, length)) {
        return -1;
    }

    while (remaining != 0) {
        size_t page_offset = (size_t)(source & (PAGE_SIZE - 1));
        size_t chunk = PAGE_SIZE - page_offset;
        if (chunk > remaining) chunk = remaining;
        memcpy(destination, (const void*)source, chunk);
        destination += chunk;
        source += chunk;
        remaining -= chunk;
    }
    return 0;
}

int copy_to_user(vaddr_t user_dst, const void* kernel_src, size_t length)
{
    const uint8_t* source = (const uint8_t*)kernel_src;
    uint64_t destination = user_dst;
    size_t remaining = length;

    if (length == 0) return 0;
    if (kernel_src == NULL ||
        !user_range_is_writable(active_cr3(), user_dst, length)) {
        return -1;
    }

    /* 先验证整个范围，再逐页私有化，避免跨页非法地址造成半次写入。 */
    uint64_t page = user_dst & PTE_ADDR_MASK;
    uint64_t last_page = (user_dst + length - 1) & PTE_ADDR_MASK;
    while (1) {
        uint64_t* pte = get_user_pte(active_cr3(), page);
        if (pte != NULL && (*pte & PTE_COW) != 0 &&
            handle_cow_page_fault(active_cr3(), page) != 0) return -1;
        if (page == last_page) break;
        page += PAGE_SIZE;
    }
    if (!user_range_has_access(active_cr3(), user_dst, length,
                               PTE_P | PTE_RW | PTE_US)) return -1;

    while (remaining != 0) {
        size_t page_offset = (size_t)(destination & (PAGE_SIZE - 1));
        size_t chunk = PAGE_SIZE - page_offset;
        if (chunk > remaining) chunk = remaining;
        memcpy((void*)destination, source, chunk);
        source += chunk;
        destination += chunk;
        remaining -= chunk;
    }
    return 0;
}

int copy_string_from_user(char* kernel_dst, vaddr_t user_src,
                          size_t max_length)
{
    if (kernel_dst == NULL || user_src == 0 || max_length == 0) return -1;

    for (size_t i = 0; i < max_length; i++) {
        uint8_t byte;
        if (user_src > UINT64_MAX - i ||
            copy_from_user(&byte, user_src + i, sizeof(byte)) != 0) {
            return -1;
        }
        kernel_dst[i] = (char)byte;
        if (byte == '\0') return i == 0 ? -1 : 0;
    }
    return -1;
}

void destroy_user_address_space(paddr_t pml4_paddr)
{
    /*
     * 不能释放空地址，也不能释放内核初始页表。
     */
    if (pml4_paddr == 0 ||
        pml4_paddr == BOOT_KERNEL_PML4_PADDR) {
        return;
    }

    uint64_t* pml4 =
        (uint64_t*)P2V(pml4_paddr);

    /*
     * 只遍历 PML4 的低半区：
     *
     * 0 ~ 255   用户地址空间
     * 256 ~ 511 内核地址空间
     *
     * 内核高半区由所有进程共享，不能释放。
     */
    for (uint64_t pml4_index = 0;
         pml4_index < 256;
         pml4_index++) {

        uint64_t pml4e =
            pml4[pml4_index];

        if (!(pml4e & PTE_P)) {
            continue;
        }

        uint64_t pdpt_paddr =
            pml4e & PTE_ADDR_MASK;

        uint64_t* pdpt =
            (uint64_t*)P2V(pdpt_paddr);

        for (uint64_t pdpt_index = 0;
             pdpt_index < 512;
             pdpt_index++) {

            uint64_t pdpte =
                pdpt[pdpt_index];

            if (!(pdpte & PTE_P)) {
                continue;
            }

            /*
             * PS=1 表示 1GB 大页。
             *
             * 当前内核只按 4KB 页设计，
             * 暂时不处理大页，防止把物理页
             * 错误当作 PD 页表。
             */
            if (pdpte & PTE_PS) {
                continue;
            }

            uint64_t pd_paddr =
                pdpte & PTE_ADDR_MASK;

            uint64_t* pd =
                (uint64_t*)P2V(pd_paddr);

            for (uint64_t pd_index = 0;
                 pd_index < 512;
                 pd_index++) {

                uint64_t pde =
                    pd[pd_index];

                if (!(pde & PTE_P)) {
                    continue;
                }

                /*
                 * PS=1 表示 2MB 大页。
                 *
                 * 当前暂时不处理。
                 */
                if (pde & PTE_PS) {
                    continue;
                }

                uint64_t pt_paddr =
                    pde & PTE_ADDR_MASK;

                uint64_t* pt =
                    (uint64_t*)P2V(pt_paddr);

                for (uint64_t pt_index = 0;
                     pt_index < 512;
                     pt_index++) {

                    uint64_t pte =
                        pt[pt_index];

                    /*
                     * 只释放：
                     * 1. 实际存在的页
                     * 2. 用户态可访问的页
                     */
                    if ((pte & (PTE_P | PTE_US)) ==
                        (PTE_P | PTE_US)) {

                        paddr_t page_paddr =
                            pte & PTE_ADDR_MASK;

                        (void)pmm_release_user_mapping(page_paddr);
                    }

                    /*
                     * 清除 PTE，避免留下悬空映射。
                     */
                    pt[pt_index] = 0;
                }

                /*
                 * PT 里的用户页已经处理完，
                 * 现在释放 PT 页表页本身。
                 */
                free_page_owned((paddr_t)pt_paddr, PAGE_OWNER_PAGE_TABLE);

                pd[pd_index] = 0;
            }

            /*
             * 释放 PD 页表页。
             */
            free_page_owned((paddr_t)pd_paddr, PAGE_OWNER_PAGE_TABLE);

            pdpt[pdpt_index] = 0;
        }

        /*
         * 释放 PDPT 页表页。
         */
        free_page_owned((paddr_t)pdpt_paddr, PAGE_OWNER_PAGE_TABLE);

        pml4[pml4_index] = 0;
    }

    /*
     * 最后释放 PML4 页表页本身。
     */
    free_page_owned(pml4_paddr, PAGE_OWNER_PAGE_TABLE);
}

void pmm_get_stats(struct pmm_stats* stats)
{
    if (stats == NULL) {
        return;
    }

    memset(stats, 0, sizeof(*stats));
    if (!pmm_ready) {
        return;
    }

    spinlock_acquire(&pmm_lock);
    for (uint64_t page = 0; page < phy_mem_map.page_count; page++) {
        uint8_t allocated = get_bit(&phy_mem_map, page);
        uint8_t reserved =
            (phy_mem_map.reserved_bits[page / 8] >> (page % 8)) & 1U;

        if (reserved) {
            stats->reserved_pages++;
        } else if (allocated) {
            stats->allocated_pages++;
        } else {
            stats->free_pages++;
        }

        if (phy_mem_map.owners[page] < PAGE_OWNER_COUNT) {
            stats->owner_pages[phy_mem_map.owners[page]]++;
        }
        if (phy_mem_map.owners[page] == PAGE_OWNER_USER &&
            phy_mem_map.refcounts[page] != 0) {
            stats->user_mapped_pages++;
            stats->user_mapping_refs += phy_mem_map.refcounts[page];
        }
    }
    spinlock_release(&pmm_lock);
}

static const char* page_owner_name(page_owner_t owner)
{
    static const char* names[PAGE_OWNER_COUNT] = {
        "free", "generic", "page-table", "kernel", "heap",
        "user", "thread", "process", "tty", "test", "reserved"
    };

    return owner < PAGE_OWNER_COUNT ? names[owner] : "unknown";
}

void pmm_dump_stats(const char* tag)
{
    struct pmm_stats stats;

    pmm_get_stats(&stats);
    print_info("[PMM] stats: ");
    if (tag != NULL) {
        print_string(tag);
        print_string(" ");
    }
    print_string("free=");
    print_int((long)stats.free_pages);
    print_string(" allocated=");
    print_int((long)stats.allocated_pages);
    print_string(" reserved=");
    print_int((long)stats.reserved_pages);
    print_string("\n");

    for (uint32_t owner = 0; owner < PAGE_OWNER_COUNT; owner++) {
        if (stats.owner_pages[owner] == 0) continue;
        print_string("[PMM] owner ");
        print_string(page_owner_name((page_owner_t)owner));
        print_string("=");
        print_int((long)stats.owner_pages[owner]);
        print_string(" pages\n");
    }
}

uint64_t get_free_page_count(void)
{
    struct pmm_stats stats;
    pmm_get_stats(&stats);
    return stats.free_pages;
}
