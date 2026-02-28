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
- `references/`: protocol, config, adapter, and update rules
- `scripts/`: minimal workspace automation
- `templates/`: files to generate into a real `.omnicontext/` directory

## Repository Layout

```text
omni-context-skill/
  SKILL.md
  README.md
  agents/
    openai.yaml
  references/
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
5. Validate the structure in one real workspace before adding automation

## Included Scripts

- `scripts/init-workspace.sh [workspace-root]`
  Creates a minimum `.omnicontext/` tree and infers project roots from Git repositories when possible.
- `scripts/status-workspace.sh [workspace-root]`
  Reports missing required OmniContext files and project coverage.

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

- `sync`
- `new-project`
- `new-doc`

See `references/automation-behaviors.md` before implementing scripts.
