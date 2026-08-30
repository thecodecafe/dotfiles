#!/bin/sh

set -eu

action=${1:-}
case "$action" in
    set|reset) ;;
    *)
        printf '%s\n' 'Usage: manage-global-preferences.sh set|reset' >&2
        exit 2
        ;;
esac

preferences_file=$HOME/Library/Preferences/.GlobalPreferences.plist
restart_delay=${KEY_REPEAT_RESTART_DELAY:-1}
preferences_error=
repair_directory=
repair_backup=
repair_active=0
preserve_backup=0

restart_preferences_service() {
    if command -v pkill >/dev/null 2>&1; then
        pkill -u "$(/usr/bin/id -u)" -x cfprefsd >/dev/null 2>&1 || :
    fi

    sleep "$restart_delay"
}

restore_preferences() {
    if [ "$repair_active" -ne 1 ]; then
        return 0
    fi

    if /bin/cp -p "$repair_backup" "$preferences_file"; then
        repair_active=0
        restart_preferences_service
        return 0
    fi

    preserve_backup=1
    printf 'Automatic rollback failed. The original preferences backup is at %s.\n' \
        "$repair_backup" >&2
    return 1
}

cleanup() {
    status=$?
    trap - 0 HUP INT TERM

    restore_preferences || status=1

    if [ -n "$repair_directory" ] && [ "$preserve_backup" -eq 0 ]; then
        /bin/rm -rf "$repair_directory"
    fi

    exit "$status"
}

trap cleanup 0
trap 'exit 1' HUP INT TERM

record_error() {
    if [ -n "$1" ]; then
        preferences_error=$1
    fi
}

write_global_preference() {
    key=$1
    value=$2

    if output=$(defaults write NSGlobalDomain "$key" -int "$value" 2>&1); then
        return 0
    fi
    record_error "$output"

    if output=$(defaults write -g "$key" -int "$value" 2>&1); then
        return 0
    fi
    record_error "$output"
    return 1
}

delete_global_preference() {
    key=$1

    if output=$(defaults delete NSGlobalDomain "$key" 2>&1); then
        return 0
    fi
    record_error "$output"

    if output=$(defaults delete -g "$key" 2>&1); then
        return 0
    fi
    record_error "$output"
    return 1
}

apply_with_defaults() {
    result=0

    if [ "$action" = set ]; then
        write_global_preference InitialKeyRepeat 15 || result=1
        write_global_preference KeyRepeat 1 || result=1
    else
        delete_global_preference InitialKeyRepeat || :
        delete_global_preference KeyRepeat || :
    fi

    return "$result"
}

plist_value_is() {
    key=$1
    expected=$2
    value=$(/usr/bin/plutil -extract "$key" raw "$preferences_file" 2>/dev/null) || return 1
    [ "$value" = "$expected" ]
}

defaults_value_is() {
    key=$1
    expected=$2
    value=$(defaults read -g "$key" 2>/dev/null) || return 1
    [ "$value" = "$expected" ]
}

preference_is_absent() {
    key=$1

    if defaults read -g "$key" >/dev/null 2>&1; then
        return 1
    fi

    if [ -e "$preferences_file" ] && \
        /usr/bin/plutil -extract "$key" raw "$preferences_file" >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

preferences_match() {
    if [ "$action" = set ]; then
        [ -f "$preferences_file" ] || return 1
        defaults_value_is InitialKeyRepeat 15 &&
            defaults_value_is KeyRepeat 1 &&
            plist_value_is InitialKeyRepeat 15 &&
            plist_value_is KeyRepeat 1
    else
        preference_is_absent InitialKeyRepeat &&
            preference_is_absent KeyRepeat
    fi
}

validate_preferences_file() {
    if [ -L "$preferences_file" ] || [ ! -f "$preferences_file" ]; then
        printf 'Refusing direct repair: %s is not a regular preferences file.\n' \
            "$preferences_file" >&2
        return 1
    fi

    if [ ! -w "$preferences_file" ]; then
        printf 'Refusing direct repair: %s is not writable.\n' "$preferences_file" >&2
        return 1
    fi

    owner_uid=$(stat -f '%u' "$preferences_file") || return 1
    current_uid=$(/usr/bin/id -u)
    if [ "$owner_uid" != "$current_uid" ]; then
        printf 'Refusing direct repair: %s is owned by UID %s, not the current UID %s.\n' \
            "$preferences_file" "$owner_uid" "$current_uid" >&2
        return 1
    fi

    if ! /usr/bin/plutil -lint "$preferences_file" >/dev/null; then
        printf 'Refusing direct repair: %s is not a valid property list.\n' \
            "$preferences_file" >&2
        return 1
    fi
}

set_plist_integer() {
    key=$1
    value=$2

    if /usr/bin/plutil -extract "$key" raw "$preferences_file" >/dev/null 2>&1; then
        /usr/bin/plutil -replace "$key" -integer "$value" "$preferences_file"
    else
        /usr/bin/plutil -insert "$key" -integer "$value" "$preferences_file"
    fi
}

remove_plist_key() {
    key=$1
    /usr/bin/plutil -remove "$key" "$preferences_file" >/dev/null 2>&1 || :
}

repair_preferences_file() {
    validate_preferences_file || return 1

    repair_directory=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/key-repeat.XXXXXX") || return 1
    repair_backup=$repair_directory/.GlobalPreferences.plist
    /bin/cp -p "$preferences_file" "$repair_backup" || return 1
    repair_active=1

    if command -v pkill >/dev/null 2>&1; then
        pkill -u "$(/usr/bin/id -u)" -x cfprefsd >/dev/null 2>&1 || :
    fi

    if [ "$action" = set ]; then
        set_plist_integer InitialKeyRepeat 15 || return 1
        set_plist_integer KeyRepeat 1 || return 1
    else
        remove_plist_key InitialKeyRepeat
        remove_plist_key KeyRepeat
    fi

    /usr/bin/plutil -lint "$preferences_file" >/dev/null || return 1
    restart_preferences_service

    if ! preferences_match; then
        printf '%s\n' 'The repaired plist did not synchronize with the macOS preferences service.' >&2
        return 1
    fi

    repair_active=0
    /bin/rm -rf "$repair_directory"
    repair_directory=
    repair_backup=
}

apply_with_defaults || :
if preferences_match; then
    exit 0
fi

restart_preferences_service
apply_with_defaults || :
if preferences_match; then
    exit 0
fi

if repair_preferences_file; then
    exit 0
fi

printf 'Unable to %s the global key-repeat preferences after guarded repair.\n' "$action" >&2
if [ -n "$preferences_error" ]; then
    printf 'macOS reported: %s\n' "$preferences_error" >&2
fi
printf '%s\n' 'Log out or reboot macOS, then run the command again.' >&2
exit 1
