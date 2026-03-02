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
4. fallback to `zh-CN`

## Scope

Language affects:

- generated handoff text
- wiki and document templates
- tool-facing summaries when the user asked for a specific language
- generated prompts, quick-start snippets, and operator-facing wording

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

## Prompt Templates By Language

Use the same workflow, but change the operator-facing prompt style by language:

- `zh-CN`
  - 默认中文提示词，语气直接、简洁，优先说明当前工作区状态、下一步动作和需要回写的文档
- `en`
  - Use concise operational English prompts that state the workspace target, the command or document action, and the expected write-back.
- `ja`
  - 日本語では簡潔な作業指示にし、対象ワークスペース、実行アクション、更新対象文書を明示する。
