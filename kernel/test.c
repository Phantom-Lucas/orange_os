// kernel/test.c

#include "test.h"
#include "debug.h"
#include "print.h"
#include "memory.h"
#include "kalloc.h"
#include "thread.h"
#include "sync.h"
#include "string.h"

static void assert_pmm_unchanged(const struct pmm_stats* before,
                                 const struct pmm_stats* after)
{
    ASSERT(before->free_pages == after->free_pages);
    ASSERT(before->allocated_pages == after->allocated_pages);
    ASSERT(before->reserved_pages == after->reserved_pages);
    for (uint32_t owner = 0; owner < PAGE_OWNER_COUNT; owner++) {
        ASSERT(before->owner_pages[owner] == after->owner_pages[owner]);
    }
}

static void assert_kalloc_unchanged(const struct kalloc_stats* before,
                                    const struct kalloc_stats* after)
{
    ASSERT(before->arenas == after->arenas);
    ASSERT(before->arena_pages == after->arena_pages);
    ASSERT(before->active_blocks == after->active_blocks);
    ASSERT(before->allocated_bytes == after->allocated_bytes);
    ASSERT(before->free_bytes == after->free_bytes);
}

// ==========================================
// A. 物理内存防泄漏测试 (PMM Test)
// ==========================================
static void test_pmm(void) {
    print_string("  [Test A] Physical Memory Manager... ");
    uint64_t start_free = get_free_page_count();
    struct pmm_stats before;
    struct pmm_stats after;
    pmm_get_stats(&before);
    
    // 1. 极限碎片化分配
    paddr_t pages[100];
    for (int i = 0; i < 100; i++) {
        pages[i] = alloc_page_owned(PAGE_OWNER_TEST);
        ASSERT(pages[i] != 0);
    }
    for (int i = 0; i < 100; i++) {
        free_page_owned(pages[i], PAGE_OWNER_TEST);
    }
    
    // 2. 大块连续内存分配
    paddr_t big_block = alloc_pages_owned(50, PAGE_OWNER_TEST);
    ASSERT(big_block != 0);
    for (int i = 0; i < 50; i++) {
        // 逐页释放
        free_page_owned(big_block + (paddr_t)i * PAGE_SIZE,
                        PAGE_OWNER_TEST);
    }
    
    uint64_t end_free = get_free_page_count();
    ASSERT(start_free == end_free); // 断言：一滴内存都没漏！
    pmm_get_stats(&after);
    assert_pmm_unchanged(&before, &after);

    /* owner 不匹配和重复释放都必须失败，且不能破坏页状态。 */
    paddr_t owned_page = alloc_page_owned(PAGE_OWNER_TEST);
    ASSERT(owned_page != 0);
    ASSERT(free_page_owned(owned_page, PAGE_OWNER_USER) != 0);
    ASSERT(free_page_owned(owned_page, PAGE_OWNER_TEST) == 0);
    ASSERT(free_page_owned(owned_page, PAGE_OWNER_TEST) != 0);

    /* 超过可管理范围的连续申请不能部分占用页，也不能改变统计。 */
    pmm_get_stats(&before);
    ASSERT(alloc_pages_owned(UINT32_MAX, PAGE_OWNER_TEST) == 0);
    pmm_get_stats(&after);
    ASSERT(after.free_pages == before.free_pages);
    ASSERT(after.allocated_pages == before.allocated_pages);
    ASSERT(after.owner_pages[PAGE_OWNER_TEST] ==
           before.owner_pages[PAGE_OWNER_TEST]);
    print_success("PASSED\n");
}

