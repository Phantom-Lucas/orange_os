#ifndef ORANGES_USER_TEST_H
#define ORANGES_USER_TEST_H

#include "libc.h"

struct user_test_state {
    int passed;
    int failed;
};

#define TEST_ASSERT(state, condition, message) \
    do { \
        if (condition) { (state)->passed++; } \
        else { (state)->failed++; printf("[FAIL] %s\n", (message)); } \
    } while (0)

static inline int test_finish(const char* name, struct user_test_state* state)
{
    printf("%s: %d passed, %d failed\n", name, state->passed, state->failed);
    return state->failed == 0 ? 0 : 1;
}

#endif
