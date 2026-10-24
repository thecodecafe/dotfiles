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
make opencode    # ~/.config/opencode/skills
```

The link manager creates one symlink per skill and prompts before replacing a real destination. Confirmed replacements are backed up beside the destination as `<name>-backup-<unix timestamp>`. Unrelated symlinks are never replaced, and re-running a link target is idempotent. Remove only repository-owned links with the matching `make unlink-codex`, `make unlink-claude`, or `make unlink-opencode` target; `make unlink-all` includes all three.

## Let's discuss

The authoritative workflow is [lets-discuss/SKILL.md](lets-discuss/SKILL.md). All three link targets discover it automatically; there is no separate registration list or generated copy. Install or refresh the links from the repository root with `make codex claude opencode`.

Use these invocations inside the corresponding agent's conversation:

| Agent | Example |
| --- | --- |
| Codex | `$lets-discuss how should tenant access work?` |
| Claude Code | `/lets-discuss how should tenant access work?` |
| OpenCode | `/lets-discuss how should tenant access work?` |

The trailing text is the discussion topic; it can also be a document path or proposed decision. Without a topic or relevant conversation context, the skill asks what to discuss. It keeps accepted decisions separate from proposals and open questions, and only updates documents when authorized.

The default is learning-first: you contribute your understanding or proposal before the agent presents a complete solution. It explains meaningful weaknesses and why they matter, offers a small hint, and gives you room to revise. Feedback on your revision explains what improved and what remains unresolved. Fuller suggestions or complete alternatives follow when you ask or get stuck; direct factual questions and explicit requests for recommendations still receive direct answers. Missing concepts are explained plainly, research supports the discussion, and occasional recaps capture useful principles alongside decisions without quizzes or grading.

Questioning uses adaptive depth, usually one focused question per turn. Follow-ups build on your answers to explore meaning, causal reasoning, assumptions, evidence, counterexamples, alternatives, consequences, or changed constraints. Sound ideas can be examined for their rationale and limits without manufacturing faults. The agent occasionally helps you formulate and pursue questions of your own, and moves on when further probing adds little value or you want to change direction. Questions may deepen understanding even when they do not change a decision; there is no fixed checklist or question quota.

When a question has an important consideration worth reflecting on, the agent may place a brief `💡 reflect on:` paragraph immediately below it, separated by a blank line. The note is specific to the question and does not give away an answer, steer you toward a preferred conclusion, or add another question. It is omitted when it adds no meaningful value. Gentle, guided-meditation-style phrasing may occasionally invite you to pause with an idea or imagine a scenario, but ordinary conversational wording remains the default. The tone and reflection notes can appear independently; neither is required in every discussion.

Only when wrapping up, the agent recaps any accepted decisions that remain unrecorded and explicitly asks, "Would you like me to capture these agreed decisions now?" It uses the authoritative documents already established in context, without asking where to put them. It does not offer capture after individual decisions or intermediate milestones, or when nothing new has been agreed. Declined, deferred, or unanswered offers leave files unchanged and are not repeated unprompted. Existing documentation requests or standing authorization are honored without another approval question; the agent reports what was actually saved and does not claim capture succeeded when its mode or permissions prevented writing. Capture approval does not authorize implementation.

[Codex supports explicit skill mentions and symlinked skill directories](https://learn.chatgpt.com/docs/build-skills). [Claude Code invokes skills as slash commands and appends arguments when the skill has no argument placeholder](https://code.claude.com/docs/en/skills). [OpenCode exposes a skill as a slash command when its metadata includes `opencode/slash: "true"`](https://opencode.ai/docs/skills); this is the only tool-specific addition to the shared definition, so no command adapter is needed.

If a running agent does not show the new skill, start a fresh session. Checking symlink targets confirms installation, not discovery by an already-running session.

## Dependencies

- The corresponding agent tool (Codex, Claude Code, or OpenCode) installed and using its standard skills directory.
- A POSIX shell and `make` for the repository helpers.
- Individual workflows may require their own tools; consult the relevant `SKILL.md` before invoking one.
