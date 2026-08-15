#!/usr/bin/env bash

set -u -o pipefail

RUNNER_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$RUNNER_DIR/.." && pwd)
export ROOT_DIR

source "$RUNNER_DIR/lib/common.sh"
source "$RUNNER_DIR/lib/artifacts.sh"

declare -a CASE_IDS=()
declare -A CASE_SUITE=()
declare -A CASE_NAME=()
declare -A CASE_PROFILE=()
declare -A CASE_TIMEOUT=()
declare -A CASE_FUNCTION=()

register_case() {
    local suite=$1
    local case_name=$2
    local profile=$3
    local timeout_seconds=$4
    local function_name=$5
    local id="$suite.$case_name"
    [[ "$suite" =~ ^[a-z][a-z0-9_-]*$ ]] || die 2 "invalid suite: $suite"
    [[ "$case_name" =~ ^[a-z][a-z0-9_-]*$ ]] || die 2 "invalid case: $case_name"
    [[ "$profile" =~ ^(fast|full|stress)$ ]] || die 2 "invalid profile for $id: $profile"
    [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ ]] || die 2 "invalid timeout for $id: $timeout_seconds"
    [ -n "$function_name" ] || die 2 "empty function for $id"
    [ -z "${CASE_FUNCTION[$id]+set}" ] || die 2 "duplicate case: $id"
    CASE_IDS+=("$id")
    CASE_SUITE["$id"]=$suite
    CASE_NAME["$id"]=$case_name
    CASE_PROFILE["$id"]=$profile
    CASE_TIMEOUT["$id"]=$timeout_seconds
    CASE_FUNCTION["$id"]=$function_name
}

usage() {
    cat <<'EOF'
Usage: tests/run.sh [options]

  --list                         List suite, case, profile and timeout
  --suite NAME                   Run all cases in a suite
  --case SUITE.CASE              Run one case
  --repeat N                     Repeat each selected case N times
  --seed N                       Set the base deterministic seed
  --keep-failed                  Keep case work directories on failure
  --artifacts-dir DIR            Root for run artifacts
  --profile fast|full|stress     Select a test profile
  --timeout N                    Override selected case timeouts
  --manifest FILE                Load an alternate manifest (selftests)
  --help                         Show this help
EOF
}

profile_includes() {
    local selected=$1
    local case_profile=$2
    case "$selected" in
        fast) [ "$case_profile" = fast ] ;;
        # full is the complete pre-UART regression matrix, including cases
        # tagged stress in the manifest; stress remains an explicit alias for
        # running the same complete set.
        full) return 0 ;;
        stress) return 0 ;;
        *) return 1 ;;
    esac
}

load_manifest() {
    local manifest=$1
    [ -f "$manifest" ] || die 2 "manifest not found: $manifest"
    # shellcheck disable=SC1090
    source "$manifest" || die 2 "manifest failed: $manifest"
    [ "${#CASE_IDS[@]}" -gt 0 ] || die 2 "manifest contains no cases"
}

case_matches_short_name() {
    local short_name=$1
    local id
    for id in "${CASE_IDS[@]}"; do
        [ "${CASE_NAME[$id]}" = "$short_name" ] && printf '%s\n' "$id"
    done
}

case_selected() {
    local id=$1
    if [ -n "$FILTER_CASE" ]; then
        [ "$id" = "$FILTER_CASE" ] || return 1
    fi
    if [ -n "$FILTER_SUITE" ]; then
        [ "${CASE_SUITE[$id]}" = "$FILTER_SUITE" ] || return 1
    fi
    if [ -n "$FILTER_PROFILE" ]; then
        profile_includes "$FILTER_PROFILE" "${CASE_PROFILE[$id]}" || return 1
    fi
    return 0
}

list_cases() {
    local id
    printf 'suite\tcase\tprofile\ttimeout\tfunction\n'
    for id in "${CASE_IDS[@]}"; do
        printf '%s\t%s\t%s\t%s\t%s\n' \
            "${CASE_SUITE[$id]}" "${CASE_NAME[$id]}" "${CASE_PROFILE[$id]}" \
            "${CASE_TIMEOUT[$id]}" "${CASE_FUNCTION[$id]}"
    done
}