// ==========================================
// B. 堆内存碎片与边界测试 (Kmalloc Test)
// ==========================================
static void test_kmalloc(void) {
    print_string("  [Test B] Kernel Heap Allocator... ");
    struct pmm_stats pmm_baseline;
    struct kalloc_stats heap_baseline;
    pmm_get_stats(&pmm_baseline);
    kalloc_get_stats(&heap_baseline);

    char* p1 = (char*)kmalloc(17);
    ASSERT(p1 != NULL);
    strcpy(p1, "MAGIC");

    // 分配超过 2 页的内存，强迫堆管理器底层扩容 (调用 alloc_pages)
    char* p2 = (char*)kmalloc(8192);
    ASSERT(p2 != NULL);
    memset(p2, 0xAB, 8192);

    ASSERT(p1[0] == 'M' && p1[4] == 'C');
    ASSERT((uint8_t)p2[8191] == 0xAB);

    kfree(p1);
    ASSERT(kfree(p1) != 0); // double-free 必须被拒绝
    kfree(p2);

    struct kalloc_stats stats;
    kalloc_get_stats(&stats);
    ASSERT(stats.active_blocks == 0);
    ASSERT(stats.arenas == 0); // 两个空 arena 都应已归还 PMM

    /* 固定种子的随机模式：覆盖跨 arena、碎片和不同大小的释放顺序。 */
    void* slots[64] = {0};
    uint32_t seed = 0x12345678U;
    struct pmm_stats pmm_before;
    struct pmm_stats pmm_after;
    pmm_get_stats(&pmm_before);
    for (int i = 0; i < 3000; i++) {
        seed = seed * 1664525U + 1013904223U;
        uint32_t slot = (seed >> 24) & 63U;
        if (slots[slot] != NULL) {
            ASSERT(kfree(slots[slot]) == 0);
            slots[slot] = NULL;
        } else {
            seed = seed * 1664525U + 1013904223U;
            size_t size = 1 + ((seed >> 8) % 20000U);
            slots[slot] = kmalloc(size);
            ASSERT(slots[slot] != NULL);
        }
    }
    for (int i = 0; i < 64; i++) {
        if (slots[i] != NULL) ASSERT(kfree(slots[i]) == 0);
    }
    pmm_get_stats(&pmm_after);
    assert_pmm_unchanged(&pmm_baseline, &pmm_after);
    kalloc_get_stats(&stats);
    assert_kalloc_unchanged(&heap_baseline, &stats);
    print_success("PASSED\n");
}

// ==========================================
// C. 多线程并发锁竞争测试 (Concurrency Test)
// ==========================================
volatile int shared_counter = 0;
volatile int threads_done = 0;
volatile int allocator_failures = 0;
mutex_t test_mutex;

static void conc_thread(void) {
    for (int i = 0; i < 1000; i++) {
        /* 不持有 test_mutex，专门测试 PMM/Kmalloc 的并发保护。 */
        void* scratch = kmalloc(32);
        if (scratch == NULL) {
            __sync_fetch_and_add(&allocator_failures, 1);
        } else {
            memset(scratch, i, 32);
            if (kfree(scratch) != 0) {
                __sync_fetch_and_add(&allocator_failures, 1);
            }
        }

        paddr_t page = alloc_page_owned(PAGE_OWNER_TEST);
        if (page == 0 || free_page_owned(page, PAGE_OWNER_TEST) != 0) {
            __sync_fetch_and_add(&allocator_failures, 1);
        }

        mutex_acquire(&test_mutex);
        shared_counter++;
        mutex_release(&test_mutex);
    }
    
    mutex_acquire(&test_mutex);
    threads_done++;
    mutex_release(&test_mutex);
    
    thread_exit(); // 线程执行完毕，自杀
}

