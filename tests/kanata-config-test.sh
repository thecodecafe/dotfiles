#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config=$project_root/kanata/kanata.kbd

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

if [ "$#" -gt 1 ]; then
    printf 'Usage: %s [--behavior]\n' "$0" >&2
    exit 64
fi
case "${1-}" in
    ''|--behavior) ;;
    *) printf 'Usage: %s [--behavior]\n' "$0" >&2; exit 64 ;;
esac

[ -s "$config" ] || fail 'Kanata config is missing or empty'

if [ "${1-}" = --behavior ]; then
    [ -n "${KANATA_SIM_BIN:-}" ] || fail 'behavior mode requires KANATA_SIM_BIN'
    simulator=$(command -v "$KANATA_SIM_BIN") || fail "Kanata simulator is not executable: $KANATA_SIM_BIN"
    [ -x "$simulator" ] || fail "Kanata simulator is not executable: $simulator"

    python3 - "$simulator" "$config" <<'PY'
import re
import subprocess
import sys

simulator, config = sys.argv[1:]
modifiers = ('LCtrl', 'LAlt', 'LGui', 'LShift')
hyper_down = [f'↓{key}' for key in modifiers]
hyper_up = [f'↑{key}' for key in modifiers]
escape = ['↓Escape', '↑Escape']
control = ['↓LCtrl', '↑LCtrl']


def navigation(key, repeats=0):
    return hyper_up + [f'↓{key}'] * (repeats + 1) + [f'↑{key}'] + hyper_down


down = hyper_down + navigation('Down') + hyper_up
cases = [
    ('single quick tap',
     'd:caps t:50 u:caps t:500', escape, (145, 155)),
    ('single tap near hold threshold',
     'd:caps t:140 u:caps t:500', escape, (235, 245)),
    ('single 200 ms hold',
     'd:caps t:200 u:caps t:500', control, (145, 155)),
    ('single 400 ms hold',
     'd:caps t:400 u:caps t:500', control, (145, 155)),
    ('single 600 ms hold',
     'd:caps t:600 u:caps t:500', control, (145, 155)),
    ('Control chord before hold timeout',
     'd:caps t:20 d:j t:50 u:j t:50 u:caps t:500',
     ['↓LCtrl', '↓J', '↑J', '↑LCtrl'], (15, 25)),
    ('fast double tap and hold',
     'd:caps t:50 u:caps t:50 d:caps t:200 d:j t:50 u:j t:50 u:caps t:500',
     down, (245, 255)),
    ('second press 90 ms after a 140 ms tap',
     'd:caps t:140 u:caps t:90 d:caps t:200 d:j t:50 u:j t:50 u:caps t:500',
     down, (375, 385)),
    ('second press just inside double-tap window',
     'd:caps t:100 u:caps t:99 d:caps t:200 d:j t:50 u:j t:50 u:caps t:500',
     down, (344, 354)),
    ('second press outside double-tap window',
     'd:caps t:100 u:caps t:101 d:caps t:200 d:j t:50 u:j t:50 u:caps t:500',
     escape + ['↓LCtrl', '↓J', '↑J', '↑LCtrl'], (195, 205)),
    ('Hyper navigation before second hold timeout',
     'd:caps t:50 u:caps t:50 d:caps t:10 d:j t:50 u:j t:50 u:caps t:500',
     down, (105, 115)),
    ('double quick tap',
     'd:caps t:50 u:caps t:50 d:caps t:50 u:caps t:500',
     escape, (145, 155)),
    ('tap resolved by another key',
     'd:caps t:50 u:caps t:50 d:j t:50 u:j t:500',
     escape + ['↓J', '↑J'], (95, 105)),
    ('intervening key ends double-tap detection',
     'd:caps t:50 u:caps t:50 d:a t:50 u:a t:50 d:caps t:200 d:j t:50 u:j t:50 u:caps t:500',
     escape + ['↓A', '↑A', '↓LCtrl', '↓J', '↑J', '↑LCtrl'], (95, 105)),
    ('other Hyper shortcuts retain modifiers',
     'd:caps t:50 u:caps t:50 d:caps t:200 d:a t:50 u:a t:50 u:caps t:500',
     hyper_down + ['↓A', '↑A'] + hyper_up, (245, 255)),
    ('all arrows and navigation repeat',
     'd:caps t:50 u:caps t:50 d:caps t:200 d:h t:50 u:h t:50 d:j t:50 r:j t:50 u:j t:50 d:k t:50 u:k t:50 d:l t:50 u:l t:50 u:caps t:500',
     hyper_down + navigation('Left') + navigation('Down', repeats=1)
     + navigation('Up') + navigation('Right') + hyper_up, (245, 255)),
    ('Caps released before navigation key',
     'd:caps t:50 u:caps t:50 d:caps t:200 d:j t:50 u:caps t:50 u:j t:50 d:a t:50 u:a t:500',
     hyper_down + hyper_up + ['↓Down', '↑Down', '↓A', '↑A'], (245, 255)),
    ('navigation released before Caps returns to base',
     'd:caps t:50 u:caps t:50 d:caps t:200 d:j t:50 u:j t:50 u:caps t:50 d:j t:50 u:j t:500',
     down + ['↓J', '↑J'], (245, 255)),
    ('Control hold does not arm Hyper',
     'd:caps t:200 u:caps t:50 d:caps t:50 u:caps t:500',
     control + escape, (145, 155)),
    ('two separate Escape taps',
     'd:caps t:50 u:caps t:500 d:caps t:50 u:caps t:500',
     escape * 2, (145, 155)),
]

for name, sequence, expected, first_output_range in cases:
    result = subprocess.run(
        [simulator, '-c', config, '-s', '/dev/stdin'],
        input=sequence, text=True, capture_output=True,
    )
    if result.returncode:
        sys.exit(f'FAIL: {name}: simulator exited {result.returncode}\n{result.stderr}')

    elapsed = 0
    events = []
    times = []
    for line in result.stdout.splitlines():
        delay = re.fullmatch(r't:(\d+)ms', line)
        if delay:
            elapsed += int(delay.group(1))
        elif line.startswith('out:'):
            events.append(line[4:])
            times.append(elapsed)

    if events != expected:
        sys.exit(f'FAIL: {name}\nExpected: {expected}\nActual:   {events}')
    minimum, maximum = first_output_range
    if not minimum <= times[0] <= maximum:
        sys.exit(f'FAIL: {name}: first output at {times[0]} ms; expected {minimum}–{maximum} ms')

print(f'Kanata behavior tests passed ({len(cases)} scenarios).')
PY
    exit 0
fi

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
