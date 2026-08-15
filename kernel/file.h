#ifndef FILE_H
#define FILE_H

#include <stdint.h>
#include "sync.h"

struct thread;

enum file_object_kind {
    FILE_OBJECT_REGULAR = 1,
    FILE_OBJECT_PIPE_READ,
    FILE_OBJECT_PIPE_WRITE
};

#define PIPE_CAPACITY 4096
#define FILE_OPEN_APPEND 0x04U

struct pipe_object {
    spinlock_t guard;
    uint8_t data[PIPE_CAPACITY];
    uint32_t head;
    uint32_t tail;
    uint32_t count;
    uint32_t readers;
    uint32_t writers;
};

struct file_object {
    mutex_t lock;
    uint32_t refs;
    uint32_t inode_nr;
    uint64_t offset;
    uint32_t flags;
    enum file_object_kind kind;
    struct pipe_object* pipe;
};

/* 仅用于运行时泄漏诊断，不改变文件描述符语义。 */
struct file_runtime_stats {
    uint32_t active_file_objects;
    uint32_t active_pipe_objects;
};

struct file_object* file_regular_create(uint32_t inode_nr);
struct file_object* file_pipe_create(struct pipe_object* pipe,
                                      enum file_object_kind kind);
void file_retain(struct file_object* file);
void file_release(struct file_object* file);
int file_read(struct file_object* file, void* buffer, uint32_t length);
int file_write(struct file_object* file, const void* buffer, uint32_t length);
int pipe_create(struct file_object** out_read, struct file_object** out_write);
void file_get_runtime_stats(struct file_runtime_stats* stats);

#endif
