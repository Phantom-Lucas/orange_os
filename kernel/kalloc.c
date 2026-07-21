// kernel/kalloc.c
#include "kalloc.h"
#include "memory.h"
#include "print.h"
#include <stdint.h>
#include <stdbool.h>

struct MemBlock* heap_head = NULL;

void kmalloc_init(void)
{
    // 找底层批发一块 4KB 内存 (返回纯物理地址)
    void* first_page = alloc_page();
    if (first_page == NULL) {
        print_string("PANIC: kmalloc_init failed to get a physical page!\n");
        return; 
    }

    // 【修复点】：将物理页转换成高半区虚拟地址，供内核 C 语言操作
    heap_head = (struct MemBlock*)P2V(first_page);
    heap_head->size = 4096 - sizeof(struct MemBlock); 
    heap_head->is_free = true;
    heap_head->next = NULL; 

    print_string("[INFO] Kernel Heap Allocator Initialized successfully!\n");
}

void* kmalloc(size_t size) 
{
    if (size == 0) return NULL;

    // 【修改点】：删掉了那个 4KB 的报错天花板，我们现在无所畏惧！

    size_t aligned_size = (size + 7) & ~7;
    struct MemBlock* current = heap_head;

    while (current != NULL) {
        if (current->is_free && current->size >= aligned_size) {
            if (current->size >= aligned_size + sizeof(struct MemBlock) + 8) {
                struct MemBlock* new_block = (struct MemBlock*)(
                    (uint8_t*)current + sizeof(struct MemBlock) + aligned_size
                );
                new_block->size = current->size - aligned_size - sizeof(struct MemBlock);
                new_block->is_free = true;
                new_block->next = current->next;
                current->size = aligned_size;
                current->next = new_block;
            }
            current->is_free = false;
            return (void*)((uint8_t*)current + sizeof(struct MemBlock));
        }
        current = current->next;
    }

    // ================================================================
    // 终极扩容魔法：按需申请连续的 N 个页面！
    // ================================================================
    
    // 1. 计算我们到底需要多少字节？(账本自身大小 + 用户申请的对齐大小)
    size_t total_needed_bytes = sizeof(struct MemBlock) + aligned_size;
    
    // 2. 算出这相当于几个 4KB 的页 (向上取整)
    uint32_t pages_needed = (total_needed_bytes + 4095) / 4096;

    // 3. 向物理层申请连续的 pages_needed 个页面
    void* new_pages = alloc_pages(pages_needed);
    
    if (new_pages != NULL) {
        struct MemBlock* new_block = (struct MemBlock*)P2V(new_pages);
        new_block->size = (pages_needed * 4096) - sizeof(struct MemBlock);
        new_block->is_free = true;
        new_block->next = NULL;

        // 5. 安全挂载到整个链表的最尾端
        if (heap_head == NULL) {
            // 如果链表是空的，这块新地皮就是唯一的头！
            heap_head = new_block;
        } else {
            // 否则顺藤摸瓜找尾巴
            struct MemBlock* tail = heap_head;
            while (tail->next != NULL) {
                tail = tail->next;
            }
            tail->next = new_block;
        }

        // 6. 进货完毕，重新执行分配逻辑！
        return kmalloc(size);
    }

    print_string("FATAL PANIC: Physical Memory Exhausted!\n");
    return NULL;
}

void kfree(void* ptr) 
{
    if (ptr == NULL) return;
    struct MemBlock* block = (struct MemBlock*)((uint8_t*)ptr - sizeof(struct MemBlock));
    block->is_free = true;
    if (block->next != NULL && block->next->is_free == true) {
        block->size = block->size + sizeof(struct MemBlock) + block->next->size;
        block->next = block->next->next;
    }
    struct MemBlock* current = heap_head;
    while (current != NULL) {
        if (current->next == block) {
            if (current->is_free == true) {
                current->size = current->size + sizeof(struct MemBlock) + block->size;
                current->next = block->next;
            }
            break; 
        }
        current = current->next;
    }
}