static void test_concurrency(void) {
    print_string("  [Test C] Thread Concurrency & Locks... ");
    struct pmm_stats before;
    struct pmm_stats after;
    struct kalloc_stats heap_before;
    struct kalloc_stats heap_after;
    struct thread* workers[3];

    shared_counter = 0;
    threads_done = 0;
    allocator_failures = 0;
    pmm_get_stats(&before);
    kalloc_get_stats(&heap_before);
    mutex_init(&test_mutex);
    
    // 创建 3 个并发线程
    for (int i = 0; i < 3; i++) {
        workers[i] = thread_create(conc_thread, 5);
        ASSERT(workers[i] != NULL);
        thread_append(workers[i]);
    }

    // 主线程死等它们干完活
    while (threads_done < 3) {
        thread_yield(); 
    }

    // 断言：如果没有互斥锁，抢占式时钟中断绝对会导致数字小于 3000！
    ASSERT(shared_counter == 3000); 
    ASSERT(allocator_failures == 0);

    for (int i = 0; i < 3; i++) {
        ASSERT(thread_join(workers[i], 0) == 0);
    }

    kalloc_get_stats(&heap_after);
    assert_kalloc_unchanged(&heap_before, &heap_after);
    pmm_get_stats(&after);
    assert_pmm_unchanged(&before, &after);
    ASSERT(preempt_disable_count == 0);
    print_success("PASSED\n");
}

static void lifecycle_quick_exit(void)
{
    thread_exit();
}

static void test_process_lifecycle(void)
{
    struct pmm_stats before;
    struct pmm_stats after;
    struct thread* child;
    struct thread* first;
    struct thread* second;

    print_string("  [Test E] Thread/Process Ownership & Reaping... ");
    pmm_get_stats(&before);

    ASSERT(current_thread != NULL);
    ASSERT(current_thread->process == kernel_process);
    ASSERT(kernel_process != NULL && kernel_process->main_thread == current_thread);
    ASSERT(kernel_process->thread_count >= 1);

    /* 创建一个未入调度环的用户进程，验证进程资源和线程资源已分离。 */
    struct process* probe = process_create(0, 5);
    ASSERT(probe != NULL && probe != kernel_process);
    ASSERT(probe->main_thread != NULL);
    ASSERT(probe->main_thread->process == probe);
    ASSERT(process_is_single_threaded(probe));
    ASSERT(probe->cr3_paddr != BOOT_KERNEL_PML4_PADDR);
    ASSERT(process_discard(probe) == 0);

    /* 内核线程只由 thread_join 回收，不再伪装成用户进程子进程。 */
    child = thread_create(lifecycle_quick_exit, 5);
    ASSERT(child != NULL);
    thread_append(child);
    ASSERT(thread_join(child, 0) == 0);

    /* 线程先退出，之后 join 仍然必须安全回收 zombie 线程。 */
    child = thread_create(lifecycle_quick_exit, 5);
    ASSERT(child != NULL);
    thread_append(child);
    for (uint32_t spins = 0;
         spins < 10000 && child->status != TASK_ZOMBIE;
         spins++) {
        thread_yield();
    }
    ASSERT(child->status == TASK_ZOMBIE);
    ASSERT(thread_join(child, 0) == 0);

    /* 多个内核线程分别 join，验证一个进程内线程对象独立回收。 */
    first = thread_create(lifecycle_quick_exit, 5);
    second = thread_create(lifecycle_quick_exit, 5);
    ASSERT(first != NULL && second != NULL);
    thread_append(first);
    thread_append(second);
    ASSERT(thread_join(second, 0) == 0);
    ASSERT(thread_join(first, 0) == 0);

    pmm_get_stats(&after);
    assert_pmm_unchanged(&before, &after);
    print_success("PASSED\n");
}

