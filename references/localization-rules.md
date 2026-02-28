# Localization Rules

OmniContext should support multilingual output with one shared protocol.

## Supported Languages

- `zh-CN`
- `en`
- `ja`

## Language Resolution Order

Choose the working language in this order:

1. explicit user request in the current task
2. project or shared language policy in `.omnicontext/shared/`
3. local user default in `.omnicontext/user.local.toml`
4. fallback to `en`

## Scope

Language affects:

- generated handoff text
- wiki and document templates
- tool-facing summaries when the user asked for a specific language

Language should not change:

- config keys
- folder names
- protocol structure

Keep file and config structure stable across languages.

## Recommended Policy

Use one canonical folder structure and let content language vary by context.

Examples:

- Internal China-facing project: `zh-CN`
- External documentation for global users: `en`
- Japan-facing delivery or collaboration: `ja`

## Shared Policy vs Local Preference

Use shared policy files for workspace or project language expectations.
Use `user.local.toml` only for the user's preferred default when the project has no stronger requirement.

## Recording Language Policy

Document language expectations in:

- `.omnicontext/shared/language-policy.md` for workspace-wide defaults
- project `overview.md` when one project differs from the workspace default

## Translation Principle

Do not maintain three separate knowledge trees unless the business truly requires independent localized content. Prefer one shared structure with language-aware content generation.
