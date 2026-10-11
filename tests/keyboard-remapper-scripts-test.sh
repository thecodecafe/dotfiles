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
    *'launchctl'*'org.pqrs.service.agent.Karabiner-Core-Service-rev2'*'system/org.pqrs.service.daemon.Karabiner-Core-Service'*) ;;
    *) fail "Karabiner Core Service dry-run output is unexpected: $core_output" ;;
esac

start_output=$("$project_root/scripts/karabiner-core-service.sh" start --dry-run)
case "$start_output" in
    *'launchctl'*'org.pqrs.service.agent.Karabiner-Core-Service-rev2'*'system/org.pqrs.service.daemon.Karabiner-Core-Service'*) ;;
    *) fail "Karabiner Core Service start dry-run output is unexpected: $start_output" ;;
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

test_directory=$(mktemp -d "${TMPDIR:-/tmp}/karabiner-service-test.XXXXXX")
trap 'rm -rf "$test_directory"' EXIT HUP INT TERM
mkdir "$test_directory/bin"
for command_name in launchctl sudo uname id open sleep; do
    ln -s "$project_root/tests/fixtures/karabiner-service-command.sh" "$test_directory/bin/$command_name"
done
export KARABINER_SERVICE_TEST_DIRECTORY=$test_directory
export KARABINER_SUPPORT_DIR=$test_directory/karabiner
daemon_plist_directory="$KARABINER_SUPPORT_DIR/Karabiner-Elements Privileged Daemons v2.app/Contents/Library/LaunchDaemons"
agent_plist_directory="$KARABINER_SUPPORT_DIR/Karabiner-Elements Non-Privileged Agents v2.app/Contents/Library/LaunchAgents"
mkdir -p "$daemon_plist_directory" "$agent_plist_directory"
touch "$daemon_plist_directory/org.pqrs.service.daemon.Karabiner-Core-Service.plist" "$agent_plist_directory/org.pqrs.service.agent.Karabiner-Core-Service.plist"
test_path=$test_directory/bin:$PATH
agent=org.pqrs.service.agent.Karabiner-Core-Service-rev2
daemon=org.pqrs.service.daemon.Karabiner-Core-Service

# Modern Karabiner runs an agent and a root daemon at the same time.
touch "$test_directory/loaded.$agent" "$test_directory/loaded.$daemon"
PATH="$test_path" "$project_root/scripts/karabiner-core-service.sh" stop >/dev/null
[ ! -e "$test_directory/loaded.$agent" ] || fail 'Core Service agent was not unloaded'
[ ! -e "$test_directory/loaded.$daemon" ] || fail 'Core Service daemon was not unloaded'
grep -Fqx "launchctl bootout gui/501/$agent" "$test_directory/commands" || fail 'user agent was not unloaded in the GUI domain'
grep -Fqx "sudo launchctl bootout system/$daemon" "$test_directory/commands" || fail 'root daemon was not unloaded with sudo'

# Settings may already be open and cannot be relied on to re-register services.
PATH="$test_path" KARABINER_SERVICE_TEST_OPEN_NO_REGISTER=true "$project_root/scripts/karabiner-core-service.sh" start >/dev/null
[ -e "$test_directory/loaded.$agent" ] || fail 'Core Service agent was not restored'
[ -e "$test_directory/loaded.$daemon" ] || fail 'Core Service daemon was not restored'
[ ! -e "$test_directory/disabled.$agent" ] || fail 'Core Service agent remains disabled'
[ ! -e "$test_directory/disabled.$daemon" ] || fail 'Core Service daemon remains disabled'
grep -Fqx "launchctl kickstart -k gui/501/$agent" "$test_directory/commands" || fail 'restored user agent was not restarted'
grep -Fqx "sudo launchctl kickstart -k system/$daemon" "$test_directory/commands" || fail 'restored daemon was not restarted'
grep -Fq "sudo launchctl bootstrap system $daemon_plist_directory/" "$test_directory/commands" || fail 'missing daemon was not explicitly registered'
grep -Fq "launchctl bootstrap gui/501 $agent_plist_directory/" "$test_directory/commands" || fail 'missing agent was not explicitly registered'

# Wait for asynchronous unloads rather than reporting a false failure.
PATH="$test_path" KARABINER_SERVICE_TEST_DELAY=true "$project_root/scripts/karabiner-core-service.sh" stop >/dev/null
[ ! -e "$test_directory/loaded.$daemon" ] || fail 'delayed daemon unload was not observed'
grep -Fqx 'sleep 1' "$test_directory/commands" || fail 'delayed service unload was not awaited'

# Machines with just the original root daemon must still stop and restore it.
PATH="$test_path" KARABINER_SUPPORT_DIR="$test_directory/legacy" KARABINER_SERVICE_TEST_LAYOUT=legacy "$project_root/scripts/karabiner-core-service.sh" start >/dev/null
[ -e "$test_directory/loaded.$daemon" ] || fail 'legacy daemon was not restored'
[ ! -e "$test_directory/loaded.$agent" ] || fail 'legacy test unexpectedly loaded an agent'
PATH="$test_path" "$project_root/scripts/karabiner-core-service.sh" stop >/dev/null
[ ! -e "$test_directory/loaded.$daemon" ] || fail 'legacy daemon was not stopped'

# Fail when a daemon stays loaded; never report a successful handoff.
touch "$test_directory/loaded.$daemon"
if PATH="$test_path" KARABINER_SERVICE_TEST_STUCK="$daemon" "$project_root/scripts/karabiner-core-service.sh" stop >"$test_directory/failure-output" 2>&1; then
    fail 'a stuck Core Service daemon was accepted as stopped'
fi
grep -Fq "system/$daemon" "$test_directory/failure-output" || fail 'stop failure does not identify the remaining service'

# A sudo failure must occur before any service is disabled or unloaded.
rm "$test_directory/commands"
if PATH="$test_path" KARABINER_SERVICE_TEST_AUTH_FAILURE=true "$project_root/scripts/karabiner-core-service.sh" stop >/dev/null 2>&1; then
    fail 'failed administrator authentication was accepted'
fi
if grep -Eq 'launchctl (disable|bootout)' "$test_directory/commands"; then
    fail 'services were changed before administrator authentication succeeded'
fi

printf '%s\n' 'Keyboard remapper script tests passed.'
