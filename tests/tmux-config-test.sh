#!/bin/sh

set -eu

if ! command -v tmux >/dev/null 2>&1; then
    printf '%s\n' 'tmux is unavailable; skipping configuration test.'
    exit 0
fi

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/tmux/tmux.conf
test_root=$(mktemp -d "${TMPDIR:-/tmp}/tmux-config.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
socket_root=$(mktemp -d /tmp/tmux-socket.XXXXXX)
socket_name=dotfiles-config-test-$$
HOME=$test_root/home
TMUX_TMPDIR=$socket_root
export HOME TMUX_TMPDIR

cleanup() {
    tmux -L "$socket_name" kill-server >/dev/null 2>&1 || :
    rm -rf "$test_root"
    rm -rf "$socket_root"
}
trap cleanup EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_option() {
    option=$1
    expected=$2
    actual=$(tmux -L "$socket_name" show-options -gv "$option")
    [ "$actual" = "$expected" ] || fail "$option is '$actual', expected '$expected'"
}

assert_binding_contains() {
    table=$1
    key=$2
    expected=$3
    binding=$(tmux -L "$socket_name" list-keys -T "$table" | tr -s ' ' | grep -F " $key " | grep -F "$expected" || :)
    case "$binding" in
        *"$expected"*) ;;
        *) fail "$table binding $key does not contain '$expected': $binding" ;;
    esac
}

mkdir -p "$test_root/home/.tmux/plugins/tpm"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$test_root/home/.tmux/plugins/tpm/tpm"
chmod +x "$test_root/home/.tmux/plugins/tpm/tpm"

tmux -L "$socket_name" -f "$config_file" new-session -d -s config-test 'sleep 60'

assert_option default-terminal screen-256color
assert_option prefix C-b
assert_option mouse on
assert_option mode-keys vi
assert_option escape-time 10
assert_option base-index 0
assert_option renumber-windows off
assert_option focus-events off
assert_option @tmux_power_theme colour6
assert_option @resurrect-capture-pane-contents on
assert_option @continuum-restore on

tpm_path=$(tmux -L "$socket_name" show-environment -g TMUX_PLUGIN_MANAGER_PATH)
[ "$tpm_path" = 'TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins/' ] || \
    fail "TMUX_PLUGIN_MANAGER_PATH is not initialized correctly: $tpm_path"

terminal_overrides=$(tmux -L "$socket_name" show-options -gv terminal-overrides)
case "$terminal_overrides" in *Smulx*) ;; *) fail 'terminal-overrides is missing undercurl support' ;; esac
case "$terminal_overrides" in *Setulc*) ;; *) fail 'terminal-overrides is missing underline color support' ;; esac

assert_binding_contains prefix C-b send-prefix
assert_binding_contains prefix '\\' split-window
assert_binding_contains prefix '-' split-window
assert_binding_contains prefix r source-file
assert_binding_contains prefix j resize-pane
assert_binding_contains prefix k resize-pane
assert_binding_contains prefix l resize-pane
assert_binding_contains prefix h resize-pane
assert_binding_contains prefix m 'resize-pane -Z'
assert_binding_contains prefix M-c attach-session
assert_binding_contains copy-mode-vi v 'send-keys -X begin-selection'
assert_binding_contains copy-mode-vi y 'send-keys -X copy-selection'

for declaration in \
    'bind-key C-b send-prefix' \
    'unbind |' \
    'bind \\ split-window -h -c "#{pane_current_path}"' \
    'bind - split-window -v -c "#{pane_current_path}"' \
    'bind r source-file ~/.config/tmux/tmux.conf' \
    'bind j resize-pane -D 5' \
    'bind k resize-pane -U 5' \
    'bind l resize-pane -R 5' \
    'bind h resize-pane -L 5' \
    'bind -r m resize-pane -Z' \
    'bind M-c attach-session -c "#{pane_current_path}"'
do
    grep -Fqx "$declaration" "$config_file" || fail "missing binding declaration: $declaration"
done

pipe_binding=$(tmux -L "$socket_name" list-keys -T prefix | tr -s ' ' | grep -F ' | ' || :)
case "$pipe_binding" in
    *split-window*) fail 'the old | key is still bound to split-window' ;;
esac

c_binding=$(tmux -L "$socket_name" list-keys -T prefix c)
case "$c_binding" in
    *pane_current_path*) fail 'new-window binding unexpectedly preserves the current pane directory' ;;
esac

for plugin in \
    tmux-plugins/tpm \
    christoomey/vim-tmux-navigator \
    wfxr/tmux-power \
    tmux-plugins/tmux-resurrect \
    tmux-plugins/tmux-continuum
do
    grep -F "set -g @plugin '$plugin'" "$config_file" >/dev/null || fail "missing plugin declaration: $plugin"
done

printf '%s\n' 'tmux configuration test passed.'
