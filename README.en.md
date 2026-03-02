# OmniContext

OmniContext is a reusable workspace knowledge skill for coding tools such as Codex, Claude Code, Qoder, and Trae.

It provides:

- a file-based protocol for `.omnicontext/`
- templates for shared, personal, and project knowledge
- thin adapter templates for multiple coding tools
- UI metadata for skill pickers via `agents/openai.yaml`
- a stable foundation for later automation such as `init`, `sync`, and `status`

## What This Repo Contains

- `SKILL.md`: trigger and workflow rules for the skill itself
- `agents/openai.yaml`: UI-facing metadata for skill catalogs and launch surfaces
- `references/`: multilingual reference entrypoint, defaulting to `references/zh-CN/`
- `scripts/`: minimal workspace automation
- `templates/`: files to generate into a real `.omnicontext/` directory

## Repository Layout

```text
omni-context-skill/
  SKILL.md
  README.md
  README.en.md
  README.zh-CN.md
  README.ja.md
  agents/
    openai.yaml
  references/
  scripts/
  templates/
```

## What This Repo Does Not Contain

- real project knowledge
- secrets or credentials
- project-specific handoff history

Those belong in the target workspace's `.omnicontext/` directory.

## Recommended Adoption Flow

1. Copy or install this skill into the coding environment
2. Create `.omnicontext/` inside a real workspace
3. Fill `workspace.toml`, `INDEX.md`, and the initial project files from `templates/`
4. Add the relevant tool adapter entry file for each coding tool in use
5. Validate the structure in one real workspace before adding more automation

## Quick Install

```bash
./scripts/install-skill.sh
```

By default this installs the skill into:

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## Included Scripts

- `scripts/omni-context [--lang zh-CN|en|ja] <command> ...`
  Unified entrypoint for `init`, `sync`, `status`, `new-project`, and `new-doc`. If omitted, Chinese is the default.

- `scripts/init-workspace.sh [workspace-root]`
  Creates a minimum `.omnicontext/` tree and infers project roots from Git repositories when possible.
- `scripts/sync-workspace.sh [workspace-root]`
  Refreshes workspace mode, adds new project mappings conservatively, recreates missing project core docs, and rebuilds the top-level OmniContext index without deleting hand-written project files.
- `scripts/status-workspace.sh [workspace-root]`
  Reports missing required OmniContext files, mapped projects, and unmapped leftovers.
- `scripts/check-skill.sh`
  Validates the skill structure, core scripts, templates, and whether `references/zh-CN|en|ja` stay in sync.
- `scripts/new-project.sh <workspace-root> <project-name> <source-path>`
  Registers a project explicitly, creates its core OmniContext files, and refreshes the workspace index.
- `scripts/new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]`
  Creates a project-level document in `technical`, `design`, `product`, `runbook`, or `wiki` and appends it to the corresponding index.

## Language-Aware Generation

- Chinese is the default for generated prompts, templates, and operator-facing script output
- Switch with `--lang en` or `--lang ja` when the user or workspace policy requires it
- `init`, `sync`, `status`, `new-project`, and `new-doc` all respect the active language

## Maintenance Guidance

- When `references/zh-CN/` changes, update `references/en/` and `references/ja/` in the same pass
- When script behavior changes, update the README files, `SKILL.md`, and the matching `references/*/automation-behaviors.md`
- If the repo uses Git, commit once per completed feature with the smallest coherent diff and a clear message
- Run this before committing:

```bash
./scripts/omni-context check
```

## Publishing Boundary

This repository should stay generic.

- Keep real project facts out of this repo
- Keep secrets and machine-specific values out of templates
- Put actual workspace knowledge in the target workspace's `.omnicontext/`

## Minimum Generated Workspace

```text
.omnicontext/
  workspace.toml
  INDEX.md
  shared/
    standards.md
    language-policy.md
  personal/
    preferences.md
  projects/
    <project-name>/
      overview.md
      handoff.md
      todo.md
      decisions.md
```

## Next Evolution

After the protocol is proven in a real workspace, add automation for:

- richer doc templates and index maintenance beyond the current conservative implementation

See `references/README.md` first. The default detailed reference set is currently under `references/zh-CN/`, including `references/zh-CN/automation-behaviors.md`.

## Language Defaults

- Default repository landing language is Chinese in `README.md`
- Default prompt language is Chinese
- Switch prompt wording to English or Japanese only when the user or workspace policy requires it
