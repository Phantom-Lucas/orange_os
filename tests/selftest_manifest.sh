#!/usr/bin/env bash

selftest_pass() {
    : >"$RUNNER_SELFTEST_MARKER"
    : >"$TEST_WORK_DIR/pass-created"
}

selftest_fail() {
    : >"$RUNNER_SELFTEST_MARKER"
    return 1
}

selftest_timeout() {
    sleep 3
}

selftest_term() {
    trap 'exit 99' TERM
    sleep 30
}

register_case selftest pass fast 3 selftest_pass
register_case selftest fail fast 3 selftest_fail
register_case selftest timeout fast 1 selftest_timeout
register_case selftest term fast 10 selftest_term
