# OmniContext

OmniContext is a reusable skill repo that creates and maintains a `.omnicontext/` delivery-control layer inside real projects.

## Current Scope

- workspace knowledge
- lifecycle workflows
- role standards
- rules packs
- skill bundles
- hard testing gates
- runtime integrations
- data-safety guards

## Repository Contents

- `SKILL.md`
- `agents/openai.yaml`
- `references/`
- `scripts/`
- `templates/`

Real business knowledge stays in the target workspace, not in this repo.

## Quick Install

```bash
./scripts/install-skill.sh
```

Default install path:

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## Unified CLI

```bash
./scripts/omni-context <command> ...
```

Main commands:

- `init`
- `sync`
- `status`
- `check`
- `git-finish`
- `new-project`
- `new-doc`
- `init-project-standards`
- `role-status`
- `runtime-status`
- `start-workflow`
- `workflow-status`
- `workflow-check`
- `advance-stage`
- `skip-stage`
- `list-workflows`
- `rules-pack-init`
- `rules-pack-status`
- `rules-pack-check`
- `rules-pack-list`
- `bundle-status`
- `bundle-install`
- `bundle-check`
- `init-test-suite`
- `execute-test-suite`
- `record-test-run`
- `test-status`
- `backup-object`
- `danger-check`
- `record-dangerous-op`
- `autopilot-run`
- `autopilot-status`

## Defaults

- Chinese by default
- concise interaction by default
- feature-sized commits by default
- push after commit by default
- hard testing gates by default
- autopilot workflow execution enabled by default
- frontend-style tests require real interaction by default
- dangerous local database/redis operations require backup first
- autopilot autofills stage summaries and prepares draft testing assets before reporting blockers

## Boundaries

- do not store real project facts in the skill repo
- do not store secrets or machine-only values in templates
- do not hardcode team-specific rules into the generic skill

## Read Next

Start with:

- `references/README.md`
- then default to `references/zh-CN/` unless another language is explicitly required
