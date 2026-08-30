#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <link|unlink> [destination-directory]\n' "$0" >&2
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
source_directory=$project_root/nvim

if [ ! -d "$source_directory" ]; then
    printf 'Neovim configuration directory does not exist: %s\n' "$source_directory" >&2
    exit 1
fi

if [ "$#" -eq 2 ]; then
    destination_directory=$2
else
    destination_directory=${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}/nvim
fi

if [ "$operation" = link ]; then
    if [ -L "$destination_directory" ]; then
        if [ "$(readlink "$destination_directory")" = "$source_directory" ]; then
            printf 'Already linked: %s\n' "$destination_directory"
            exit 0
        fi

        printf 'Refusing to replace unrelated symlink: %s\n' "$destination_directory" >&2
        exit 1
    fi

    exec "$project_root/scripts/link-destination.sh" "$source_directory" "$destination_directory"
fi

if [ -L "$destination_directory" ] && [ "$(readlink "$destination_directory")" = "$source_directory" ]; then
    rm "$destination_directory"
    printf 'Unlinked: %s\n' "$destination_directory"
elif [ -e "$destination_directory" ] || [ -L "$destination_directory" ]; then
    printf 'Skipped unrelated destination: %s\n' "$destination_directory"
else
    printf 'Destination does not exist; nothing to unlink: %s\n' "$destination_directory"
fi
