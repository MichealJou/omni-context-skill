#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
TITLE="${3:-}"
SLUG="${4:-}"
if [[ -z "${PROJECT_NAME}" || -z "${TITLE}" ]]; then
  echo "Usage: start-workflow.sh <workspace-root> <project-name> <title> [slug]" >&2
  exit 1
fi

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"
if [[ -z "${SLUG}" ]]; then
  SLUG="$(printf '%s' "${TITLE}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//')"
fi
WORKFLOW_ID="$(date +%Y%m%d)-${SLUG}"
WORKFLOWS_DIR="${PROJECT_DIR}/workflows"
WORKFLOW_DIR="${WORKFLOWS_DIR}/${WORKFLOW_ID}"
mkdir -p "${WORKFLOW_DIR}" "${WORKSPACE_ROOT}/.omnicontext/shared/workflows"

omni_write_workflow_current "${WORKFLOWS_DIR}/current.toml" "${WORKFLOW_ID}"
omni_write_workflow_lifecycle "${WORKFLOW_DIR}/lifecycle.toml" "${WORKFLOW_ID}" "${PROJECT_NAME}" "${TITLE}" "${language}"
for stage in $(omni_workflow_stages); do
  owner="$(omni_stage_owner_default "${PROJECT_DIR}" "${stage}")"
  omni_update_workflow_stage_owner "${WORKFLOW_DIR}/lifecycle.toml" "${stage}" "${owner}"
  case "${stage}" in
    intake) title_local="01 Intake" ;;
    clarification) title_local="02 Clarification" ;;
    design) title_local="03 Design" ;;
    delivery) title_local="04 Delivery" ;;
    testing) title_local="05 Testing" ;;
    acceptance) title_local="06 Acceptance" ;;
  esac
  omni_write_stage_doc "$(omni_stage_doc_path "${WORKFLOW_DIR}" "${stage}")" "${language}" "${stage}" "${title_local}"
done
cp "${SKILL_ROOT}/templates/workflow-index.md" "${WORKFLOW_DIR}/index.md"
python3 - "${WORKFLOW_DIR}/index.md" "${PROJECT_NAME}" "${WORKFLOW_ID}" "${TITLE}" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
for src, dst in {
    "replace-with-project-name": sys.argv[2],
    "replace-with-workflow-id": sys.argv[3],
    "replace-with-workflow-title": sys.argv[4],
}.items():
    text = text.replace(src, dst)
path.write_text(text)
PY

REGISTRY="${WORKSPACE_ROOT}/.omnicontext/shared/workflows/registry.toml"
if [[ ! -f "${REGISTRY}" ]]; then
  cp "${SKILL_ROOT}/templates/workflow-registry.toml" "${REGISTRY}"
fi
cat >> "${REGISTRY}" <<EOF

[[workflows]]
workflow_id = "${WORKFLOW_ID}"
project_name = "${PROJECT_NAME}"
title = "${TITLE}"
status = "in_progress"
current_stage = "intake"
language = "${language}"
path = "projects/${PROJECT_NAME}/workflows/${WORKFLOW_ID}"
EOF
echo "Started workflow ${WORKFLOW_ID} for ${PROJECT_NAME}"
