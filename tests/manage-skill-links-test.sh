#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-skill-links.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/manage-skill-links.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_link_target() {
    link_path=$1
    expected_target=$2

    [ -L "$link_path" ] || fail "$link_path is not a symlink"
    [ "$(readlink "$link_path")" = "$expected_target" ] || fail "$link_path has the wrong target"
}

source_dir=$test_root/source
mkdir -p "$source_dir/alpha" "$source_dir/beta" "$source_dir/ignored"
printf '%s\n' '---' 'name: alpha' 'description: test' '---' > "$source_dir/alpha/SKILL.md"
printf '%s\n' '---' 'name: beta' 'description: test' '---' > "$source_dir/beta/SKILL.md"

destination_dir=$test_root/destination
mkdir -p "$destination_dir"
printf '%s\n' 'keep me' > "$destination_dir/unrelated"

"$manager" link "$source_dir" "$destination_dir"
assert_link_target "$destination_dir/alpha" "$source_dir/alpha"
assert_link_target "$destination_dir/beta" "$source_dir/beta"
[ ! -e "$destination_dir/ignored" ] || fail 'directory without SKILL.md was linked'

"$manager" link "$source_dir" "$destination_dir"
assert_link_target "$destination_dir/alpha" "$source_dir/alpha"
assert_link_target "$destination_dir/beta" "$source_dir/beta"

check_collision() {
    collision_type=$1
    collision_dir=$test_root/collision-$collision_type
    mkdir -p "$collision_dir"

    case "$collision_type" in
        file) printf '%s\n' 'existing' > "$collision_dir/alpha" ;;
        directory) mkdir "$collision_dir/alpha" ;;
        symlink) ln -s "$source_dir/beta" "$collision_dir/alpha" ;;
        broken-symlink) ln -s "$test_root/missing" "$collision_dir/alpha" ;;
        *) fail "unknown collision fixture: $collision_type" ;;
    esac

    if "$manager" link "$source_dir" "$collision_dir" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi

    [ -L "$collision_dir/beta" ] || fail "$collision_type collision did not continue with unrelated links"
}

check_collision file
check_collision directory
check_collision symlink
check_collision broken-symlink

if command -v script >/dev/null 2>&1; then
    replacement_dir=$test_root/replacement
    mkdir -p "$replacement_dir"
    printf '%s\n' 'preserve this skill' > "$replacement_dir/alpha"
    printf 'y\n' | script -q /dev/null "$manager" link "$source_dir" "$replacement_dir" >/dev/null 2>&1
    [ -L "$replacement_dir/alpha" ] || fail 'confirmed skill replacement did not create a symlink'
    backup_file=$(find "$replacement_dir" -name 'alpha-backup-*' -type f -print -quit)
    [ -n "$backup_file" ] || fail 'skill replacement did not create a timestamped backup'
    [ "$(cat "$backup_file")" = 'preserve this skill' ] || fail 'skill backup contents changed'
    [ -L "$replacement_dir/beta" ] || fail 'skill replacement did not link unrelated entries'
fi

"$manager" unlink "$source_dir" "$destination_dir"
[ ! -e "$destination_dir/alpha" ] && [ ! -L "$destination_dir/alpha" ] || fail 'alpha link was not removed'
[ ! -e "$destination_dir/beta" ] && [ ! -L "$destination_dir/beta" ] || fail 'beta link was not removed'
[ -f "$destination_dir/unrelated" ] || fail 'unrelated destination was removed'

foreign_dir=$test_root/foreign
mkdir -p "$foreign_dir"
ln -s "$source_dir/beta" "$foreign_dir/alpha"
"$manager" unlink "$source_dir" "$foreign_dir"
assert_link_target "$foreign_dir/alpha" "$source_dir/beta"

run_skill_make() {
    make -s -C "$project_root" "$@" \
        "CODEX_SKILLS_DIR=$test_root/make-codex" \
        "CLAUDE_SKILLS_DIR=$test_root/make-claude" \
        "OPENCODE_SKILLS_DIR=$test_root/make-opencode" \
        "OPENCODE_COMMANDS_DIR=$test_root/make-opencode-commands" \
        "OPENCODE_COMMANDS_CACHE_DIR=$test_root/make-opencode-cache" \
        "CURSOR_SKILLS_DIR=$test_root/make-cursor"
}

for agent in codex claude opencode cursor; do
    agent_destination=$test_root/make-$agent
    mkdir -p "$agent_destination"
    printf '%s\n' 'keep this user skill' > "$agent_destination/unrelated"
    ln -s "$source_dir/alpha" "$agent_destination/unrelated-symlink"

    run_skill_make "$agent"
    run_skill_make "$agent"

    integration_skill_count=0
    for repository_skill in "$project_root/skills"/*; do
        if [ ! -d "$repository_skill" ] || [ ! -f "$repository_skill/SKILL.md" ]; then
            continue
        fi

        integration_skill_count=$((integration_skill_count + 1))
        skill_name=${repository_skill##*/}
        assert_link_target "$agent_destination/$skill_name" "$repository_skill"
        cmp "$repository_skill/SKILL.md" "$agent_destination/$skill_name/SKILL.md" \
            || fail "$agent skill content differs from the authoritative definition"
        if [ "$agent" = opencode ]; then
            assert_link_target "$test_root/make-opencode-commands/$skill_name.md" "$test_root/make-opencode-cache/$skill_name.md"
        fi
    done
    [ "$integration_skill_count" -gt 0 ] || fail 'no repository skills were tested'

    run_skill_make "unlink-$agent"
    for repository_skill in "$project_root/skills"/*; do
        if [ ! -d "$repository_skill" ] || [ ! -f "$repository_skill/SKILL.md" ]; then
            continue
        fi

        skill_name=${repository_skill##*/}
        [ ! -e "$agent_destination/$skill_name" ] && [ ! -L "$agent_destination/$skill_name" ] \
            || fail "$agent Make target did not unlink $skill_name"
        if [ "$agent" = opencode ]; then
            [ ! -e "$test_root/make-opencode-commands/$skill_name.md" ] && [ ! -L "$test_root/make-opencode-commands/$skill_name.md" ] \
                || fail 'OpenCode Make target did not unlink its command adapters'
        fi
    done
    [ "$(cat "$agent_destination/unrelated")" = 'keep this user skill' ] \
        || fail "$agent unlink target removed unrelated data"
    assert_link_target "$agent_destination/unrelated-symlink" "$source_dir/alpha"
done

all_commands=$(run_skill_make -n all)
printf '%s\n' "$all_commands" \
    | grep -Fq "\"$manager\" link \"$project_root/skills\" \"$test_root/make-cursor\"" \
    || fail 'make all does not include Cursor skills'
unlink_all_commands=$(run_skill_make -n unlink-all)
printf '%s\n' "$unlink_all_commands" \
    | grep -Fq "\"$manager\" unlink \"$project_root/skills\" \"$test_root/make-cursor\"" \
    || fail 'make unlink-all does not include Cursor skills'

printf '%s\n' 'All skill symlink tests passed.'
