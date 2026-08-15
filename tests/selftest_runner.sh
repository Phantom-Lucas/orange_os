#!/usr/bin/env bash

set -u -o pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RUNNER="$ROOT_DIR/tests/run.sh"
TMP_DIR=$(mktemp -d /tmp/oranges-runner-selftest.XXXXXX)
MARKER="$TMP_DIR/executed"
TERM_MARKER="$TMP_DIR/term-cleaned"
trap 'rm -rf "$TMP_DIR"' EXIT

list_output=$(RUNNER_SELFTEST_MARKER="$MARKER" "$RUNNER" \
    --manifest "$ROOT_DIR/tests/selftest_manifest.sh" --list --artifacts-dir "$TMP_DIR/list")
grep -Fq $'selftest\tpass\tfast\t3' <<<"$list_output" || exit 1
[ ! -e "$MARKER" ] || exit 1

RUNNER_SELFTEST_MARKER="$MARKER" "$RUNNER" \
    --manifest "$ROOT_DIR/tests/selftest_manifest.sh" --case selftest.pass \
    --seed 123 --artifacts-dir "$TMP_DIR/pass" >/dev/null || exit 1
[ -e "$MARKER" ] || exit 1
pass_work=$(find "$TMP_DIR/pass" -type f -name pass-created -print -quit)
[ -z "$pass_work" ] || exit 1

if RUNNER_SELFTEST_MARKER="$MARKER" "$RUNNER" \
    --manifest "$ROOT_DIR/tests/selftest_manifest.sh" --case selftest.timeout \
    --artifacts-dir "$TMP_DIR/timeout" >/dev/null 2>&1; then
    exit 1
else
    timeout_status=$?
    [ "$timeout_status" -eq 4 ] || exit 1
fi

if RUNNER_SELFTEST_MARKER="$MARKER" "$RUNNER" \
    --manifest "$ROOT_DIR/tests/selftest_manifest.sh" --case selftest.fail \
    --keep-failed --artifacts-dir "$TMP_DIR/fail" >/dev/null 2>&1; then
    exit 1
else
    fail_status=$?
    [ "$fail_status" -eq 1 ] || exit 1
fi
find "$TMP_DIR/fail" -type f -name result.env -print -quit | grep -q . || exit 1

"$RUNNER" --manifest "$ROOT_DIR/tests/selftest_duplicate_manifest.sh" --list \
    --artifacts-dir "$TMP_DIR/duplicate" >/dev/null 2>&1
duplicate_status=$?
[ "$duplicate_status" -eq 2 ] || exit 1

cleanup_dir="$TMP_DIR/cleanup-target"
mkdir -p "$cleanup_dir"
if bash -c "source '$ROOT_DIR/tests/lib/common.sh'; cleanup_register '$cleanup_dir'; kill -TERM \$BASHPID"; then
    exit 1
fi
[ ! -e "$cleanup_dir" ] || exit 1

echo "[selftest-runner] list/filter/timeout/cleanup/duplicate-manifest: PASSED"
