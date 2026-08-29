#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-nvim-link.sh
source_directory=$project_root/nvim
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-nvim-link.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

destination_directory=$test_root/explicit/nvim
"$manager" link "$destination_directory"
[ -L "$destination_directory" ] || fail "$destination_directory is not a symlink"
[ "$(readlink "$destination_directory")" = "$source_directory" ] || fail "$destination_directory has the wrong target"

"$manager" link "$destination_directory"
[ -L "$destination_directory" ] || fail 'idempotent link removed the destination'

"$manager" unlink "$destination_directory"
[ ! -e "$destination_directory" ] && [ ! -L "$destination_directory" ] || fail 'owned link was not removed'

xdg_root=$test_root/xdg
XDG_CONFIG_HOME=$xdg_root "$manager" link
default_destination=$xdg_root/nvim
[ -L "$default_destination" ] || fail 'default XDG destination was not linked'
XDG_CONFIG_HOME=$xdg_root "$manager" unlink
[ ! -e "$default_destination" ] && [ ! -L "$default_destination" ] || fail 'default XDG destination was not unlinked'

for collision_type in file directory symlink broken-symlink
do
    collision=$test_root/collision-$collision_type/nvim
    mkdir -p "$(dirname "$collision")"
    case "$collision_type" in
        file) printf '%s\n' existing > "$collision" ;;
        directory) mkdir "$collision" ;;
        symlink)
            mkdir "$test_root/foreign-nvim"
            ln -s "$test_root/foreign-nvim" "$collision"
            ;;
        broken-symlink) ln -s "$test_root/missing-nvim" "$collision" ;;
    esac

    if "$manager" link "$collision" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi
done

foreign_directory=$test_root/foreign/destination
mkdir -p "$foreign_directory"
"$manager" unlink "$foreign_directory"
[ -d "$foreign_directory" ] || fail 'unrelated directory was removed'

foreign_link=$test_root/foreign-link/nvim
mkdir -p "$(dirname "$foreign_link")"
ln -s "$foreign_directory" "$foreign_link"
"$manager" unlink "$foreign_link"
[ -L "$foreign_link" ] || fail 'unrelated symlink was removed'

"$manager" unlink "$test_root/missing/nvim"

printf '%s\n' 'All Neovim symlink tests passed.'
