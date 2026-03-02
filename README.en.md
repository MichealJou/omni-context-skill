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
- `create-demo-workspace`
- `git-finish`
- `new-project`
- `new-doc`
- `init-project-standards`
- `project-doctor`
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
- `collect-test-evidence`
- `setup-test-runtime`
- `run-browser-suite-devtools`
- `run-browser-suite`
- `run-api-suite`
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
- formal test runs are bound to suite fingerprints and reject draft-only cases
- Web formal testing now uses a DevTools-first executor and falls back to Playwright only when allowed
- Backend formal testing uses the API executor and does not install browser runtime by default
- Web/API testing can now collect live runtime evidence before final verification
- API suites support richer assertions for headers, JSON values, JSON array lengths, and status ranges
- dangerous local database/redis operations require backup first
- dangerous checks now validate object-level backup records instead of only checking the backups directory
- autopilot autofills stage summaries and prepares draft testing assets before reporting blockers

## Quick Demo

```bash
scripts/omni-context create-demo-workspace /tmp/omni-demo
cd /tmp/omni-demo/demo-web && python3 -m http.server 38080
```

Then in another shell:

```bash
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context collect-test-evidence /tmp/omni-demo demo-web homepage-smoke --platform web

# or run the DevTools-first browser executor directly
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context run-browser-suite-devtools /tmp/omni-demo demo-web homepage-smoke --platform web

# backend formal execution
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context run-api-suite /tmp/omni-demo demo-api health-check --platform backend
```

Daily diagnosis:

```bash
scripts/omni-context project-doctor /path/to/workspace my-app
```

## Boundaries

- do not store real project facts in the skill repo
- do not store secrets or machine-only values in templates
- do not hardcode team-specific rules into the generic skill

## Read Next

Start with:

- `references/README.md`
- then default to `references/zh-CN/` unless another language is explicitly required
