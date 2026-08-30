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
grep -Fq '"key_code": "left_arrow"' "$config_file" || fail 'Hyper+h navigation is missing'
grep -Fq '"key_code": "down_arrow"' "$config_file" || fail 'Hyper+j navigation is missing'
grep -Fq '"key_code": "up_arrow"' "$config_file" || fail 'Hyper+k navigation is missing'
grep -Fq '"key_code": "right_arrow"' "$config_file" || fail 'Hyper+l navigation is missing'

printf '%s\n' 'Karabiner configuration test passed.'
