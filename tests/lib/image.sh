#!/usr/bin/env bash

set -u -o pipefail

image_create_sparse() {
    local image=$1
    local size=$2
    [ -n "$image" ] || return 2
    [ -n "$size" ] || return 2
    truncate -s "$size" "$image"
}

image_sha256() {
    sha256sum "$1"
}
