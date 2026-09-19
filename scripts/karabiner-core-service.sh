#!/bin/sh

set -eu

label=org.pqrs.service.daemon.Karabiner-Core-Service
domain=system

usage() {
    printf 'Usage: %s <start|stop|status> [--dry-run]\n' "$0" >&2
    exit 64
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage
operation=$1
dry_run=false
if [ "$#" -eq 2 ]; then
    [ "$2" = --dry-run ] || usage
    dry_run=true
fi
case "$operation" in
    start|stop|status) ;;
    *) usage ;;
esac

if [ "$dry_run" = true ]; then
    printf 'Would %s Karabiner Core Service (%s/%s) using launchctl.\n' "$operation" "$domain" "$label"
    exit 0
fi

[ "$(uname -s)" = Darwin ] || { printf '%s\n' 'Karabiner Core Service control is supported on macOS only.' >&2; exit 1; }

is_loaded() {
    sudo launchctl print "$domain/$label" >/dev/null 2>&1
}

case "$operation" in
    stop)
        if ! is_loaded; then
            printf '%s\n' 'Karabiner Core Service is not loaded; nothing to stop.'
            exit 0
        fi
        sudo -v
        sudo launchctl disable "$domain/$label"
        sudo launchctl bootout "$domain/$label"
        if is_loaded; then
            printf '%s\n' 'Karabiner Core Service is still loaded after stop.' >&2
            exit 1
        fi
        printf '%s\n' 'Karabiner Core Service stopped and disabled until explicitly started.'
        ;;
    start)
        sudo -v
        sudo launchctl enable "$domain/$label"
        if is_loaded; then
            sudo launchctl kickstart -k "$domain/$label"
        else
            open -a Karabiner-Elements
            attempt=0
            while [ "$attempt" -lt 10 ] && ! is_loaded; do
                sleep 1
                attempt=$((attempt + 1))
            done
            if ! is_loaded; then
                printf 'Karabiner Core Service did not register. Check Karabiner-Elements and its Login Items permissions; expected label: %s\n' "$label" >&2
                exit 1
            fi
            sudo launchctl kickstart -k "$domain/$label"
        fi
        printf '%s\n' 'Karabiner Core Service enabled and restarted.'
        ;;
    status)
        if is_loaded; then
            printf '%s\n' 'Karabiner Core Service: loaded'
        else
            printf '%s\n' 'Karabiner Core Service: not loaded'
            exit 1
        fi
        ;;
esac
