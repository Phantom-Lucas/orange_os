// kernel/syscall.c
#include "syscall.h"
#include "print.h"
#include "memory.h"
#include "timer.h"
#include "tty.h"
#include "fs.h"
#include "thread.h"
#include "string.h"
#include "elf.h"
#include "ipc.h"
#include "kalloc.h"
#include "futex.h"
#include "file.h"
#include "process.h"

// 硬件规定的 4 个 MSR 寄存器地址
#define MSR_EFER           0xC0000080
#define MSR_STAR           0xC0000081
#define MSR_LSTAR          0xC0000082
#define MSR_FMASK          0xC0000084
// 内核 GS 基址寄存器 (用于 swapgs)
#define MSR_KERNEL_GS_BASE 0xC0000102 

// 声明即将用汇编写的传送门函数
extern void syscall_entry(void);
extern void set_user_fs_base(uint64_t base);

/* 当前内核是单 CPU；系统调用不会嵌套执行，exec 参数暂存放在专用
 * 内核缓冲区，避免把 4KiB 内核栈压爆。多 CPU 时应改为 per-CPU。 */
static char exec_argument_storage[ELF_MAX_ARGS][FS_PATH_MAX];
static const char* exec_argument_pointers[ELF_MAX_ARGS];

// 定义每 CPU (Per-CPU) 的局部数据结构
// 注意：内存布局必须严格，汇编里依靠硬编码的偏移量 (0x0 和 0x8) 来读写
struct cpu_local_data {
    uint64_t kernel_rsp; // 偏移 0x0：当前线程的内核栈
    uint64_t user_rsp;   // 偏移 0x8：用来临时保存用户的栈
};

// 全局实例化一个 cpu 数据结构 (目前是单核，所以一个就够了)
struct cpu_local_data current_cpu;

// 读写 MSR 的内置汇编函数
static inline void wrmsr(uint32_t msr, uint64_t val) {
    uint32_t low = (uint32_t)val;
    uint32_t high = (uint32_t)(val >> 32);
    __asm__ volatile("wrmsr" : : "c"(msr), "a"(low), "d"(high));
}

static inline uint64_t rdmsr(uint32_t msr) {
    uint32_t low, high;
    __asm__ volatile("rdmsr" : "=a"(low), "=d"(high) : "c"(msr));
    return ((uint64_t)high << 32) | low;
}

// ==========================================
// 1. 初始化系统调用机制
// ==========================================
void syscall_init() {
    // 1. 开启 EFER 寄存器中的 SCE (System Call Enable) 位
    uint64_t efer = rdmsr(MSR_EFER);
    wrmsr(MSR_EFER, efer | 1);
    
    // 2. 配置 STAR 寄存器 (内核段 0x08，用户段基址 0x10)
    wrmsr(MSR_STAR, (0x10ULL << 48) | (0x08ULL << 32));
    
    // 3. 配置 LSTAR 寄存器 (syscall 触发后跳转的内核入口点)
    wrmsr(MSR_LSTAR, (uint64_t)syscall_entry);
    
    // 4. 配置 FMASK 寄存器 (进入内核时，自动屏蔽 IF 中断位 0x200)
    wrmsr(MSR_FMASK, 0x200); 

    // 5. 【极其关键】：把 current_cpu 结构体的地址绑定到 KERNEL_GS_BASE
    wrmsr(MSR_KERNEL_GS_BASE, (uint64_t)&current_cpu);
}

// ==========================================
// 2. 真正的系统调用处理中心 (由汇编传送门调用)
// ==========================================
static uint64_t read_cr3(void) {
    uint64_t cr3;
    __asm__ volatile("mov %%cr3, %0" : "=r"(cr3));
    return cr3 & PTE_ADDR_MASK;
}

static void write_cr3(uint64_t cr3)
{
    __asm__ volatile(
        "mov %0, %%cr3"
        :
        : "r"(cr3)
        : "memory"
    );
}

static uint64_t get_current_cr3(void)
{
    uint64_t value;

    __asm__ volatile(
        "mov %%cr3, %0"
        : "=r"(value)
    );

    return value & PTE_ADDR_MASK;
}

static struct file_object* get_file_object(uint64_t fd) {
    if (!current_thread || fd >= FIRST_FILE_FD + MAX_OPEN_FILES) {
        return 0;
    }
    struct process* process = current_thread->process;
    struct file_object* object;
    spinlock_acquire(&process->files_lock);
    object = fd < STD_FILE_COUNT ? process->stdio[fd].object :
             process->files[fd - FIRST_FILE_FD].object;
    if (object != 0) file_retain(object);
    spinlock_release(&process->files_lock);
    return object;
}

