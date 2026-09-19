#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
karabiner_source=$project_root/karabiner/karabiner.json
karabiner_destination=${KARABINER_CONFIG_FILE:-${HOME:?HOME is not set}/.config/karabiner/karabiner.json}
service=$project_root/scripts/kanata-service.sh
core_service=$project_root/scripts/karabiner-core-service.sh
refresh=$project_root/scripts/refresh-karabiner.sh
dry_run=false

usage() {
    printf 'Usage: %s <kanata|karabiner> [--dry-run]\n' "$0" >&2
    exit 64
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi
mode=$1
if [ "$#" -eq 2 ]; then
    [ "$2" = --dry-run ] || usage
    dry_run=true
fi
case "$mode" in
    kanata|karabiner) ;;
    *) usage ;;
esac

if [ "$dry_run" = true ]; then
    printf 'Would switch keyboard remapping to %s\n' "$mode"
    if [ "$mode" = kanata ]; then
        printf 'Would stop Karabiner Core Service, unlink %s, and start Kanata.\n' "$karabiner_destination"
    else
        printf 'Would stop Kanata, link %s to %s, and start/refresh Karabiner Core Service.\n' "$karabiner_source" "$karabiner_destination"
    fi
    exit 0
fi

if [ "$mode" = kanata ]; then
    [ -f /Library/LaunchDaemons/com.thecodecafe.kanata.plist ] || {
        printf '%s\n' 'Kanata service is not installed; run make kanata-service-install first.' >&2
        exit 1
    }
    restore_karabiner() {
        "$service" stop || :
        make -s -C "$project_root" karabiner KARABINER_CONFIG_FILE="$karabiner_destination" || :
        "$core_service" start || :
        "$refresh" start || :
    }

    if ! "$core_service" stop; then
        printf '%s\n' 'Could not stop Karabiner Core Service; leaving its config link unchanged.' >&2
        exit 1
    fi
    if ! make -s -C "$project_root" unlink-karabiner KARABINER_CONFIG_FILE="$karabiner_destination"; then
        printf '%s\n' 'Could not unlink the Karabiner config; restoring Karabiner service.' >&2
        restore_karabiner
        exit 1
    fi
    if [ -e "$karabiner_destination" ] || [ -L "$karabiner_destination" ]; then
        printf 'Karabiner config destination remains in place; refusing to start Kanata: %s\n' "$karabiner_destination" >&2
        restore_karabiner
        exit 1
    fi
    if "$service" start; then
        printf '%s\n' 'Kanata is now active. Use make keyboard-karabiner to switch back.'
    else
        printf '%s\n' 'Kanata failed to start; restoring the Karabiner config link.' >&2
        restore_karabiner
        exit 1
    fi
else
    "$service" stop
    if ! make -s -C "$project_root" karabiner KARABINER_CONFIG_FILE="$karabiner_destination"; then
        "$service" start || :
        exit 1
    fi
    if ! "$core_service" start || ! "$refresh" start; then
        printf '%s\n' 'Karabiner did not come back up; its config link is restored but the Core Service needs attention.' >&2
        exit 1
    fi
    printf '%s\n' 'Karabiner is now active. Use make keyboard-kanata to switch back.'
fi
