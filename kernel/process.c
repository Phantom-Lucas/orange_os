// kernel/process.c
#include "process.h"
#include "thread.h"
#include "thread_internal.h"
#include "memory.h"
#include "kalloc.h"
#include "debug.h"
#include "print.h"
#include "string.h"
#include "futex.h"
#include "elf.h"
#include "file.h"
#include "timer.h"
#include "tty.h"

struct process* kernel_process = 0;
static struct process* process_list = 0;
static uint32_t next_pid = 1;

extern void return_to_user(void);
extern void return_to_user_with_arg(void);
extern void syscall_child_return(void);
extern paddr_t create_page_dir(void);

static struct process* alloc_process(void)
{
    paddr_t paddr = alloc_page_owned(PAGE_OWNER_PROCESS);
    struct process* process;

    if (paddr == 0) return 0;
    if (current_thread != 0) {
        struct thread* scan = current_thread;
        do {
            ASSERT(scan->object_paddr != paddr);
            scan = scan->next;
        } while (scan != current_thread);
    }
    process = (struct process*)P2V(paddr);
    memset(process, 0, PAGE_SIZE);
    process->object_paddr = paddr;
    process->state = PROCESS_RUNNING;
    process->next_thread_stack_top = 0x00007FFFE0000000ULL;
    process->next_thread_tls_top = 0x00007FFFD0000000ULL;
    process->next_mmap_base = 0x0000600000000000ULL;
    process->cwd_inode = FS_ROOT_INODE;
    strcpy(process->cwd_path, "/");
    strcpy(process->name, "process");
    spinlock_init(&process->address_space_lock);
    spinlock_init(&process->lifecycle_lock);
    spinlock_init(&process->files_lock);
    process->next_all = process_list;
    process_list = process;
    return process;
}

static void unlink_process(struct process* victim)
{
    struct process** link = &process_list;
    while (*link != 0 && *link != victim) link = &(*link)->next_all;
    if (*link == victim) *link = victim->next_all;
    victim->next_all = 0;
}

static void free_process_object(struct process* process)
{
    paddr_t paddr;

    if (process == 0) return;
    paddr = process->object_paddr;
    process->object_paddr = 0;
    unlink_process(process);
    if (free_page_owned(paddr, PAGE_OWNER_PROCESS) != 0) {
        print_error("[PROC] failed to reclaim process object.\n");
    }
}

void process_free_vmas(struct process* process)
{
    struct vm_area* area;
    if (process == 0) return;
    area = process->vma_head;
    process->vma_head = 0;
    while (area != 0) {
        struct vm_area* next = area->next;
        kfree(area);
        area = next;
    }
}

static int vma_overlaps(const struct process* process, vaddr_t start,
                        vaddr_t end)
{
    const struct vm_area* area = process == 0 ? 0 : process->vma_head;
    while (area != 0) {
        if (start < area->end && area->start < end) return 1;
        area = area->next;
    }
    return 0;
}

int process_add_vma(struct process* process, vaddr_t start, vaddr_t end,
                    uint64_t flags, uint64_t file_offset)
{
    struct vm_area* area;
    struct vm_area** link;

    if (process == 0 || start == 0 || start >= end ||
        (start & (PAGE_SIZE - 1)) != 0 || (end & (PAGE_SIZE - 1)) != 0 ||
        end > 0x0000800000000000ULL || vma_overlaps(process, start, end)) {
        return -1;
    }
    area = (struct vm_area*)kmalloc(sizeof(*area));
    if (area == 0) return -1;
    area->start = start;
    area->end = end;
    area->flags = flags;
    area->file = 0;
    area->file_offset = file_offset;
    area->next = 0;
    link = &process->vma_head;
    while (*link != 0 && (*link)->start < start) link = &(*link)->next;
    area->next = *link;
    *link = area;
    return 0;
}

static struct vm_area* find_vma_locked(struct process* process,
                                       vaddr_t address)
{
    struct vm_area* area = process == 0 ? 0 : process->vma_head;
    while (area != 0) {
        if (address >= area->start && address < area->end) return area;
        area = area->next;
    }
    return 0;
}

static void link_child(struct process* child, struct process* parent)
{
    if (child == 0) return;
    child->parent = parent;
    child->sibling_next = 0;
    if (parent != 0) {
        child->sibling_next = parent->child_head;
        parent->child_head = child;
    }
}

static void unlink_child(struct process* child)
{
    struct process** link;

    if (child == 0 || child->parent == 0) return;
    link = &child->parent->child_head;
    while (*link != 0 && *link != child) link = &(*link)->sibling_next;
    if (*link == child) *link = child->sibling_next;
    child->parent = 0;
    child->sibling_next = 0;
}

void process_init(void)
{
    kernel_process = alloc_process();
    if (kernel_process == 0) return;
    kernel_process->pid = 0;
    strcpy(kernel_process->name, "kernel");
    kernel_process->cr3_paddr = BOOT_KERNEL_PML4_PADDR;
}

struct process* process_current(void)
{
    return current_thread == 0 ? 0 : current_thread->process;
}

