#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config=$project_root/kanata/kanata.kbd

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -s "$config" ] || fail 'Kanata config is missing or empty'

awk '
    { sub(/;;.*/, "") }
    /macos-dev-names-exclude[[:space:]]*\(/ { in_exclusions = 1 }
    in_exclusions && /"MX Master 2S"/ { mouse_excluded = 1 }
    in_exclusions && /\)/ { in_exclusions = 0 }
    END { exit !mouse_excluded }
' "$config" || fail 'MX Master 2S must be excluded from macOS keyboard capture'
grep -Fq '(defsrc caps h j k l)' "$config" || fail 'Caps Lock and navigation keys are not declared'
caps_action=$(awk '{ sub(/;;.*/, ""); printf "%s ", $0 }' "$config" | tr -s '[:space:]' ' ')
printf '%s\n' "$caps_action" | grep -Fq 'caps (tap-hold-press 0 150 (tap-dance 100 ( esc (tap-hold-press 0 150 esc @hyper) )) lctl )' || fail 'Caps Lock must resolve holds before starting double-tap detection'
grep -Fq 'hyper (multi (layer-while-held hyper) lctl lalt lmet lsft)' "$config" || fail 'Hyper modifiers/layer are incorrect'
grep -Eq '_[[:space:]]+\(unmod left\)[[:space:]]+\(unmod down\)[[:space:]]+\(unmod up\)[[:space:]]+\(unmod right\)' "$config" || fail 'Hyper navigation must map H/J/K/L to unmodified arrows'

printf '%s\n' 'Kanata configuration test passed.'
