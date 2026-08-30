# Skills

This directory contains reusable workflow instructions for coding agents:

- `aidlc`: initializes and runs the AWS AI-DLC workflow.
- `commit`: plans and creates small conventional commits from the current Git diff.
- `maprepo`: inspects a repository and builds a concise structural map.

Each skill is a directory containing a `SKILL.md` definition. The Makefile links those directories into the supported agent locations:

```sh
make codex       # ~/.agents/skills
make claude      # ~/.claude/skills
make opencode    # ~/.config/opencode/skills
```

The link manager creates one symlink per skill and prompts before replacing a real destination. Confirmed replacements are backed up beside the destination as `<name>-backup-<unix timestamp>`. Unrelated symlinks are never replaced, and re-running a link target is idempotent. Remove only repository-owned links with the matching `make unlink-codex`, `make unlink-claude`, or `make unlink-opencode` target; `make unlink-all` includes all three.

## Dependencies

- The corresponding agent tool (Codex, Claude Code, or OpenCode) installed and using its standard skills directory.
- A POSIX shell and `make` for the repository helpers.
- Individual workflows may require their own tools; consult the relevant `SKILL.md` before invoking one.
