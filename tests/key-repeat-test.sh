#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
script=$project_root/key-repeat/configure.sh
reset_script=$project_root/key-repeat/reset.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/key-repeat.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

fake_bin=$test_root/bin
mkdir -p "$fake_bin"

printf '%s\n' '#!/bin/sh' 'printf "%s\n" Darwin' > "$fake_bin/uname"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$fake_bin/sleep"
printf '%s\n' \
    '#!/bin/sh' \
    'count=0' \
    'if [ -f "$KEY_REPEAT_STATE_DIR/pkill-count" ]; then IFS= read -r count < "$KEY_REPEAT_STATE_DIR/pkill-count"; fi' \
    'count=$((count + 1))' \
    'printf "%s\n" "$count" > "$KEY_REPEAT_STATE_DIR/pkill-count"' \
    'printf "%s\n" "$*" >> "$KEY_REPEAT_LOG.pkill"' > "$fake_bin/pkill"
printf '%s\n' \
    '#!/bin/sh' \
    'if [ -n "${KEY_REPEAT_FAKE_OWNER:-}" ]; then printf "%s\n" "$KEY_REPEAT_FAKE_OWNER"; exit 0; fi' \
    'exec /usr/bin/stat "$@"' > "$fake_bin/stat"
printf '%s\n' \
    '#!/bin/sh' \
    'printf "%s\n" "$*" >> "$KEY_REPEAT_LOG"' \
    'plist=$HOME/Library/Preferences/.GlobalPreferences.plist' \
    'mode=${KEY_REPEAT_DEFAULTS_MODE:-standard}' \
    'command_name=${1:-}' \
    'domain=${2:-}' \
    'key=${3:-}' \
    'if [ "$command_name" = write ] && [ "$domain" = com.vscodium ] && [ "${KEY_REPEAT_MISSING_APP:-0}" -eq 1 ]; then exit 1; fi' \
    'case "$domain" in NSGlobalDomain|-g) ;; *) exit 0 ;; esac' \
    'if [ "$mode" = alias ] && [ "$domain" = NSGlobalDomain ]; then printf "%s\n" "simulated NSGlobalDomain failure" >&2; exit 1; fi' \
    'count=0' \
    'if [ -f "$KEY_REPEAT_STATE_DIR/pkill-count" ]; then IFS= read -r count < "$KEY_REPEAT_STATE_DIR/pkill-count"; fi' \
    'case "$mode" in' \
    '  retry) if [ "$count" -lt 1 ]; then printf "%s\n" "simulated retryable failure" >&2; exit 1; fi ;;' \
    '  stuck) if [ "$command_name" != read ] || [ "$count" -lt 3 ]; then printf "%s\n" "simulated stuck preferences service" >&2; exit 1; fi ;;' \
    '  verify-fail) printf "%s\n" "simulated permanent preferences failure" >&2; exit 1 ;;' \
    'esac' \
    'case "$command_name" in' \
    '  write)' \
    '    value=${5:-}' \
    '    if /usr/bin/plutil -extract "$key" raw "$plist" >/dev/null 2>&1; then' \
    '      /usr/bin/plutil -replace "$key" -integer "$value" "$plist"' \
    '    else' \
    '      /usr/bin/plutil -insert "$key" -integer "$value" "$plist"' \
    '    fi' \
    '    ;;' \
    '  delete) /usr/bin/plutil -remove "$key" "$plist" >/dev/null 2>&1 ;;' \
    '  read) /usr/bin/plutil -extract "$key" raw "$plist" ;;' \
    '  *) exit 1 ;;' \
    'esac' > "$fake_bin/defaults"
chmod +x "$fake_bin/uname" "$fake_bin/sleep" "$fake_bin/pkill" "$fake_bin/stat" "$fake_bin/defaults"

