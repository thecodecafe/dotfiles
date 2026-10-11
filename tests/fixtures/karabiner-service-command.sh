#!/bin/sh

# Simulate launchd for the Core Service tests without controlling real services.
set -eu
command_name=$(basename "$0")
test_directory=${KARABINER_SERVICE_TEST_DIRECTORY:?test directory is required}
printf '%s %s\n' "$command_name" "$*" >> "$test_directory/commands"

case "$command_name" in
    uname) printf '%s\n' Darwin ;;
    id) printf '%s\n' 501 ;;
    sudo)
        if [ "$1" = -v ]; then
            [ "${KARABINER_SERVICE_TEST_AUTH_FAILURE:-false}" != true ]
        else
            exec "$@"
        fi
        ;;
    sleep) exit 0 ;;
    open)
        [ "${KARABINER_SERVICE_TEST_OPEN_NO_REGISTER:-false}" != true ] || exit 0
        touch "$test_directory/loaded.org.pqrs.service.daemon.Karabiner-Core-Service"
        if [ "${KARABINER_SERVICE_TEST_LAYOUT:-dual}" = dual ]; then
            touch "$test_directory/loaded.org.pqrs.service.agent.Karabiner-Core-Service-rev2"
        fi
        ;;
    launchctl)
        operation=$1
        for argument do service_target=$argument; done
        if [ "$operation" = bootstrap ]; then
            case "$service_target" in
                */LaunchDaemons/org.pqrs.service.daemon.Karabiner-Core-Service.plist)
                    touch "$test_directory/loaded.org.pqrs.service.daemon.Karabiner-Core-Service"
                    ;;
                */LaunchAgents/org.pqrs.service.agent.Karabiner-Core-Service.plist)
                    touch "$test_directory/loaded.org.pqrs.service.agent.Karabiner-Core-Service-rev2"
                    ;;
                *) printf 'Unexpected bootstrap plist: %s\n' "$service_target" >&2; exit 1 ;;
            esac
            exit 0
        fi
        label=${service_target##*/}
        case "$label" in
            org.pqrs.service.agent.Karabiner-Core-Service-rev2|org.pqrs.service.agent.Karabiner-Core-Service|org.pqrs.service.daemon.Karabiner-Core-Service) ;;
            *) printf 'Unexpected service target: %s\n' "$service_target" >&2; exit 1 ;;
        esac
        case "$operation" in
            print)
                [ -f "$test_directory/loaded.$label" ] || exit 1
                if [ -f "$test_directory/pending.$label" ]; then
                    rm "$test_directory/pending.$label" "$test_directory/loaded.$label"
                fi
                printf '%s\n' 'state = running'
                ;;
            disable) touch "$test_directory/disabled.$label" ;;
            enable) rm -f "$test_directory/disabled.$label" ;;
            bootout)
                if [ "${KARABINER_SERVICE_TEST_STUCK:-}" = "$label" ]; then
                    exit 0
                elif [ "${KARABINER_SERVICE_TEST_DELAY:-false}" = true ]; then
                    touch "$test_directory/pending.$label"
                else
                    rm "$test_directory/loaded.$label"
                fi
                ;;
            kickstart) [ -f "$test_directory/loaded.$label" ] ;;
            *) printf 'Unexpected launchctl operation: %s\n' "$operation" >&2; exit 1 ;;
        esac
        ;;
    *) printf 'Unexpected test command: %s\n' "$command_name" >&2; exit 1 ;;
esac
