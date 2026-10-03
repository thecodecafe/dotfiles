---
name: api-route-docs
description: Discover implemented HTTP API routes within a project scope and document them as OpenAPI or a Postman collection.
---

# API route documentation

Use this skill to inventory and document implemented HTTP API routes in the requested project scope. This is a documentation-only workflow: do not change application code, start services, call live endpoints, run API tests, or sync documentation to Postman Cloud.

## Scope and discovery

- Read the repository's agent instructions and inspect `git status` before editing. Preserve existing changes.
- Read the `scope=` argument from the skill invocation. Accept `scope=all`, one module name/path, or a comma-separated set such as `scope=internal/auth,internal/billing`. If it is missing, ask for it. Resolve names and paths against the repository's actual module/service layout; ask if a value is unknown or maps to multiple scopes. `all` means all project-owned API services in the repository.
- Identify project and service boundaries from manifests and source. Within scope, inspect router registrations, route groups, handlers, request/response types, validators, auth middleware, tests, and existing API documentation. Follow framework conventions to account for prefixes, versioning, and parameterized paths.
- Document only implemented routes. Include method and path, purpose, parameters, request body, auth requirements, response status/body schemas, and error responses when supported by source or tests. Do not invent fields or behavior; report routes or details that are dynamic or cannot be verified.
- If scope covers independent API services, keep their documentation artifacts separate. Do not alter routes outside scope.

## Choose and update the documentation format

- After resolving the scope and before editing documentation, ask the user to choose exactly one output for this run: OpenAPI or Postman. Do not generate both.
- Find the selected format's existing documentation in each service and update it in place, preserving its version, conventions, and out-of-scope content. Avoid duplicate operations or requests. Do not delete entries just because they are outside the requested scope.
- If no OpenAPI document exists, create `docs/openapi.yaml` under each applicable service root, using the latest stable published OpenAPI version supported by the project's tools (3.2.1 at the time this skill was written). Follow an existing repository convention if present.
- If no Postman collection exists, create a local Postman Collection v3.0.0 Native Git collection under `postman/<service-name>/`, following Postman's current YAML collection schema. Preserve any existing Postman mappings/configuration and do not initialize, connect, or publish a cloud workspace as part of this workflow.
- Do not place credentials, tokens, cookies, personal data, or real sensitive response bodies in examples. Use clearly synthetic values.

## Validate and report

- Compare the generated operations/requests against the in-scope route inventory and confirm that every discovered route is represented without adding unsupported routes.
- Run the repository's existing documentation validator when available. For OpenAPI, use the configured OpenAPI linter; for Postman v3, use `postman collection lint` if the Postman CLI is installed. Do not install tools. If no suitable validator is available, check file syntax/structure with available local tools and state the limitation.
- Review the diff to ensure only the selected documentation format and intended service scope changed. Do not run the API or make network requests.
- Report the resolved scope, discovered route count, documentation format and files updated/created, validation results, and any undocumented/uncertain routes or blockers.
