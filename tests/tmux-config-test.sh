#!/bin/sh

set -eu

if ! command -v tmux >/dev/null 2>&1; then
    printf '%s\n' 'tmux is unavailable; skipping configuration test.'
    exit 0
fi

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/tmux/tmux.conf
socket_name=dotfiles-config-test-$$

cleanup() {
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || :
}
trap cleanup EXIT HUP INT TERM

tmux -L "$socket_name" -f "$config_file" new-session -d -s config-test 'sleep 60'

[ "$(tmux -L "$socket_name" show-options -gv mouse)" = 'on' ]
[ "$(tmux -L "$socket_name" show-options -gv base-index)" = '1' ]
[ "$(tmux -L "$socket_name" show-window-options -gv pane-base-index)" = '1' ]
[ "$(tmux -L "$socket_name" show-window-options -gv mode-keys)" = 'vi' ]

printf '%s\n' 'tmux configuration test passed.'
