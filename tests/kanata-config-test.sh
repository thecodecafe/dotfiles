#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config=$project_root/kanata/kanata.kbd

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -s "$config" ] || fail 'Kanata config is missing or empty'
grep -Fq '(defsrc caps h j k l)' "$config" || fail 'Caps Lock and navigation keys are not declared'
grep -Fq 'caps (tap-dance 300 (' "$config" || fail 'double-tap window must be 300 ms'
grep -Fq '(tap-hold-press 150 150 esc lctl)' "$config" || fail 'single tap/Control behavior is missing'
grep -Fq '(tap-hold-press 150 150 esc @hyper)' "$config" || fail 'double-tap Hyper behavior is missing'
grep -Fq 'hyper (multi (layer-while-held hyper) lctl lalt lmet lsft)' "$config" || fail 'Hyper modifiers/layer are incorrect'
grep -Eq '_[[:space:]]+left[[:space:]]+down[[:space:]]+up[[:space:]]+right' "$config" || fail 'Hyper navigation does not map H/J/K/L to arrows'

printf '%s\n' 'Kanata configuration test passed.'
