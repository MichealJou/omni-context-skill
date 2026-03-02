---
name: omni-context
description: Build and maintain a reusable OmniContext workspace knowledge system for coding tools such as Codex, Claude Code, Qoder, and Trae. Use when the user wants a shared knowledge structure, project wiki, handoff flow, technical docs, design docs, or multi-project workspace context that can be initialized per real project.
---

# OmniContext

OmniContext is a reusable workflow for creating and maintaining a `.omnicontext/` delivery-control layer inside a real codebase. The skill does not store business knowledge itself. It defines how to initialize, read, validate, and update project-local OmniContext data.

## Use This Skill When

- The user wants a reusable knowledge system across projects or machines
- The user wants project wiki, handoff, todo, decision, technical, design, or runbook documents organized consistently
- The user uses more than one coding tool and wants a shared context layer
- The user wants to detect whether a workspace is single-project or multi-project and configure context accordingly

## Core Model

Separate the system into two parts:

1. **Skill repo**: reusable rules, templates, and optional scripts
2. **Workspace data**: a `.omnicontext/` directory created inside a real business workspace

The skill should remain generic. Real project facts belong in `.omnicontext/`, not in the skill repo.

## Interaction Principle

- Be concise by default
- Ask only when blocked by missing critical input or high-risk confirmation
- Prefer direct status, blocker, and next-step output
- Default to Chinese unless the user or workspace explicitly requires another language

## Current Automation

The skill now includes a unified CLI plus workflow, rules, bundle, testing, runtime, safety, and autopilot commands:

- `scripts/omni-context <command> ...`
- `scripts/omni-context [--lang zh-CN|en|ja] <command> ...`
- `scripts/install-skill.sh [destination]`
- `scripts/create-demo-workspace.sh <target-dir>`
- `scripts/init-workspace.sh [workspace-root]`
- `scripts/sync-workspace.sh [workspace-root]`
- `scripts/status-workspace.sh [workspace-root]`
- `scripts/project-doctor.sh <workspace-root> <project-name> [workflow-id]`
- `scripts/check-skill.sh`
- `scripts/git-finish.sh <repo-root> <commit-message> [--all|<path>...]`
- `scripts/new-project.sh <workspace-root> <project-name> <source-path>`
- `scripts/new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]`
- `scripts/init-project-standards.sh <workspace-root> <project-name> [project-type]`
- `scripts/role-status.sh <workspace-root> <project-name>`
- `scripts/runtime-status.sh <workspace-root> <project-name>`
- `scripts/start-workflow.sh <workspace-root> <project-name> <title> [slug]`
- `scripts/workflow-status.sh <workspace-root> <project-name> [workflow-id]`
- `scripts/workflow-check.sh <workspace-root> <project-name> [workflow-id]`
- `scripts/advance-stage.sh <workspace-root> <project-name> <stage> <role>`
- `scripts/skip-stage.sh <workspace-root> <project-name> <stage> <role> <reason> <risk> <authority>`
- `scripts/list-workflows.sh <workspace-root>`
- `scripts/rules-pack-init.sh <workspace-root> <project-name> [pack-id]`
- `scripts/rules-pack-status.sh <workspace-root> <project-name>`
- `scripts/rules-pack-check.sh <workspace-root> <project-name>`
- `scripts/rules-pack-list.sh`
- `scripts/bundle-status.sh <workspace-root> <project-name> [stage] [role]`
- `scripts/bundle-install.sh <workspace-root> <project-name> [stage] [role]`
- `scripts/bundle-check.sh <workspace-root> <project-name> [stage] [role]`
- `scripts/init-test-suite.sh <workspace-root> <project-name> <suite-title> [suite-id]`
- `scripts/collect-test-evidence.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--dependency dep-id] [--mode auto|browser|api|service|miniapp] [--platform web|backend|miniapp]`
- `scripts/setup-test-runtime.sh <workspace-root> <project-name> [--platform web|backend|miniapp|all] [--check-only]`
- `scripts/run-browser-suite-devtools.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform web|miniapp] [--dependency dep-id]`
- `scripts/run-browser-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform web|miniapp] [--dependency dep-id] [--fallback-note note]`
- `scripts/run-api-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform backend] [--dependency dep-id]`
- `scripts/execute-test-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--mode browser|api|service|miniapp] [--platform web|backend|miniapp] [--evidence path]`
- `scripts/record-test-run.sh <workspace-root> <project-name> <suite-id> <run-title> [run-id]`
- `scripts/test-status.sh <workspace-root> <project-name> [workflow-id]`
- `scripts/backup-object.sh <workspace-root> <project-name> <dependency-id> <object> <action>`
- `scripts/danger-check.sh <workspace-root> <project-name> <dependency-id> <operation-type> <object>`
- `scripts/record-dangerous-op.sh <workspace-root> <project-name> <dependency-id> <operation-type> <object> <backup-path>`
- `scripts/autopilot-run.sh <workspace-root> <project-name> [workflow-id]`
- `scripts/autopilot-status.sh <workspace-root> <project-name> [workflow-id]`

