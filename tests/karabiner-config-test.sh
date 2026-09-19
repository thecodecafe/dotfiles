#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_file=$project_root/karabiner/karabiner.json

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

[ -s "$config_file" ] || fail 'Karabiner configuration is missing or empty.'

if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$config_file" >/dev/null || fail 'Karabiner configuration is not valid JSON.'
else
    fail 'python3 is required to validate the Karabiner JSON.'
fi

grep -Fq '"basic.to_if_alone_timeout_milliseconds": 150' "$config_file" || fail 'tap timeout is not 150 ms'
grep -Fq '"basic.to_if_held_down_threshold_milliseconds": 150' "$config_file" || fail 'hold threshold is not 150 ms'
grep -Fq '"basic.to_delayed_action_delay_milliseconds": 300' "$config_file" || fail 'double-tap delay is not 300 ms'
grep -Fq '"key_code": "caps_lock"' "$config_file" || fail 'Caps Lock manipulator is missing'
grep -Fq '"key_code": "escape"' "$config_file" || fail 'Caps Lock tap does not send Escape'
python3 - "$config_file" <<'PY' || fail 'physical Escape is unexpectedly remapped'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    config = json.load(handle)

manipulators = config["profiles"][0]["complex_modifications"]["rules"][0]["manipulators"]
if any(
    manipulator.get("from", {}).get("key_code") == "escape"
    for manipulator in manipulators
):
    sys.exit(1)
PY
python3 - "$config_file" <<'PY' || fail 'Caps Lock hold does not send left Control or navigation mappings remain'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    config = json.load(handle)

manipulators = config["profiles"][0]["complex_modifications"]["rules"][0]["manipulators"]
caps_lock_manipulators = [
    manipulator
    for manipulator in manipulators
    if manipulator.get("from", {}).get("key_code") == "caps_lock"
]
if len(caps_lock_manipulators) != 2:
    sys.exit(1)

control_manipulator = next(
    manipulator for manipulator in caps_lock_manipulators
    if not manipulator.get("conditions")
)
if control_manipulator.get("to", [{}])[1] != {"key_code": "left_control"}:
    sys.exit(1)
if control_manipulator.get("to_if_alone") != [{"key_code": "escape"}]:
    sys.exit(1)

hyper_manipulator = next(
    manipulator for manipulator in caps_lock_manipulators
    if manipulator.get("conditions")
)
if hyper_manipulator["conditions"] != [
    {"name": "caps_lock_first_tap", "type": "variable_if", "value": 1}
]:
    sys.exit(1)
if hyper_manipulator.get("to") != [{
    "key_code": "left_command",
    "modifiers": ["left_control", "left_option", "left_shift"],
}]:
    sys.exit(1)

navigation = {"h": "left_arrow", "j": "down_arrow", "k": "up_arrow", "l": "right_arrow"}
for key_code, arrow in navigation.items():
    matching = [
        manipulator for manipulator in manipulators
        if manipulator.get("from", {}).get("key_code") == key_code
    ]
    if len(matching) != 1 or matching[0].get("to") != [{"key_code": arrow}]:
        sys.exit(1)

if any(
    manipulator.get("from", {}).get("key_code") == "escape"
    for manipulator in manipulators
):
    sys.exit(1)
PY

printf '%s\n' 'Karabiner configuration test passed.'
