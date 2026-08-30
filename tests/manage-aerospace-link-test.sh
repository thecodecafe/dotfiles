#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-aerospace-link.sh
source_file=$project_root/aerospace/aerospace.toml
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-aerospace-link.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

destination_file=$test_root/explicit/aerospace/aerospace.toml
"$manager" link "$destination_file"
[ -L "$destination_file" ] || fail "$destination_file is not a symlink"
[ "$(readlink "$destination_file")" = "$source_file" ] || fail "$destination_file has the wrong target"

"$manager" link "$destination_file"
[ -L "$destination_file" ] || fail 'idempotent link removed the destination'

"$manager" unlink "$destination_file"
[ ! -e "$destination_file" ] && [ ! -L "$destination_file" ] || fail 'owned link was not removed'

xdg_root=$test_root/xdg
XDG_CONFIG_HOME=$xdg_root "$manager" link
default_destination=$xdg_root/aerospace/aerospace.toml
[ -L "$default_destination" ] || fail 'default XDG destination was not linked'
XDG_CONFIG_HOME=$xdg_root "$manager" unlink
[ ! -e "$default_destination" ] && [ ! -L "$default_destination" ] || fail 'default XDG destination was not unlinked'

for collision_type in file directory symlink broken-symlink
do
    collision=$test_root/collision-$collision_type/aerospace/aerospace.toml
    mkdir -p "$(dirname "$collision")"
    case "$collision_type" in
        file) printf '%s\n' existing > "$collision" ;;
        directory) mkdir "$collision" ;;
        symlink)
            mkdir "$test_root/foreign-$collision_type"
            ln -s "$test_root/foreign-$collision_type" "$collision"
            ;;
        broken-symlink) ln -s "$test_root/missing" "$collision" ;;
    esac

    if "$manager" link "$collision" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi
done

foreign_file=$test_root/foreign/config
mkdir -p "$(dirname "$foreign_file")"
printf '%s\n' 'keep me' > "$foreign_file"
"$manager" unlink "$foreign_file"
[ -f "$foreign_file" ] || fail 'unrelated destination was removed'

foreign_link=$test_root/foreign-link/aerospace.toml
mkdir -p "$(dirname "$foreign_link")"
ln -s "$foreign_file" "$foreign_link"
"$manager" unlink "$foreign_link"
[ -L "$foreign_link" ] || fail 'unrelated symlink was removed'

printf '%s\n' 'All AeroSpace symlink tests passed.'