Prefer the unified CLI. The standalone scripts remain the implementation targets.

## Working Rules

1. Start from protocol, not automation.
   Define the folder structure, config format, and core document set before writing scripts.
2. Prefer dynamic discovery.
   Do not assume the workspace is multi-project. Detect structure from the current environment or a workspace config.
3. Scan project standards before writing them.
   When initializing project standards, inspect existing config, linting, formatting, build, CI, test, and runtime files first. Then solidify the discovered rules into project-local `standards/`.
3. Keep context loading small.
   Read `INDEX.md`, then the relevant project `overview.md` and `handoff.md`, and only then load shared or personal files if needed.
4. Record durable knowledge only.
   Write decisions, run instructions, architecture notes, and active handoff state. Do not write secrets, raw tokens, or disposable logs.
5. Keep local differences local.
   Put machine-specific and user-specific settings in local config files, not in shared workspace config.
6. Resolve language from context.
   Prefer explicit user language, then project or shared language policy, then the local user default. Default to Chinese. Support Chinese, English, and Japanese without forking the skill into separate copies.
7. Keep formal test cases immutable during execution.
   Formal testing only accepts non-draft suites. Runs must match the current suite fingerprint and may not silently rewrite or reinterpret suite steps.
7. If Git is in use, commit by smallest completed feature by default.
   This rule is enabled by default. When one function or coherent change is complete, create one minimal commit with a clear message. Do not mix unrelated changes into the same commit. This keeps rollback and regression tracing practical. A workspace may explicitly disable it through config when needed.
8. Push by default, but allow opt-out.
   The default behavior is commit and push after each completed feature-sized change. A workspace or local config may explicitly disable `auto_push_after_commit` when the user does not want every commit pushed.
9. Treat testing as a hard gate.
   Testing must use defined test cases, execution records, and evidence. Frontend-style clients must use real interaction testing. Do not modify test cases during execution.
10. Prefer DevTools for formal browser execution.
   Formal web and miniapp suites should run through the DevTools-first browser executor. Only fall back to Playwright when DevTools execution fails in an allowed fallback condition.
11. Protect dangerous data operations.
   Local destructive database or Redis operations require backup first. Production destructive operations require a clear explanation and explicit user confirmation.
12. Support autopilot, but stop on real blockers.
   Autopilot should continue through the workflow by default and stop only on missing critical input, failed gates, missing strict dependencies, or high-risk confirmations.
13. Let autopilot generate useful stage artifacts.
   Autopilot should autofill workflow stage summaries from existing project context. In testing, it may prepare draft assets, but it must not silently convert draft test cases into formal passing evidence.

## Minimum First Version

For the first implementation, create only:

- `.omnicontext/workspace.toml`
- `.omnicontext/INDEX.md`
- `.omnicontext/shared/`
- `.omnicontext/personal/`
- `.omnicontext/projects/<project>/overview.md`
- `.omnicontext/projects/<project>/handoff.md`
- `.omnicontext/projects/<project>/todo.md`
- `.omnicontext/projects/<project>/decisions.md`

Do not start with scripts unless the folder protocol and templates already work in a real workspace.

## Recommended Flow

### 1. Inspect the workspace

- Check whether `.omnicontext/workspace.toml` already exists
- If not, inspect the current directory for Git repos, docs folders, and major app/service roots
- Infer `single`, `multi`, or `auto` mode conservatively

Read [references/README.md](references/README.md) first, then default to [references/zh-CN/protocol.md](references/zh-CN/protocol.md) and [references/zh-CN/config-rules.md](references/zh-CN/config-rules.md) unless another language is explicitly required.

### 2. Initialize `.omnicontext/`

Create the minimum folder and file set from the templates:

