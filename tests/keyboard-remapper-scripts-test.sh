#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

for script in \
    scripts/kanata-service.sh \
    scripts/karabiner-core-service.sh \
    scripts/refresh-karabiner.sh \
    scripts/switch-keyboard-remapper.sh
do
    sh -n "$project_root/$script" || fail "$script has a shell syntax error"
done

service_output=$("$project_root/scripts/kanata-service.sh" install --dry-run)
case "$service_output" in
    *'com.thecodecafe.kanata'*'service disabled'*) ;;
    *) fail "Kanata service dry-run output is unexpected: $service_output" ;;
esac

core_output=$("$project_root/scripts/karabiner-core-service.sh" stop --dry-run)
case "$core_output" in
    *'org.pqrs.service.daemon.Karabiner-Core-Service'*'launchctl'*) ;;
    *) fail "Karabiner Core Service dry-run output is unexpected: $core_output" ;;
esac

switch_output=$(HOME="$project_root/tests" "$project_root/scripts/switch-keyboard-remapper.sh" kanata --dry-run)
case "$switch_output" in
    *'stop Karabiner Core Service'*'start Kanata'*) ;;
    *) fail "Kanata switch dry-run omits the coordinated handoff: $switch_output" ;;
esac

switch_output=$(HOME="$project_root/tests" "$project_root/scripts/switch-keyboard-remapper.sh" karabiner --dry-run)
case "$switch_output" in
    *'stop Kanata'*'start/refresh Karabiner Core Service'*) ;;
    *) fail "Karabiner switch dry-run omits the coordinated handoff: $switch_output" ;;
esac

printf '%s\n' 'Keyboard remapper script tests passed.'
