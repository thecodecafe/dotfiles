#!/bin/sh

set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
manager=$project_root/scripts/manage-opencode-commands.sh
test_root=$(mktemp -d "${TMPDIR:-/tmp}/opencode commands.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_link_target() {
    [ -L "$1" ] || fail "$1 is not a symlink"
    [ "$(readlink "$1")" = "$2" ] || fail "$1 has the wrong target"
}

skills_dir=$test_root/source\ skills
cache_dir=$test_root/generated\ files
commands_dir=$test_root/user\ commands
mkdir -p "$skills_dir/alpha" "$skills_dir/beta" "$skills_dir/ignored" "$commands_dir"
printf '%s\n' '---' 'name: alpha' 'description: test alpha' '---' 'authoritative alpha instructions' > "$skills_dir/alpha/SKILL.md"
printf '%s\n' '---' 'name: beta' 'description: test beta' '---' 'authoritative beta instructions' > "$skills_dir/beta/SKILL.md"
printf '%s\n' 'preserve this command' > "$commands_dir/unrelated.md"
ln -s "$skills_dir/alpha/SKILL.md" "$commands_dir/foreign.md"

"$manager" link "$skills_dir" "$cache_dir" "$commands_dir"
for skill_name in alpha beta; do
    adapter=$cache_dir/$skill_name.md
    assert_link_target "$commands_dir/$skill_name.md" "$adapter"
    grep -Fqx "description: Run the shared $skill_name skill" "$adapter"
    grep -Fq "Load the \"$skill_name\" skill using the native skill tool" "$adapter"
    grep -Fqx '$ARGUMENTS' "$adapter"
    if grep -Eq '^(agent|model|subtask):|^!' "$adapter"; then
        fail 'adapter overrides execution settings or adds a shell command'
    fi
    if grep -Fq 'authoritative' "$adapter"; then
        fail 'adapter copied the skill body'
    fi
done
[ ! -e "$commands_dir/ignored.md" ] || fail 'directory without SKILL.md was registered'

adapter_inode=$(ls -di "$cache_dir/alpha.md" | awk '{print $1}')
adapter_checksum=$(cksum < "$cache_dir/alpha.md")
printf '%s\n' 'changed authoritative instructions' >> "$skills_dir/alpha/SKILL.md"
"$manager" link "$skills_dir" "$cache_dir" "$commands_dir"
[ "$(ls -di "$cache_dir/alpha.md" | awk '{print $1}')" = "$adapter_inode" ] \
    || fail 'repeat installation rewrote an unchanged adapter'
[ "$(cksum < "$cache_dir/alpha.md")" = "$adapter_checksum" ] \
    || fail 'skill-body edits changed the thin adapter'
printf '%s\n' 'outdated adapter content' >> "$cache_dir/alpha.md"
"$manager" link "$skills_dir" "$cache_dir" "$commands_dir"
[ "$(cksum < "$cache_dir/alpha.md")" = "$adapter_checksum" ] \
    || fail 'owned adapter was not refreshed'

mkdir -p "$skills_dir/gamma"
printf '%s\n' '---' 'name: gamma' 'description: test gamma' '---' 'gamma instructions' > "$skills_dir/gamma/SKILL.md"
mv "$skills_dir/beta" "$test_root/removed beta"
printf '%s\n' 'preserve unrelated cache data' > "$cache_dir/unrelated.md"
"$manager" link "$skills_dir" "$cache_dir" "$commands_dir"
assert_link_target "$commands_dir/gamma.md" "$cache_dir/gamma.md"
[ ! -e "$commands_dir/beta.md" ] && [ ! -L "$commands_dir/beta.md" ] \
    || fail 'removed skill retained its command link'
[ ! -e "$cache_dir/beta.md" ] || fail 'removed skill retained its generated adapter'
[ "$(cat "$cache_dir/unrelated.md")" = 'preserve unrelated cache data' ] \
    || fail 'stale cleanup removed unrelated cache data'

