#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  new-project.sh <workspace-root> <project-name> <source-path>

Example:
  new-project.sh /path/to/workspace my-app apps/my-app
EOF
}

if [[ "${#}" -lt 3 ]]; then
  usage >&2
  exit 1
fi

WORKSPACE_ROOT="$(cd "${1}" && pwd)"
PROJECT_NAME="${2}"
SOURCE_PATH="${3}"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
WORKSPACE_TOML="${OMNI_ROOT}/workspace.toml"
PROJECT_DIR="${OMNI_ROOT}/projects/${PROJECT_NAME}"

if [[ ! -f "${WORKSPACE_TOML}" ]]; then
  echo "Missing ${WORKSPACE_TOML}" >&2
  exit 1
fi

if [[ ! -d "${WORKSPACE_ROOT}/${SOURCE_PATH}" ]]; then
  echo "Source path does not exist: ${WORKSPACE_ROOT}/${SOURCE_PATH}" >&2
  exit 1
fi

if ! [[ "${PROJECT_NAME}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Project name must use letters, digits, dot, underscore, or hyphen" >&2
  exit 1
fi

if sed -n 's/^name = "\(.*\)"/\1/p' "${WORKSPACE_TOML}" | grep -Fxq "${PROJECT_NAME}"; then
  echo "Project mapping already exists for ${PROJECT_NAME}" >&2
  exit 1
fi

mkdir -p "${PROJECT_DIR}"

cat >> "${WORKSPACE_TOML}" <<EOF

[[project_mappings]]
name = "${PROJECT_NAME}"
source_path = "${SOURCE_PATH}"
knowledge_path = "projects/${PROJECT_NAME}"
type = "project"
EOF

cat > "${PROJECT_DIR}/overview.md" <<EOF
# Overview

## Summary

- Project name: ${PROJECT_NAME}
- Purpose:
- Scope:

## Structure

- Main directories:
- Important entry points:
- Related upstream/downstream systems:

## Runbook

- Install:
- Start:
- Test:
- Build:

## Constraints

- Runtime or platform constraints:
- Non-obvious dependencies:
- Known boundaries:
EOF

cat > "${PROJECT_DIR}/handoff.md" <<'EOF'
# Handoff

## Current State

- Status: Project added by OmniContext new-project
- Active branch or working area:
- Current focus:

## Recent Progress

- OmniContext project records were created explicitly by new-project

## Next Steps

- Fill in project purpose and entry points

## Risks And Blockers

- None recorded yet

## Pointers

- Key files:
- Key commands:
- Related docs:
EOF

cat > "${PROJECT_DIR}/todo.md" <<'EOF'
# Todo

## Active

- [ ] Fill in overview details

## Upcoming

- [ ] Add current project-specific documentation

## Deferred

- [ ] Add more OmniContext docs only when needed
EOF

cat > "${PROJECT_DIR}/decisions.md" <<'EOF'
# Decisions

## Decision Log

### YYYY-MM-DD - OmniContext new-project initialization

- Context: A new project was registered explicitly in OmniContext.
- Decision: Start with the minimum document set.
- Rationale: Keep maintenance cost low until the workflow proves useful.
- Consequence: Add more document types only when real use requires them.
EOF

"${SCRIPT_DIR}/sync-workspace.sh" "${WORKSPACE_ROOT}" >/dev/null

echo "Added project to OmniContext"
echo "- Name: ${PROJECT_NAME}"
echo "- Source path: ${SOURCE_PATH}"
echo "- Knowledge path: .omnicontext/projects/${PROJECT_NAME}"
