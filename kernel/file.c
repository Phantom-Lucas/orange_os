#include "file.h"

#include "fs.h"
#include "kalloc.h"
#include "string.h"
#include "thread.h"

static uint32_t active_file_objects;
static uint32_t active_pipe_objects;

/*
 * 普通文件的 inode 操作在当前单 CPU 内核中直接执行，并在整个 cache/disk
 * 临界区禁止抢占。这样 syscall 不会在持有 file_object 锁时睡眠；FS 服务
 * 线程仍负责 ELF、目录和路径请求。多进程请求在单 CPU 调度器下天然串行，
 * 以后扩展 SMP 时应把这里的临界区提升为独立 fs_lock。
 */

static void wake_pipe_waiters(struct pipe_object* pipe) {
    if (current_thread == 0 || pipe == 0) return;
    struct thread* scan = current_thread->next;
    while (scan != current_thread) {
        struct thread* next = scan->next;
        if (scan->status == TASK_BLOCKED && scan->waiting_lock == pipe)
            thread_unblock(scan);
        scan = next;
    }
    if (current_thread->status == TASK_BLOCKED && current_thread->waiting_lock == pipe)
        thread_unblock(current_thread);
}

static int pipe_read(struct pipe_object* pipe, void* buffer, uint32_t length) {
    uint8_t* output = (uint8_t*)buffer;
    if (pipe == 0 || buffer == 0) return -1;
    while (1) {
        spinlock_acquire(&pipe->guard);
        if (pipe->count != 0) {
            uint32_t n = length < pipe->count ? length : pipe->count;
            for (uint32_t i = 0; i < n; i++) {
                output[i] = pipe->data[pipe->head];
                pipe->head = (pipe->head + 1) % PIPE_CAPACITY;
            }
            pipe->count -= n;
            wake_pipe_waiters(pipe);
            spinlock_release(&pipe->guard);
            return (int)n;
        }
        if (pipe->writers == 0) {
            spinlock_release(&pipe->guard);
            return 0;
        }
        /* thread_block_with_lock makes the condition check and enqueue atomic. */
        current_thread->waiting_lock = pipe;
        thread_block_with_lock(&pipe->guard);
    }
}

static int pipe_write(struct pipe_object* pipe, const void* buffer, uint32_t length) {
    const uint8_t* input = (const uint8_t*)buffer;
    if (pipe == 0 || buffer == 0) return -1;
    while (1) {
        spinlock_acquire(&pipe->guard);
        if (pipe->readers == 0) {
            spinlock_release(&pipe->guard);
            return -1;
        }
        if (pipe->count < PIPE_CAPACITY) {
            uint32_t n = length < PIPE_CAPACITY - pipe->count ? length : PIPE_CAPACITY - pipe->count;
            for (uint32_t i = 0; i < n; i++) {
                pipe->data[pipe->tail] = input[i];
                pipe->tail = (pipe->tail + 1) % PIPE_CAPACITY;
            }
            pipe->count += n;
            wake_pipe_waiters(pipe);
            spinlock_release(&pipe->guard);
            return (int)n;
        }
        current_thread->waiting_lock = pipe;
        thread_block_with_lock(&pipe->guard);
    }
}

struct file_object* file_regular_create(uint32_t inode_nr) {
    struct file_object* file = (struct file_object*)kmalloc(sizeof(*file));
    if (file == 0) return 0;
    memset(file, 0, sizeof(*file));
    mutex_init(&file->lock);
    file->refs = 1;
    file->inode_nr = inode_nr;
    file->kind = FILE_OBJECT_REGULAR;
    active_file_objects++;
    return file;
}

struct file_object* file_pipe_create(struct pipe_object* pipe,
                                      enum file_object_kind kind) {
    struct file_object* file = (struct file_object*)kmalloc(sizeof(*file));
    if (file == 0) return 0;
    memset(file, 0, sizeof(*file));
    mutex_init(&file->lock);
    file->refs = 1;
    file->kind = kind;
    file->pipe = pipe;
    active_file_objects++;
    return file;
}

