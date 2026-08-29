#!/bin/sh

set -eu

usage() {
    printf 'Usage: %s <check|install> [destination-directory]\n' "$0" >&2
    exit 64
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

operation=$1
case "$operation" in
    check|install) ;;
    *) usage ;;
esac

if [ "$#" -eq 2 ]; then
    destination=$2
else
    destination=${XDG_DATA_HOME:-${HOME:?HOME is not set}/.local/share}/nvim/lazy-rocks/hererocks
fi

is_valid_installation() {
    [ ! -L "$destination" ] &&
        [ -x "$destination/bin/lua" ] &&
        [ -x "$destination/bin/luarocks" ] &&
        "$destination/bin/lua" -v 2>&1 | grep -Eq '^Lua 5\.1([. ]|$)' &&
        "$destination/bin/luarocks" --version >/dev/null 2>&1
}

if [ "$operation" = check ]; then
    is_valid_installation
    exit
fi

if [ -e "$destination" ] || [ -L "$destination" ]; then
    if is_valid_installation; then
        printf 'Neovim LuaRocks environment is already installed: %s\n' "$destination"
        exit 0
    fi

    printf 'Refusing to replace conflicting LuaRocks destination: %s\n' "$destination" >&2
    exit 1
fi

for required_command in git python3 cc make
do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'Required command is unavailable: %s\n' "$required_command" >&2
        exit 1
    fi
done

resolve_certificate_file() {
    if [ -n "${SSL_CERT_FILE:-}" ]; then
        if [ ! -r "$SSL_CERT_FILE" ]; then
            printf 'Configured SSL_CERT_FILE is not readable: %s\n' "$SSL_CERT_FILE" >&2
            return 1
        fi

        printf '%s\n' "$SSL_CERT_FILE"
        return 0
    fi

    certifi_file=$(python3 -c 'import certifi; print(certifi.where())' 2>/dev/null || :)
    if [ -n "$certifi_file" ] && [ -r "$certifi_file" ]; then
        printf '%s\n' "$certifi_file"
        return 0
    fi

    if command -v brew >/dev/null 2>&1; then
        homebrew_ca_prefix=$(brew --prefix ca-certificates 2>/dev/null || :)
        homebrew_ca_file=$homebrew_ca_prefix/share/ca-certificates/cacert.pem
        if [ -n "$homebrew_ca_prefix" ] && [ -r "$homebrew_ca_file" ]; then
            printf '%s\n' "$homebrew_ca_file"
            return 0
        fi
    fi

    system_ca_file=${NVIM_SYSTEM_CA_BUNDLE:-/etc/ssl/cert.pem}
    if [ -r "$system_ca_file" ]; then
        printf '%s\n' "$system_ca_file"
        return 0
    fi

    printf '%s\n' 'Unable to find a trusted CA bundle; set SSL_CERT_FILE to a readable certificate bundle.' >&2
    return 1
}

certificate_file=$(resolve_certificate_file)
SSL_CERT_FILE=$certificate_file
export SSL_CERT_FILE

destination_parent=$(dirname "$destination")
mkdir -p "$destination_parent"
install_root=$(mktemp -d "$destination_parent/.nvim-luarocks-install.XXXXXX")
destination_created=false

cleanup() {
    rm -rf "$install_root"
    if [ "$destination_created" = true ]; then
        rm -rf "$destination"
    fi
}
trap cleanup EXIT HUP INT TERM

git clone --filter=blob:none https://github.com/luarocks/hererocks "$install_root/hererocks"

if [ -e "$destination" ] || [ -L "$destination" ] || ! mkdir "$destination"; then
    printf 'Refusing to replace destination created during installation: %s\n' "$destination" >&2
    exit 1
fi
destination_created=true

python3 "$install_root/hererocks/hererocks.py" "$destination" -l 5.1 -r latest

if ! is_valid_installation; then
    printf '%s\n' 'The generated environment is not a valid Lua 5.1 and LuaRocks installation.' >&2
    exit 1
fi

destination_created=false
printf 'Installed Neovim Lua 5.1 and LuaRocks environment: %s\n' "$destination"
