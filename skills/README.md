# Skills

This directory contains reusable workflow instructions for coding agents:

- `aidlc`: initializes and runs the AWS AI-DLC workflow.
- `api-route-docs`: discovers HTTP API routes within a supplied scope and documents them as OpenAPI or a Postman collection.
- `commit`: plans and creates small conventional commits from the current Git diff.
- `grill-me`: invokes Matthew Pocock's interview workflow to sharpen a plan or design; it delegates to `grilling`.
- `grilling`: stress-tests a plan or idea through rounds of focused questions. Both skills are vendored from [mattpocock/skills](https://github.com/mattpocock/skills).
- `issue-to-review`: implements a GitHub or GitLab issue in an isolated worktree, then prepares a ready-for-review PR or MR.
- `lets-discuss`: develops your own ideas and reasoning about a product, domain, business, or architecture topic through learning-first discussion and explicit decisions, without implementing the discussed system.
- `maprepo`: inspects a repository and builds a concise structural map.
- `postman-api-testing`: discovers, tests, and documents a repository's REST API with the Postman CLI.

Each skill is a directory containing a `SKILL.md` definition. The Makefile links those directories into the supported agent locations:

```sh
make codex       # ~/.agents/skills
make claude      # ~/.claude/skills
make opencode    # ~/.config/opencode/skills and ~/.config/opencode/commands
make cursor      # ~/.cursor/skills
```

`make cursor` and `make opencode` are independent targets. `make cursor opencode` runs both in one invocation, sequentially unless Make's parallel execution is enabled.

The link manager creates one symlink per skill and prompts before replacing a real destination. Confirmed replacements are backed up beside the destination as `<name>-backup-<unix timestamp>`. Unrelated symlinks are never replaced, and re-running a link target is idempotent. Remove only repository-owned links with the matching `make unlink-codex`, `make unlink-claude`, `make unlink-opencode`, or `make unlink-cursor` target; `make all` and `make unlink-all` include all four agents. Override `CURSOR_SKILLS_DIR` to install Cursor links somewhere other than `~/.cursor/skills`.

All skills listed above support `/skill-name <arguments>` invocation in OpenCode and Cursor, including companion skills such as `/grilling`. For example, use `/commit`, `/api-route-docs scope=all`, or `/lets-discuss tenant access`. OpenCode 1.18.32 [registers discovered skills as commands automatically](https://github.com/anomalyco/opencode/blob/v1.18.32/packages/opencode/src/command/index.ts#L124), but its TUI [excludes native skill entries from individual slash autocomplete](https://github.com/anomalyco/opencode/blob/v1.18.32/packages/tui/src/component/prompt/autocomplete.tsx#L416). Its [frontmatter guidance](https://opencode.ai/docs/skills) confirms that `opencode/slash` metadata does not control this behavior.

`make opencode` therefore generates a thin [custom command adapter](https://opencode.ai/docs/commands) for every discovered skill. These appear directly in slash autocomplete: type `/lets` or `/com` to find `/lets-discuss` or `/commit`. Each adapter tells the agent to load the exact shared skill through OpenCode's native skill tool and passes the supplied text through `$ARGUMENTS`. It does not copy the workflow, override the current agent/model, or grant additional authorization. Existing invocation settings such as `grill-me`'s `disable-model-invocation: true` are preserved.

Adapters are generated only during installation/refresh in the gitignored `.generated/opencode/commands/` directory and linked individually into `~/.config/opencode/commands/`. Do not edit the generated files; change the shared skill or the adapter template in `scripts/manage-opencode-commands.sh`. Run `make opencode` after adding/removing skills or changing the adapter template. Workflow-only edits do not require adapter regeneration because the skill remains authoritative; start a fresh agent instance if a running one has cached the old instructions. Re-running setup is idempotent, removes stale owned adapters, and protects unrelated files/symlinks using the existing backup and confirmation rules. `make unlink-opencode` removes owned skill and command links, leaving generated files available for reuse. Override `OPENCODE_COMMANDS_DIR` and `OPENCODE_COMMANDS_CACHE_DIR` to change the command destination and generated-file location. An unrelated project/configuration command can still override a name; resolve that conflict explicitly rather than overwriting user configuration.

[Cursor discovers skills in `~/.cursor/skills` and supports slash invocation](https://cursor.com/docs/skills). It can also read the shared `~/.agents/skills` directory, but `make cursor` provides an independent, repository-managed installation using Cursor's own location. This setup is for local editor/CLI use; it does not enable Cloud Agent sync or publish a plugin. Linking does not install or upgrade either application. After linking, check OpenCode's slash autocomplete and Cursor's Skills view or slash menu; filesystem link checks alone do not prove live application discovery.

## Let's discuss

The authoritative workflow is [lets-discuss/SKILL.md](lets-discuss/SKILL.md). All four link targets discover it automatically; there is no separate registration list or copied workflow. OpenCode additionally generates the thin autocomplete adapter described above. Install or refresh the links from the repository root with `make codex claude opencode cursor`.

Use these invocations inside the corresponding agent's conversation:

| Agent | Example |
| --- | --- |
| Codex | `$lets-discuss how should tenant access work?` |
| Claude Code | `/lets-discuss how should tenant access work?` |
| OpenCode | `/lets-discuss how should tenant access work?` |
| Cursor | `/lets-discuss how should tenant access work?` |

The trailing text is the discussion topic; it can also be a document path or proposed decision. Without a topic or relevant conversation context, the skill asks what to discuss. It keeps accepted decisions separate from proposals and open questions, and only updates documents when authorized.

The default is learning-first: you contribute your understanding or proposal before the agent presents a complete solution. It explains meaningful weaknesses and why they matter, offers a small hint, and gives you room to revise. Feedback on your revision explains what improved and what remains unresolved. Fuller suggestions or complete alternatives follow when you ask or get stuck; direct factual questions and explicit requests for recommendations still receive direct answers. Missing concepts are explained plainly, research supports the discussion, and occasional recaps capture useful principles alongside decisions without quizzes or grading.

Questioning uses adaptive depth, usually one focused question per turn. Follow-ups build on your answers to explore meaning, causal reasoning, assumptions, evidence, counterexamples, alternatives, consequences, or changed constraints. Sound ideas can be examined for their rationale and limits without manufacturing faults. The agent occasionally helps you formulate and pursue questions of your own, and moves on when further probing adds little value or you want to change direction. Questions may deepen understanding even when they do not change a decision; there is no fixed checklist or question quota.

When a question has an important consideration worth reflecting on, the agent may place a brief `💡 reflect on:` paragraph immediately below it, separated by a blank line. The note is specific to the question and does not give away an answer, steer you toward a preferred conclusion, or add another question. It is omitted when it adds no meaningful value. Gentle, guided-meditation-style phrasing may occasionally invite you to pause with an idea or imagine a scenario, but ordinary conversational wording remains the default. The tone and reflection notes can appear independently; neither is required in every discussion.

Only when wrapping up, the agent recaps any accepted decisions that remain unrecorded and explicitly asks, "Would you like me to capture these agreed decisions now?" It uses the authoritative documents already established in context, without asking where to put them. It does not offer capture after individual decisions or intermediate milestones, or when nothing new has been agreed. Declined, deferred, or unanswered offers leave files unchanged and are not repeated unprompted. Existing documentation requests or standing authorization are honored without another approval question; the agent reports what was actually saved and does not claim capture succeeded when its mode or permissions prevented writing. Capture approval does not authorize implementation.

[Codex supports explicit skill mentions and symlinked skill directories](https://learn.chatgpt.com/docs/build-skills). [Claude Code invokes skills as slash commands and appends arguments when the skill has no argument placeholder](https://code.claude.com/docs/en/skills). OpenCode's command adapter delegates to its native skill loader, and Cursor uses native skill discovery; all four installations share the same workflow.

If a running agent does not show the new skill, start a fresh session. Checking symlink targets confirms installation, not discovery by an already-running session.

## Dependencies

- The corresponding agent tool (Codex, Claude Code, OpenCode, or Cursor) installed and using its standard skills directory.
- A POSIX shell and `make` for the repository helpers.
- Individual workflows may require their own tools; consult the relevant `SKILL.md` before invoking one.
