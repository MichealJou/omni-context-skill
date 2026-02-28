#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"

if [[ -e "${OMNI_ROOT}/workspace.toml" ]]; then
  echo "OmniContext already exists at ${OMNI_ROOT}" >&2
  exit 1
fi

mkdir -p \
  "${OMNI_ROOT}/shared" \
  "${OMNI_ROOT}/personal" \
  "${OMNI_ROOT}/projects" \
  "${OMNI_ROOT}/tools/codex" \
  "${OMNI_ROOT}/tools/claude-code" \
  "${OMNI_ROOT}/tools/trae" \
  "${OMNI_ROOT}/tools/qoder"

workspace_name="$(basename "${WORKSPACE_ROOT}")"

discovered_projects=()
while IFS= read -r project_path; do
  discovered_projects+=("${project_path}")
done < <(
  find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 3 -type d -name .git -prune \
    | sed "s#${WORKSPACE_ROOT}/##" \
    | sed 's#/.git$##' \
    | sort -u
)

if [[ "${#discovered_projects[@]}" -eq 0 ]]; then
  discovered_projects=("$(basename "${WORKSPACE_ROOT}")")
  mode="single"
elif [[ "${#discovered_projects[@]}" -eq 1 ]]; then
  mode="single"
else
  mode="multi"
fi

cat > "${OMNI_ROOT}/workspace.toml" <<EOF
version = 1
workspace_name = "${workspace_name}"
mode = "${mode}"
knowledge_root = ".omnicontext"

[discovery]
scan_git_repos = true
scan_depth = 3
ignore = [".git", "node_modules", "dist", "build", "coverage", "target"]

[shared]
path = "shared"

[personal]
path = "personal"

[projects]
path = "projects"

[localization]
default_language = "en"
supported_languages = ["zh-CN", "en", "ja"]
EOF

for project_path in "${discovered_projects[@]}"; do
  project_name="$(basename "${project_path}")"
  cat >> "${OMNI_ROOT}/workspace.toml" <<EOF

[[project_mappings]]
name = "${project_name}"
source_path = "${project_path}"
knowledge_path = "projects/${project_name}"
type = "project"
EOF
done

cat > "${OMNI_ROOT}/INDEX.md" <<EOF
# OmniContext Index

## Workspace

- Workspace name: ${workspace_name}
- Mode: ${mode}
- Knowledge root: \`.omnicontext\`

## Shared Knowledge

- \`shared/standards.md\`
- \`shared/language-policy.md\`

## Personal Knowledge

- \`personal/preferences.md\`

## Projects
EOF

for project_path in "${discovered_projects[@]}"; do
  project_name="$(basename "${project_path}")"
  project_dir="${OMNI_ROOT}/projects/${project_name}"
  mkdir -p "${project_dir}"

  cat > "${project_dir}/overview.md" <<EOF
# Overview

## Summary

- Project name: ${project_name}
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

  cat > "${project_dir}/handoff.md" <<'EOF'
# Handoff

## Current State

- Status: Initialized by OmniContext
- Active branch or working area:
- Current focus:

## Recent Progress

- OmniContext project scaffold created

## Next Steps

- Fill in project purpose and entry points

## Risks And Blockers

- None recorded yet

## Pointers

- Key files:
- Key commands:
- Related docs:
EOF

  cat > "${project_dir}/todo.md" <<'EOF'
# Todo

## Active

- [ ] Fill in overview details

## Upcoming

- [ ] Add current project-specific documentation

## Deferred

- [ ] Add more OmniContext docs only when needed
EOF

  cat > "${project_dir}/decisions.md" <<'EOF'
# Decisions

## Decision Log

### YYYY-MM-DD - OmniContext initialization

- Context: OmniContext was initialized for this project.
- Decision: Start with the minimum document set.
- Rationale: Keep maintenance cost low until the workflow proves useful.
- Consequence: Add more document types only when real use requires them.
EOF

  cat >> "${OMNI_ROOT}/INDEX.md" <<EOF

- Project name: ${project_name}
  - Source path: ${project_path}
  - Overview: \`projects/${project_name}/overview.md\`
  - Handoff: \`projects/${project_name}/handoff.md\`
  - Todo: \`projects/${project_name}/todo.md\`
  - Decisions: \`projects/${project_name}/decisions.md\`
EOF
done

cat >> "${OMNI_ROOT}/INDEX.md" <<'EOF'

## Notes

- Discovery assumptions: project roots inferred from Git repositories when available
- Missing documentation: fill shared and project details after initialization
- Follow-up setup: copy tool adapter files into the host tool locations if needed
EOF

cp "${SKILL_ROOT}/templates/shared-standards.md" "${OMNI_ROOT}/shared/standards.md"
cp "${SKILL_ROOT}/templates/shared-language-policy.md" "${OMNI_ROOT}/shared/language-policy.md"
cp "${SKILL_ROOT}/templates/personal-preferences.md" "${OMNI_ROOT}/personal/preferences.md"
cp "${SKILL_ROOT}/templates/machine.local.toml" "${OMNI_ROOT}/machine.local.toml"
cp "${SKILL_ROOT}/templates/user.local.toml" "${OMNI_ROOT}/user.local.toml"
cp "${SKILL_ROOT}/templates/codex-AGENTS.md" "${OMNI_ROOT}/tools/codex/AGENTS.md"
cp "${SKILL_ROOT}/templates/claude-CLAUDE.md" "${OMNI_ROOT}/tools/claude-code/CLAUDE.md"
cp "${SKILL_ROOT}/templates/trae-TRAE.md" "${OMNI_ROOT}/tools/trae/TRAE.md"
cp "${SKILL_ROOT}/templates/qoder-QODER.md" "${OMNI_ROOT}/tools/qoder/QODER.md"

echo "Initialized OmniContext at ${OMNI_ROOT}"
echo "Mode: ${mode}"
echo "Projects:"
for project_path in "${discovered_projects[@]}"; do
  echo "- $(basename "${project_path}") (${project_path})"
done
