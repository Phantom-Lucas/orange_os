// kernel/test.c

#include "test.h"
#include "debug.h"
#include "print.h"
#include "memory.h"
#include "kalloc.h"
#include "thread.h"
#include "sync.h"
#include "string.h"

// ==========================================
// A. 物理内存防泄漏测试 (PMM Test)
// ==========================================
static void test_pmm(void) {
    print_string("  [Test A] Physical Memory Manager... ");
    uint32_t start_free = get_free_page_count();
    
    // 1. 极限碎片化分配
    void* pages[100];
    for (int i = 0; i < 100; i++) {
        pages[i] = alloc_page();
        ASSERT(pages[i] != NULL);
    }
    for (int i = 0; i < 100; i++) {
        free_page(pages[i]);
    }
    
    // 2. 大块连续内存分配
    void* big_block = alloc_pages(50);
    ASSERT(big_block != NULL);
    for (int i = 0; i < 50; i++) {
        // 逐页释放
        free_page((void*)((uint64_t)big_block + i * 4096)); 
    }
    
    uint32_t end_free = get_free_page_count();
    ASSERT(start_free == end_free); // 断言：一滴内存都没漏！
    print_success("PASSED\n");
}

// ==========================================
// B. 堆内存碎片与边界测试 (Kmalloc Test)
// ==========================================
static void test_kmalloc(void) {
    print_string("  [Test B] Kernel Heap Allocator... ");
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
    kfree(p2);
    print_success("PASSED\n");
}

// ==========================================
// C. 多线程并发锁竞争测试 (Concurrency Test)
// ==========================================
volatile int shared_counter = 0;
volatile int threads_done = 0;
mutex_t test_mutex;

static void conc_thread(void) {
    for (int i = 0; i < 1000; i++) {
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
    mutex_init(&test_mutex);
    
    // 创建 3 个并发线程
    thread_append(thread_create(conc_thread, 5));
    thread_append(thread_create(conc_thread, 5));
    thread_append(thread_create(conc_thread, 5));

    // 主线程死等它们干完活
    while (threads_done < 3) {
        thread_yield(); 
    }

    // 断言：如果没有互斥锁，抢占式时钟中断绝对会导致数字小于 3000！
    ASSERT(shared_counter == 3000); 
    print_success("PASSED\n");
}

// ==========================================
// D. 虚拟页表覆盖重映射测试 (VMM Test)
// ==========================================
static void test_vmm(void) {
    print_string("  [Test D] Virtual Memory Mapping... ");
    uint64_t test_cr3 = (uint64_t)create_page_dir();
    
    void* phys_A = alloc_page();
    void* phys_B = alloc_page();
    
    // 利用高半区后门直接给物理页写入标志数据
    *(volatile uint64_t*)P2V(phys_A) = 0xAAAAAAAAAAAAAAAA;
    *(volatile uint64_t*)P2V(phys_B) = 0xBBBBBBBBBBBBBBBB;

    uint64_t target_vaddr = 0x50000000;
    
    // 将地址映射给 A
    map_page(test_cr3, target_vaddr, (uint64_t)phys_A, 0x07);
    // 强行覆盖映射给 B
    map_page(test_cr3, target_vaddr, (uint64_t)phys_B, 0x07); 

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

    free_page(phys_A);
    free_page(phys_B);
    free_page((void*)test_cr3); // 简单回收根表
    print_success("PASSED\n");
}

// 执行全家桶
void run_all_kernel_tests(void) {
    print_info("[SYSTEM] Running Automated Kernel Tests...\n");
    test_pmm();
    test_kmalloc();
    test_vmm();
    test_concurrency();
    print_success("[SYSTEM] ALL TESTS PASSED! Kernel is solid as a rock.\n\n");
}