#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <link|unlink> [destination-file]\n' "$0" >&2
    exit 64
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

operation=$1

case "$operation" in
    link|unlink) ;;
    *) usage ;;
esac

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
source_file=$project_root/aerospace/aerospace.toml

if [ "$#" -eq 2 ]; then
    destination_file=$2
else
    destination_file=${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}/aerospace/aerospace.toml
fi

exec "$project_root/scripts/manage-dotfile-link.sh" "$operation" "$source_file" "$destination_file"
