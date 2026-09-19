#!/bin/sh

set -eu

label=com.thecodecafe.kanata
plist=/Library/LaunchDaemons/$label.plist
project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config=$project_root/kanata/kanata.kbd
dry_run=false

usage() {
    printf 'Usage: %s <install|uninstall|start|stop|restart|status> [--dry-run]\n' "$0" >&2
    exit 64
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

operation=$1
if [ "$#" -eq 2 ]; then
    [ "$2" = --dry-run ] || usage
    dry_run=true
fi

case "$operation" in
    install|uninstall|start|stop|restart|status) ;;
    *) usage ;;
esac

if [ "$dry_run" = true ]; then
    printf 'Would %s Kanata LaunchDaemon %s (%s)\n' "$operation" "$label" "$plist"
    [ "$operation" != install ] || printf 'Would configure binary from Homebrew, use config %s, and leave the service disabled.\n' "$config"
    exit 0
fi

if [ "$(uname -s)" != Darwin ]; then
    printf '%s\n' 'The Kanata service manager supports macOS only.' >&2
    exit 1
fi

run_root() {
    sudo "$@"
}

is_loaded() {
    sudo launchctl print "system/$label" >/dev/null 2>&1
}

plist_has_our_label() {
    [ -f "$plist" ] &&
        [ "$(sudo /usr/libexec/PlistBuddy -c 'Print :Label' "$plist" 2>/dev/null || :)" = "$label" ]
}

xml_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

case "$operation" in
    install)
        [ -s "$config" ] || { printf 'Kanata config is missing: %s\n' "$config" >&2; exit 1; }
        command -v brew >/dev/null 2>&1 || { printf '%s\n' 'Homebrew is required; install Kanata with: brew install --HEAD kanata' >&2; exit 1; }
        kanata_prefix=$(brew --prefix kanata 2>/dev/null || :)
        kanata_bin=$kanata_prefix/bin/kanata
        [ -x "$kanata_bin" ] || { printf 'Kanata executable not found at %s; install it with: brew install --HEAD kanata\n' "$kanata_bin" >&2; exit 1; }

        temporary_plist=$(mktemp "${TMPDIR:-/tmp}/kanata-launchd.XXXXXX")
        trap 'rm -f "$temporary_plist"' EXIT HUP INT TERM
        escaped_bin=$(xml_escape "$kanata_bin")
        escaped_config=$(xml_escape "$config")
        escaped_log=$(xml_escape /var/log/kanata.log)
        cat > "$temporary_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key>
  <array><string>$escaped_bin</string><string>-c</string><string>$escaped_config</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><false/>
  <key>StandardOutPath</key><string>$escaped_log</string>
  <key>StandardErrorPath</key><string>$escaped_log</string>
</dict>
</plist>
EOF
        plutil -lint "$temporary_plist" >/dev/null || { printf '%s\n' 'Generated LaunchDaemon plist is invalid.' >&2; exit 1; }

        if [ -e "$plist" ]; then
            if ! sudo cmp -s "$temporary_plist" "$plist"; then
                printf 'Refusing to replace an existing, different LaunchDaemon plist: %s\n' "$plist" >&2
                exit 1
            fi
            printf 'Kanata LaunchDaemon is already installed: %s\n' "$plist"
        else
            sudo -v
            run_root install -o root -g wheel -m 644 "$temporary_plist" "$plist"
        fi
        run_root launchctl disable "system/$label"
        if is_loaded; then
            run_root launchctl bootout "system/$label"
        fi
        printf '%s\n' 'Installed Kanata LaunchDaemon in the disabled state. Use the start command or make keyboard-kanata to activate it.'
        ;;
    uninstall)
        if [ ! -e "$plist" ]; then
            printf '%s\n' 'Kanata LaunchDaemon is not installed.'
            exit 0
        fi
        plist_has_our_label || { printf 'Refusing to remove an unexpected plist at %s\n' "$plist" >&2; exit 1; }
        sudo -v
        if is_loaded; then
            run_root launchctl bootout "system/$label"
        fi
        run_root launchctl disable "system/$label"
        run_root rm "$plist"
        printf 'Removed Kanata LaunchDaemon plist: %s\n' "$plist"
        ;;
    start)
        plist_has_our_label || { printf 'Kanata LaunchDaemon is not installed: %s\n' "$plist" >&2; exit 1; }
        sudo -v
        run_root launchctl enable "system/$label"
        if is_loaded; then
            printf '%s\n' 'Kanata LaunchDaemon is already loaded.'
        else
            run_root launchctl bootstrap system "$plist"
            printf '%s\n' 'Kanata LaunchDaemon started.'
        fi
        ;;
    stop)
        if [ ! -e "$plist" ]; then
            printf '%s\n' 'Kanata LaunchDaemon is not installed; nothing to stop.'
            exit 0
        fi
        sudo -v
        if is_loaded; then
            run_root launchctl bootout "system/$label"
        fi
        run_root launchctl disable "system/$label"
        printf '%s\n' 'Kanata LaunchDaemon stopped and disabled for the next boot.'
        ;;
    restart)
        plist_has_our_label || { printf 'Kanata LaunchDaemon is not installed: %s\n' "$plist" >&2; exit 1; }
        sudo -v
        run_root launchctl enable "system/$label"
        if is_loaded; then
            run_root launchctl kickstart -k "system/$label"
        else
            run_root launchctl bootstrap system "$plist"
        fi
        printf '%s\n' 'Kanata LaunchDaemon restarted.'
        ;;
    status)
        if plist_has_our_label; then
            printf 'Installed: %s\n' "$plist"
            if is_loaded; then
                printf '%s\n' 'State: loaded'
            else
                printf '%s\n' 'State: stopped/disabled'
            fi
        else
            printf '%s\n' 'State: not installed'
            exit 1
        fi
        ;;
esac