- `templates/INDEX.md`
- `templates/workspace.toml`
- `templates/machine.local.toml`
- `templates/user.local.toml`
- `templates/shared-standards.md`
- `templates/shared-language-policy.md`
- `templates/personal-preferences.md`
- `templates/overview.md`
- `templates/handoff.md`
- `templates/todo.md`
- `templates/decisions.md`
- `templates/roles.toml`
- `templates/skills.toml`
- `templates/runtime.toml`
- `templates/testing-platforms.toml`
- `templates/rules-pack.toml`
- `templates/sources.toml`
- `templates/changes.md`
- `templates/standards-map.md`
- `templates/coordinator.md`
- `templates/product.md`
- `templates/architecture.md`
- `templates/engineering.md`
- `templates/frontend.md`
- `templates/backend.md`
- `templates/design.md`
- `templates/testing.md`
- `templates/acceptance.md`
- `templates/workflow-current.toml`
- `templates/workflow-lifecycle.toml`
- `templates/workflow-index.md`
- `templates/workflow-stage-intake.md`
- `templates/workflow-stage-clarification.md`
- `templates/workflow-stage-design.md`
- `templates/workflow-stage-delivery.md`
- `templates/workflow-stage-testing.md`
- `templates/workflow-stage-acceptance.md`
- `templates/tests-index.md`
- `templates/test-suite.md`
- `templates/test-run.md`
- `templates/dangerous-op-log.md`
- `templates/backup-record.md`
- `templates/codex-AGENTS.md`
- `templates/claude-CLAUDE.md`
- `templates/trae-TRAE.md`
- `templates/qoder-QODER.md`

Use project names from real directories or explicit user input. Avoid fake placeholders in the generated workspace data.

### 3. Route context by task

- Workspace-wide policy questions: read `shared/`
- Personal preference questions: read `personal/`
- Project execution work: read the target project's `overview.md` and `handoff.md`
- Historical rationale: read `decisions.md`

### 4. Update after meaningful work

When a task changes durable understanding, update the corresponding OmniContext files. Read [references/zh-CN/update-rules.md](references/zh-CN/update-rules.md) before deciding what to write back.

### 5. Commit by feature boundary

If the workspace or skill repo uses Git:

- finish one coherent function or rule change first
- stage only the files needed for that change
- write one clear commit message for that change
- avoid bundling unrelated refactors or doc cleanups into the same commit
- treat this rule as enabled by default unless config explicitly disables it
- push after commit by default unless config explicitly disables `auto_push_after_commit`

Use `scripts/omni-context check` before release-oriented commits that touch references, templates, or script behavior.

## File Loading Guidance

Load references only as needed:

- `references/README.md`: language entrypoint and default loading rules
- `references/zh-CN/protocol.md`: folder layout and document responsibilities
- `references/zh-CN/config-rules.md`: workspace config semantics and local overrides
- `references/zh-CN/update-rules.md`: what to persist after task work
- `references/zh-CN/adapter-rules.md`: how tool-specific entry files should point to the same OmniContext data
- `references/zh-CN/automation-behaviors.md`: design targets for future init, sync, status, and generation scripts
- `references/zh-CN/localization-rules.md`: how to select and persist Chinese, English, or Japanese output by context
- `references/zh-CN/prompt-templates.md`: default Chinese prompt wording
- `references/zh-CN/standards-alignment.md`: industry-standard alignment for lifecycle, testing, security, and safety
- `references/zh-CN/rules-pack-model.md`: rules-pack model and module composition
- `references/zh-CN/rules-pack-presets.md`: default and preset pack definitions
- `references/zh-CN/rules-pack-validation.md`: invalid-combination checks and warning rules
- `references/zh-CN/bundle-model.md`: project-type, stage, and role-driven skill bundles
- `references/zh-CN/bundle-commands.md`: bundle command semantics
- `references/zh-CN/bundle-policy.md`: recommended vs strict bundle modes
- `references/zh-CN/testing-model.md`: hard testing gate model
- `references/zh-CN/testing-platforms.md`: platform testing matrix
- `references/zh-CN/runtime-integrations.md`: runtime dependency declarations
- `references/zh-CN/data-safety.md`: dangerous operation protection
- `references/zh-CN/autopilot.md`: autopilot execution rules
- `references/en/prompt-templates.md`: English prompt wording when English is explicitly required
- `references/ja/prompt-templates.md`: Japanese prompt wording when Japanese is explicitly required

## Non-Goals

- Do not turn OmniContext into a database before the file protocol is proven
- Do not force one workspace layout on every user
- Do not require a project to be frontend/backend split
- Do not store secrets or personal credentials in OmniContext files