static struct file_object* detach_file_object(uint64_t fd) {
    if (!current_thread || fd >= FIRST_FILE_FD + MAX_OPEN_FILES) return 0;
    struct process* process = current_thread->process;
    struct file_object* object;
    spinlock_acquire(&process->files_lock);
    if (fd < STD_FILE_COUNT) {
        object = process->stdio[fd].object;
        process->stdio[fd].object = 0;
    } else {
        object = process->files[fd - FIRST_FILE_FD].object;
        process->files[fd - FIRST_FILE_FD].object = 0;
    }
    spinlock_release(&process->files_lock);
    return object;
}

static int install_file_object(struct process* process, struct file_object* object,
                               int requested) {
    uint32_t begin = requested < 0 ? 0 : (uint32_t)requested;
    if (process == 0 || object == 0 ||
        (requested < 0 && begin >= MAX_OPEN_FILES) ||
        (requested >= 0 && (uint32_t)requested >= FIRST_FILE_FD + MAX_OPEN_FILES))
        return -1;
    spinlock_acquire(&process->files_lock);
    if (requested >= 0) {
        if (requested >= STD_FILE_COUNT) {
            begin = (uint32_t)requested - FIRST_FILE_FD;
            if (begin >= MAX_OPEN_FILES || process->files[begin].object != 0) {
                spinlock_release(&process->files_lock); return -1;
            }
            process->files[begin].object = object;
        } else {
            if (process->stdio[requested].object != 0) {
                spinlock_release(&process->files_lock); return -1;
            }
            process->stdio[requested].object = object;
        }
        spinlock_release(&process->files_lock);
        return requested;
    }
    for (uint32_t i = 0; i < MAX_OPEN_FILES; i++) {
        if (process->files[i].object == 0) {
            process->files[i].object = object;
            spinlock_release(&process->files_lock);
            return (int)(FIRST_FILE_FD + i);
        }
    }
    spinlock_release(&process->files_lock);
    return -1;
}

static struct file_object** file_slot_locked(struct process* process,
                                             uint64_t fd) {
    if (process == 0 || fd >= FIRST_FILE_FD + MAX_OPEN_FILES) return 0;
    return fd < STD_FILE_COUNT ? &process->stdio[fd].object :
           &process->files[fd - FIRST_FILE_FD].object;
}

/* The old requested-fd branch is intentionally kept in install_file_object;
   this helper centralizes dup2's standard-fd and regular-fd address mapping. */
static int valid_file_fd(uint64_t fd) {
    return fd < FIRST_FILE_FD + MAX_OPEN_FILES;
}

static int file_is_regular(struct file_object* object) {
    return object != 0 && object->kind == FILE_OBJECT_REGULAR;
}

/* FS 服务可能调度当前进程；与 wait/TTY 路径一样，在阻塞区间恢复用户 GS。 */
static int fs_call_from_user(struct fs_request* request) {
    __asm__ volatile("swapgs" ::: "memory");
    int result = fs_service_call(request);
    __asm__ volatile("swapgs" ::: "memory");
    return result;
}

static int tty_write_from_user(const char* buffer, unsigned long length) {
    __asm__ volatile("swapgs" ::: "memory");
    int result = tty_service_write(buffer, length);
    __asm__ volatile("swapgs" ::: "memory");
    return result;
}

static int copy_exec_arguments(uint64_t user_argv,
                               char arguments[ELF_MAX_ARGS][FS_PATH_MAX],
                               const char* pointers[ELF_MAX_ARGS],
                               uint32_t* out_count)
{
    uint32_t count = 0;
    if (out_count == 0) return -1;
    if (user_argv == 0) {
        *out_count = 0;
        return 0;
    }
    while (count < ELF_MAX_ARGS) {
        uint64_t user_string;
        uint64_t slot = user_argv + (uint64_t)count * sizeof(uint64_t);
        if (slot < user_argv || !user_range_is_readable(read_cr3(), slot,
                                                         sizeof(user_string)) ||
            copy_from_user(&user_string, slot, sizeof(user_string)) != 0) {
            return -1;
        }
        if (user_string == 0) {
            *out_count = count;
            return 0;
        }
        if (copy_string_from_user(arguments[count], user_string,
                                  FS_PATH_MAX) != 0) return -1;
        pointers[count] = arguments[count];
        count++;
    }
    return -1;
}