// ==========================================
// D. 虚拟页表覆盖重映射测试 (VMM Test)
// ==========================================
static void test_vmm(void) {
    print_string("  [Test D] Virtual Memory Mapping... ");
    struct pmm_stats before;
    struct pmm_stats after;
    pmm_get_stats(&before);
    paddr_t test_cr3 = create_page_dir();
    
    paddr_t phys_A = alloc_page_owned(PAGE_OWNER_USER);
    paddr_t phys_B = alloc_page_owned(PAGE_OWNER_USER);
    
    // 利用高半区后门直接给物理页写入标志数据
    *(volatile uint64_t*)P2V(phys_A) = 0xAAAAAAAAAAAAAAAA;
    *(volatile uint64_t*)P2V(phys_B) = 0xBBBBBBBBBBBBBBBB;

    uint64_t target_vaddr = 0x50000000;
    
    // 将地址映射给 A
    if(map_page(test_cr3, target_vaddr, phys_A, 0x07)!=0){
        free_page_owned(phys_A, PAGE_OWNER_USER);
        free_page_owned(phys_B, PAGE_OWNER_USER);
        print_error("map page wrong");
        return;
    }
    // 覆盖映射必须显式调用 remap_page，避免 map_page 语义含糊。
    if(remap_page(test_cr3, target_vaddr, phys_B, 0x07)!=0){
        free_page_owned(phys_B, PAGE_OWNER_USER);
        print_error("map page wrong");
        return;
    }

    /* 构造一个真正共享的 COW 页，强制下一次 PMM 分配失败；失败时
       PTE、COW 标志和共享引用数必须完全保持不变。 */
    paddr_t shared = alloc_page_owned(PAGE_OWNER_USER);
    ASSERT(shared != 0);
    ASSERT(map_page(test_cr3, target_vaddr + 2 * PAGE_SIZE, shared,
                    PTE_RW | PTE_US) == 0);
    ASSERT(map_page(test_cr3, target_vaddr + 3 * PAGE_SIZE, shared,
                    PTE_RW | PTE_US) == 0);
    uint64_t* cow_pte = get_user_pte(test_cr3,
                                     target_vaddr + 2 * PAGE_SIZE);
    ASSERT(cow_pte != NULL && (*cow_pte & PTE_RW) != 0);
    *cow_pte = (*cow_pte & ~PTE_RW) | PTE_COW;
    uint64_t cow_before = *cow_pte;
    uint32_t refs_before = pmm_page_refcount(shared);
    ASSERT(refs_before == 2);
    pmm_test_inject_alloc_failure_once();
    ASSERT(handle_cow_page_fault(test_cr3,
                                 target_vaddr + 2 * PAGE_SIZE) != 0);
    ASSERT(*cow_pte == cow_before);
    ASSERT(pmm_page_refcount(shared) == refs_before);

    // 切入测试页表
    uint64_t old_cr3;
    __asm__ volatile("mov %%cr3, %0" : "=r"(old_cr3));
    __asm__ volatile("mov %0, %%cr3" :: "r"(test_cr3) : "memory");

    // 读取虚拟地址数据
    uint64_t val = *(volatile uint64_t*)target_vaddr;

    // 撤回内核页表
    __asm__ volatile("mov %0, %%cr3" :: "r"(old_cr3) : "memory");

    // 断言：地址覆盖生效，读出的必须是 B 的数据
    ASSERT(val == 0xBBBBBBBBBBBBBBBB);

    /* remap 已经解除 A 的映射并递减其引用；此处不能再次释放 A。 */
    /* phys_B 仍由 test_cr3 的映射拥有，由销毁地址空间时统一释放。 */
    destroy_user_address_space(test_cr3);
    pmm_get_stats(&after);
    assert_pmm_unchanged(&before, &after);
    print_success("PASSED\n");
}

// 执行全家桶
void run_all_kernel_tests(void) {
    print_info("[SYSTEM] Running Automated Kernel Tests...\n");
    test_pmm();
    test_kmalloc();
    test_vmm();
    /* 多轮创建/退出线程，验证线程栈页和堆页每轮都回到基线。 */
    for (int round = 0; round < 4; round++) {
        test_concurrency();
    }
    test_process_lifecycle();
    pmm_dump_stats("after-kernel-tests");
    kalloc_dump_stats("after-kernel-tests");
    print_success("[SYSTEM] ALL TESTS PASSED! Kernel is solid as a rock.\n\n");
}
