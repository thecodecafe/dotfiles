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

delete_preference() {
    defaults delete "$1" "$2" >/dev/null 2>&1 || :
}

delete_preference com.microsoft.VSCode ApplePressAndHoldEnabled
delete_preference com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled
delete_preference com.vscodium ApplePressAndHoldEnabled
delete_preference com.microsoft.VSCodeExploration ApplePressAndHoldEnabled
delete_preference com.exafunction.windsurf ApplePressAndHoldEnabled
delete_preference -g ApplePressAndHoldEnabled

script_dir=$(CDPATH= cd -- "$(/usr/bin/dirname "$0")" && pwd -P)
/bin/sh "$script_dir/manage-global-preferences.sh" reset

printf '%s\n' 'Reset macOS key repetition and press-and-hold overrides.'
