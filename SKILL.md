---
name: omni-context
description: Build and maintain a reusable OmniContext workspace knowledge system for coding tools such as Codex, Claude Code, Qoder, and Trae. Use when the user wants a shared knowledge structure, project wiki, handoff flow, technical docs, design docs, or multi-project workspace context that can be initialized per real project.
---

# OmniContext

OmniContext is a reusable workflow for creating a portable workspace knowledge layer inside a real codebase. The skill does not store the user's business knowledge itself. It defines how to initialize, read, and update a `.omnicontext/` directory in any workspace.

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

## Current Automation

The skill now includes two minimal scripts:

- `scripts/init-workspace.sh [workspace-root]`
- `scripts/sync-workspace.sh [workspace-root]`
- `scripts/status-workspace.sh [workspace-root]`
- `scripts/new-project.sh <workspace-root> <project-name> <source-path>`
- `scripts/new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]`

Use these before writing more automation. They are intentionally conservative and keep the protocol simple.

## Working Rules

1. Start from protocol, not automation.
   Define the folder structure, config format, and core document set before writing scripts.
2. Prefer dynamic discovery.
   Do not assume the workspace is multi-project. Detect structure from the current environment or a workspace config.
3. Keep context loading small.
   Read `INDEX.md`, then the relevant project `overview.md` and `handoff.md`, and only then load shared or personal files if needed.
4. Record durable knowledge only.
   Write decisions, run instructions, architecture notes, and active handoff state. Do not write secrets, raw tokens, or disposable logs.
5. Keep local differences local.
   Put machine-specific and user-specific settings in local config files, not in shared workspace config.
6. Resolve language from context.
   Prefer explicit user language, then project or shared language policy, then the local user default. Support Chinese, English, and Japanese without forking the skill into separate copies.

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

Read [references/protocol.md](references/protocol.md) and [references/config-rules.md](references/config-rules.md) when defining structure.

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

When a task changes durable understanding, update the corresponding OmniContext files. Read [references/update-rules.md](references/update-rules.md) before deciding what to write back.

## File Loading Guidance

Load references only as needed:

- `references/protocol.md`: folder layout and document responsibilities
- `references/config-rules.md`: workspace config semantics and local overrides
- `references/update-rules.md`: what to persist after task work
- `references/adapter-rules.md`: how tool-specific entry files should point to the same OmniContext data
- `references/automation-behaviors.md`: design targets for future init, sync, status, and generation scripts
- `references/localization-rules.md`: how to select and persist Chinese, English, or Japanese output by context

## Non-Goals

- Do not turn OmniContext into a database before the file protocol is proven
- Do not force one workspace layout on every user
- Do not require a project to be frontend/backend split
- Do not store secrets or personal credentials in OmniContext files
