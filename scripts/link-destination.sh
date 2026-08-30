#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <source> <destination>\n' "$0" >&2
    exit 64
}

[ "$#" -eq 2 ] || usage

source_path=$1
destination_path=$2

if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
    printf 'Source does not exist: %s\n' "$source_path" >&2
    exit 1
fi

if [ -L "$destination_path" ]; then
    printf 'Refusing to replace unrelated symlink: %s\n' "$destination_path" >&2
    exit 1
fi

if [ -e "$destination_path" ]; then
    if [ ! -t 0 ]; then
        printf 'Refusing to replace real destination without an interactive terminal: %s\n' "$destination_path" >&2
        exit 1
    fi

    printf 'Replace %s with a symlink? The original will be backed up. [y/N] ' "$destination_path" >&2
    if ! read -r answer; then
        answer=
    fi

    case "$answer" in
        y|Y|yes|YES|Yes)
            ;;
        *)
            printf 'Skipped real destination: %s\n' "$destination_path"
            exit 0
            ;;
    esac

    destination_parent=$(dirname "$destination_path")
    destination_name=$(basename "$destination_path")
    backup_path=$destination_parent/${destination_name}-backup-$(date +%s)

    if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
        printf 'Refusing to replace destination; backup already exists: %s\n' "$backup_path" >&2
        exit 1
    fi

    if ! mv "$destination_path" "$backup_path"; then
        printf 'Unable to back up destination: %s\n' "$destination_path" >&2
        exit 1
    fi

    if ln -s "$source_path" "$destination_path"; then
        printf 'Backed up: %s -> %s\n' "$destination_path" "$backup_path"
        printf 'Linked: %s -> %s\n' "$destination_path" "$source_path"
        exit 0
    fi

    if mv "$backup_path" "$destination_path"; then
        printf 'Unable to create symlink; restored destination: %s\n' "$destination_path" >&2
    else
        printf 'Unable to create symlink or restore destination. Backup remains at: %s\n' "$backup_path" >&2
    fi
    exit 1
fi

mkdir -p "$(dirname "$destination_path")"
ln -s "$source_path" "$destination_path"
printf 'Linked: %s -> %s\n' "$destination_path" "$source_path"
