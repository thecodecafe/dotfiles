#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-skill-links.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-skill-links.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_link_target() {
    link_path=$1
    expected_target=$2

    [ -L "$link_path" ] || fail "$link_path is not a symlink"
    [ "$(readlink "$link_path")" = "$expected_target" ] || fail "$link_path has the wrong target"
}

source_dir=$test_root/source
mkdir -p "$source_dir/alpha" "$source_dir/beta" "$source_dir/ignored"
printf '%s\n' '---' 'name: alpha' 'description: test' '---' > "$source_dir/alpha/SKILL.md"
printf '%s\n' '---' 'name: beta' 'description: test' '---' > "$source_dir/beta/SKILL.md"

destination_dir=$test_root/destination
mkdir -p "$destination_dir"
printf '%s\n' 'keep me' > "$destination_dir/unrelated"

"$manager" link "$source_dir" "$destination_dir"
assert_link_target "$destination_dir/alpha" "$source_dir/alpha"
assert_link_target "$destination_dir/beta" "$source_dir/beta"
[ ! -e "$destination_dir/ignored" ] || fail 'directory without SKILL.md was linked'

"$manager" link "$source_dir" "$destination_dir"
assert_link_target "$destination_dir/alpha" "$source_dir/alpha"
assert_link_target "$destination_dir/beta" "$source_dir/beta"

check_collision() {
    collision_type=$1
    collision_dir=$test_root/collision-$collision_type
    mkdir -p "$collision_dir"

    case "$collision_type" in
        file) printf '%s\n' 'existing' > "$collision_dir/alpha" ;;
        directory) mkdir "$collision_dir/alpha" ;;
        symlink) ln -s "$source_dir/beta" "$collision_dir/alpha" ;;
        broken-symlink) ln -s "$test_root/missing" "$collision_dir/alpha" ;;
        *) fail "unknown collision fixture: $collision_type" ;;
    esac

    if "$manager" link "$source_dir" "$collision_dir" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi

    [ ! -e "$collision_dir/beta" ] && [ ! -L "$collision_dir/beta" ] || fail "$collision_type collision caused a partial install"
}

check_collision file
check_collision directory
check_collision symlink
check_collision broken-symlink

"$manager" unlink "$source_dir" "$destination_dir"
[ ! -e "$destination_dir/alpha" ] && [ ! -L "$destination_dir/alpha" ] || fail 'alpha link was not removed'
[ ! -e "$destination_dir/beta" ] && [ ! -L "$destination_dir/beta" ] || fail 'beta link was not removed'
[ -f "$destination_dir/unrelated" ] || fail 'unrelated destination was removed'

foreign_dir=$test_root/foreign
mkdir -p "$foreign_dir"
ln -s "$source_dir/beta" "$foreign_dir/alpha"
"$manager" unlink "$source_dir" "$foreign_dir"
assert_link_target "$foreign_dir/alpha" "$source_dir/beta"

printf '%s\n' 'All skill symlink tests passed.'
