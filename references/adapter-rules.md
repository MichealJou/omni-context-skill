# Adapter Rules

Tool adapter files should be thin entry points, not independent knowledge systems.

## Goal

Every supported coding tool should load the same `.omnicontext/` data with minimal tool-specific wording.

## Required Behavior

Each adapter should instruct the tool to:

1. Read `.omnicontext/INDEX.md` first
2. Identify the active project from the task or current working area
3. Read that project's `overview.md` and `handoff.md`
4. Read `shared/` files only when workspace-wide standards or architecture matter
5. Read `personal/` files only when user preferences are relevant
6. Update `handoff.md`, `todo.md`, or `decisions.md` after durable task changes

## Adapter Scope

Adapters may mention tool-specific conventions such as `AGENTS.md` or `CLAUDE.md`, but they should not redefine:

- directory structure
- config semantics
- document responsibilities
- update rules

Those are defined by the OmniContext protocol and shared references.

## Supported Entry Files

- `tools/codex/AGENTS.md`
- `tools/claude-code/CLAUDE.md`
- `tools/trae/TRAE.md`
- `tools/qoder/QODER.md`

Add more adapters only when there is a real tool target.
