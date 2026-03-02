#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
STAGE="${3:-}"
ROLE="${4:-}"
REASON="${5:-}"
RISK="${6:-}"
AUTHORITY="${7:-}"
if [[ -z "${AUTHORITY}" ]]; then
  echo "Usage: skip-stage.sh <workspace-root> <project-name> <stage> <role> <reason> <risk> <authority>" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
LIFECYCLE="${PROJECT_DIR}/workflows/${WORKFLOW_ID}/lifecycle.toml"
OWNER="$(omni_workflow_status_value "${LIFECYCLE}" "stages.${STAGE}.owner")"
if [[ "${ROLE}" != "${OWNER}" && "${ROLE}" != "coordinator" ]]; then
  echo "Role ${ROLE} cannot skip stage ${STAGE}" >&2
  exit 1
fi
omni_set_workflow_value "${LIFECYCLE}" "stages.${STAGE}.status" "skipped"
omni_set_workflow_value "${LIFECYCLE}" "stages.${STAGE}.skip_reason" "${REASON}"
omni_set_workflow_value "${LIFECYCLE}" "stages.${STAGE}.skip_risk" "${RISK}"
omni_set_workflow_value "${LIFECYCLE}" "stages.${STAGE}.skip_authority" "${AUTHORITY}"
omni_update_workflow_timestamps "${LIFECYCLE}" "${STAGE}"
omni_sync_workflow_registry "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}" "${LIFECYCLE}"
omni_append_handoff_stage_update "${PROJECT_DIR}" "${STAGE}" "skipped by ${ROLE}"
echo "Skipped stage ${STAGE}"
