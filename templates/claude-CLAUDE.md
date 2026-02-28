# OmniContext For Claude Code

Before starting work:

1. Read `.omnicontext/INDEX.md`.
2. Determine which project in `.omnicontext/projects/` matches the task.
3. Load that project's `overview.md` and `handoff.md`.
4. Load `.omnicontext/shared/` only if the task depends on workspace-wide rules.
5. Load `.omnicontext/personal/` only if user-specific preferences are relevant.

After meaningful progress:

1. Update `handoff.md` if the current state changed.
2. Update `todo.md` if remaining work changed.
3. Update `decisions.md` if a technical or workflow decision was made.

Never write secrets into `.omnicontext/`.