make_home() {
    name=$1
    initial_repeat=${2:-2}
    test_home=$test_root/$name/home
    mkdir -p "$test_home/Library/Preferences" "$test_root/$name/state"
    plist=$test_home/Library/Preferences/.GlobalPreferences.plist
    /usr/bin/plutil -create binary1 "$plist"
    /usr/bin/plutil -insert UnrelatedSetting -string preserved "$plist"
    /usr/bin/plutil -insert InitialKeyRepeat -integer 12 "$plist"
    /usr/bin/plutil -insert KeyRepeat -integer "$initial_repeat" "$plist"
    printf '%s\n' "$test_home"
}

run_configure() {
    name=$1
    mode=$2
    test_home=$3
    KEY_REPEAT_LOG=$test_root/$name/defaults.log \
    KEY_REPEAT_STATE_DIR=$test_root/$name/state \
    KEY_REPEAT_DEFAULTS_MODE=$mode \
    KEY_REPEAT_RESTART_DELAY=0 \
    HOME=$test_home \
    PATH=$fake_bin:/usr/bin:/bin \
        "$script"
}

run_reset() {
    name=$1
    mode=$2
    test_home=$3
    KEY_REPEAT_LOG=$test_root/$name/defaults.log \
    KEY_REPEAT_STATE_DIR=$test_root/$name/state \
    KEY_REPEAT_DEFAULTS_MODE=$mode \
    KEY_REPEAT_RESTART_DELAY=0 \
    HOME=$test_home \
    PATH=$fake_bin:/usr/bin:/bin \
        "$reset_script"
}

assert_configured() {
    plist=$1/Library/Preferences/.GlobalPreferences.plist
    [ "$(/usr/bin/plutil -extract InitialKeyRepeat raw "$plist")" = 15 ] || fail 'InitialKeyRepeat was not configured'
    [ "$(/usr/bin/plutil -extract KeyRepeat raw "$plist")" = 1 ] || fail 'KeyRepeat was not configured'
    [ "$(/usr/bin/plutil -extract UnrelatedSetting raw "$plist")" = preserved ] || fail 'an unrelated preference changed'
}

standard_home=$(make_home standard)
run_configure standard standard "$standard_home" >/dev/null
assert_configured "$standard_home"
[ ! -e "$test_root/standard/state/pkill-count" ] || fail 'cfprefsd restarted after a normal write'
grep -q '^write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false$' "$test_root/standard/defaults.log" || fail 'editor preference was not written'

missing_home=$(make_home missing)
KEY_REPEAT_MISSING_APP=1 run_configure missing standard "$missing_home" >/dev/null
unset KEY_REPEAT_MISSING_APP
assert_configured "$missing_home"

alias_home=$(make_home alias)
run_configure alias alias "$alias_home" >/dev/null
assert_configured "$alias_home"
grep -q '^write -g InitialKeyRepeat -int 15$' "$test_root/alias/defaults.log" || fail 'global-domain alias was not used'

retry_home=$(make_home retry)
run_configure retry retry "$retry_home" >/dev/null
assert_configured "$retry_home"
[ "$(cat "$test_root/retry/state/pkill-count")" = 1 ] || fail 'retry did not restart cfprefsd exactly once'

repair_home=$(make_home repair)
run_configure repair stuck "$repair_home" >/dev/null
assert_configured "$repair_home"
[ "$(cat "$test_root/repair/state/pkill-count")" = 3 ] || fail 'guarded repair did not perform the expected service restarts'

rollback_home=$(make_home rollback 2)
rollback_plist=$rollback_home/Library/Preferences/.GlobalPreferences.plist
cp -p "$rollback_plist" "$test_root/rollback/original.plist"
if rollback_output=$(run_configure rollback verify-fail "$rollback_home" 2>&1); then
    fail 'permanent preferences failure unexpectedly succeeded'
fi
cmp "$test_root/rollback/original.plist" "$rollback_plist" || fail 'failed repair did not restore the original plist'
case "$rollback_output" in
    *'macOS reported: simulated permanent preferences failure'*'Log out or reboot macOS'*) ;;
    *) fail 'failed repair did not include the underlying error and recovery guidance' ;;
