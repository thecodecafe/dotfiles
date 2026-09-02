#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
installer=$project_root/scripts/install-tmux-tpm.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/install-tmux-tpm.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

fake_bin=$test_root/bin
fake_git_log=$test_root/git.log
fake_tpm_log=$test_root/tpm.log
fake_event_log=$test_root/events.log
mkdir -p "$fake_bin"
printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    '[ "$#" -eq 3 ]' \
    '[ "$1" = clone ]' \
    '[ "$2" = https://github.com/tmux-plugins/tpm ]' \
    'printf "%s\\n" "$*" >> "${FAKE_GIT_LOG:?}"' \
    'mkdir -p "$3/.git"' \
    'printf "%s\\n" "#!/bin/sh" "exit 0" > "$3/tpm"' \
    'mkdir -p "$3/bin"' \
    'printf "%s\\n" "#!/bin/sh" "echo install_plugins >> \"${FAKE_TPM_LOG:?}\"" "echo install_plugins >> \"${FAKE_EVENT_LOG:?}\"" > "$3/bin/install_plugins"' \
    'chmod +x "$3/tpm" "$3/bin/install_plugins"' > "$fake_bin/git"
chmod +x "$fake_bin/git"

printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'case "$1" in' \
    '    list-sessions) [ "${FAKE_TMUX_RUNNING:-1}" = 1 ] ;;' \
    '    source-file)' \
    '        [ "$#" -eq 2 ]' \
    '        printf "source-file %s\\n" "$2" >> "${FAKE_EVENT_LOG:?}"' \
    '        ;;' \
    '    *) exit 1 ;;' \
    'esac' > "$fake_bin/tmux"
chmod +x "$fake_bin/tmux"

linked_config=$test_root/home/.config/tmux/tmux.conf
link_output=$(PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_EVENT_LOG=$fake_event_log \
    make -s -C "$project_root" tmux TMUX_CONFIG_FILE="$linked_config")
[ -L "$linked_config" ] || fail 'make tmux did not link the configuration'
case "$link_output" in
    *'Run make tmux-tpm to install missing tmux plugins.'*) ;;
    *) fail 'make tmux did not print the plugin installation instruction' ;;
esac
[ ! -e "$fake_git_log" ] || fail 'make tmux unexpectedly invoked Git'
[ "$(sed -n '1p' "$fake_event_log")" = "source-file $linked_config" ] || \
    fail 'make tmux did not reload the active server after linking'

: > "$fake_event_log"

destination=$test_root/home/.tmux/plugins/tpm
PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_TPM_LOG=$fake_tpm_log \
    FAKE_EVENT_LOG=$fake_event_log make -s -C "$project_root" tmux-tpm \
    TMUX_TPM_DIR="$destination" TMUX_CONFIG_FILE="$linked_config"

[ -d "$destination/.git" ] || fail 'installer did not create a Git checkout'
[ -x "$destination/tpm" ] || fail 'installer did not create an executable TPM entrypoint'
[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'installer did not clone exactly once'
[ "$(wc -l < "$fake_tpm_log" | tr -d ' ')" = 1 ] || fail 'make tmux-tpm did not install plugins'
[ "$(sed -n '1p' "$fake_event_log")" = install_plugins ] || fail 'plugins were not installed first'
[ "$(sed -n '2p' "$fake_event_log")" = "source-file $linked_config" ] || fail 'active tmux server was not reloaded after plugin installation'

PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log "$installer" "$destination"
[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'valid checkout was cloned again'

PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_TPM_LOG=$fake_tpm_log \
    FAKE_EVENT_LOG=$fake_event_log make -s -C "$project_root" tmux-tpm \
    TMUX_TPM_DIR="$destination" TMUX_CONFIG_FILE="$linked_config"
[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'make tmux-tpm cloned an existing TPM checkout again'
[ "$(wc -l < "$fake_tpm_log" | tr -d ' ')" = 2 ] || fail 'existing TPM checkout did not check for missing plugins'
[ "$(sed -n '4p' "$fake_event_log")" = "source-file $linked_config" ] || fail 'existing plugin installation did not reload tmux'

PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_TPM_LOG=$fake_tpm_log \
    FAKE_EVENT_LOG=$fake_event_log FAKE_TMUX_RUNNING=0 \
    make -s -C "$project_root" tmux-tpm TMUX_TPM_DIR="$destination" TMUX_CONFIG_FILE="$linked_config"
[ "$(wc -l < "$fake_tpm_log" | tr -d ' ')" = 3 ] || fail 'no-server path did not install plugins'
[ "$(wc -l < "$fake_event_log" | tr -d ' ')" = 5 ] || fail 'no-server path unexpectedly sourced the config'

for conflict_type in file directory symlink
do
    conflict=$test_root/conflict-$conflict_type/tpm
    mkdir -p "$(dirname "$conflict")"
    case "$conflict_type" in
        file) printf '%s\n' existing > "$conflict" ;;
        directory) mkdir "$conflict" ;;
        symlink) ln -s "$destination" "$conflict" ;;
    esac

    if PATH=$fake_bin:$PATH FAKE_GIT_LOG=$fake_git_log FAKE_TPM_LOG=$fake_tpm_log FAKE_EVENT_LOG=$fake_event_log \
        make -s -C "$project_root" tmux-tpm TMUX_TPM_DIR="$conflict" >/dev/null 2>&1; then
        fail "$conflict_type conflict unexpectedly succeeded"
    fi
done

[ "$(wc -l < "$fake_git_log" | tr -d ' ')" = 1 ] || fail 'a conflict triggered another clone'
[ "$(wc -l < "$fake_tpm_log" | tr -d ' ')" = 3 ] || fail 'a conflict triggered plugin installation'

printf '%s\n' 'All TPM installer tests passed.'