run_case() {
    local id=$1
    local iteration=$2
    local seed=$3
    local suite=${CASE_SUITE[$id]}
    local case_name=${CASE_NAME[$id]}
    local function_name=${CASE_FUNCTION[$id]}
    local timeout_seconds=${TIMEOUT_OVERRIDE:-${CASE_TIMEOUT[$id]}}
    local case_dir="$RUN_ARTIFACTS_DIR/$suite/$case_name/$iteration"
    local log_file="$case_dir/test.log"
    local work_dir="$case_dir/work"

    mkdir -p "$work_dir"
    export TEST_SUITE=$suite TEST_CASE=$case_name TEST_ITERATION=$iteration
    export TEST_SEED=$seed SEED=$seed RUNNER_SEED=$seed
    export TEST_TIMEOUT=$timeout_seconds TEST_PROFILE=${CASE_PROFILE[$id]}
    export TEST_KEEP_FAILED=$KEEP_FAILED
    export TEST_CASE_DIR=$case_dir TEST_WORK_DIR=$work_dir
    artifacts_init_case "$case_dir"
    artifacts_record_environment "$case_dir"
    {
        printf 'function=%s\n' "$function_name"
        printf 'timeout=%s\n' "$timeout_seconds"
        printf 'seed=%s\n' "$seed"
        printf 'command=bash -c %q\n' "$function_name"
    } >"$case_dir/command.txt"

    printf '[runner] START suite=%s case=%s iteration=%s seed=%s timeout=%s\n' \
        "$suite" "$case_name" "$iteration" "$seed" "$timeout_seconds"
    export -f "$function_name" 2>/dev/null || {
        artifacts_record_result "$case_dir" ERROR 127
        printf '[runner] ERROR suite=%s case=%s function-not-exportable artifacts=%s\n' \
            "$suite" "$case_name" "$case_dir" >&2
        return 3
    }
    local child_script
    child_script="source '$RUNNER_DIR/lib/common.sh'; source '$RUNNER_DIR/lib/artifacts.sh'; source '$RUNNER_DIR/lib/qemu.sh'; source '$RUNNER_DIR/lib/monitor.sh'; source '$RUNNER_DIR/lib/image.sh'; source '$RUNNER_DIR/lib/assertions.sh'; source '$RUNNER_DIR/lib/events.sh'; $function_name"
    timeout --signal=TERM --kill-after=5 "$timeout_seconds" bash -c "$child_script" \
        >"$log_file" 2>&1
    local raw_status=$?
    local status=FAIL
    local result_code=1
    case "$raw_status" in
        0) status=PASS; result_code=0 ;;
        124|137) status=TIMEOUT; result_code=4 ;;
        126|127) status=ERROR; result_code=3 ;;
        5) status=INFRASTRUCTURE_ERROR; result_code=5 ;;
    esac
    artifacts_record_result "$case_dir" "$status" "$raw_status"
    if [ "$raw_status" -eq 0 ]; then
        rm -rf -- "$work_dir"
        printf '[runner] PASS suite=%s case=%s artifacts=%s\n' "$suite" "$case_name" "$case_dir"
    else
        printf '[runner] %s suite=%s case=%s exit=%s artifacts=%s\n' \
            "$status" "$suite" "$case_name" "$raw_status" "$case_dir" >&2
        tail -40 "$log_file" >&2 || true
    fi
    return "$result_code"
}

