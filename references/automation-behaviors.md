# Automation Behaviors

These are the intended behaviors for OmniContext automation. `install-skill`, `init`, `sync`, `status`, `new-project`, and `new-doc` now exist as conservative scripts; the rest remain design targets. Chinese is the default operator-facing language unless user or project policy says otherwise.

## `init`

Purpose:
- Create a new `.omnicontext/` directory in the current workspace
- Infer workspace mode conservatively
- Generate the minimum required files from templates

Expected behavior:
- Detect existing `.omnicontext/` and avoid overwriting by default
- Scan for likely project roots such as Git repositories and major app/service folders
- Write `workspace.toml`
- Write `INDEX.md`
- Create `shared/standards.md`
- Create `personal/preferences.md`
- Create one project folder per discovered or user-confirmed project
- Generate headings and operator-facing text in the active language, defaulting to Chinese

## `sync`

Purpose:
- Refresh OmniContext metadata against the current workspace state

Expected behavior:
- Re-scan the workspace using `workspace.toml`
- Detect newly added or removed project roots
- Update `INDEX.md`
- Add missing project folders without deleting existing notes by default
- Preserve hand-written content whenever possible
- Respect the active language for regenerated summaries and console output

## `status`

Purpose:
- Report the current OmniContext health and coverage

Expected output:
- workspace mode
- discovered project list
- mapped project list
- missing required files
- stale or unresolved mappings
- localized operator-facing status text, defaulting to Chinese

## `new-project`

Purpose:
- Add a new project knowledge area intentionally

Expected behavior:
- create `projects/<project-name>/`
- generate `overview.md`, `handoff.md`, `todo.md`, and `decisions.md`
- append the project to `INDEX.md`
- optionally add or update `[[project_mappings]]` in `workspace.toml`
- generate the initial project records in the active language

## `new-doc`

Purpose:
- Create additional documents only when the workspace needs them

Current supported targets:
- technical docs
- design docs
- product docs
- runbooks
- wiki pages
- document skeletons should be generated in the active language

## Safety Rules

- Never write secrets into `.omnicontext/`
- Never delete existing project notes automatically unless explicitly requested
- Prefer additive generation over destructive rewrites
- Preserve local override files such as `machine.local.toml` and `user.local.toml`
