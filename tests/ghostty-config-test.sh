#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/ghostty/config

if ! command -v ghostty >/dev/null 2>&1; then
    printf '%s\n' 'Ghostty is unavailable; skipping configuration validation.'
    exit 0
fi

ghostty +validate-config --config-file="$config_file"
ghostty +show-face --font-family="CommitMono Nerd Font" --string=A >/dev/null

grep -Fqx 'font-family = "CommitMono Nerd Font"' "$config_file"
grep -Fqx 'font-size = 12' "$config_file"

printf '%s\n' 'Ghostty configuration test passed.'
