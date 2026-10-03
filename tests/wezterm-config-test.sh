#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/wezterm/wezterm.lua

grep -Fq "wezterm.font('CommitMono Nerd Font Mono')" "$config_file"
grep -Fq 'config.font_size = 12' "$config_file"
grep -Fq 'config.window_background_opacity = 0.9' "$config_file"
grep -Fq "background = '#000000'" "$config_file"
grep -Fq "foreground = '#E8EAED'" "$config_file"
grep -Fq "cursor = '#FE8010'" "$config_file"
grep -Fq "selection = '#FE8019'" "$config_file"
grep -Fq "active_tab = '#1A1A1A'" "$config_file"
grep -Fq 'active_titlebar_bg = colors.background' "$config_file"
grep -Fq 'inactive_titlebar_bg = colors.background' "$config_file"

if command -v luac >/dev/null 2>&1; then
    luac -p "$config_file"
fi

wezterm_bin=$(command -v wezterm || true)
if [ -z "$wezterm_bin" ] && [ -x /Applications/WezTerm.app/Contents/MacOS/wezterm ]; then
    wezterm_bin=/Applications/WezTerm.app/Contents/MacOS/wezterm
fi

if [ -n "$wezterm_bin" ]; then
    "$wezterm_bin" --config-file "$config_file" show-keys >/dev/null
else
    printf '%s\n' 'WezTerm is unavailable; skipped runtime configuration validation.'
fi

printf '%s\n' 'WezTerm configuration test passed.'
