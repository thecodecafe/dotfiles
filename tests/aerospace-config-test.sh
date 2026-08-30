#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/aerospace/aerospace.toml

[ -s "$config_file" ] || {
    printf '%s\n' 'FAIL: AeroSpace configuration is missing or empty.' >&2
    exit 1
}

grep -Fqx 'config-version = 2' "$config_file"
grep -Fqx 'start-at-login = true' "$config_file"
grep -Fqx "default-root-container-layout = 'tiles'" "$config_file"
grep -Fqx "default-root-container-orientation = 'auto'" "$config_file"
grep -Fqx 'persistent-workspaces = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B",' "$config_file"
grep -Fqx "    preset = 'qwerty'" "$config_file"
grep -Fqx "    alt-h = 'focus --boundaries-action wrap-around-the-workspace left'" "$config_file"
grep -Fqx "    alt-shift-h = 'move left'" "$config_file"
grep -Fqx "    alt-tab = 'workspace-back-and-forth'" "$config_file"
grep -Fqx "    esc = ['reload-config', 'mode main']" "$config_file"
grep -Fqx 'if.app-id = "com.mitchellh.ghostty"' "$config_file"
grep -Fqx 'if.app-id = "ai.opencode.desktop"' "$config_file"

printf '%s\n' 'AeroSpace configuration test passed.'
