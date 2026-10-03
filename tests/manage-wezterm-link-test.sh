#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-wezterm-link.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

source_file=$project_root/wezterm/wezterm.lua
destination_file=$test_root/config/wezterm/wezterm.lua

make -s -C "$project_root" wezterm WEZTERM_CONFIG_FILE="$destination_file"
[ -L "$destination_file" ] || fail 'WezTerm configuration was not linked'
[ "$(readlink "$destination_file")" = "$source_file" ] || fail 'WezTerm link has the wrong target'

make -s -C "$project_root" wezterm WEZTERM_CONFIG_FILE="$destination_file"
[ -L "$destination_file" ] || fail 're-linking removed the WezTerm configuration link'

make -s -C "$project_root" unlink-wezterm WEZTERM_CONFIG_FILE="$destination_file"
[ ! -e "$destination_file" ] && [ ! -L "$destination_file" ] || fail 'repository-owned WezTerm link was not removed'

unrelated_file=$test_root/unrelated/wezterm.lua
mkdir -p "$(dirname "$unrelated_file")"
printf '%s\n' 'keep me' > "$unrelated_file"
make -s -C "$project_root" unlink-wezterm WEZTERM_CONFIG_FILE="$unrelated_file"
[ -f "$unrelated_file" ] || fail 'unrelated WezTerm config file was removed'

printf '%s\n' 'WezTerm make link tests passed.'
