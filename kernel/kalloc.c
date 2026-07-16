// kernel/kalloc.c

#include "kalloc.h"
#include "memory.h"
#include "print.h"

struct MemBlock* heap_head = NULL;

void kmalloc_init(void) {
    // 1. 找底层物理页管理器 (国土局) 批发一块崭新的 4KB 物理内存
    void* first_page = alloc_page();

    // 严谨的内核绝不允许指针为空，一定要做错误检查
    if (first_page == NULL) {
        print_string("PANIC: kmalloc_init failed to get a physical page!\n");
        return; // 死机或者陷入死循环也可以
    }

    // 2. 将这 4KB 内存的开头部分，强制征用为第一个“账本”
    heap_head = (struct MemBlock*)first_page;

    // 3. 填写账本信息
    // 实际能出租的面积 = 总面积 (4096) - 账本自己占用的面积 (sizeof(struct MemBlock))
    heap_head->size = 4096 - sizeof(struct MemBlock); 
    
    // 标记为全新空闲
    heap_head->is_free = 1;
    
    // 目前整个系统中只有这一大块地，所以没有下一块
    heap_head->next = NULL; 

    // 打印一句开业大吉的日志
    print_string("[INFO] Kernel Heap Allocator Initialized successfully!\n");
}

void* kmalloc(size_t size) {
    if (size == 0) return NULL;

    // 1. 内存对齐（极其重要！）
    // 算法：向上取 8 的倍数。比如 13 -> 16, 8 -> 8
    size_t aligned_size = (size + 7) & ~7;

    struct MemBlock* current = heap_head;

    // 2. 遍历链表，寻找能塞得下这块数据的空闲商铺
    while (current != NULL) {
        
        // 找到了一个空闲，且容量足够大的块！
        if (current->is_free && current->size >= aligned_size) {
            
            // 3. 判断是否需要“切割找零” (Split)
            // 如果这个块比我们需要的大很多，大到切出 aligned_size 后，
            // 剩下的空间还足够放得下一个新账本(sizeof) + 至少8字节的数据，我们就切开它！
            if (current->size >= aligned_size + sizeof(struct MemBlock) + 8) {
                
                // 【核心黑魔法：指针运算定位新账本的位置】
                // 必须先强转成 uint8_t*，才能按“字节”为单位在内存里往前移动！
                // 新账本地址 = 当前账本地址 + 账本自身大小 + 你要的实际内存大小
                struct MemBlock* new_block = (struct MemBlock*)(
                    (uint8_t*)current + sizeof(struct MemBlock) + aligned_size
                );
                
                // 填写新账本（这就是找给系统的零钱）
                new_block->size = current->size - aligned_size - sizeof(struct MemBlock);
                new_block->is_free = true;
                new_block->next = current->next; // 接管原来的下一个块
                
                // 更新当前账本
                current->size = aligned_size;    // 当前块被切得只剩这么大了
                current->next = new_block;       // 下一块指向刚刚生成的找零块
            }
            
            // 4. 办理入住手续
            current->is_free = false;
            
            // 5. 交钥匙！
            // 绝对不能返回 current！因为 current 是账本的地址！
            // 我们必须返回账本【后面】的数据区地址给用户去随便写！
            return (void*)((uint8_t*)current + sizeof(struct MemBlock));
        }
        
        // 如果当前块不合适，继续看下一个块
        current = current->next;
    }

    // 6. OOM (Out of Memory)
    // 如果把整个链表都找遍了，都没找到合适的空闲块。
    // （进阶做法：在这里去调用 alloc_page() 批发新的一页挂载到链表尾部，然后再试一次）
    // 目前为了简单，我们先直接报错。
    print_string("PANIC: kmalloc Out Of Memory!\n");
    return NULL;
}


void kfree(void* ptr) {
    if (ptr == NULL) return;

    // 1. 魔法倒退：通过数据区指针，找回它的“账本”头部！
    // 必须强转成 uint8_t* 才能按字节后退，退完之后再强转回 MemBlock*
    struct MemBlock* block = (struct MemBlock*)((uint8_t*)ptr - sizeof(struct MemBlock));

    // 2. 标记为空闲
    block->is_free = true;

    // 3. 碎片合并 (Coalescing)：向后合并
    // 如果当前块的下一个块存在，而且也是空闲的，我们就把它们融为一体！
    if (block->next != NULL && block->next->is_free == true) {
        
        // 新的大小 = 当前块自身容量 + 后面账本占用的空间 + 后面块的容量
        // （直接把中间那个多余的账本给“吃”掉了，变成了可用空间）
        block->size = block->size + sizeof(struct MemBlock) + block->next->size;
        
        // 链表指针跳过下一个块，直接连到下下个块
        block->next = block->next->next;
    }

    // 4. (进阶) 碎片合并：向前合并
    // 因为我们是单向链表，只能从头开始找是谁的 next 指向了当前的 block
    struct MemBlock* current = heap_head;
    while (current != NULL) {
        if (current->next == block) {
            // 找到了当前块的“前任”
            if (current->is_free == true) {
                // 如果前任也是空的，让前任把我们给合并了！
                current->size = current->size + sizeof(struct MemBlock) + block->size;
                current->next = block->next;
            }
            break; // 找到了前任就可以退出了
        }
        current = current->next;
    }
}