---
name: postman-api-testing
description: Discover, test, and document a repository's REST API with the Postman CLI and a private Postman workspace.
---

# Postman API testing

Use this workflow when asked to test REST endpoints or create/update their Postman collection documentation. Test only the API surface relevant to the request unless the user asks for a broader audit. This skill tests and documents the API; it does not change application implementation to make tests pass unless separately requested.

## Inspect the project and identify the API

- Read the repository's agent instructions and inspect `git status` before working. Preserve existing changes.
- Identify the API service root, especially in a monorepo. Determine its project type from manifests and source, then inspect its OpenAPI/Swagger spec, existing Postman collection, route handlers, tests, README, and task scripts. Prefer an existing spec or collection as the contract; use implementation and tests to fill gaps. Don't invent undocumented routes or response fields.
- Limit new or changed requests to the API surface asked about. Reuse matching existing collection requests instead of creating duplicates. Document method, path, required inputs/auth, and supported success/error responses with sanitized examples.

## Configure and remember project preferences

Store only non-secret preferences in `.postman/agent-config.json` at the API service root. Keep this separate from Postman's `.postman/resources.yaml` and `.postman/config.json`; never ignore the whole `.postman/` directory. Add an exact path to the repository `.gitignore`, written relative to the Git root (including the service subdirectory when in a monorepo), and verify it with `git check-ignore` before writing the config. If the config is already tracked or cannot be safely ignored, stop and ask.

On first use, inspect the repo first, then ask only for information that cannot be discovered or safely inferred. Save confirmed answers. When the config already exists, ask whether to reuse it or configure fresh. If the user chooses fresh, collect the new answers and ask before replacing the saved file; if replacement is declined, use the fresh answers only for that run.

The config may contain a version, project type, working directory, approved startup command as an argument array, API base URL, readiness path, target environment (`local`, `dev`, or `test`), Postman collection path/workspace ID, authentication variable names, and whether to upload run results to Postman Cloud. Omit unknown values rather than guessing. Never store token, password, cookie, or other secret values; refer to environment-variable names or local Postman secret values only.

## Start the API safely

- Prefer an already-running API. Otherwise, find its documented local start command in the service README, Makefile, task runner, or project scripts.
- Detect language/framework from project manifests. For Go, inspect `go.mod`, documented scripts, and `main` packages (commonly under `cmd/`). Prefer documented commands such as `make dev`; infer a `go run` package only if there is exactly one clearly identifiable API entrypoint. If the command, service root, port, or target environment is ambiguous, ask instead of guessing.
- Execute a saved or discovered command as an argument array from its service working directory, not through an interpolated shell string. Start only the API process. Reuse a running service and never kill a process the skill did not start. Track any process started by the skill and stop only that process after testing.
- Use the documented/configured readiness path. If startup fails or readiness times out, report sanitized logs and stop; do not kill whatever is listening on the port.
- Ask before starting databases, containers, queues, or other dependencies, and before migrations, seeding, resets, or cleanup that could affect pre-existing data.

## Run API tests with Postman

- Require the Postman CLI (`postman`). If it is unavailable, stop before claiming tests ran and provide the [official installation instructions](https://learning.postman.com/docs/postman-cli/postman-cli-installation/). Don't substitute GUI automation or another runner.
- If no API service is already running and no safe, clear start command exists, ask the user. Run the relevant collection with `postman collection run`, using the configured local environment when needed. Report actual request/assertion outcomes; never claim a test passed if it was skipped or couldn't run.
- Test writes only when the selected target is explicitly known to be local/dev/test. Use isolated, uniquely identifiable test records. Cleanup may delete only records created by that run; never issue broad deletes, reset a database, or target production. If the environment or cleanup safety is unclear, ask first.
- Use credentials already configured in the environment or local Postman secrets. Do not print, copy into the collection, or sync secret values. Redact tokens, cookies, personal data, and sensitive response bodies from logs and summaries.
- Check `postman whoami` before cloud operations. If unauthenticated, ask the user to sign in with `postman login`; do not request or display an API key as a fallback.
- A signed-in CLI can upload run results for a collection linked to Postman Cloud. Respect `upload_run_results` (default `false`): when false, run an unlinked temporary copy of the local collection outside the connected workspace; when true, run the linked collection and report the resulting Postman link if provided.

## Maintain Postman collection and documentation

- Keep collection files alongside the API repo under its existing Postman Native Git layout. If Native Git is already configured, preserve its manifests and mappings. If it isn't, run `postman init --dry-run`, explain the files/agent skills it proposes to add, and ask before initializing with `postman init --no-cloud`. Never rerun initialization over an existing Postman setup.
- For cloud documentation, use the workspace already connected/configured for this service. If no workspace is selected or multiple candidates exist, ask. Ask before creating a workspace or connecting a repo. Use a non-public private/team workspace; never publish documentation publicly without a separate, explicit request.
- Before syncing, preview with `postman workspace diff --push-strategy default`. If the target workspace is wrong or the diff includes unexpected resources, stop and ask. Otherwise sync with `postman workspace push --push-strategy default` and without `--yes`. Never use `force-sync`: it can delete cloud resources absent locally. Do not sync secret environment values or live response examples.
- If local tests succeed but cloud authentication or sync is unavailable, keep the local collection, report what remains unsynced, and do not claim the cloud documentation was updated.

## Report results

Summarize the API surface tested, target environment, startup command used, test pass/fail/skip results, documentation/collection changes, cloud sync status, and any cleanup performed. Call out untested cases and blockers. Do not modify API implementation or publish/share the collection beyond the selected private workspace unless asked.
