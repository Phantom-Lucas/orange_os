#ifndef PROCESS_H
#define PROCESS_H

#include <stdint.h>
#include "memory.h"
#include "sync.h"
#include "fs.h"

#define MAX_OPEN_FILES 32
#define FIRST_FILE_FD  3
#define STD_FILE_COUNT 3

struct thread;
struct elf_load_vma;

struct vm_area {
    vaddr_t start;
    vaddr_t end;             /* exclusive */
    uint64_t flags;
    void* file;              /* 目前匿名映射为 NULL，文件映射预留。 */
    uint64_t file_offset;
    struct vm_area* next;
};

#define VM_READ       (1ULL << 0)
#define VM_WRITE      (1ULL << 1)
#define VM_EXEC       (1ULL << 2)
#define VM_GROWSDOWN  (1ULL << 3)
#define VM_ANON       (1ULL << 4)
#define VM_PRIVATE    (1ULL << 5)

#define MMAP_PROT_READ   0x1U
#define MMAP_PROT_WRITE  0x2U
#define MMAP_PROT_EXEC   0x4U
#define MMAP_MAP_PRIVATE 0x02U
#define MMAP_MAP_ANON    0x20U

struct file_object;
struct file_descriptor { struct file_object* object; };

typedef enum {
    PROCESS_RUNNING = 0,
    PROCESS_ZOMBIE,
    PROCESS_DEAD
} process_state_t;

/*
 * 进程对象只保存进程级资源。调度上下文、内核栈和阻塞状态属于 thread。
 * 用户线程共享这里的地址空间和文件表；每个线程自己的调度上下文、
 * 内核栈、用户栈和阻塞状态仍保存在 struct thread 中。
 */
struct process {
    paddr_t object_paddr;

    uint32_t pid;
    process_state_t state;
    int32_t exit_status;
    uint32_t exit_waited;

    paddr_t cr3_paddr;

    struct process* parent;
    struct process* child_head;
    struct process* sibling_next;
    struct process* next_all;

    struct thread* main_thread;
    struct thread* thread_head;
    uint32_t thread_count;
    uint64_t next_thread_stack_top;
    uint64_t next_thread_tls_top;
    uint64_t next_mmap_base;
    uint32_t cwd_inode;
    char cwd_path[FS_PATH_MAX];
    struct vm_area* vma_head;
    uint32_t exit_requested;
    int32_t kill_status;
    /* 只有终端 Shell 能改变 tty foreground_pid；普通用户进程的
       内部 wait/fork 不得覆盖终端前台任务。 */
    uint32_t terminal_controller;
    char name[32];

    /* 锁顺序：address_space_lock -> files_lock -> file_object.lock。 */
    spinlock_t address_space_lock;
    spinlock_t lifecycle_lock;
    spinlock_t files_lock;

    /* 0/1/2 为空时由 syscall 层回退到 TTY；被 dup2 重定向后保存文件对象。 */
    struct file_descriptor stdio[STD_FILE_COUNT];
    struct file_descriptor files[MAX_OPEN_FILES];
};

extern struct process* kernel_process;

void process_init(void);
struct process* process_current(void);
struct process* process_find_by_pid(uint32_t pid);
int process_is_single_threaded(const struct process* process);
int process_discard(struct process* process);
struct process* process_create(void (*app_func)(void), uint32_t priority);
struct process* process_create_loaded(uint64_t entry, uint64_t cr3_paddr,
                                      uint64_t user_rsp, uint32_t priority,
                                      const struct elf_load_vma* vmas,
                                      uint32_t vma_count);
int process_create_thread(struct process* process, uint64_t entry,
                          uint64_t arg, uint32_t* out_tid);
void process_exit(int status);
int process_wait(uint32_t pid, int* status, uint32_t options);
int process_fork(uint64_t syscall_frame_rsp);
int process_mmap(struct process* process, vaddr_t hint, uint64_t length,
                 uint32_t prot, uint32_t flags, vaddr_t* out_address);
int process_munmap(struct process* process, vaddr_t address, uint64_t length);
int process_handle_page_fault(struct process* process, vaddr_t address,
                              uint64_t error_code);
int process_add_vma(struct process* process, vaddr_t start, vaddr_t end,
                    uint64_t flags, uint64_t file_offset);
void process_free_vmas(struct process* process);
void process_reap_orphans(void);

struct process_runtime_stats {
    uint32_t processes;
    uint32_t running_processes;
    uint32_t zombie_processes;
    uint32_t threads;
};

struct process_info {
    uint32_t pid;
    uint32_t ppid;
    uint32_t state;
    uint32_t threads;
    uint32_t user_pages;
    uint32_t name_length;
    char name[32];
};

void process_get_runtime_stats(struct process_runtime_stats* stats);
void process_dump_runtime_stats(const char* tag);
uint32_t process_snapshot(struct process_info* out, uint32_t capacity);
int process_request_kill(uint32_t pid, int status);
/* 终端控制键使用的前台终止请求；允许目标就是当前进程。 */
int process_request_terminal_signal(uint32_t pid, int status);

#define USER_TLS_PAGE_SIZE PAGE_SIZE
int process_allocate_thread_tls(struct process* process, struct thread* thread);

#endif
