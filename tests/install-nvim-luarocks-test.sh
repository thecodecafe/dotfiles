#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
installer=$project_root/scripts/install-nvim-luarocks.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/install-nvim-luarocks.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

fake_bin=$test_root/bin
fake_git_log=$test_root/git.log
fake_python_log=$test_root/python.log
explicit_ca_file=$test_root/explicit-ca.pem
mkdir -p "$fake_bin"
printf '%s\n' 'test certificate bundle' > "$explicit_ca_file"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    '[ "$#" -eq 4 ]' \
    '[ "$1" = clone ]' \
    '[ "$2" = --filter=blob:none ]' \
    '[ "$3" = https://github.com/luarocks/hererocks ]' \
    'printf "%s\\n" "$*" >> "${FAKE_GIT_LOG:?}"' \
    'mkdir -p "$4"' \
    ': > "$4/hererocks.py"' > "$fake_bin/git"
chmod +x "$fake_bin/git"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'if [ "${1:-}" = -c ]; then' \
    '    [ -n "${FAKE_CERTIFI_PATH:-}" ] || exit 1' \
    '    printf "%s\\n" "$FAKE_CERTIFI_PATH"' \
    '    exit 0' \
    'fi' \
    ': "${SSL_CERT_FILE:?}"' \
    '[ -z "${EXPECTED_SSL_CERT_FILE:-}" ] || [ "$SSL_CERT_FILE" = "$EXPECTED_SSL_CERT_FILE" ]' \
    'printf "%s\\n" "$*" >> "${FAKE_PYTHON_LOG:?}"' \
    '[ "${FAKE_PYTHON_FAIL:-0}" = 0 ] || exit 1' \
    '[ "$#" -eq 6 ]' \
    '[ "$3" = -l ]' \
    '[ "$4" = 5.1 ]' \
    '[ "$5" = -r ]' \
    '[ "$6" = latest ]' \
    'mkdir -p "$2/bin"' \
    'printf "%s\\n" "#!/bin/sh" "printf '\''%s\\n'\'' '\''Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio'\'' >&2" > "$2/bin/lua"' \
    'printf "%s\\n" "#!/bin/sh" "[ -x '\''$2/bin/lua'\'' ] || exit 1" "printf '\''%s\\n'\'' '\''LuaRocks 3.13.0'\''" > "$2/bin/luarocks"' \
    'chmod +x "$2/bin/lua" "$2/bin/luarocks"' > "$fake_bin/python3"
chmod +x "$fake_bin/python3"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    '[ -n "${FAKE_BREW_PREFIX:-}" ] || exit 1' \
    '[ "$#" -eq 2 ]' \
    '[ "$1" = --prefix ]' \
    '[ "$2" = ca-certificates ]' \
    'printf "%s\\n" "$FAKE_BREW_PREFIX"' > "$fake_bin/brew"
chmod +x "$fake_bin/brew"

destination=$test_root/data/nvim/lazy-rocks/hererocks
config_destination=$test_root/config/nvim

if "$installer" check "$destination"; then
    fail 'missing environment passed validation'
fi

prerequisite_bin=$test_root/prerequisite-bin
mkdir "$prerequisite_bin"
ln -s "$fake_bin/git" "$prerequisite_bin/git"
ln -s "$fake_bin/python3" "$prerequisite_bin/python3"
ln -s "$(command -v make)" "$prerequisite_bin/make"
if prerequisite_output=$(PATH=$prerequisite_bin "$installer" install "$test_root/prerequisite-failure" 2>&1); then
    fail 'installer succeeded without a C compiler'
fi
case "$prerequisite_output" in
    *'Required command is unavailable: cc'*) ;;
    *) fail "missing prerequisite error was unclear: $prerequisite_output" ;;
esac

link_output=$(make -s -C "$project_root" nvim \
    NVIM_CONFIG_DIR="$config_destination" NVIM_LUAROCKS_DIR="$destination")
case "$link_output" in
    *'Run make nvim-luarocks to install Lua 5.1 and LuaRocks for Neovim.'*) ;;
    *) fail 'make nvim did not print the missing LuaRocks instruction' ;;
esac
[ ! -e "$fake_git_log" ] || fail 'make nvim unexpectedly invoked Git'

PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_PYTHON_LOG=$fake_python_log \
    SSL_CERT_FILE=$explicit_ca_file EXPECTED_SSL_CERT_FILE=$explicit_ca_file \
    make -s -C "$project_root" nvim-luarocks NVIM_LUAROCKS_DIR="$destination"

"$installer" check "$destination" || fail 'installed environment failed validation'
[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'hererocks was not cloned exactly once'
[ "$(wc -l < "$fake_python_log" | tr -d ' ')" = 1 ] || fail 'hererocks was not run exactly once'

link_output=$(make -s -C "$project_root" nvim \
    NVIM_CONFIG_DIR="$config_destination" NVIM_LUAROCKS_DIR="$destination")
case "$link_output" in
    *'Run make nvim-luarocks'*) fail 'valid environment still triggered the setup instruction' ;;
esac

PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_PYTHON_LOG=$fake_python_log \
    SSL_CERT_FILE=$explicit_ca_file EXPECTED_SSL_CERT_FILE=$explicit_ca_file \
    make -s -C "$project_root" nvim-luarocks NVIM_LUAROCKS_DIR="$destination"
[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'valid environment was cloned again'
[ "$(wc -l < "$fake_python_log" | tr -d ' ')" = 1 ] || fail 'valid environment was rebuilt'

for conflict_type in file directory symlink
do
    conflict=$test_root/conflict-$conflict_type/hererocks
    mkdir -p "$(dirname "$conflict")"
    case "$conflict_type" in
        file) printf '%s\n' existing > "$conflict" ;;
        directory) mkdir "$conflict" ;;
        symlink) ln -s "$destination" "$conflict" ;;
    esac

    if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_PYTHON_LOG=$fake_python_log \
        SSL_CERT_FILE=$explicit_ca_file EXPECTED_SSL_CERT_FILE=$explicit_ca_file \
        "$installer" install "$conflict" >/dev/null 2>&1; then
        fail "$conflict_type conflict unexpectedly succeeded"
    fi
done

failed_destination=$test_root/failed/hererocks
if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_PYTHON_LOG=$fake_python_log \
    SSL_CERT_FILE=$explicit_ca_file EXPECTED_SSL_CERT_FILE=$explicit_ca_file \
    FAKE_PYTHON_FAIL=1 "$installer" install "$failed_destination" >/dev/null 2>&1; then
    fail 'failed hererocks build unexpectedly succeeded'
fi
[ ! -e "$failed_destination" ] || fail 'failed build left a destination behind'
if find "$test_root/failed" -name '.nvim-luarocks-install.*' -print | grep -q .; then
    fail 'failed build left a temporary directory behind'
fi

certifi_ca_file=$test_root/certifi-ca.pem
printf '%s\n' 'certifi test bundle' > "$certifi_ca_file"
if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$test_root/certifi-git.log FAKE_PYTHON_LOG=$test_root/certifi-python.log \
    FAKE_CERTIFI_PATH=$certifi_ca_file EXPECTED_SSL_CERT_FILE=$certifi_ca_file FAKE_PYTHON_FAIL=1 \
    "$installer" install "$test_root/certifi-failure" >/dev/null 2>&1; then
    fail 'certifi fallback build unexpectedly succeeded'
fi
[ -e "$test_root/certifi-python.log" ] || fail 'certifi CA bundle was not passed to hererocks'

homebrew_prefix=$test_root/homebrew-ca
homebrew_ca_file=$homebrew_prefix/share/ca-certificates/cacert.pem
mkdir -p "$(dirname "$homebrew_ca_file")"
printf '%s\n' 'Homebrew test bundle' > "$homebrew_ca_file"
if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$test_root/homebrew-git.log FAKE_PYTHON_LOG=$test_root/homebrew-python.log \
    FAKE_BREW_PREFIX=$homebrew_prefix EXPECTED_SSL_CERT_FILE=$homebrew_ca_file FAKE_PYTHON_FAIL=1 \
    "$installer" install "$test_root/homebrew-failure" >/dev/null 2>&1; then
    fail 'Homebrew CA fallback build unexpectedly succeeded'
fi
[ -e "$test_root/homebrew-python.log" ] || fail 'Homebrew CA bundle was not passed to hererocks'

system_ca_file=$test_root/system-ca.pem
printf '%s\n' 'system test bundle' > "$system_ca_file"
if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$test_root/system-git.log FAKE_PYTHON_LOG=$test_root/system-python.log \
    NVIM_SYSTEM_CA_BUNDLE=$system_ca_file EXPECTED_SSL_CERT_FILE=$system_ca_file FAKE_PYTHON_FAIL=1 \
    "$installer" install "$test_root/system-failure" >/dev/null 2>&1; then
    fail 'system CA fallback build unexpectedly succeeded'
fi
[ -e "$test_root/system-python.log" ] || fail 'system CA bundle was not passed to hererocks'

if missing_ca_output=$(PATH=$fake_bin:$PATH NVIM_SYSTEM_CA_BUNDLE=$test_root/missing-ca.pem \
    "$installer" install "$test_root/missing-ca-failure" 2>&1); then
    fail 'installer succeeded without a trusted CA bundle'
fi
case "$missing_ca_output" in
    *'Unable to find a trusted CA bundle'*) ;;
    *) fail "missing CA error was unclear: $missing_ca_output" ;;
esac

if unreadable_ca_output=$(SSL_CERT_FILE=$test_root/missing-explicit-ca.pem \
    "$installer" install "$test_root/unreadable-ca-failure" 2>&1); then
    fail 'installer accepted an unreadable SSL_CERT_FILE'
fi
case "$unreadable_ca_output" in
    *'Configured SSL_CERT_FILE is not readable'*) ;;
    *) fail "unreadable CA error was unclear: $unreadable_ca_output" ;;
esac

printf '%s\n' 'All Neovim LuaRocks installer tests passed.'