for collision_type in file directory symlink broken-symlink; do
    collision_dir=$test_root/collision-$collision_type
    collision_cache=$test_root/cache-$collision_type
    mkdir -p "$collision_dir"
    case "$collision_type" in
        file) printf '%s\n' 'keep this file' > "$collision_dir/alpha.md" ;;
        directory) mkdir "$collision_dir/alpha.md" ;;
        symlink) ln -s "$skills_dir/alpha/SKILL.md" "$collision_dir/alpha.md" ;;
        broken-symlink) ln -s "$test_root/missing" "$collision_dir/alpha.md" ;;
    esac
    if "$manager" link "$skills_dir" "$collision_cache" "$collision_dir" >/dev/null 2>&1; then
        fail "$collision_type collision unexpectedly succeeded"
    fi
    case "$collision_type" in
        file) [ "$(cat "$collision_dir/alpha.md")" = 'keep this file' ] || fail 'file collision changed user data' ;;
        directory) [ -d "$collision_dir/alpha.md" ] && [ ! -L "$collision_dir/alpha.md" ] || fail 'directory collision changed user data' ;;
        symlink) assert_link_target "$collision_dir/alpha.md" "$skills_dir/alpha/SKILL.md" ;;
        broken-symlink) assert_link_target "$collision_dir/alpha.md" "$test_root/missing" ;;
    esac
    assert_link_target "$collision_dir/gamma.md" "$collision_cache/gamma.md"
done

if command -v script >/dev/null 2>&1; then
    replacement_dir=$test_root/replacement
    replacement_cache=$test_root/replacement-cache
    mkdir -p "$replacement_dir"
    printf '%s\n' 'back up this command' > "$replacement_dir/alpha.md"
    printf 'y\n' | script -q /dev/null "$manager" link "$skills_dir" "$replacement_cache" "$replacement_dir" >/dev/null 2>&1
    assert_link_target "$replacement_dir/alpha.md" "$replacement_cache/alpha.md"
    backup_file=$(find "$replacement_dir" -name 'alpha.md-backup-*' -type f -print -quit)
    [ -n "$backup_file" ] && [ "$(cat "$backup_file")" = 'back up this command' ] \
        || fail 'confirmed replacement did not preserve a backup'
fi

foreign_cache=$test_root/foreign-cache
mkdir -p "$foreign_cache"
printf '%s\n' 'not a generated adapter' > "$foreign_cache/alpha.md"
if "$manager" link "$skills_dir" "$foreign_cache" "$test_root/foreign-commands" >/dev/null 2>&1; then
    fail 'unrelated generated-path file was overwritten'
fi
[ "$(cat "$foreign_cache/alpha.md")" = 'not a generated adapter' ] || fail 'unrelated cache file changed'

unsafe_source=$test_root/invalid-source
mkdir -p "$unsafe_source/Invalid Name"
printf '%s\n' 'invalid fixture' > "$unsafe_source/Invalid Name/SKILL.md"
if "$manager" link "$unsafe_source" "$test_root/invalid-cache" "$test_root/invalid-commands" >/dev/null 2>&1; then
    fail 'invalid skill name was accepted'
fi
[ ! -e "$test_root/invalid-cache" ] || fail 'invalid names caused generation'
if "$manager" link "$skills_dir" "$skills_dir" "$commands_dir" >/dev/null 2>&1; then
    fail 'source directory was accepted as a generated directory'
fi

# A missing cache must not prevent removal of the installed owned symlinks.
mv "$cache_dir" "$test_root/removed cache"
"$manager" unlink "$skills_dir" "$cache_dir" "$commands_dir"
"$manager" unlink "$skills_dir" "$cache_dir" "$commands_dir"
for skill_name in alpha gamma; do
    [ ! -e "$commands_dir/$skill_name.md" ] && [ ! -L "$commands_dir/$skill_name.md" ] \
        || fail 'unlink retained a broken owned command link'
done
[ ! -e "$cache_dir" ] || fail 'unlink recreated the missing cache'
[ "$(cat "$commands_dir/unrelated.md")" = 'preserve this command' ] \
    || fail 'unlink removed unrelated data'
assert_link_target "$commands_dir/foreign.md" "$skills_dir/alpha/SKILL.md"

"$manager" link "$skills_dir" "$cache_dir" "$commands_dir"
"$manager" unlink "$skills_dir" "$cache_dir" "$commands_dir"
[ -f "$cache_dir/alpha.md" ] || fail 'unlink unnecessarily removed reusable generated files'

printf '%s\n' 'All OpenCode command adapter tests passed.'