static uint64_t syscall_handler_impl(uint64_t sys_num, uint64_t arg1,
                                     uint64_t arg2, uint64_t arg3,
                                     uint64_t syscall_frame_rsp) {
    switch (sys_num) {
    case SYS_WRITE:
        if (arg3 > 4096) {
            return SYSCALL_ERR_INVAL;
        }
        struct file_object* redirected =
            (arg1 == 1 || arg1 == 2) ? get_file_object(arg1) : 0;
        if ((arg1 == 1 || arg1 == 2) && redirected == 0) {
            if (arg3 == 0) return 0;
            uint8_t* staging = (uint8_t*)kmalloc(arg3);
            if (!staging) return SYSCALL_ERR_INVAL;
            if (copy_from_user(staging, arg2, arg3) != 0) {
                kfree(staging);
                return SYSCALL_ERR_INVAL;
            }
            int written = tty_write_from_user((const char*)staging, arg3);
            kfree(staging);
            return written == 0 ? arg3 : SYSCALL_ERR_INVAL;
        }
        {
            struct file_object* file = redirected != 0 ? redirected :
                                       get_file_object(arg1);
            if (!file) return SYSCALL_ERR_INVAL;
            if (arg3 == 0) { file_release(file); return 0; }
            uint8_t* staging = (uint8_t*)kmalloc(arg3);
            if (!staging) { file_release(file); return SYSCALL_ERR_INVAL; }
            if (copy_from_user(staging, arg2, arg3) != 0) {
                file_release(file); kfree(staging);
                return SYSCALL_ERR_INVAL;
            }
            if (file_is_regular(file)) mutex_acquire(&file->lock);
            if (!file_is_regular(file)) __asm__ volatile("swapgs" ::: "memory");
            int written = file_write(file, staging, (uint32_t)arg3);
            if (!file_is_regular(file)) __asm__ volatile("swapgs" ::: "memory");
            if (file_is_regular(file)) mutex_release(&file->lock);
            file_release(file);
            kfree(staging);
            return written < 0 ? SYSCALL_ERR_INVAL : (uint64_t)written;
        }

    case SYS_GET_TICKS:
        return system_ticks;

    case SYS_GETPID:
        return current_thread == 0 || current_thread->process == 0
                   ? SYSCALL_ERR_INVAL : current_thread->process->pid;

    case SYS_SLEEP:
        if (current_thread == 0 || current_thread->process == kernel_process) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        thread_sleep_ticks(arg1);
        __asm__ volatile("swapgs" ::: "memory");
        /* Ctrl+C/SIGTERM 可能在睡眠期间取消等待并把线程唤醒；不能让
           被标记终止的线程继续回到用户态并以正常码覆盖 kill_status。 */
        if (current_thread->process != 0 &&
            current_thread->process->exit_requested) {
            __asm__ volatile("swapgs" ::: "memory");
            process_exit(current_thread->process->kill_status);
        }
        return 0;

    case SYS_KILL: {
        uint32_t pid = (uint32_t)arg1;
        int signal = (int)arg2;
        if (arg1 != pid || signal <= 0 || signal > 64 ||
            process_find_by_pid(pid) == 0) return SYSCALL_ERR_INVAL;
        if (current_thread != 0 && current_thread->process != kernel_process &&
            current_thread->process->pid == pid) {
            __asm__ volatile("swapgs" ::: "memory");
            process_exit(128 + signal);
        }
        return process_request_kill(pid, 128 + signal) == 0
                   ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_PS: {
        uint64_t bytes;
        uint8_t* staging;
        uint32_t count = (uint32_t)arg2;
        uint32_t copied;
        if (arg2 != count || count > 64 ||
            count > UINT64_MAX / sizeof(struct process_info)) {
            return SYSCALL_ERR_INVAL;
        }
        bytes = (uint64_t)count * sizeof(struct process_info);
        if (count == 0) return 0;
        if (arg1 == 0 || !user_range_is_writable(read_cr3(), arg1, bytes)) {
            return SYSCALL_ERR_INVAL;
        }
        staging = (uint8_t*)kmalloc(bytes);
        if (staging == 0) return SYSCALL_ERR_INVAL;
        copied = process_snapshot((struct process_info*)staging, count);
        if (copy_to_user(arg1, staging,
                         (uint64_t)copied * sizeof(struct process_info)) != 0) {
            kfree(staging);
            return SYSCALL_ERR_INVAL;
        }
        kfree(staging);
        return copied;
    }

    case SYS_CLEAR:
        tty_clear_active();
        return 0;

    case SYS_OPEN: {
        char name[FS_PATH_MAX];
        if (copy_string_from_user(name, arg1, sizeof(name)) != 0 ||
            !current_thread) return SYSCALL_ERR_INVAL;
        struct fs_request request = {0};
        request.operation = FS_REQUEST_OPEN;
        request.flags = (uint32_t)arg2;
        strcpy(request.name, name);
        request.cwd_inode = current_thread->process->cwd_inode;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        if (fs_call_from_user(&request) != 0) return SYSCALL_ERR_INVAL;
        struct file_object* file = file_regular_create(request.inode_nr);
        if (file == 0) {
            request.operation = FS_REQUEST_RELEASE;
            (void)fs_call_from_user(&request);
            return SYSCALL_ERR_INVAL;
        }
        file->flags = (uint32_t)arg2;
        if ((file->flags & FILE_OPEN_APPEND) != 0) {
            file->offset = request.stat_size;
        }
        int fd = install_file_object(current_thread->process, file, -1);
        if (fd < 0) {
            file_release(file);
            return SYSCALL_ERR_INVAL;
        }
        return (uint64_t)fd;
    }

    case SYS_READ: {
        if (arg3 > 4096) {
            return SYSCALL_ERR_INVAL;
        }
        if (arg3 == 0) {
            return 0;
        }
        /* 先完整验证输出范围，再进入可能阻塞的设备/文件路径。 */
        if (!user_range_is_writable(read_cr3(), arg2, arg3)) {
            return SYSCALL_ERR_INVAL;
        }
        struct file_object* file = get_file_object(arg1);
        if (arg1 == 0 && file == 0) {
            uint8_t* staging = (uint8_t*)kmalloc(arg3);
            int read;
            if (staging == 0) return SYSCALL_ERR_INVAL;
            /* TTY 请求会阻塞当前用户进程；调度期间保持与 wait 相同的 GS 约定。 */
            __asm__ volatile("swapgs" ::: "memory");
            read = tty_service_read((char*)staging, arg3);
            __asm__ volatile("swapgs" ::: "memory");
            if (read <= 0 || (unsigned long)read > arg3) {
                kfree(staging);
                return SYSCALL_ERR_INVAL;
            }
            if (copy_to_user(arg2, staging, (unsigned long)read) != 0) {
                kfree(staging);
                return SYSCALL_ERR_INVAL;
            }
            kfree(staging);
            return (uint64_t)read;
        }
        if (!file) return SYSCALL_ERR_INVAL;
        uint8_t* staging = (uint8_t*)kmalloc(arg3);
        if (!staging) return SYSCALL_ERR_INVAL;
        if (file_is_regular(file)) mutex_acquire(&file->lock);
        if (!file_is_regular(file)) __asm__ volatile("swapgs" ::: "memory");
        int read = file_read(file, staging, (uint32_t)arg3);
        if (!file_is_regular(file)) __asm__ volatile("swapgs" ::: "memory");
        if (read > 0 && copy_to_user(arg2, staging, (unsigned long)read) != 0) {
            if (file_is_regular(file)) mutex_release(&file->lock);
            file_release(file);
            kfree(staging);
            return SYSCALL_ERR_INVAL;
        }
        kfree(staging);
        if (file_is_regular(file)) mutex_release(&file->lock);
        file_release(file);
        return read < 0 ? SYSCALL_ERR_INVAL : (uint64_t)read;
    }

    case SYS_CLOSE: {
        struct file_object* file = detach_file_object(arg1);
        if (!file) return SYSCALL_ERR_INVAL;
        file_release(file);
        return 0;
    }

    case SYS_UNLINK: {
        char name[FS_PATH_MAX];
        if (copy_string_from_user(name, arg1, sizeof(name)) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        struct fs_request request = {0};
        request.operation = FS_REQUEST_UNLINK;
        strcpy(request.name, name);
        request.cwd_inode = current_thread->process->cwd_inode;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        return fs_call_from_user(&request) == 0 ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_EXIT:
        /* exit 不会回到 syscall_entry。先恢复用户 GS 状态，避免下一个
           被调度到 Ring 3 的进程把 current_cpu 当成用户 GS 基址。 */
        __asm__ volatile("swapgs" ::: "memory");
        process_exit((int)arg1);
        return 0;

    case SYS_WAIT: {
        int status;
        /* 先验证输出地址，避免非法指针导致已经回收子进程却无法返回状态。 */
        if (arg2 != 0 &&
            !user_range_is_writable(read_cr3(), arg2, sizeof(status))) {
            return SYSCALL_ERR_INVAL;
        }
        /* wait 可能在 syscall 内切走当前进程；切走前后成对恢复 GS 状态。 */
        __asm__ volatile("swapgs" ::: "memory");
        int pid = process_wait((uint32_t)arg1, &status, (uint32_t)arg3);
        __asm__ volatile("swapgs" ::: "memory");
        if (pid < 0) return SYSCALL_ERR_INVAL;
        if (arg2 != 0) {
            if (copy_to_user(arg2, &status, sizeof(status)) != 0) {
                return SYSCALL_ERR_INVAL;
            }
        }
        return (uint64_t)pid;
    }

    case SYS_SPAWN: {
        char name[FS_PATH_MAX];
        uint32_t argc;
        if (copy_string_from_user(name, arg1, sizeof(name)) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        if (copy_exec_arguments(arg2, exec_argument_storage,
                                exec_argument_pointers, &argc) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        int pid = execute_elf_args(name, exec_argument_pointers, argc);
        __asm__ volatile("swapgs" ::: "memory");
        return pid < 0 ? SYSCALL_ERR_INVAL : (uint64_t)pid;
    }

    case SYS_LIST:
        if (arg2 > 4096) {
            return SYSCALL_ERR_INVAL;
        }
        if (arg2 != 0 && !user_range_is_writable(read_cr3(), arg1, arg2)) {
            return SYSCALL_ERR_INVAL;
        }
        {
            if (arg2 == 0) return 0;
            uint8_t* staging = (uint8_t*)kmalloc(arg2);
            if (!staging) return SYSCALL_ERR_INVAL;
            struct fs_request request = {0};
            request.operation = FS_REQUEST_LIST;
            request.length = (uint32_t)arg2;
            request.buffer = staging;
            strcpy(request.name, ".");
            request.cwd_inode = current_thread->process->cwd_inode;
            strcpy(request.cwd_path, current_thread->process->cwd_path);
            int listed = fs_call_from_user(&request);
            if (listed > 0 &&
                ((uint64_t)listed > arg2 ||
                 copy_to_user(arg1, staging, (unsigned long)listed) != 0)) {
                kfree(staging);
                return SYSCALL_ERR_INVAL;
            }
            kfree(staging);
            return listed < 0 ? SYSCALL_ERR_INVAL : (uint64_t)listed;
        }

    case SYS_MKDIR: {
        char path[FS_PATH_MAX];
        if (copy_string_from_user(path, arg1, sizeof(path)) != 0) return SYSCALL_ERR_INVAL;
        struct fs_request request = {0};
        request.operation = FS_REQUEST_MKDIR;
        strcpy(request.name, path);
        request.cwd_inode = current_thread->process->cwd_inode;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        return fs_call_from_user(&request) == 0 ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_STAT: {
        struct {
            uint32_t inode;
            uint32_t type;
            uint64_t size;
            uint32_t links;
        } stat;
        char path[FS_PATH_MAX];
        if (copy_string_from_user(path, arg1, sizeof(path)) != 0 ||
            !user_range_is_writable(read_cr3(), arg2, sizeof(stat))) return SYSCALL_ERR_INVAL;
        struct fs_request request = {0};
        request.operation = FS_REQUEST_STAT; strcpy(request.name, path);
        request.cwd_inode = current_thread->process->cwd_inode;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        if (fs_call_from_user(&request) < 0) return SYSCALL_ERR_INVAL;
        stat.inode = request.result_inode; stat.type = request.result_type;
        stat.size = request.stat_size; stat.links = request.stat_links;
        return copy_to_user(arg2, &stat, sizeof(stat)) == 0 ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_CHDIR: {
        char path[FS_PATH_MAX];
        if (copy_string_from_user(path, arg1, sizeof(path)) != 0) return SYSCALL_ERR_INVAL;
        struct fs_request request = {0};
        request.operation = FS_REQUEST_CHDIR; strcpy(request.name, path);
        request.cwd_inode = current_thread->process->cwd_inode;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        if (fs_call_from_user(&request) != 0) return SYSCALL_ERR_INVAL;
        spinlock_acquire(&current_thread->process->files_lock);
        current_thread->process->cwd_inode = request.result_inode;
        strcpy(current_thread->process->cwd_path, request.result_path);
        spinlock_release(&current_thread->process->files_lock);
        return 0;
    }

    case SYS_GETCWD: {
        if (arg3 != 0 || arg2 == 0 || arg2 > FS_PATH_MAX ||
            !user_range_is_writable(read_cr3(), arg1, arg2)) return SYSCALL_ERR_INVAL;
        char* staging = (char*)kmalloc(arg2);
        if (staging == 0) return SYSCALL_ERR_INVAL;
        struct fs_request request = {0};
        request.operation = FS_REQUEST_GETCWD; request.buffer = (uint8_t*)staging;
        request.length = (uint32_t)arg2;
        strcpy(request.cwd_path, current_thread->process->cwd_path);
        int result = fs_call_from_user(&request);
        if (result >= 0 && copy_to_user(arg1, staging, arg2) != 0) result = -1;
        kfree(staging);
        return result < 0 ? SYSCALL_ERR_INVAL : (uint64_t)result;
    }

    case SYS_DUP: {
        struct file_object* object = get_file_object(arg1);
        if (object == 0) return SYSCALL_ERR_INVAL;
        int fd = install_file_object(current_thread->process, object, -1);
        if (fd < 0) file_release(object);
        return fd < 0 ? SYSCALL_ERR_INVAL : (uint64_t)fd;
    }

    case SYS_DUP2: {
        struct process* process = current_thread->process;
        uint64_t newfd = arg2;
        if (!valid_file_fd(arg1) || !valid_file_fd(newfd)) return SYSCALL_ERR_INVAL;
        if (arg1 == newfd) {
            struct file_object* same = get_file_object(arg1);
            if (same == 0) return SYSCALL_ERR_INVAL;
            file_release(same);
            return newfd;
        }
        spinlock_acquire(&process->files_lock);
        struct file_object** source = file_slot_locked(process, arg1);
        struct file_object** target = file_slot_locked(process, newfd);
        struct file_object* object = source == 0 ? 0 : *source;
        if (object != 0) file_retain(object);
        struct file_object* replaced = target == 0 ? 0 : *target;
        if (object != 0 && target != 0) *target = object;
        spinlock_release(&process->files_lock);
        if (object == 0) return SYSCALL_ERR_INVAL;
        if (replaced != 0) file_release(replaced);
        return newfd;
    }

    case SYS_PIPE: {
        struct file_object* read_file;
        struct file_object* write_file;
        int fds[2];
        if (!user_range_is_writable(read_cr3(), arg1, sizeof(fds)) || pipe_create(&read_file, &write_file) != 0)
            return SYSCALL_ERR_INVAL;
        fds[0] = install_file_object(current_thread->process, read_file, -1);
        if (fds[0] < 0) { file_release(read_file); file_release(write_file); return SYSCALL_ERR_INVAL; }
        fds[1] = install_file_object(current_thread->process, write_file, -1);
        if (fds[1] < 0) { file_release(read_file); (void)detach_file_object((uint64_t)fds[0]); file_release(write_file); return SYSCALL_ERR_INVAL; }
        if (copy_to_user(arg1, fds, sizeof(fds)) != 0) {
            (void)detach_file_object((uint64_t)fds[0]); file_release(read_file);
            (void)detach_file_object((uint64_t)fds[1]); file_release(write_file);
            return SYSCALL_ERR_INVAL;
        }
        return 0;
    }

    case SYS_EXEC: {
        char name[FS_PATH_MAX];
        uint32_t argc;
        uint64_t entry;
        uint64_t cr3;
        uint64_t stack;
        struct elf_load_vma vmas[ELF_MAX_LOAD_VMAS];
        uint32_t vma_count = 0;
        struct process* prepared_vmas;

        /* 当前 exec 只支持单线程进程，避免替换共享地址空间时留下线程。 */
        if (!process_is_single_threaded(process_current())) {
            return SYSCALL_ERR_INVAL;
        }

        if (copy_string_from_user(name, arg1, sizeof(name)) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        if (copy_exec_arguments(arg2, exec_argument_storage,
                                exec_argument_pointers, &argc) != 0) {
            return SYSCALL_ERR_INVAL;
        }

        __asm__ volatile("swapgs" ::: "memory");
        int loaded = elf_load_image_args(name, exec_argument_pointers, argc, &entry, &cr3,
                                         &stack, vmas, &vma_count);
        __asm__ volatile("swapgs" ::: "memory");

        if (!loaded) {
            return SYSCALL_ERR_INVAL;
        }

        uint64_t old_cr3 =
            current_thread->process->cr3_paddr & PTE_ADDR_MASK;

        uint64_t new_cr3 =
            cr3 & PTE_ADDR_MASK;
        prepared_vmas = (struct process*)kmalloc(sizeof(struct process));
        if (prepared_vmas == 0) {
            destroy_user_address_space(new_cr3);
            return SYSCALL_ERR_INVAL;
        }
        memset(prepared_vmas, 0, sizeof(*prepared_vmas));
        /* 先在临时链表中完整准备新 VMA，失败时旧地址空间不受影响。 */
        for (uint32_t i = 0; i < vma_count; i++) {
            uint64_t flags = VM_PRIVATE;
            if (vmas[i].flags & 0x4) flags |= VM_READ;
            if (vmas[i].flags & 0x2) flags |= VM_WRITE;
            if (vmas[i].flags & 0x1) flags |= VM_EXEC;
            if (process_add_vma(prepared_vmas, vmas[i].start,
                                vmas[i].end, flags,
                                vmas[i].file_offset) != 0) {
                process_free_vmas(prepared_vmas);
                kfree(prepared_vmas);
                destroy_user_address_space(new_cr3);
                return SYSCALL_ERR_INVAL;
            }
        }
        uint64_t stack_top = (stack & ~(PAGE_SIZE - 1)) + PAGE_SIZE;
        if (process_add_vma(prepared_vmas,
                            stack_top - 8 * 1024 * 1024ULL, stack_top,
                            VM_READ | VM_WRITE | VM_GROWSDOWN |
                            VM_ANON | VM_PRIVATE, 0) != 0) {
            process_free_vmas(prepared_vmas);
            kfree(prepared_vmas);
            destroy_user_address_space(new_cr3);
            return SYSCALL_ERR_INVAL;
        }
        current_thread->process->cr3_paddr = new_cr3;
        if (process_allocate_thread_tls(current_thread->process,
                                         current_thread) != 0) {
            current_thread->process->cr3_paddr = old_cr3;
            process_free_vmas(prepared_vmas);
            kfree(prepared_vmas);
            destroy_user_address_space(new_cr3);
            return SYSCALL_ERR_INVAL;
        }
        struct vm_area* old_vmas = current_thread->process->vma_head;
        current_thread->process->vma_head = prepared_vmas->vma_head;
        prepared_vmas->vma_head = old_vmas;
        {
            const char* base = name;
            uint32_t length = 0;
            const char* scan = name;
            while (*scan != '\0') {
                if (*scan == '/' && *(scan + 1) != '\0') base = scan + 1;
                scan++;
            }
            while (base[length] != '\0' && length + 1 < sizeof(current_thread->process->name)) {
                current_thread->process->name[length] = base[length];
                length++;
            }
            current_thread->process->name[length] = '\0';
        }
        write_cr3(new_cr3);
        destroy_user_address_space(old_cr3);
        thread_set_current_user_rsp(stack);
        process_free_vmas(prepared_vmas);
        kfree(prepared_vmas);
        set_user_fs_base(current_thread->tls_base);
        resume_user_image(entry, stack, new_cr3);
        return SYSCALL_ERR_INVAL;
    }

    case SYS_FORK: {
        int pid = process_fork(syscall_frame_rsp);
        return pid < 0 ? SYSCALL_ERR_INVAL : (uint64_t)pid;
    }

    case SYS_SEND: {
        struct message message;
        if (arg1 == 0 || arg1 != (uint64_t)(uint32_t)arg1 ||
            !user_range_is_readable(read_cr3(), arg2, sizeof(message))) {
            return SYSCALL_ERR_INVAL;
        }
        struct thread* destination = thread_find_by_pid((uint32_t)arg1);
        if (!destination || destination->kernel_stack_top == 0 || destination == current_thread) {
            return SYSCALL_ERR_INVAL;
        }
        if (copy_from_user(&message, arg2, sizeof(message)) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        int result = ipc_send(destination, &message);
        __asm__ volatile("swapgs" ::: "memory");
        return result == 0 ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_RECEIVE: {
        struct message message;
        int32_t source_pid = (int32_t)arg1;
        if (arg2 == 0 || arg1 != (uint64_t)(int64_t)source_pid || source_pid < IPC_ANY ||
            !user_range_is_writable(read_cr3(), arg2, sizeof(message))) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        int result = ipc_receive(source_pid, &message);
        __asm__ volatile("swapgs" ::: "memory");
        if (result != 0) return SYSCALL_ERR_INVAL;
        return copy_to_user(arg2, &message, sizeof(message)) == 0
                   ? 0 : SYSCALL_ERR_INVAL;
    }

    case SYS_THREAD_CREATE: {
        uint32_t tid;
        if (current_thread == 0 || current_thread->process == kernel_process ||
            arg1 == 0 ||
            !user_range_is_readable(read_cr3(), arg1, 1)) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        int result = process_create_thread(process_current(), arg1, arg2, &tid);
        __asm__ volatile("swapgs" ::: "memory");
        return result == 0 ? tid : SYSCALL_ERR_INVAL;
    }

    case SYS_THREAD_JOIN: {
        int status;
        struct thread* target;
        if (current_thread == 0 || current_thread->process == kernel_process ||
            arg1 == 0 ||
            (arg2 != 0 && !user_range_is_writable(read_cr3(), arg2,
                                                   sizeof(status)))) {
            return SYSCALL_ERR_INVAL;
        }
        target = thread_find_by_tid(process_current(), (uint32_t)arg1);
        if (target == 0 || target == current_thread) return SYSCALL_ERR_INVAL;
        __asm__ volatile("swapgs" ::: "memory");
        int result = thread_join(target, &status);
        __asm__ volatile("swapgs" ::: "memory");
        if (result != 0) return SYSCALL_ERR_INVAL;
        if (arg2 != 0 && copy_to_user(arg2, &status, sizeof(status)) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        return 0;
    }

    case SYS_THREAD_EXIT:
        __asm__ volatile("swapgs" ::: "memory");
        thread_exit_with_status((int)arg1);

    case SYS_GETTID:
        return current_thread == 0 ? SYSCALL_ERR_INVAL : current_thread->tid;

    case SYS_FUTEX_WAIT: {
        int result;
        if (current_thread == 0 || current_thread->process == kernel_process) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        result = futex_wait(process_current(), arg1, (uint32_t)arg2);
        __asm__ volatile("swapgs" ::: "memory");
        return result;
    }

    case SYS_FUTEX_WAKE: {
        int result;
        if (current_thread == 0 || current_thread->process == kernel_process) {
            return SYSCALL_ERR_INVAL;
        }
        __asm__ volatile("swapgs" ::: "memory");
        result = futex_wake(process_current(), arg1, (uint32_t)arg2);
        __asm__ volatile("swapgs" ::: "memory");
        return result;
    }

    case SYS_THREAD_DETACH: {
        struct thread* target;
        int result;
        if (current_thread == 0 || current_thread->process == kernel_process ||
            arg1 == 0) return SYSCALL_ERR_INVAL;
        target = thread_find_by_tid(process_current(), (uint32_t)arg1);
        if (target == 0 || target == current_thread) return SYSCALL_ERR_INVAL;
        __asm__ volatile("swapgs" ::: "memory");
        result = thread_detach(target);
        __asm__ volatile("swapgs" ::: "memory");
        return result;
    }

    case SYS_THREAD_YIELD:
        if (current_thread == 0) return SYSCALL_ERR_INVAL;
        __asm__ volatile("swapgs" ::: "memory");
        thread_yield();
        __asm__ volatile("swapgs" ::: "memory");
        return 0;

    case SYS_MMAP: {
        vaddr_t address = 0;
        uint32_t prot = (uint32_t)(arg3 & 0xFFU);
        uint32_t flags = (uint32_t)((arg3 >> 8) & 0xFFU);
        if (process_mmap(current_thread == 0 ? 0 : current_thread->process,
                         arg1, arg2, prot, flags, &address) != 0) {
            return SYSCALL_ERR_INVAL;
        }
        return address;
    }

    case SYS_MUNMAP:
        return process_munmap(current_thread == 0 ? 0 : current_thread->process,
                              arg1, arg2) == 0 ? 0 : SYSCALL_ERR_INVAL;

    default:
        return SYSCALL_ERR_INVAL;
    }
}

uint64_t syscall_handler(uint64_t sys_num, uint64_t arg1, uint64_t arg2,
                         uint64_t arg3, uint64_t syscall_frame_rsp)
{
    uint64_t result = syscall_handler_impl(sys_num, arg1, arg2, arg3,
                                           syscall_frame_rsp);
    /* 终端 Ctrl+C、kill 或父进程退出可能在当前系统调用阻塞期间标记
       当前进程；统一出口保证 TTY/IPC/管道等唤醒路径都不会恢复用户态。 */
    if (current_thread != 0 && current_thread->process != 0 &&
        current_thread->process != kernel_process &&
        current_thread->process->exit_requested) {
        __asm__ volatile("swapgs" ::: "memory");
        process_exit(current_thread->process->kill_status);
    }
    return result;
}
