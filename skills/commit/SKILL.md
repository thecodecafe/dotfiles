---
name: commit
description: Commits the code using conventional git messages while splitting the changes into small commits.
---
/plan
Your goal is to commit the repository changes efficiently. Ignore previous conversations or any previous plan you made/had, your source of truth for what need to be committed is the result you get from running `git status` and `git diff`.

Tooling rules:

- Use rg (ripgrep) to search the codebase before opening files.
- Only open files that are relevant.
- Prefer shell tools over model reasoning whenever possible.

Workflow:

1. Inspect repository changes:
   - Run `git status` to list all changed files
   - Run `git diff` to see the full diff of all unstaged changes
   - Analyze each file's diff to identify distinct logical changes — a single file may contain multiple unrelated changes that should be committed separately
   - Inspect hunk boundaries (@@ lines) in the diff to verify that `git add -p` will split cleanly across planned commits

2. Plan all commits before executing any commands.

3. Group changes into logical commits based on what the code actually does, not which files changed.

4. Present the commit plan to the user and wait for approval. Do NOT execute any commits until explicitly told to proceed.
   - If the user asks you to re-run or try again, re-present the plan from scratch. Never assume a previous plan carries over.

5. Once approved, execute commits using git commands.
   - Before running `git commit`, output a summary of exactly which files/hunks are staged and what each commit will contain. This is your final checkpoint.

6. Do not push the commits.

Commit rules:

• CRITICAL: ABSOLUTELY NO FILE MODIFYING, RESTORING, OR RECONSTRUCTING AT ANY POINT BEFORE EXECUTION. The working tree is immutable until I approve the plan. During planning (steps 1-4), you MUST NOT use `sed`, `python3` writes, `write`, `edit`, `cp`, `mv`, `rm`, `git checkout`, `git restore`, `git reset`, or ANY command that changes files, git state, or the working tree. Accept `git status` and `git diff` output as-is. Never attempt to fix, restore, or reconstruct changes. If the state looks wrong, report it — do NOT touch anything. If you cannot produce a plan from the current state, stop and ask the user.
• CRITICAL: ABSOLUTELY NO REBASE — EVER. Never run `git rebase`, `git rebase -i`, `git pull --rebase`, or any rebase variant under any circumstances. This rule has ZERO exceptions. If you need to update a branch, use merge only when explicitly requested by the user. Never suggest, propose, or execute a rebase.
• Use Conventional Commits
• Each commit should represent one logical change — one distinct component (one use case, one handler, one DTO, one router, one error mapper, etc.)
• Do not bundle multiple distinct components into a single commit even if they share a directory or even the same file
• A single file can contain multiple logical changes — analyze the diff to identify separate concerns (e.g., removing unused methods, adding new methods, changing validation logic)
• Separate unrelated bug fixes even when they are in the same file. Each fix gets its own commit.
• Separate infrastructure additions (new files) from configuration changes (wiring, registration)
• Wiring dependencies in bootstrap files is a separate logical change from registering routes in the application entry point
• When adding a new feature (e.g., a new endpoint), separate into distinct commits: the query/port, the use case, the handler and DTOs, then the wiring and route registration
• Each commit must be small enough for a human reviewer to read through and easily comprehend what's going on
• Commit messages must describe the GOAL of the change from a domain/business perspective, not the implementation mechanics
  - Bad: "add account reader dependency to create team use case"
  - Good: "include team owner name when creating a team"
  - Bad: "fix resend invitation use case bugs"
  - Good: "adapt resend invitation to renamed invitation token service interface"
• Focus only on the uncommitted changes and come up with a commit plan
• You MUST account for ALL unstaged and untracked files shown by `git status` — do not skip or ignore any changed files
• Before executing commits, verify that every file from `git status` is included in your commit plan
• Avoid vague messages — always ensure the commit message is clear about what's changing
• Always use the right commit type. Use these definitions:
  - `feat`: Any change that adds new behavior, new capabilities, new validation rules, new constraints, new fields, or new requirements. If anything the code does is different from before, it's a feat.
  - `fix`: Any change that corrects broken or incorrect behavior.
  - `refactor`: Code restructuring that changes NOTHING — not external behavior, not internal behavior, not inputs, not outputs, not validation, not constraints. Only the structure, naming, or organization of the code changes.
  - `docs`: Documentation-only changes.
  - `test`: Adding or modifying tests.
  - `chore`: Maintenance tasks, dependency updates, tooling config.
  - `perf`: Performance improvements.
  - `style`: Code style changes (formatting, whitespace) that do not affect behavior.
• When a file contains multiple distinct logical changes, you MUST use `git add -p` to stage only the relevant hunks for each commit. Do not stage entire files when they contain unrelated changes.
   - If `git add -p` hunks don't split cleanly or get messy, DO NOT fall back to staging the entire file. Stop and ask the user how to proceed.
• Never delete, exclude, or skip an untracked file based on naming assumptions (e.g., _old, _backup, _tmp). If a file exists in the working directory, treat it as intentional and include it in your commit plan.

Commit format:

type(scope): short description

Allowed types:
feat
fix
refactor
docs
test
chore
perf
style

Scope naming:
• Use joined words without hyphens (e.g., `createteam`, `membersummaryquery`, `accountreader`, `teammemberstable`)
• Scope must be meaningfull and as specific as the component being changed — avoid broad module-level scopes when the change affects a single component (e.g., use `listteampipelines` or `pipelinesummaryquery` instead of `pipelinecore`)
• Derive scope names from the actual directory, package, or domain name being changed — do not invent new names. For example, if changes are in `internal/adaptation/adaptationcore/`, use `adaptationcore` as the scope, not `adaptationmigrationrunner` or `adaptationschema`.
• When in doubt about the scope, check the directory structure or existing commits for the naming convention used in that area.

Self-review before presenting the plan:
• For each commit, verify: Are there multiple unrelated changes bundled together? (e.g., two different bug fixes in the same file, a feature addition mixed with a refactor). If so, split them.
• For each commit, verify: Does the type match the change? (feat for new behavior/constraints/requirements, fix for broken behavior, refactor ONLY when nothing changes except structure)
• Does the message describe the goal, not the implementation?
• Is the scope a single joined word without hyphens?
• If any commit fails these checks, revise it before presenting.

Final step:
Show the resulting commit history with:

git log --oneline -n 10