void file_retain(struct file_object* file) {
    if (file == 0) return;
    spinlock_acquire(&file->lock.guard);
    file->refs++;
    if (file->pipe != 0) {
        spinlock_acquire(&file->pipe->guard);
        if (file->kind == FILE_OBJECT_PIPE_READ) file->pipe->readers++;
        else file->pipe->writers++;
        spinlock_release(&file->pipe->guard);
    }
    spinlock_release(&file->lock.guard);
}

void file_release(struct file_object* file) {
    uint32_t refs;
    if (file == 0) return;
    spinlock_acquire(&file->lock.guard);
    if (file->refs == 0) { spinlock_release(&file->lock.guard); return; }
    file->refs--;
    refs = file->refs;
    if (file->pipe != 0) {
        struct pipe_object* pipe = file->pipe;
        spinlock_acquire(&pipe->guard);
        if (file->kind == FILE_OBJECT_PIPE_READ && pipe->readers != 0) pipe->readers--;
        if (file->kind == FILE_OBJECT_PIPE_WRITE && pipe->writers != 0) pipe->writers--;
        wake_pipe_waiters(pipe);
        uint32_t empty = pipe->readers == 0 && pipe->writers == 0;
        spinlock_release(&pipe->guard);
        spinlock_release(&file->lock.guard);
        if (refs == 0) {
            if (active_file_objects != 0) active_file_objects--;
            kfree(file);
        }
        if (empty) {
            if (active_pipe_objects != 0) active_pipe_objects--;
            kfree(pipe);
        }
        return;
    }
    spinlock_release(&file->lock.guard);
    if (refs == 0) {
        thread_preempt_disable();
        fs_release_inode(file->inode_nr);
        thread_preempt_enable();
        if (active_file_objects != 0) active_file_objects--;
        kfree(file);
    }
}

int file_read(struct file_object* file, void* buffer, uint32_t length) {
    if (file == 0 || buffer == 0) return -1;
    if (file->kind == FILE_OBJECT_PIPE_READ) return pipe_read(file->pipe, buffer, length);
    if (file->kind != FILE_OBJECT_REGULAR) return -1;
    thread_preempt_disable();
    int result = fs_read_inode(file->inode_nr, file->offset, buffer, length);
    thread_preempt_enable();
    if (result > 0) file->offset += (uint64_t)result;
    return result;
}

int file_write(struct file_object* file, const void* buffer, uint32_t length) {
    if (file == 0 || buffer == 0) return -1;
    if (file->kind == FILE_OBJECT_PIPE_WRITE) return pipe_write(file->pipe, buffer, length);
    if (file->kind != FILE_OBJECT_REGULAR) return -1;
    thread_preempt_disable();
    int result = fs_write_inode(file->inode_nr, file->offset, buffer, length);
    thread_preempt_enable();
    if (result > 0) file->offset += (uint64_t)result;
    return result;
}

int pipe_create(struct file_object** out_read, struct file_object** out_write) {
    struct pipe_object* pipe;
    struct file_object* read_file;
    struct file_object* write_file;
    if (out_read == 0 || out_write == 0) return -1;
    *out_read = 0; *out_write = 0;
    pipe = (struct pipe_object*)kmalloc(sizeof(*pipe));
    if (pipe == 0) return -1;
    memset(pipe, 0, sizeof(*pipe));
    spinlock_init(&pipe->guard);
    pipe->readers = 1; pipe->writers = 1;
    active_pipe_objects++;
    read_file = file_pipe_create(pipe, FILE_OBJECT_PIPE_READ);
    write_file = file_pipe_create(pipe, FILE_OBJECT_PIPE_WRITE);
    if (read_file == 0 || write_file == 0) {
        if (read_file != 0) kfree(read_file);
        if (write_file != 0) kfree(write_file);
        if (active_file_objects >= (read_file != 0) + (write_file != 0))
            active_file_objects -= (read_file != 0) + (write_file != 0);
        if (active_pipe_objects != 0) active_pipe_objects--;
        kfree(pipe);
        return -1;
    }
    *out_read = read_file; *out_write = write_file;
    return 0;
}

void file_get_runtime_stats(struct file_runtime_stats* stats) {
    if (stats == 0) return;
    stats->active_file_objects = active_file_objects;
    stats->active_pipe_objects = active_pipe_objects;
}
