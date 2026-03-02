# Update Rules

Update OmniContext only when the change is durable and useful to future sessions.

## Usually Update

- `handoff.md` after meaningful implementation progress
- `todo.md` when open work changed
- `decisions.md` when a non-trivial technical choice was made
- `overview.md` when the project structure or entry points changed
- if Git is in use, make one minimal commit when a coherent feature or rule change is complete

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

- Commit after one feature or coherent change is complete, not after a large mixed batch
- Keep one commit focused on one clear topic
- Use a commit message that explains the feature or rule change
- Do not mix unrelated formatting, opportunistic refactors, or temporary debug files into the same commit
- This makes rollback and regression tracing much easier when something breaks

## Handoff Standard

Every `handoff.md` should make these points easy to answer:

- What is currently true?
- What was done recently?
- What should happen next?
- What is blocked or risky?
