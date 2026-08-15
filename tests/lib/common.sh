#!/usr/bin/env bash

set -u -o pipefail

ROOT_DIR=${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}

die() {
    local code=$1
    shift
    printf '[runner] ERROR: %s\n' "$*" >&2
    exit "$code"
}

require_command() {
    local command_name=$1
    command -v "$command_name" >/dev/null 2>&1 ||
        die 3 "missing command: $command_name"
}

record_command() {
    local output_file=$1
    shift
    printf '$' >>"$output_file"
    printf ' %q' "$@" >>"$output_file"
    printf '\n' >>"$output_file"
}

case_workspace_create() {
    local directory=$1
    mkdir -p "$directory/work"
    printf '%s\n' "$directory"
}

run_with_timeout() {
    local seconds=$1
    local log_file=$2
    shift 2
    require_command timeout
    timeout --signal=TERM --kill-after=5 "$seconds" "$@" >"$log_file" 2>&1
    local status=$?
    case "$status" in
        124|137) return 124 ;;
        *) return "$status" ;;
    esac
}

CLEANUP_RAN=0
CLEANUP_PATHS=()

cleanup_register() {
    local path=$1
    [ -n "$path" ] || die 2 "cleanup target is empty"
    case "$path" in
        /|"$ROOT_DIR"|"$ROOT_DIR/"|/home|/tmp) die 2 "unsafe cleanup target: $path" ;;
    esac
    CLEANUP_PATHS+=("$path")
}

cleanup_once() {
    [ "$CLEANUP_RAN" -eq 0 ] || return 0
    CLEANUP_RAN=1
    local path
    for path in "${CLEANUP_PATHS[@]}"; do
        [ -n "$path" ] || continue
        [ -e "$path" ] || continue
        rm -rf -- "$path"
    done
}

cleanup_on_signal() {
    cleanup_once
    exit 143
}

trap cleanup_once EXIT
trap cleanup_on_signal INT TERM
