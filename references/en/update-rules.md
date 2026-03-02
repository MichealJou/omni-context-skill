# Update Rules

Update OmniContext only when the change is durable and useful to future sessions.

## Usually Update

- `handoff.md` after meaningful implementation progress
- `todo.md` when open work changed
- `decisions.md` when a non-trivial technical choice was made
- `overview.md` when the project structure or entry points changed
- if Git is in use, enable one-feature-per-commit by default and make one minimal commit when a coherent feature or rule change is complete
- if Git is in use, default to local commit only; push only when the user explicitly wants every commit pushed or config explicitly enables it

## Usually Do Not Update

- temporary debugging output
- raw command logs
- secrets, credentials, or tokens
- facts already obvious from code unless they save real discovery effort

## Writing Standard

- Prefer short factual entries
- Record what changed and why it matters
- Use exact file or command names where helpful
- Avoid narrative prose that will become stale quickly

## Git Commit Standard

- enabled by default; only skip it when project or local config explicitly disables it
- Commit after one feature or coherent change is complete, not after a large mixed batch
- Keep one commit focused on one clear topic
- Use a commit message that explains the feature or rule change
- Do not mix unrelated formatting, opportunistic refactors, or temporary debug files into the same commit
- This makes rollback and regression tracing much easier when something breaks

## Git Push Standard

- Default to local commit only; do not push automatically
- Auto-push is allowed only when the user explicitly asks for every commit to be pushed, or config explicitly sets `auto_push_after_commit = true`
- Without that explicit instruction, treat push as a separate action

## Handoff Standard

Every `handoff.md` should make these points easy to answer:

- What is currently true?
- What was done recently?
- What should happen next?
- What is blocked or risky?
