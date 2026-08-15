#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUTPUT_DIR=${1:-${ENV_ARTIFACTS_DIR:-"$ROOT_DIR/build/environment"}}

if [ -z "$OUTPUT_DIR" ]; then
    echo "usage: $0 [artifacts-dir]" >&2
    exit 2
fi

if [[ "$OUTPUT_DIR" != /* ]]; then
    OUTPUT_DIR="$ROOT_DIR/$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/environment.txt"
: >"$OUTPUT_FILE"

missing=0

record_header() {
    printf '\n[%s]\n' "$1" >>"$OUTPUT_FILE"
}

record_command() {
    local label=$1
    shift
    record_header "$label"
    printf '$' >>"$OUTPUT_FILE"
    printf ' %q' "$@" >>"$OUTPUT_FILE"
    printf '\n' >>"$OUTPUT_FILE"

    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'missing\n' >>"$OUTPUT_FILE"
        printf '[collect-env] missing: %s\n' "$1" >&2
        missing=1
        return 0
    fi

    if ! "$@" >>"$OUTPUT_FILE" 2>&1; then
        printf '[collect-env] command failed: %s\n' "$label" >&2
        missing=1
    fi
}

record_file_hash() {
    local path=$1
    record_header "sha256:$path"
    if [ ! -f "$ROOT_DIR/$path" ]; then
        printf 'missing\n' >>"$OUTPUT_FILE"
        printf '[collect-env] missing file: %s\n' "$path" >&2
        missing=1
        return 0
    fi

    if ! command -v sha256sum >/dev/null 2>&1; then
        printf 'missing\n' >>"$OUTPUT_FILE"
        printf '[collect-env] missing: sha256sum\n' >&2
        missing=1
        return 0
    fi

    if ! sha256sum "$ROOT_DIR/$path" >>"$OUTPUT_FILE" 2>&1; then
        printf '[collect-env] failed to hash: %s\n' "$path" >&2
        missing=1
    fi
}

printf 'root=%s\n' "$ROOT_DIR" >>"$OUTPUT_FILE"
printf 'output=%s\n' "$OUTPUT_FILE" >>"$OUTPUT_FILE"

record_command uname uname -a
record_command gcc gcc --version
record_command ld ld --version
record_command nasm nasm --version
record_command qemu qemu-system-x86_64 --version
record_command gdb gdb --version
record_command make make --version
record_file_hash Makefile
record_file_hash boot/loader.S
record_file_hash kernel/linker.ld

record_header git
if command -v git >/dev/null 2>&1; then
    (
        cd "$ROOT_DIR" || exit 1
        printf 'commit='
        git rev-parse HEAD
        printf 'branch='
        git branch --show-current
        printf 'status=\n'
        git status --short
    ) >>"$OUTPUT_FILE" 2>&1 || {
        printf '[collect-env] git inspection failed\n' >&2
        missing=1
    }
else
    printf 'missing\n' >>"$OUTPUT_FILE"
    printf '[collect-env] missing: git\n' >&2
    missing=1
fi

printf '[collect-env] wrote %s\n' "$OUTPUT_FILE"
exit "$missing"
