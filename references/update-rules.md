# Update Rules

Update OmniContext after work only when the change is durable and useful to future sessions.

## Usually Update

- `handoff.md` after meaningful implementation progress
- `todo.md` when open work changed
- `decisions.md` when a non-trivial technical choice was made
- `overview.md` when the project structure or entry points changed

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

## Handoff Standard

Every `handoff.md` should make these points easy to answer:

- What is currently true?
- What was done recently?
- What should happen next?
- What is blocked or risky?