struct process* process_find_by_pid(uint32_t pid)
{
    struct process* process = process_list;
    while (process != 0) {
        if (process->pid == pid) return process;
        process = process->next_all;
    }
    return 0;
}

int process_is_single_threaded(const struct process* process)
{
    return process != 0 && process->thread_count == 1 &&
           process->main_thread != 0 &&
           process->main_thread->process == process;
}

struct thread* thread_find_by_pid(uint32_t pid)
{
    struct process* process = process_find_by_pid(pid);
    return process == 0 ? 0 : process->main_thread;
}

static void release_process_address_space(struct process* process)
{
    paddr_t cr3;

    if (process == 0) return;
    cr3 = process->cr3_paddr & PTE_ADDR_MASK;
    process->cr3_paddr = 0;
    if (cr3 == 0 || cr3 == BOOT_KERNEL_PML4_PADDR) {
        process_free_vmas(process);
        return;
    }
    if (process == process_current()) {
        __asm__ volatile("mov %0, %%cr3" ::
                         "r"((paddr_t)BOOT_KERNEL_PML4_PADDR) : "memory");
    }
    destroy_user_address_space(cr3);
    process_free_vmas(process);
}

static void setup_user_thread(struct thread* thread, uint64_t entry,
                              uint64_t user_rsp, uint64_t arg, int with_arg)
{
    uint64_t* stack = (uint64_t*)thread->kernel_stack_top;
    struct thread_context* context;

    thread->user_rsp = user_rsp;

    /* 参数放在 iret frame 上方，避免破坏 switch.S 紧邻的上下文布局。 */
    if (with_arg) *(--stack) = arg;
    *(--stack) = 0x1B;
    *(--stack) = user_rsp;
    *(--stack) = 0x202;
    *(--stack) = 0x23;
    *(--stack) = entry;
    stack = (uint64_t*)((uint64_t)stack - sizeof(struct thread_context));
    context = (struct thread_context*)stack;
    memset(context, 0, sizeof(*context));
    context->rip = (uint64_t)(with_arg ? return_to_user_with_arg :
                              return_to_user);
    thread->rsp = (uint64_t)stack;
}

/* 为同一地址空间中的新线程分配一个独立用户栈，栈之间保留一页保护间隙。 */
static int allocate_user_thread_stack(struct process* process,
                                      struct thread* thread)
{
    paddr_t stack_paddr;
    vaddr_t stack_top;
    vaddr_t stack_base;

    if (process == 0 || thread == 0 || process->cr3_paddr == 0) return -1;
    stack_paddr = alloc_page_owned(PAGE_OWNER_USER);
    if (stack_paddr == 0) return -1;

    spinlock_acquire(&process->address_space_lock);
    if (process->next_thread_stack_top < 2 * PAGE_SIZE) {
        spinlock_release(&process->address_space_lock);
        free_page_owned(stack_paddr, PAGE_OWNER_USER);
        return -1;
    }
    stack_top = process->next_thread_stack_top;
    stack_base = stack_top - PAGE_SIZE;
    process->next_thread_stack_top = stack_base - PAGE_SIZE;
    if (map_page(process->cr3_paddr, stack_base, stack_paddr,
                 PTE_RW | PTE_US) != 0) {
        spinlock_release(&process->address_space_lock);
        free_page_owned(stack_paddr, PAGE_OWNER_USER);
        return -1;
    }
    spinlock_release(&process->address_space_lock);

    thread->user_stack_base = stack_base;
    thread->user_stack_top = stack_top;
    thread->user_stack_paddr = stack_paddr;
    return 0;
}

int process_allocate_thread_tls(struct process* process, struct thread* thread)
{
    paddr_t tls_paddr;
    vaddr_t tls_base;

    if (process == 0 || thread == 0 || process->cr3_paddr == 0) return -1;
    tls_paddr = alloc_page_owned(PAGE_OWNER_USER);
    if (tls_paddr == 0) return -1;
    spinlock_acquire(&process->address_space_lock);
    if (process->next_thread_tls_top < PAGE_SIZE) {
        spinlock_release(&process->address_space_lock);
        free_page_owned(tls_paddr, PAGE_OWNER_USER);
        return -1;
    }
    tls_base = process->next_thread_tls_top - PAGE_SIZE;
    process->next_thread_tls_top = tls_base - PAGE_SIZE;
    if (map_page(process->cr3_paddr, tls_base, tls_paddr,
                 PTE_RW | PTE_US) != 0) {
        spinlock_release(&process->address_space_lock);
        free_page_owned(tls_paddr, PAGE_OWNER_USER);
        return -1;
    }
    spinlock_release(&process->address_space_lock);
    *(uint64_t*)P2V(tls_paddr) = tls_base;
    thread->tls_base = tls_base;
    thread->tls_paddr = tls_paddr;
    return 0;
}

struct process* process_create(void (*app_func)(void), uint32_t priority)
{
    struct process* process = alloc_process();
    struct thread* thread;
    paddr_t user_stack;
    uint64_t user_stack_vaddr = 0xC0000000;