main() {
    local list_only=0
    local repeat=1
    local base_seed=$(( $(date +%s) ^ $$ ))
    local manifest=${RUNNER_MANIFEST:-$RUNNER_DIR/manifest.sh}
    RUN_ARTIFACTS_DIR=${ARTIFACTS_DIR:-$ROOT_DIR/build/test-artifacts}
    FILTER_SUITE=
    FILTER_CASE=
    FILTER_PROFILE=
    TIMEOUT_OVERRIDE=
    KEEP_FAILED=0

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --list) list_only=1 ;;
            --suite) [ "$#" -ge 2 ] || die 2 "--suite requires a value"; FILTER_SUITE=$2; shift ;;
            --case) [ "$#" -ge 2 ] || die 2 "--case requires a value"; FILTER_CASE=$2; shift ;;
            --repeat) [ "$#" -ge 2 ] || die 2 "--repeat requires a value"; repeat=$2; shift ;;
            --seed) [ "$#" -ge 2 ] || die 2 "--seed requires a value"; base_seed=$2; shift ;;
            --keep-failed) KEEP_FAILED=1 ;;
            --artifacts-dir) [ "$#" -ge 2 ] || die 2 "--artifacts-dir requires a value"; RUN_ARTIFACTS_DIR=$2; shift ;;
            --profile) [ "$#" -ge 2 ] || die 2 "--profile requires a value"; FILTER_PROFILE=$2; shift ;;
            --timeout) [ "$#" -ge 2 ] || die 2 "--timeout requires a value"; TIMEOUT_OVERRIDE=$2; shift ;;
            --manifest) [ "$#" -ge 2 ] || die 2 "--manifest requires a value"; manifest=$2; shift ;;
            --help|-h) usage; return 0 ;;
            *) die 2 "unknown option: $1" ;;
        esac
        shift
    done

    [[ "$repeat" =~ ^[1-9][0-9]*$ ]] || die 2 "invalid repeat: $repeat"
    [[ "$base_seed" =~ ^[0-9]+$ ]] || die 2 "invalid seed: $base_seed"
    if [ -n "$TIMEOUT_OVERRIDE" ]; then
        [[ "$TIMEOUT_OVERRIDE" =~ ^[1-9][0-9]*$ ]] || die 2 "invalid timeout: $TIMEOUT_OVERRIDE"
    fi
    [ -z "$FILTER_PROFILE" ] || [[ "$FILTER_PROFILE" =~ ^(fast|full|stress)$ ]] ||
        die 2 "invalid profile: $FILTER_PROFILE"

    load_manifest "$manifest"
    if [ "$list_only" -eq 1 ]; then
        list_cases
        return 0
    fi

    if [ -n "$FILTER_CASE" ] && [[ "$FILTER_CASE" != *.* ]]; then
        mapfile -t short_matches < <(case_matches_short_name "$FILTER_CASE")
        [ "${#short_matches[@]}" -eq 1 ] || {
            [ "${#short_matches[@]}" -eq 0 ] && die 2 "case not found: $FILTER_CASE"
            die 2 "case is ambiguous; use suite.case: $FILTER_CASE"
        }
        FILTER_CASE=${short_matches[0]}
    fi
    if [ -n "$FILTER_CASE" ] && [ -z "${CASE_FUNCTION[$FILTER_CASE]+set}" ]; then
        die 2 "case not found: $FILTER_CASE"
    fi
    if [ -n "$FILTER_SUITE" ]; then
        local suite_found=0
        local candidate
        for candidate in "${CASE_IDS[@]}"; do
            [ "${CASE_SUITE[$candidate]}" = "$FILTER_SUITE" ] && suite_found=1
        done
        [ "$suite_found" -eq 1 ] || die 2 "suite not found: $FILTER_SUITE"
    fi

    local run_id
    run_id="$(date +%Y%m%d-%H%M%S)-$$-$base_seed"
    RUN_ARTIFACTS_DIR="$RUN_ARTIFACTS_DIR/$run_id"
    mkdir -p "$RUN_ARTIFACTS_DIR"
    printf '[runner] run_id=%s seed=%s artifacts=%s\n' "$run_id" "$base_seed" "$RUN_ARTIFACTS_DIR"
    local selected=0
    local failures=0
    local first_failure_code=1
    local id iteration seed
    for id in "${CASE_IDS[@]}"; do
        case_selected "$id" || continue
        selected=1
        for ((iteration = 1; iteration <= repeat; iteration++)); do
            seed=$((base_seed + iteration - 1))
            if run_case "$id" "$iteration" "$seed"; then
                :
            else
                local case_status=$?
                failures=$((failures + 1))
                first_failure_code=$case_status
                break
            fi
        done
        [ "$failures" -eq 0 ] || break
    done
    [ "$selected" -eq 1 ] || die 2 "no cases selected"
    if [ "$failures" -ne 0 ]; then
        printf '[runner] FAIL failures=%s artifacts=%s\n' "$failures" "$RUN_ARTIFACTS_DIR" >&2
        case "$first_failure_code" in
            2|3|4|5) return "$first_failure_code" ;;
            *) return 1 ;;
        esac
    fi
    printf '[runner] PASS all selected cases artifacts=%s\n' "$RUN_ARTIFACTS_DIR"
    return 0
}

main "$@"
