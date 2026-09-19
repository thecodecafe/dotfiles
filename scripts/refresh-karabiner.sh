#!/bin/sh

set -eu

mode=${1:-reload}
[ "$#" -le 1 ] || { printf 'Usage: %s [reload|start]\n' "$0" >&2; exit 64; }
case "$mode" in
    reload|start) ;;
    *) printf 'Usage: %s [reload|start]\n' "$0" >&2; exit 64 ;;
esac

[ "$(uname -s)" = Darwin ] || { printf '%s\n' 'Karabiner refresh is supported on macOS only.' >&2; exit 1; }

label=org.pqrs.service.agent.Karabiner-Console-User-Server
domain=gui/$(id -u)
if launchctl print "$domain/$label" >/dev/null 2>&1; then
    launchctl kickstart -k "$domain/$label"
    printf '%s\n' 'Restarted Karabiner Console User Server to reload its configuration.'
elif [ "$mode" = start ]; then
    open -a Karabiner-Elements
    printf '%s\n' 'Opened Karabiner-Elements to load its configuration.'
else
    printf '%s\n' 'Karabiner is not running; its configuration will be read when Karabiner-Elements starts.'
fi