    if (process == 0) return 0;
    process->pid = next_pid++;
    process->parent = process_current();
    if (process->parent != 0) link_child(process, process->parent);
    process->cr3_paddr = create_page_dir();
    if (process->cr3_paddr == 0) {
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    thread = thread_alloc_for_process(process, priority);
    if (thread == 0) {
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    thread->kernel_stack_top = (uint64_t)thread->stack_base + PAGE_SIZE;
    user_stack = alloc_page_owned(PAGE_OWNER_USER);
    if (user_stack == 0 || map_page(process->cr3_paddr, user_stack_vaddr,
                                    user_stack, PTE_RW | PTE_US) != 0) {
        if (user_stack != 0) free_page_owned(user_stack, PAGE_OWNER_USER);
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    thread->user_stack_base = user_stack_vaddr;
    thread->user_stack_top = user_stack_vaddr + PAGE_SIZE;
    thread->user_stack_paddr = user_stack;
    if (process_add_vma(process, user_stack_vaddr,
                        user_stack_vaddr + PAGE_SIZE,
                        VM_READ | VM_WRITE | VM_ANON | VM_PRIVATE, 0) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    if (process_allocate_thread_tls(process, thread) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    setup_user_thread(thread, (uint64_t)app_func, user_stack_vaddr + PAGE_SIZE,
                      0, 0);
    return process;
}

struct process* process_create_loaded(uint64_t entry, uint64_t cr3_paddr,
                                      uint64_t user_rsp, uint32_t priority,
                                      const struct elf_load_vma* vmas,
                                      uint32_t vma_count)
{
    struct process* process = alloc_process();
    struct thread* thread;

    if (process == 0) {
        destroy_user_address_space(cr3_paddr);
        return 0;
    }
    process->pid = next_pid++;
    process->parent = process_current();
    if (process->parent != 0) link_child(process, process->parent);
    process->cr3_paddr = cr3_paddr;
    thread = thread_alloc_for_process(process, priority);
    if (thread == 0) {
        destroy_user_address_space(cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    thread->kernel_stack_top = (uint64_t)thread->stack_base + PAGE_SIZE;
    /* ELF loader owns this initial stack as part of the process image. */
    thread->user_stack_top = user_rsp;
    thread->user_stack_top = (user_rsp & ~(PAGE_SIZE - 1)) + PAGE_SIZE;
    thread->user_stack_base = thread->user_stack_top - PAGE_SIZE;
    for (uint32_t i = 0; i < vma_count; i++) {
        uint64_t flags = VM_PRIVATE;
        if (vmas[i].flags & 0x4) flags |= VM_READ;
        if (vmas[i].flags & 0x2) flags |= VM_WRITE;
        if (vmas[i].flags & 0x1) flags |= VM_EXEC;
        if (process_add_vma(process, vmas[i].start, vmas[i].end,
                            flags, vmas[i].file_offset) != 0) {
            thread->status = TASK_DEAD;
            thread_free_object(thread);
            destroy_user_address_space(process->cr3_paddr);
            unlink_child(process);
            process_free_vmas(process);
            free_process_object(process);
            return 0;
        }
    }
    /* 初始 ELF 栈允许在保守的 8 MiB 范围内按页增长。 */
    if (process_add_vma(process, thread->user_stack_top - 8 * 1024 * 1024ULL,
                        thread->user_stack_top,
                        VM_READ | VM_WRITE | VM_GROWSDOWN |
                        VM_ANON | VM_PRIVATE, 0) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        process_free_vmas(process);
        free_process_object(process);
        return 0;
    }
    if (process_allocate_thread_tls(process, thread) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        destroy_user_address_space(process->cr3_paddr);
        unlink_child(process);
        free_process_object(process);
        return 0;
    }
    setup_user_thread(thread, entry, user_rsp, 0, 0);
    return process;
}

int process_create_thread(struct process* process, uint64_t entry,
                          uint64_t arg, uint32_t* out_tid)
{
    struct thread* thread;

    if (out_tid != 0) *out_tid = 0;
    if (process == 0 || process == kernel_process || entry == 0 ||
        process->state != PROCESS_RUNNING || process->exit_requested ||
        !user_range_is_readable(process->cr3_paddr, entry, 1)) return -1;

    thread = thread_alloc_for_process(process, process->main_thread == 0 ? 5 :
                                      process->main_thread->priority);
    if (thread == 0) return -1;
    thread->kernel_stack_top = (uint64_t)thread->stack_base + PAGE_SIZE;
    if (allocate_user_thread_stack(process, thread) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        return -1;
    }
    if (process_allocate_thread_tls(process, thread) != 0) {
        thread->status = TASK_DEAD;
        thread_free_object(thread);
        return -1;
    }
    setup_user_thread(thread, entry, thread->user_stack_top, arg, 1);
    thread_append(thread);
    if (out_tid != 0) *out_tid = thread->tid;
    return 0;
}

int process_mmap(struct process* process, vaddr_t hint, uint64_t length,
                 uint32_t prot, uint32_t flags, vaddr_t* out_address)
{
    vaddr_t start;
    vaddr_t end;
    uint64_t pages;
    struct vm_area* area;
    uint64_t pte_flags = PTE_US;

    if (out_address != 0) *out_address = 0;
    if (process == 0 || process == kernel_process || length == 0 ||
        (flags & (MMAP_MAP_PRIVATE | MMAP_MAP_ANON)) !=
            (MMAP_MAP_PRIVATE | MMAP_MAP_ANON) ||
        (prot & ~(MMAP_PROT_READ | MMAP_PROT_WRITE | MMAP_PROT_EXEC)) != 0 ||
        (hint != 0 && (hint & (PAGE_SIZE - 1)) != 0) ||
        length > UINT64_MAX - (PAGE_SIZE - 1)) return -1;

    length = (length + PAGE_SIZE - 1) & PTE_ADDR_MASK;
    if (length == 0) return -1;
    if (prot & MMAP_PROT_WRITE) pte_flags |= PTE_RW;
    pages = length / PAGE_SIZE;

    spinlock_acquire(&process->address_space_lock);
    start = hint != 0 ? hint : process->next_mmap_base;
    if (start == 0 || start > 0x00007FFFFFFFFFFFULL ||
        length > 0x0000800000000000ULL - start) {
        spinlock_release(&process->address_space_lock);
        return -1;
    }
    end = start + length;
    if (vma_overlaps(process, start, end) ||
        end > 0x0000800000000000ULL) {
        if (hint != 0) {
            spinlock_release(&process->address_space_lock);
            return -1;
        }
        /* 自动地址只向上寻找空洞，避免覆盖 ELF/线程栈。 */
        while (vma_overlaps(process, start, end)) {
            start = end;
            if (start > 0x00007FFFFFFFFFFFULL ||
                length > 0x0000800000000000ULL - start) {
                spinlock_release(&process->address_space_lock);
                return -1;
            }
            end = start + length;
        }
    }

    if (process_add_vma(process, start, end,
                        VM_ANON | VM_PRIVATE |
                        ((prot & MMAP_PROT_READ) ? VM_READ : 0) |
                        ((prot & MMAP_PROT_WRITE) ? VM_WRITE : 0) |
                        ((prot & MMAP_PROT_EXEC) ? VM_EXEC : 0), 0) != 0) {
        spinlock_release(&process->address_space_lock);
        return -1;
    }

    for (uint64_t i = 0; i < pages; i++) {
        paddr_t page = alloc_page_owned(PAGE_OWNER_USER);
        if (page == 0 || map_page(process->cr3_paddr,
                                  start + i * PAGE_SIZE,
                                  page, pte_flags) != 0) {
            if (page != 0) free_page_owned(page, PAGE_OWNER_USER);
            for (uint64_t j = 0; j < i; j++) {
                (void)unmap_user_page(process->cr3_paddr,
                                      start + j * PAGE_SIZE,
                                      PAGE_OWNER_USER);
            }
            struct vm_area** link = &process->vma_head;
            while (*link != 0 && (*link)->start != start) link = &(*link)->next;
            if (*link != 0) {
                area = *link;
                *link = area->next;
                kfree(area);
            }
            spinlock_release(&process->address_space_lock);
            return -1;
        }
    }
    if (hint == 0) process->next_mmap_base = end + PAGE_SIZE;
    if (out_address != 0) *out_address = start;
    spinlock_release(&process->address_space_lock);
    return 0;
}

int process_munmap(struct process* process, vaddr_t address, uint64_t length)
{
    vaddr_t end;
    struct vm_area* area;
    struct vm_area* suffix = 0;
    struct vm_area** link;
    int remove_area = 0;

    if (process == 0 || address == 0 ||
        (address & (PAGE_SIZE - 1)) != 0 || length == 0 ||
        length > UINT64_MAX - (PAGE_SIZE - 1)) return -1;
    length = (length + PAGE_SIZE - 1) & PTE_ADDR_MASK;
    if (length == 0 || address > UINT64_MAX - length) return -1;
    end = address + length;

    spinlock_acquire(&process->address_space_lock);
    area = find_vma_locked(process, address);
    if (area == 0 || end > area->end ||
        !(area->flags & VM_ANON) || (area->flags & VM_GROWSDOWN)) {
        spinlock_release(&process->address_space_lock);
        return -1;
    }
    if (address > area->start && end < area->end) {
        suffix = (struct vm_area*)kmalloc(sizeof(*suffix));
        if (suffix == 0) {
            spinlock_release(&process->address_space_lock);
            return -1;
        }
        *suffix = *area;
        suffix->start = end;
        suffix->next = area->next;
    }

    for (vaddr_t page = address; page < end; page += PAGE_SIZE) {
        if (get_user_pte(process->cr3_paddr, page) != 0 &&
            unmap_user_page(process->cr3_paddr, page,
                            PAGE_OWNER_USER) != 0) {
            if (suffix != 0) kfree(suffix);
            spinlock_release(&process->address_space_lock);
            return -1;
        }
    }

    if (suffix != 0) {
        area->end = address;
        area->next = suffix;
    } else if (address == area->start && end == area->end) {
        link = &process->vma_head;
        while (*link != 0 && *link != area) link = &(*link)->next;
        if (*link == area) *link = area->next;
        remove_area = 1;
    } else if (address == area->start) {
        area->start = end;
    } else {
        area->end = address;
    }
    if (remove_area) kfree(area);
    spinlock_release(&process->address_space_lock);
    return 0;
}

int process_handle_page_fault(struct process* process, vaddr_t address,
                              uint64_t error_code)
{
    struct vm_area* area;
    uint64_t* pte;
    paddr_t page;
    uint64_t flags;

    if (process == 0 || address == 0 ||
        address > 0x00007FFFFFFFFFFFULL) return -1;
    address &= PTE_ADDR_MASK;
    spinlock_acquire(&process->address_space_lock);
    area = find_vma_locked(process, address);
    pte = get_user_pte(process->cr3_paddr, address);
    if (area == 0 || !(area->flags & VM_GROWSDOWN) ||
        (pte != 0 && (*pte & PTE_P) != 0) ||
        ((error_code & 0x2) != 0 && !(area->flags & VM_WRITE))) {
        spinlock_release(&process->address_space_lock);
        return -1;
    }
    page = alloc_page_owned(PAGE_OWNER_USER);
    if (page == 0) {
        spinlock_release(&process->address_space_lock);
        return -1;
    }
    flags = PTE_US | ((area->flags & VM_WRITE) ? PTE_RW : 0);
    if (map_page(process->cr3_paddr, address, page, flags) != 0) {
        free_page_owned(page, PAGE_OWNER_USER);
        spinlock_release(&process->address_space_lock);
        return -1;
    }
    spinlock_release(&process->address_space_lock);
    return 0;
}

static struct process* find_child(uint32_t pid)
{
    struct process* parent = process_current();
    struct process* candidate = 0;
    struct process* child;

    if (parent == 0) return 0;
    child = parent->child_head;
    while (child != 0) {
        if (pid == 0 && candidate == 0) candidate = child;
        if (pid != 0 && child->pid == pid) return child;
        if (pid == 0 && child->state == PROCESS_ZOMBIE) return child;
        child = child->sibling_next;
    }
    return candidate;
}

static void reap_process(struct process* process)
{
    struct thread* main_thread;

    if (process == 0 || process == kernel_process ||
        process->state != PROCESS_ZOMBIE) return;
    main_thread = process->main_thread;
    if (main_thread == 0 || main_thread == current_thread ||
        main_thread->status != TASK_ZOMBIE ||
        !process_is_single_threaded(process)) return;
    release_process_address_space(process);
    thread_remove_from_scheduler(main_thread);
    main_thread->status = TASK_DEAD;
    thread_free_object(main_thread);
    unlink_child(process);
    process->state = PROCESS_DEAD;
    free_process_object(process);
}

int process_discard(struct process* process)
{
    struct thread* thread;

    if (process == 0 || process == kernel_process ||
        process->state != PROCESS_RUNNING || process->main_thread == 0 ||
        process->main_thread->status != TASK_READY ||
        !process_is_single_threaded(process) ||
        thread_in_scheduler_ring(process->main_thread)) return -1;
    thread = process->main_thread;
    release_process_address_space(process);
    unlink_child(process);
    thread->status = TASK_DEAD;
    thread_free_object(thread);
    process->state = PROCESS_DEAD;
    free_process_object(process);
    return 0;
}

void process_reap_orphans(void)
{
    struct process* process = process_list;
    while (process != 0) {
        struct process* next = process->next_all;
        if (process != kernel_process && process->parent == 0 &&
            process->state == PROCESS_ZOMBIE) reap_process(process);
        process = next;
    }
}

void process_get_runtime_stats(struct process_runtime_stats* stats)
{
    struct process* process;

    if (stats == 0) return;
    memset(stats, 0, sizeof(*stats));
    process = process_list;
    while (process != 0) {
        stats->processes++;
        stats->threads += process->thread_count;
        if (process->state == PROCESS_RUNNING) stats->running_processes++;
        if (process->state == PROCESS_ZOMBIE) stats->zombie_processes++;
        process = process->next_all;
    }
}

void process_dump_runtime_stats(const char* tag)
{
#if !BOOT_DIAGNOSTIC
    (void)tag;
    return;
#else
    struct process_runtime_stats processes;
    struct pmm_stats pmm;
    struct kalloc_stats heap;
    struct futex_stats futex;
    struct file_runtime_stats files;

    process_get_runtime_stats(&processes);
    pmm_get_stats(&pmm);
    kalloc_get_stats(&heap);
    futex_get_stats(&futex);
    file_get_runtime_stats(&files);
    print_info("[RUNTIME] ");
    if (tag != 0) print_string(tag);
    print_string(" processes="); print_int(processes.processes);
    print_string(" threads="); print_int(processes.threads);
    print_string(" zombies="); print_int(processes.zombie_processes);
    print_string(" futex_waiters="); print_int(futex.waiters);
    print_string(" pmm_allocated="); print_int(pmm.allocated_pages);
    print_string(" owner_thread="); print_int(pmm.owner_pages[PAGE_OWNER_THREAD]);
    print_string(" owner_user="); print_int(pmm.owner_pages[PAGE_OWNER_USER]);
    print_string(" user_mapped="); print_int(pmm.user_mapped_pages);
    print_string(" user_refs="); print_int(pmm.user_mapping_refs);
    print_string(" heap_arenas="); print_int(heap.arenas);
    print_string(" heap_blocks="); print_int(heap.active_blocks);
    print_string(" heap_bytes="); print_int(heap.allocated_bytes);
    print_string(" file_objects="); print_int(files.active_file_objects);
    print_string(" pipe_objects="); print_int(files.active_pipe_objects);
    print_string("\n");
#endif
}

static uint32_t process_count_user_pages(struct process* process)
{
    uint32_t count = 0;
    if (process == 0 || process->cr3_paddr == 0) return 0;
    spinlock_acquire(&process->address_space_lock);
    uint64_t* pml4 = (uint64_t*)P2V(process->cr3_paddr & PTE_ADDR_MASK);
    for (uint32_t i = 0; i < 256; i++) {
        if ((pml4[i] & (PTE_P | PTE_US)) != (PTE_P | PTE_US)) continue;
        uint64_t* pdpt = (uint64_t*)P2V(pml4[i] & PTE_ADDR_MASK);
        for (uint32_t j = 0; j < 512; j++) {
            if ((pdpt[j] & (PTE_P | PTE_US)) != (PTE_P | PTE_US) ||
                (pdpt[j] & PTE_PS)) continue;
            uint64_t* pd = (uint64_t*)P2V(pdpt[j] & PTE_ADDR_MASK);
            for (uint32_t k = 0; k < 512; k++) {
                if ((pd[k] & (PTE_P | PTE_US)) != (PTE_P | PTE_US) ||
                    (pd[k] & PTE_PS)) continue;
                uint64_t* pt = (uint64_t*)P2V(pd[k] & PTE_ADDR_MASK);
                for (uint32_t l = 0; l < 512; l++) {
                    if ((pt[l] & (PTE_P | PTE_US)) == (PTE_P | PTE_US)) count++;
                }
            }
        }
    }
    spinlock_release(&process->address_space_lock);
    return count;
}

uint32_t process_snapshot(struct process_info* out, uint32_t capacity)
{
    struct process* process;
    uint32_t copied = 0;

    if (out == 0 || capacity == 0) return 0;
    process = process_list;
    while (process != 0 && copied < capacity) {
        struct process_info* info = &out[copied++];
        uint32_t length = 0;

        info->pid = process->pid;
        info->ppid = process->parent == 0 ? 0 : process->parent->pid;
        info->state = (uint32_t)process->state;
        info->threads = process->thread_count;
        info->user_pages = process_count_user_pages(process);
        while (length + 1 < sizeof(info->name) && process->name[length] != '\0') {
            info->name[length] = process->name[length];
            length++;
        }
        info->name[length] = '\0';
        info->name_length = length;
        process = process->next_all;
    }
    return copied;
}

static int request_process_termination(uint32_t pid, int status,
                                        int reject_current)
{
    struct process* process = process_find_by_pid(pid);
    struct thread* thread;

    if (process == 0 || process == kernel_process ||
        process->state != PROCESS_RUNNING ||
        (reject_current && process == process_current())) {
        return -1;
    }
    process->exit_requested = 1;
    process->kill_status = status;
    futex_cancel_process(process, FUTEX_ERR_INTR);
    thread = process->thread_head;
    while (thread != 0) {
        struct thread* next = thread->process_next;
        timer_cancel_thread_sleep(thread);
        ipc_abort_thread(thread);
        if (thread->status == TASK_BLOCKED) thread_unblock(thread);
        thread = next;
    }
    thread_request_reschedule();
    return 0;
}

int process_request_kill(uint32_t pid, int status)
{
    return request_process_termination(pid, status, 1);
}

int process_request_terminal_signal(uint32_t pid, int status)
{
    return request_process_termination(pid, status, 0);
}

int process_wait(uint32_t pid, int* status, uint32_t options)
{
    struct process* parent = process_current();
    int controls_terminal = parent != 0 && parent->terminal_controller;

    while (1) {
        struct process* child = find_child(pid);
        if (child == 0) return -1;
        if (child->state == PROCESS_ZOMBIE) {
            uint32_t child_pid = child->pid;
            if (status != 0) *status = child->exit_status;
            child->exit_waited = 1;
            reap_process(child);
            process_dump_runtime_stats("after-wait");
            return (int)child_pid;
        }
        if ((options & 1U) != 0) return 0;
        /* 只有 Shell 的外层 wait 设置终端前台；sync-demo 等普通用户
           进程内部的 wait 不能覆盖 Shell 正在等待的前台任务。 */
        if (controls_terminal) tty_set_foreground_pid(child->pid);
        thread_block();
        if (controls_terminal) tty_set_foreground_pid(0);
    }
}

static void reparent_children(struct process* process)
{
    while (process != 0 && process->child_head != 0) {
        struct process* child = process->child_head;
        process->child_head = child->sibling_next;
        child->parent = 0;
        child->sibling_next = 0;
    }
}

static void process_close_files(struct process* process)
{
    struct file_object* objects[STD_FILE_COUNT + MAX_OPEN_FILES];
    uint32_t count = 0;
    if (process == 0) return;
    spinlock_acquire(&process->files_lock);
    for (uint32_t i = 0; i < STD_FILE_COUNT; i++) {
        objects[count] = process->stdio[i].object;
        process->stdio[i].object = 0;
        if (objects[count] != 0) count++;
    }
    for (uint32_t i = 0; i < MAX_OPEN_FILES; i++) {
        objects[count] = process->files[i].object;
        process->files[i].object = 0;
        if (objects[count] != 0) count++;
    }
    spinlock_release(&process->files_lock);
    for (uint32_t i = 0; i < count; i++) file_release(objects[i]);
}

void process_exit(int status)
{
    struct process* process = process_current();
    struct thread* parent_thread;
    struct thread* victim;

    if (process == 0 || process == kernel_process) {
        thread_exit();
        return;
    }
    __asm__ volatile("cli");
    process->exit_requested = 1;
    /* 避免终端在进程退出后保留一个可复用 PID。 */
    if (tty_get_foreground_pid() == process->pid) tty_set_foreground_pid(0);
    futex_cancel_process(process, FUTEX_ERR_INTR);
    ipc_abort_current();
    /* 进程退出是全体线程的终止点，先清理其它调度实体，再释放共享页表。 */
    victim = process->thread_head;
    while (victim != 0) {
        struct thread* next = victim->process_next;
        if (victim != current_thread) {
            ipc_abort_thread(victim);
            thread_remove_from_scheduler(victim);
            victim->status = TASK_DEAD;
            thread_free_object(victim);
        }
        victim = next;
    }
    process_close_files(process);
    release_process_address_space(process);
    process->exit_status = status;
    process->state = PROCESS_ZOMBIE;
    current_thread->status = TASK_ZOMBIE;
    current_thread->lifecycle =
        current_thread->lifecycle == THREAD_DETACHED_RUNNING
            ? THREAD_DETACHED_ZOMBIE : THREAD_JOINABLE_ZOMBIE;
    reparent_children(process);
    parent_thread = process->parent == 0 ? 0 : process->parent->main_thread;
    if (parent_thread != 0 && parent_thread->status == TASK_BLOCKED) {
        thread_unblock(parent_thread);
    }
    while (1) thread_yield();
}

static paddr_t clone_user_address_space(paddr_t parent_cr3)
{
    paddr_t child_cr3 = create_page_dir();
    if (!child_cr3) return 0;
    uint64_t* parent_pml4 = (uint64_t*)P2V(parent_cr3);
    for (uint64_t pml4_index = 0; pml4_index < 256; pml4_index++) {
        if (!(parent_pml4[pml4_index] & PTE_P)) continue;
        uint64_t* parent_pdpt = (uint64_t*)P2V(parent_pml4[pml4_index] & PTE_ADDR_MASK);
        for (uint64_t pdpt_index = 0; pdpt_index < 512; pdpt_index++) {
            if (!(parent_pdpt[pdpt_index] & PTE_P) ||
                (parent_pdpt[pdpt_index] & PTE_PS)) continue;
            uint64_t* parent_pd = (uint64_t*)P2V(parent_pdpt[pdpt_index] & PTE_ADDR_MASK);
            for (uint64_t pd_index = 0; pd_index < 512; pd_index++) {
                if (!(parent_pd[pd_index] & PTE_P) ||
                    (parent_pd[pd_index] & PTE_PS)) continue;
                uint64_t* parent_pt = (uint64_t*)P2V(parent_pd[pd_index] & PTE_ADDR_MASK);
                for (uint64_t pt_index = 0; pt_index < 512; pt_index++) {
                    uint64_t entry = parent_pt[pt_index];
                    if ((entry & (PTE_P | PTE_US)) != (PTE_P | PTE_US)) continue;
                    uint64_t vaddr = (pml4_index << 39) | (pdpt_index << 30) |
                                     (pd_index << 21) | (pt_index << 12);
                    uint64_t child_flags = entry & 0xFFFULL;

                    /*
                     * 先不改父 PTE。子页表全部建立成功后，再一次性把父页
                     * 改成只读 COW；因此任意分配/建表失败都能无损回滚。
                     */
                    if (entry & PTE_RW) {
                        child_flags &= ~PTE_RW;
                        child_flags |= PTE_COW;
                    }
                    if (map_page(child_cr3, vaddr,
                                 entry & PTE_ADDR_MASK, child_flags) != 0) {
                        destroy_user_address_space(child_cr3);
                        return 0;
                    }
                }
            }
        }
    }
    /* 子地址空间已经完整建立，现在才封存父方可写页。 */
    for (uint64_t pml4_index = 0; pml4_index < 256; pml4_index++) {
        if (!(parent_pml4[pml4_index] & PTE_P)) continue;
        uint64_t* parent_pdpt =
            (uint64_t*)P2V(parent_pml4[pml4_index] & PTE_ADDR_MASK);
        for (uint64_t pdpt_index = 0; pdpt_index < 512; pdpt_index++) {
            if (!(parent_pdpt[pdpt_index] & PTE_P) ||
                (parent_pdpt[pdpt_index] & PTE_PS)) continue;
            uint64_t* parent_pd =
                (uint64_t*)P2V(parent_pdpt[pdpt_index] & PTE_ADDR_MASK);
            for (uint64_t pd_index = 0; pd_index < 512; pd_index++) {
                if (!(parent_pd[pd_index] & PTE_P) ||
                    (parent_pd[pd_index] & PTE_PS)) continue;
                uint64_t* parent_pt =
                    (uint64_t*)P2V(parent_pd[pd_index] & PTE_ADDR_MASK);
                for (uint64_t pt_index = 0; pt_index < 512; pt_index++) {
                    uint64_t* pte = &parent_pt[pt_index];
                    if ((*pte & (PTE_P | PTE_US | PTE_RW)) !=
                        (PTE_P | PTE_US | PTE_RW)) continue;
                    *pte = (*pte & ~PTE_RW) | PTE_COW;
                    uint64_t vaddr = (pml4_index << 39) |
                                     (pdpt_index << 30) |
                                     (pd_index << 21) | (pt_index << 12);
                    __asm__ volatile("invlpg (%0)" ::
                                     "r"((void*)vaddr) : "memory");
                }
            }
        }
    }
    return child_cr3;
}

int process_fork(uint64_t syscall_frame_rsp)
{
    struct process* parent = process_current();
    struct process* child_process;
    struct thread* child;
    paddr_t child_cr3;

    if (current_thread == 0 || parent == 0 || parent == kernel_process ||
        current_thread->kernel_stack_top == 0 ||
        !process_is_single_threaded(parent)) return -1;
    spinlock_acquire(&parent->address_space_lock);
    child_cr3 = clone_user_address_space(parent->cr3_paddr);
    spinlock_release(&parent->address_space_lock);
    if (!child_cr3) return -1;
    child_process = alloc_process();
    if (child_process == 0) {
        destroy_user_address_space(child_cr3);
        return -1;
    }
    child_process->pid = next_pid++;
    child_process->cr3_paddr = child_cr3;
    child_process->next_thread_tls_top = parent->next_thread_tls_top;
    child_process->next_mmap_base = parent->next_mmap_base;
    child_process->cwd_inode = parent->cwd_inode;
    strcpy(child_process->cwd_path, parent->cwd_path);
    for (struct vm_area* area = parent->vma_head; area != 0;
         area = area->next) {
        if (process_add_vma(child_process, area->start, area->end,
                            area->flags, area->file_offset) != 0) {
            destroy_user_address_space(child_cr3);
            unlink_child(child_process);
            process_free_vmas(child_process);
            free_process_object(child_process);
            return -1;
        }
    }
    link_child(child_process, parent);
    spinlock_acquire(&parent->files_lock);
    for (uint32_t i = 0; i < STD_FILE_COUNT; i++) {
        child_process->stdio[i].object = parent->stdio[i].object;
        if (child_process->stdio[i].object != 0)
            file_retain(child_process->stdio[i].object);
    }
    for (uint32_t i = 0; i < MAX_OPEN_FILES; i++) {
        child_process->files[i].object = parent->files[i].object;
        if (child_process->files[i].object != 0) file_retain(child_process->files[i].object);
    }
    spinlock_release(&parent->files_lock);
    child = thread_alloc_for_process(child_process, parent->main_thread->priority);
    if (child == 0) {
        process_close_files(child_process);
        destroy_user_address_space(child_cr3);
        unlink_child(child_process);
        process_free_vmas(child_process);
        free_process_object(child_process);
        return -1;
    }
    child->kernel_stack_top = (uint64_t)child->stack_base + PAGE_SIZE;
    child->user_rsp = thread_current_user_rsp();
    /* fork 已经复制了父线程的 TLS 映射；由地址空间整体回收它，
       不让 thread_free_object 在 child 仍存活时误拆共享副本。 */
    child->tls_base = parent->main_thread->tls_base;
    child->tls_paddr = 0;
    uint64_t child_frame_rsp = child->kernel_stack_top - 14 * sizeof(uint64_t);
    memcpy((void*)child_frame_rsp, (const void*)syscall_frame_rsp,
           14 * sizeof(uint64_t));
    struct thread_context* context =
        (struct thread_context*)(child_frame_rsp - sizeof(struct thread_context));
    memset(context, 0, sizeof(*context));
    context->rip = (uint64_t)syscall_child_return;
    child->rsp = (uint64_t)context;
    thread_append(child);
    return (int)child_process->pid;
}
