#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <link|unlink> <source-file> <destination-file>\n' "$0" >&2
    exit 64
}

if [ "$#" -ne 3 ]; then
    usage
fi

operation=$1
source_input=$2
destination_path=$3

case "$operation" in
    link|unlink) ;;
    *) usage ;;
esac

if [ ! -f "$source_input" ]; then
    printf 'Source dotfile does not exist: %s\n' "$source_input" >&2
    exit 1
fi

source_parent=$(CDPATH= cd -- "$(dirname "$source_input")" && pwd -P)
source_path=$source_parent/$(basename "$source_input")

if [ "$operation" = link ]; then
    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$source_path" ]; then
            printf 'Already linked: %s\n' "$destination_path"
            exit 0
        fi

        printf 'Refusing to replace existing destination: %s\n' "$destination_path" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$destination_path")"
    ln -s "$source_path" "$destination_path"
    printf 'Linked: %s -> %s\n' "$destination_path" "$source_path"
    exit 0
fi

if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$source_path" ]; then
    rm "$destination_path"
    printf 'Unlinked: %s\n' "$destination_path"
elif [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
    printf 'Skipped unrelated destination: %s\n' "$destination_path"
else
    printf 'Destination does not exist; nothing to unlink: %s\n' "$destination_path"
fi
