#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <link|unlink> <source-directory> <destination-directory>\n' "$0" >&2
    exit 64
}

if [ "$#" -ne 3 ]; then
    usage
fi

operation=$1
source_input=$2
destination_dir=$3
project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)

case "$operation" in
    link|unlink) ;;
    *) usage ;;
esac

if [ ! -d "$source_input" ]; then
    printf 'Source skills directory does not exist: %s\n' "$source_input" >&2
    exit 1
fi

source_dir=$(CDPATH= cd -- "$source_input" && pwd -P)
skill_count=0

for skill_dir in "$source_dir"/*; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
        skill_count=$((skill_count + 1))
    fi
done

if [ "$skill_count" -eq 0 ]; then
    printf 'No skill directories containing SKILL.md found in: %s\n' "$source_dir" >&2
    exit 1
fi

if [ "$operation" = link ]; then
    mkdir -p "$destination_dir"
    link_failed=0

    for skill_dir in "$source_dir"/*; do
        if [ ! -d "$skill_dir" ] || [ ! -f "$skill_dir/SKILL.md" ]; then
            continue
        fi

        skill_name=${skill_dir##*/}
        destination_path=$destination_dir/$skill_name

        if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$skill_dir" ]; then
            printf 'Already linked: %s\n' "$destination_path"
        elif ! "$project_root/scripts/link-destination.sh" "$skill_dir" "$destination_path"; then
            link_failed=1
        fi
    done

    exit "$link_failed"
fi

if [ ! -d "$destination_dir" ]; then
    printf 'Destination does not exist; nothing to unlink: %s\n' "$destination_dir"
    exit 0
fi

for skill_dir in "$source_dir"/*; do
    if [ ! -d "$skill_dir" ] || [ ! -f "$skill_dir/SKILL.md" ]; then
        continue
    fi

    skill_name=${skill_dir##*/}
    destination_path=$destination_dir/$skill_name

    if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$skill_dir" ]; then
        rm "$destination_path"
        printf 'Unlinked: %s\n' "$destination_path"
    elif [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        printf 'Skipped unrelated destination: %s\n' "$destination_path"
    fi
done
