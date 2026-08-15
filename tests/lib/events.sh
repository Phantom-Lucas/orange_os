#!/usr/bin/env bash

set -u -o pipefail

event_emit() {
    local type=$1
    shift
    printf '[%s]' "$type"
    local field
    for field in "$@"; do
        case "$field" in
            *' '*|*'	'*) return 2 ;;
        esac
        printf ' %s' "$field"
    done
    printf '\n'
}

event_wait_pass() {
    local file=$1
    local suite=$2
    local case_name=$3
    grep -Fq "[TEST] suite=$suite case=$case_name state=PASS" "$file"
}