esac

symlink_home=$test_root/symlink/home
mkdir -p "$symlink_home/Library/Preferences" "$test_root/symlink/state"
cp -p "$test_root/rollback/original.plist" "$test_root/symlink/target.plist"
ln -s "$test_root/symlink/target.plist" "$symlink_home/Library/Preferences/.GlobalPreferences.plist"
if run_configure symlink stuck "$symlink_home" >/dev/null 2>&1; then
    fail 'symlinked global preferences file was not refused'
fi
cmp "$test_root/rollback/original.plist" "$test_root/symlink/target.plist" || fail 'symlink target was changed'

owner_home=$(make_home owner)
if KEY_REPEAT_FAKE_OWNER=0 run_configure owner stuck "$owner_home" >/dev/null 2>&1; then
    fail 'wrongly owned global preferences file was not refused'
fi
unset KEY_REPEAT_FAKE_OWNER

invalid_home=$test_root/invalid/home
mkdir -p "$invalid_home/Library/Preferences" "$test_root/invalid/state"
printf '%s\n' 'not a plist' > "$invalid_home/Library/Preferences/.GlobalPreferences.plist"
if run_configure invalid stuck "$invalid_home" >/dev/null 2>&1; then
    fail 'invalid global preferences plist was not refused'
fi

unwritable_home=$(make_home unwritable)
unwritable_plist=$unwritable_home/Library/Preferences/.GlobalPreferences.plist
chmod 400 "$unwritable_plist"
if run_configure unwritable stuck "$unwritable_home" >/dev/null 2>&1; then
    fail 'unwritable global preferences plist was not refused'
fi
chmod 600 "$unwritable_plist"
assert_configured_value=$(/usr/bin/plutil -extract InitialKeyRepeat raw "$unwritable_plist")
[ "$assert_configured_value" = 12 ] || fail 'unwritable preferences file was changed'

reset_home=$(make_home reset)
run_reset reset standard "$reset_home" >/dev/null
reset_plist=$reset_home/Library/Preferences/.GlobalPreferences.plist
if /usr/bin/plutil -extract InitialKeyRepeat raw "$reset_plist" >/dev/null 2>&1 || \
    /usr/bin/plutil -extract KeyRepeat raw "$reset_plist" >/dev/null 2>&1; then
    fail 'reset did not remove the managed global preferences'
fi
[ "$(/usr/bin/plutil -extract UnrelatedSetting raw "$reset_plist")" = preserved ] || fail 'reset changed an unrelated preference'
run_reset reset standard "$reset_home" >/dev/null

stuck_reset_home=$(make_home stuck-reset)
run_reset stuck-reset stuck "$stuck_reset_home" >/dev/null
stuck_reset_plist=$stuck_reset_home/Library/Preferences/.GlobalPreferences.plist
if /usr/bin/plutil -extract InitialKeyRepeat raw "$stuck_reset_plist" >/dev/null 2>&1 || \
    /usr/bin/plutil -extract KeyRepeat raw "$stuck_reset_plist" >/dev/null 2>&1; then
    fail 'guarded reset did not remove the managed preferences'
fi

nonmac_bin=$test_root/nonmac-bin
mkdir -p "$nonmac_bin"
printf '%s\n' '#!/bin/sh' 'printf "%s\n" Linux' > "$nonmac_bin/uname"
printf '%s\n' '#!/bin/sh' 'exit 1' > "$nonmac_bin/defaults"
chmod +x "$nonmac_bin/uname" "$nonmac_bin/defaults"

if PATH=$nonmac_bin:/usr/bin:/bin "$script" >/dev/null 2>&1; then
    fail 'configure script unexpectedly succeeded on non-macOS'
fi

if PATH=$nonmac_bin:/usr/bin:/bin "$reset_script" >/dev/null 2>&1; then
    fail 'reset script unexpectedly succeeded on non-macOS'
fi

printf '%s\n' 'Key-repeat configuration tests passed.'
