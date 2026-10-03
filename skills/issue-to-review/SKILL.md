---
name: issue-to-review
description: Implement a GitHub or GitLab issue in an isolated worktree, use the commit skill, and publish a ready-for-review PR or MR.
---

# Issue to review

Use this workflow when asked to implement an issue in a repository and prepare the result for review.

## Identify the task and verify access

- Require an issue URL, or an issue number when the current repository and hosting service are unambiguous. Identify the repository root, provider, host, and remote from the issue reference and Git remotes. If they disagree or are ambiguous, ask before proceeding.
- Capture the currently checked-out branch and its `HEAD` commit before creating the task worktree. If the checkout is detached or no starting branch can be identified, stop and ask; never silently use the default branch.
- Check provider authentication for the issue's host before making code changes. Prefer `gh` for GitHub and `glab` for GitLab when installed and authenticated. Run provider CLIs through the current agent's approved host/unsandboxed command path. Never run `gh` inside a sandbox or treat a sandbox-only auth failure as proof that the user is unauthenticated. Do not request or display token values.
- If the CLI is unavailable or reports an auth problem, ask whether the user wants to fix CLI access or explicitly use API authentication. Use API authentication only after that choice and only with an already-configured environment token; check its presence without printing it. If no safe host-side CLI or token path is available, stop and explain what is needed.
- Read the issue title, description, and relevant discussion, plus repository instructions. Confirm the issue belongs to the current repository before proceeding.

## Create and use an isolated worktree

- Derive a concise task slug from the issue, using lowercase ASCII letters and digits separated by single hyphens. The slug must be no more than 20 characters; exclude spaces and the issue number. If no clear slug fits, ask the user to choose one.
- Create the branch with the exact form `feature/<task-name>`, starting from the captured `HEAD` of the branch checked out when this skill began—not the default branch. The pull/merge request base is that same starting branch.
- Place the worktree at `../<repo-name>-worktrees/<task-name>`, relative to the starting worktree's parent directory. Check for both local/remote branch conflicts and a pre-existing path first. If either exists, stop and ask; do not reuse, overwrite, or delete it.
- If the starting worktree has uncommitted changes, leave them untouched and do not copy or stash them. The new worktree contains only committed content at the captured `HEAD`. If the issue cannot be completed without those uncommitted changes, stop and ask how to proceed.
- Make all task edits and run checks only in the new worktree. Do not modify or commit changes in the starting worktree.

## Implement, commit, and publish

- Implement only the issue's scope, following repository guidance, and run relevant tests or checks. Summarize any checks that cannot be run.
- Invoke the existing `commit` skill using the active agent's native skill mechanism. Preserve its commit-plan approval and all its rules. If the skill is unavailable, stop rather than bypassing its approval workflow. Do not push or publish if the commit plan is declined or the commits fail.
- After the approved commits succeed, push only the task branch; never force-push or push the starting branch. If the starting branch is not available on the hosting service as a review target, or publishing fails, stop and report the blocker rather than pushing that base branch or changing the target.
- Create a ready-for-review GitHub PR or GitLab MR targeting the captured starting branch. Use the provider CLI when authenticated; use the API only under the explicit fallback choice above. Include a concise change summary, tests run, and the issue reference with the provider's supported close-link syntax. Do not enable auto-merge.
- Leave the task worktree and branch in place after publishing so the user can review the code locally. Report the worktree path and review URL.

## Stop conditions

Ask the user rather than guessing if the issue/repository mapping, starting branch, task slug, or review target cannot be determined safely. Honor the current agent's permission and approval requirements; this skill does not authorize bypassing sandbox or host security controls.
