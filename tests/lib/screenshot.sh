#!/usr/bin/env bash

set -u -o pipefail

check_terminal_theme_screenshot() {
    local ppm=$1
    [ -s "$ppm" ] || {
        printf '[screenshot] missing or empty PPM: %s\n' "$ppm" >&2
        return 1
    }

    local magic width height max
    magic=$(sed -n '1p' "$ppm")
    width=$(sed -n '2p' "$ppm" | awk '{print $1}')
    height=$(sed -n '2p' "$ppm" | awk '{print $2}')
    max=$(sed -n '3p' "$ppm")
    [ "$magic" = P6 ] || { printf '[screenshot] magic=%s\n' "$magic" >&2; return 1; }
    [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ && "$max" = 255 ]] || {
        printf '[screenshot] invalid header: %s %sx%s max=%s\n' \
            "$magic" "$width" "$height" "$max" >&2
        return 1
    }
    case "$width $height" in
        '640 400'|'720 400') ;;
        *) printf '[screenshot] unexpected VGA dimensions: %sx%s\n' "$width" "$height" >&2; return 1 ;;
    esac

    local header_bytes file_bytes expected_bytes
    header_bytes=$(head -n 3 "$ppm" | wc -c)
    file_bytes=$(wc -c <"$ppm")
    expected_bytes=$((header_bytes + width * height * 3))
    [ "$file_bytes" -ge "$expected_bytes" ] || {
        printf '[screenshot] truncated PPM: %s < %s bytes\n' "$file_bytes" "$expected_bytes" >&2
        return 1
    }

    # Bottom-right is outside the shell prompt and is expected to be blank.
    local offset red green blue
    offset=$((header_bytes + ((height - 2) * width + width - 2) * 3))
    read -r red green blue < <(od -An -j "$offset" -N 3 -tu1 "$ppm")
    local delta
    for delta in "$red" "$green" "$blue"; do
        [ -n "$delta" ] || { printf '[screenshot] missing background pixel\n' >&2; return 1; }
    done
    local dr dg db
    dr=$((red - 48)); dg=$((green - 8)); db=$((blue - 36))
    [ "$dr" -ge -4 ] && [ "$dr" -le 4 ] &&
    [ "$dg" -ge -4 ] && [ "$dg" -le 4 ] &&
    [ "$db" -ge -4 ] && [ "$db" -le 4 ] || {
        printf '[screenshot] background RGB=%s,%s,%s expected near 48,8,36\n' \
            "$red" "$green" "$blue" >&2
        return 1
    }

    local non_background
    non_background=$(od -An -v -w3 -j "$header_bytes" -N $((width * height * 3)) -tu1 "$ppm" |
        awk -v r="$red" -v g="$green" -v b="$blue" '
            { for (i = 1; i + 2 <= NF; i += 3)
                if ($i != r || $(i + 1) != g || $(i + 2) != b) count++ }
            END { print count + 0 }
        ')
    [ "$non_background" -gt 0 ] || {
        printf '[screenshot] no non-background text pixels found\n' >&2
        return 1
    }
    printf '[screenshot] P6 %sx%s background=%s,%s,%s text_pixels=%s\n' \
        "$width" "$height" "$red" "$green" "$blue" "$non_background"
}

check_framebuffer_screenshot() {
    local ppm=$1 expected_width=$2 expected_height=$3
    [ -s "$ppm" ] || return 1
    local magic width height max header_bytes file_bytes expected_bytes
    magic=$(sed -n '1p' "$ppm")
    width=$(sed -n '2p' "$ppm" | awk '{print $1}')
    height=$(sed -n '2p' "$ppm" | awk '{print $2}')
    max=$(sed -n '3p' "$ppm")
    [ "$magic" = P6 ] && [ "$width" = "$expected_width" ] &&
        [ "$height" = "$expected_height" ] && [ "$max" = 255 ] || return 1
    header_bytes=$(head -n 3 "$ppm" | wc -c)
    file_bytes=$(wc -c <"$ppm")
    expected_bytes=$((header_bytes + width * height * 3))
    [ "$file_bytes" -ge "$expected_bytes" ] || return 1
    local offset red green blue
    offset=$((header_bytes + ((height - 2) * width + width - 2) * 3))
    read -r red green blue < <(od -An -j "$offset" -N 3 -tu1 "$ppm")
    [ "$red" -ge 44 ] && [ "$red" -le 52 ] &&
        [ "$green" -ge 4 ] && [ "$green" -le 12 ] &&
        [ "$blue" -ge 32 ] && [ "$blue" -le 40 ] || return 1
    printf '[framebuffer] P6 %sx%s deep-purple background\n' "$width" "$height"
}
