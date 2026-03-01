#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
WORKSPACE_TOML="${OMNI_ROOT}/workspace.toml"
INDEX_FILE="${OMNI_ROOT}/INDEX.md"

if [[ ! -f "${WORKSPACE_TOML}" ]]; then
  echo "Missing ${WORKSPACE_TOML}" >&2
  exit 1
fi

workspace_name="$(sed -n 's/^workspace_name = "\(.*\)"/\1/p' "${WORKSPACE_TOML}")"
current_mode="$(sed -n 's/^mode = "\(.*\)"/\1/p' "${WORKSPACE_TOML}")"

discovered_projects=()
while IFS= read -r project_path; do
  case "${project_path}" in
    .omnicontext|.omnicontext/*|.local-tools|.local-tools/*)
      continue
      ;;
  esac
  discovered_projects+=("${project_path}")
done < <(
  find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 3 -type d -name .git -prune \
    | sed "s#${WORKSPACE_ROOT}/##" \
    | sed 's#/.git$##' \
    | sort -u
)

if [[ "${#discovered_projects[@]}" -eq 0 ]]; then
  discovered_projects=("$(basename "${WORKSPACE_ROOT}")")
  desired_mode="single"
elif [[ "${#discovered_projects[@]}" -eq 1 ]]; then
  desired_mode="single"
else
  desired_mode="multi"
fi

mapped_names=()
mapped_source_paths=()
while IFS='|' read -r name source_path; do
  [[ -n "${name}" ]] || continue
  mapped_names+=("${name}")
  mapped_source_paths+=("${source_path}")
done < <(
  awk '
    /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && source_path != "") print name "|" source_path
      in_block=1
      name=""
      source_path=""
      next
    }
    /^\[/ && $0 !~ /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && source_path != "") print name "|" source_path
      in_block=0
    }
    in_block && /^name = / {
      line=$0
      sub(/^name = "/, "", line)
      sub(/"$/, "", line)
      name=line
    }
    in_block && /^source_path = / {
      line=$0
      sub(/^source_path = "/, "", line)
      sub(/"$/, "", line)
      source_path=line
    }
    END {
      if (in_block && name != "" && source_path != "") print name "|" source_path
    }
  ' "${WORKSPACE_TOML}"
)

if [[ "${current_mode}" != "${desired_mode}" ]]; then
  python3 - "${WORKSPACE_TOML}" "${desired_mode}" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
mode = sys.argv[2]
text = path.read_text()
old = None
for line in text.splitlines():
    if line.startswith("mode = "):
        old = line
        break
if old is None:
    raise SystemExit("mode field not found")
path.write_text(text.replace(old, f'mode = "{mode}"', 1))
PY
fi

added_projects=()
for project_path in "${discovered_projects[@]}"; do
  mapped=0
  for existing_path in "${mapped_source_paths[@]}"; do
    if [[ "${existing_path}" == "${project_path}" ]]; then
      mapped=1
      break
    fi
  done

  if [[ "${mapped}" -eq 0 ]]; then
    project_name="$(basename "${project_path}")"
    cat >> "${WORKSPACE_TOML}" <<EOF

[[project_mappings]]
name = "${project_name}"
source_path = "${project_path}"
knowledge_path = "projects/${project_name}"
type = "project"
EOF
    mapped_names+=("${project_name}")
    mapped_source_paths+=("${project_path}")
    added_projects+=("${project_name}|${project_path}")
  fi
done

ensure_project_docs() {
  local project_name="$1"
  local project_dir="${OMNI_ROOT}/projects/${project_name}"
  mkdir -p "${project_dir}"

  if [[ ! -f "${project_dir}/overview.md" ]]; then
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
  fi

  if [[ ! -f "${project_dir}/handoff.md" ]]; then
    cat > "${project_dir}/handoff.md" <<'EOF'
# Handoff

## Current State

- Status: Initialized by OmniContext sync
- Active branch or working area:
- Current focus:

## Recent Progress

- OmniContext project records were created by sync

## Next Steps

- Fill in project purpose and entry points

## Risks And Blockers

- None recorded yet

## Pointers

- Key files:
- Key commands:
- Related docs:
EOF
  fi

  if [[ ! -f "${project_dir}/todo.md" ]]; then
    cat > "${project_dir}/todo.md" <<'EOF'
# Todo

## Active

- [ ] Fill in overview details

## Upcoming

- [ ] Add current project-specific documentation

## Deferred

- [ ] Add more OmniContext docs only when needed
EOF
  fi

  if [[ ! -f "${project_dir}/decisions.md" ]]; then
    cat > "${project_dir}/decisions.md" <<'EOF'
# Decisions

## Decision Log

### YYYY-MM-DD - OmniContext sync initialization

- Context: OmniContext sync created missing project records.
- Decision: Start with the minimum document set.
- Rationale: Keep maintenance cost low until the workflow proves useful.
- Consequence: Add more document types only when real use requires them.
EOF
  fi
}

for project_name in "${mapped_names[@]}"; do
  ensure_project_docs "${project_name}"
done

cat > "${INDEX_FILE}" <<EOF
# OmniContext Index

## Workspace

- Workspace name: ${workspace_name}
- Mode: ${desired_mode}
- Knowledge root: \`.omnicontext\`

## Shared Knowledge

- \`shared/standards.md\`
- \`shared/language-policy.md\`
EOF

if [[ -f "${OMNI_ROOT}/shared/docs/index.md" ]]; then
  cat >> "${INDEX_FILE}" <<'EOF'
- `shared/docs/index.md`
EOF
fi

cat >> "${INDEX_FILE}" <<'EOF'

## Personal Knowledge

- `personal/preferences.md`

## Projects
EOF

for idx in "${!mapped_names[@]}"; do
  project_name="${mapped_names[$idx]}"
  project_path="${mapped_source_paths[$idx]}"
  cat >> "${INDEX_FILE}" <<EOF

- Project name: ${project_name}
  - Source path: ${project_path}
  - Overview: \`projects/${project_name}/overview.md\`
  - Handoff: \`projects/${project_name}/handoff.md\`
  - Todo: \`projects/${project_name}/todo.md\`
  - Decisions: \`projects/${project_name}/decisions.md\`
EOF

  if [[ -d "${OMNI_ROOT}/projects/${project_name}/docs" ]]; then
    cat >> "${INDEX_FILE}" <<EOF
  - Managed docs: \`projects/${project_name}/docs/\`
EOF
  fi
done

cat >> "${INDEX_FILE}" <<'EOF'

## Notes

- Discovery assumptions: project roots inferred from Git repositories when available
- Missing documentation: fill shared and project details after initialization
- Follow-up setup: copy tool adapter files into the host tool locations if needed
EOF

echo "Synced OmniContext at ${OMNI_ROOT}"
echo "Mode: ${desired_mode}"
if [[ "${#added_projects[@]}" -gt 0 ]]; then
  echo "Added project mappings:"
  for item in "${added_projects[@]}"; do
    name="${item%%|*}"
    path="${item#*|}"
    echo "- ${name} (${path})"
  done
else
  echo "Added project mappings:"
  echo "- None"
fi

stale_mappings=0
echo "Missing source paths for mapped projects:"
for idx in "${!mapped_names[@]}"; do
  project_name="${mapped_names[$idx]}"
  project_path="${mapped_source_paths[$idx]}"
  if [[ ! -d "${WORKSPACE_ROOT}/${project_path}" ]]; then
    stale_mappings=1
    echo "- ${project_name} (${project_path})"
  fi
done
if [[ "${stale_mappings}" -eq 0 ]]; then
  echo "- None"
fi
