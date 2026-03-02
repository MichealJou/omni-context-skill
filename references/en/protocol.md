# OmniContext Protocol

OmniContext is a workspace-local knowledge layer stored under `.omnicontext/`.

## Minimum Layout

```text
.omnicontext/
  workspace.toml
  INDEX.md
  shared/
  personal/
  projects/
    <project-name>/
      overview.md
      handoff.md
      todo.md
      decisions.md
```

## Directory Responsibilities

`shared/`
- Knowledge that applies across multiple projects in the same workspace
- Examples: glossary, standards, architecture principles, common tooling notes

`personal/`
- Personal but non-secret preferences and working conventions
- Examples: writing preferences, naming conventions, recurring checklists

`projects/<project-name>/`
- Knowledge specific to one project or repository
- Holds execution context, decisions, and operational notes

## Core Documents

`INDEX.md`
- Entry point for the whole OmniContext tree
- Lists active projects and shared knowledge files

`overview.md`
- Stable project summary: purpose, boundaries, major directories, run/test entry points

`handoff.md`
- Current state: recent progress, in-flight work, next steps, blockers

`todo.md`
- Action-oriented items that remain open

`decisions.md`
- Durable design and implementation decisions with rationale

## Growth Path

Expand only after the minimum set proves useful. Typical next files:

- `wiki/index.md`
- `docs/technical/index.md`
- `docs/design/index.md`
- `docs/runbook/index.md`

Add these only when the workspace actually needs them.
