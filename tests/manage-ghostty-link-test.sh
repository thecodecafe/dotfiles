#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-ghostty-link.sh
source_file=$project_root/ghostty/config
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-ghostty-link.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

destination_file=$test_root/explicit/ghostty/config
"$manager" link "$destination_file"
[ -L "$destination_file" ] || fail "$destination_file is not a symlink"
[ "$(readlink "$destination_file")" = "$source_file" ] || fail "$destination_file has the wrong target"

"$manager" link "$destination_file"
[ -L "$destination_file" ] || fail 'idempotent link removed the destination'

"$manager" unlink "$destination_file"
[ ! -e "$destination_file" ] && [ ! -L "$destination_file" ] || fail 'owned link was not removed'

xdg_root=$test_root/xdg
XDG_CONFIG_HOME=$xdg_root "$manager" link
default_destination=$xdg_root/ghostty/config
[ -L "$default_destination" ] || fail 'default XDG destination was not linked'
XDG_CONFIG_HOME=$xdg_root "$manager" unlink
[ ! -e "$default_destination" ] && [ ! -L "$default_destination" ] || fail 'default XDG destination was not unlinked'

foreign_file=$test_root/foreign/config
mkdir -p "$(dirname "$foreign_file")"
printf '%s\n' 'keep me' > "$foreign_file"
"$manager" unlink "$foreign_file"
[ -f "$foreign_file" ] || fail 'unrelated destination was removed'

foreign_link=$test_root/foreign-link/config
mkdir -p "$(dirname "$foreign_link")"
ln -s "$foreign_file" "$foreign_link"
"$manager" unlink "$foreign_link"
[ -L "$foreign_link" ] || fail 'unrelated symlink was removed'

printf '%s\n' 'All Ghostty symlink tests passed.'
