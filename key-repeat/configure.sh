#!/bin/sh

set -eu

if [ "$(uname -s)" != "Darwin" ]; then
    printf '%s\n' 'The key-repeat module requires macOS.' >&2
    exit 1
fi

if ! command -v defaults >/dev/null 2>&1; then
    printf '%s\n' 'The macOS defaults command is unavailable.' >&2
    exit 1
fi

write_app_preference() {
    defaults write "$1" ApplePressAndHoldEnabled -bool false >/dev/null 2>&1 || :
}

write_app_preference com.microsoft.VSCode
write_app_preference com.microsoft.VSCodeInsiders
write_app_preference com.vscodium
write_app_preference com.microsoft.VSCodeExploration
write_app_preference com.exafunction.windsurf
defaults delete -g ApplePressAndHoldEnabled >/dev/null 2>&1 || :
write_app_preference com.microsoft.VSCode

script_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")" && pwd -P)
/bin/sh "$script_dir/manage-global-preferences.sh" set

printf '%s\n' 'Configured macOS key repetition and press-and-hold behavior.'
