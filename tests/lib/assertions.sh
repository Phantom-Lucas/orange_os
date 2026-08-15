#!/usr/bin/env bash

set -u -o pipefail

assert_eq() {
    local expected=$1
    local actual=$2
    [ "$expected" = "$actual" ] || {
        printf '[%s.%s] assert_eq failed: expected=%q actual=%q artifacts=%s\n' \
            "${TEST_SUITE:-unknown}" "${TEST_CASE:-unknown}" "$expected" "$actual" \
            "${TEST_CASE_DIR:-unknown}" >&2
        return 1
    }
}

assert_contains() {
    local haystack=$1
    local needle=$2
    grep -Fq -- "$needle" <<<"$haystack" || {
        printf '[%s.%s] assert_contains failed: needle=%q artifacts=%s\n' \
            "${TEST_SUITE:-unknown}" "${TEST_CASE:-unknown}" "$needle" \
            "${TEST_CASE_DIR:-unknown}" >&2
        return 1
    }
}

assert_file_exists() {
    [ -f "$1" ] || {
        printf '[%s.%s] missing file: %s artifacts=%s\n' \
            "${TEST_SUITE:-unknown}" "${TEST_CASE:-unknown}" "$1" \
            "${TEST_CASE_DIR:-unknown}" >&2
        return 1
    }
}
