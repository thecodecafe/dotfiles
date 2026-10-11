#!/bin/sh

set -eu

daemon_target=system/org.pqrs.service.daemon.Karabiner-Core-Service
user_domain=gui/${SUDO_UID:-$(id -u)}
agent_target=$user_domain/org.pqrs.service.agent.Karabiner-Core-Service-rev2
previous_agent_target=$user_domain/org.pqrs.service.agent.Karabiner-Core-Service
core_targets="$agent_target $previous_agent_target $daemon_target"
support_directory=${KARABINER_SUPPORT_DIR:-/Library/Application Support/org.pqrs/Karabiner-Elements}
daemon_plist="$support_directory/Karabiner-Elements Privileged Daemons v2.app/Contents/Library/LaunchDaemons/org.pqrs.service.daemon.Karabiner-Core-Service.plist"
agent_plist="$support_directory/Karabiner-Elements Non-Privileged Agents v2.app/Contents/Library/LaunchAgents/org.pqrs.service.agent.Karabiner-Core-Service.plist"

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
    printf 'Would %s Karabiner Core Service agent and daemon using launchctl: %s\n' "$operation" "$core_targets"
    exit 0
fi

[ "$(uname -s)" = Darwin ] || { printf '%s\n' 'Karabiner Core Service control is supported on macOS only.' >&2; exit 1; }

is_loaded() {
    launchctl print "$1" >/dev/null 2>&1
}

run_launchctl() {
    service_target=$1
    shift
    case "$service_target" in
        system/*) sudo launchctl "$@" "$service_target" ;;
        *) launchctl "$@" "$service_target" ;;
    esac
}

loaded_targets() {
    for candidate in $core_targets; do
        if is_loaded "$candidate"; then
            printf '%s\n' "$candidate"
        fi
    done
}

register_service() {
    registration_target=$1
    registration_plist=$2
    if is_loaded "$registration_target" || [ ! -f "$registration_plist" ]; then
        return 0
    fi
    registration_domain=${registration_target%/*}
    if [ "$registration_domain" = system ]; then
        sudo launchctl bootstrap "$registration_domain" "$registration_plist" || is_loaded "$registration_target"
    else
        launchctl bootstrap "$registration_domain" "$registration_plist" || is_loaded "$registration_target"
    fi
}

case "$operation" in
    stop)
        sudo -v
        # Both the agent and root daemon can be loaded on the same machine.
        # Disable every Core Service target before unloading either one.
        for target in $core_targets; do
            run_launchctl "$target" disable
        done
        for target in $core_targets; do
            if is_loaded "$target"; then
                if ! run_launchctl "$target" bootout && is_loaded "$target"; then
                    printf 'Could not unload Karabiner Core Service: %s\n' "$target" >&2
                    exit 1
                fi
            fi
        done
        attempt=0
        remaining=$(loaded_targets)
        while [ -n "$remaining" ] && [ "$attempt" -lt 10 ]; do
            sleep 1
            attempt=$((attempt + 1))
            remaining=$(loaded_targets)
        done
        if [ -n "$remaining" ]; then
            printf 'Karabiner Core Service is still loaded after stop:\n%s\n' "$remaining" >&2
            exit 1
        fi
        printf '%s\n' 'Karabiner Core Service stopped and disabled until explicitly started.'
        ;;
    start)
        sudo -v
        for target in $core_targets; do
            run_launchctl "$target" enable
        done
        # Reopening an already-open Settings app does not register services
        # removed by bootout. Restore them from the installed service plists.
        register_service "$daemon_target" "$daemon_plist"
        register_service "$agent_target" "$agent_plist"
        if ! is_loaded "$daemon_target"; then
            open -a Karabiner-Elements
        fi
        attempt=0
        while ! is_loaded "$daemon_target" && [ "$attempt" -lt 10 ]; do
            sleep 1
            attempt=$((attempt + 1))
        done
        if ! is_loaded "$daemon_target"; then
            printf 'Karabiner Core Service did not register. Check Karabiner-Elements and its Login Items permissions; expected daemon: %s\n' "$daemon_target" >&2
            exit 1
        fi
        for target in $core_targets; do
            if is_loaded "$target"; then
                run_launchctl "$target" kickstart -k
            fi
        done
        printf '%s\n' 'Karabiner Core Service enabled and restarted.'
        ;;
    status)
        remaining=$(loaded_targets)
        if [ -n "$remaining" ]; then
            printf 'Karabiner Core Service: loaded\n%s\n' "$remaining"
        else
            printf '%s\n' 'Karabiner Core Service: not loaded'
            exit 1
        fi
        ;;
esac
