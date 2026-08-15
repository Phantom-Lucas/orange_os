#include "test.h"

int main(void)
{
    struct user_test_state state = {0, 0};
    char buffer[64];
    char readback[16] = {0};
    user_mutex_t mutex;
    const char payload[] = "test";

    void* memory = malloc(37);
    TEST_ASSERT(&state, memory != 0, "malloc");
    if (memory != 0) {
        memset(memory, 0x5A, 37);
        TEST_ASSERT(&state, ((unsigned char*)memory)[36] == 0x5A, "memset");
        free(memory);
    }
    TEST_ASSERT(&state, snprintf(buffer, sizeof(buffer), "%s:%u", "ok", 7) == 4 &&
                          strcmp(buffer, "ok:7") == 0, "format");

    user_tls_set_custom(0x12345678ULL);
    TEST_ASSERT(&state, user_tls_get_custom() == 0x12345678ULL, "TLS custom value");
    *user_errno_location() = LIBC_EINVAL;
    TEST_ASSERT(&state, errno == LIBC_EINVAL, "TLS errno");

    user_mutex_init(&mutex);
    TEST_ASSERT(&state, user_mutex_lock(&mutex) == 0, "mutex lock");
    TEST_ASSERT(&state, user_mutex_unlock(&mutex) == 0, "mutex unlock");
    TEST_ASSERT(&state, user_mutex_unlock(&mutex) != 0, "duplicate unlock");

    int fd = open("libc-test.tmp", O_CREATE | O_TRUNC);
    TEST_ASSERT(&state, fd >= 0, "open");
    if (fd >= 0) {
        TEST_ASSERT(&state, write(fd, payload, sizeof(payload) - 1) == 4, "write");
        close(fd);
        fd = open("libc-test.tmp", 0);
        TEST_ASSERT(&state, fd >= 0, "reopen");
        if (fd >= 0) {
            TEST_ASSERT(&state, read(fd, readback, sizeof(payload) - 1) == 4 &&
                                  memcmp(readback, payload, 4) == 0, "read");
            close(fd);
        }
    }
    TEST_ASSERT(&state, unlink("libc-test.tmp") == 0, "unlink");
    return test_finish("libc-test", &state);
}
