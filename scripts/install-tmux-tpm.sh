#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s [destination-directory]\n' "$0" >&2
    exit 64
}

if [ "$#" -gt 1 ]; then
    usage
fi

destination=${1:-${HOME:?HOME is not set}/.tmux/plugins/tpm}

if [ -e "$destination" ] || [ -L "$destination" ]; then
    if [ ! -L "$destination" ] && [ -d "$destination/.git" ] && [ -x "$destination/tpm" ]; then
        printf 'TPM is already installed: %s\n' "$destination"
        exit 0
    fi

    printf 'Refusing to replace conflicting TPM destination: %s\n' "$destination" >&2
    exit 1
fi

destination_parent=$(dirname "$destination")
mkdir -p "$destination_parent"
install_root=$(mktemp -d "$destination_parent/.tpm-install.XXXXXX")

cleanup() {
    rm -rf "$install_root"
}
trap cleanup EXIT HUP INT TERM

git clone https://github.com/tmux-plugins/tpm "$install_root/tpm"

if [ ! -d "$install_root/tpm/.git" ] || [ ! -x "$install_root/tpm/tpm" ]; then
    printf '%s\n' 'The cloned repository is not a valid TPM checkout.' >&2
    exit 1
fi

if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'Refusing to replace destination created during installation: %s\n' "$destination" >&2
    exit 1
fi

mv "$install_root/tpm" "$destination"
printf 'Installed TPM: %s\n' "$destination"
