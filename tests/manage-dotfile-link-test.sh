#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-dotfile-link.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-dotfile-link.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

source_file=$test_root/source/tmux.conf
mkdir -p "$(dirname "$source_file")"
printf '%s\n' 'set -g mouse on' > "$source_file"

destination_file=$test_root/home/.config/tmux/tmux.conf
"$manager" link "$source_file" "$destination_file"
[ -L "$destination_file" ] || fail "$destination_file is not a symlink"
[ "$(readlink "$destination_file")" = "$source_file" ] || fail "$destination_file has the wrong target"

"$manager" link "$source_file" "$destination_file"
[ -L "$destination_file" ] || fail 'idempotent link removed the destination'

check_collision() {
    collision_type=$1
    collision_path=$test_root/collision-$collision_type/tmux.conf
    mkdir -p "$(dirname "$collision_path")"

    case "$collision_type" in
        file) printf '%s\n' 'existing' > "$collision_path" ;;
        directory) mkdir "$collision_path" ;;
        symlink)
            printf '%s\n' 'foreign' > "$test_root/foreign-target"
            ln -s "$test_root/foreign-target" "$collision_path"
            ;;
        broken-symlink) ln -s "$test_root/missing" "$collision_path" ;;
        *) fail "unknown collision fixture: $collision_type" ;;
    esac

    if "$manager" link "$source_file" "$collision_path" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi
}

check_collision file
check_collision directory
check_collision symlink
check_collision broken-symlink

if command -v script >/dev/null 2>&1; then
    replacement_file=$test_root/replacement/tmux.conf
    mkdir -p "$(dirname "$replacement_file")"
    printf '%s\n' 'preserve this file' > "$replacement_file"
    printf 'y\n' | script -q /dev/null "$manager" link "$source_file" "$replacement_file" >/dev/null 2>&1
    [ -L "$replacement_file" ] || fail 'confirmed file replacement did not create a symlink'
    backup_file=$(find "$(dirname "$replacement_file")" -name 'tmux.conf-backup-*' -type f -print -quit)
    [ -n "$backup_file" ] || fail 'file replacement did not create a timestamped backup'
    [ "$(cat "$backup_file")" = 'preserve this file' ] || fail 'file backup contents changed'

    replacement_directory=$test_root/replacement/config
    mkdir "$replacement_directory"
    printf '%s\n' 'preserve this directory' > "$replacement_directory/value"
    printf 'y\n' | script -q /dev/null "$manager" link "$source_file" "$replacement_directory" >/dev/null 2>&1
    [ -L "$replacement_directory" ] || fail 'confirmed directory replacement did not create a symlink'
    backup_directory=$(find "$(dirname "$replacement_directory")" -name 'config-backup-*' -type d -print -quit)
    [ -n "$backup_directory" ] || fail 'directory replacement did not create a timestamped backup'
    [ "$(cat "$backup_directory/value")" = 'preserve this directory' ] || fail 'directory backup contents changed'
fi

"$manager" unlink "$source_file" "$destination_file"
[ ! -e "$destination_file" ] && [ ! -L "$destination_file" ] || fail 'owned link was not removed'

foreign_file=$test_root/foreign/tmux.conf
mkdir -p "$(dirname "$foreign_file")"
printf '%s\n' 'keep me' > "$foreign_file"
"$manager" unlink "$source_file" "$foreign_file"
[ -f "$foreign_file" ] || fail 'unrelated destination was removed'

foreign_link=$test_root/foreign-link/tmux.conf
mkdir -p "$(dirname "$foreign_link")"
ln -s "$foreign_file" "$foreign_link"
"$manager" unlink "$source_file" "$foreign_link"
[ -L "$foreign_link" ] || fail 'unrelated symlink was removed'

"$manager" unlink "$source_file" "$test_root/missing/tmux.conf"

printf '%s\n' 'All dotfile symlink tests passed.'
