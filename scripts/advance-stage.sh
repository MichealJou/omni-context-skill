#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
STAGE="${3:-}"
ROLE="${4:-}"
if [[ -z "${PROJECT_NAME}" || -z "${STAGE}" || -z "${ROLE}" ]]; then
  echo "Usage: advance-stage.sh <workspace-root> <project-name> <stage> <role>" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
LIFECYCLE="${PROJECT_DIR}/workflows/${WORKFLOW_ID}/lifecycle.toml"
CURRENT_STAGE="$(omni_workflow_status_value "${LIFECYCLE}" "current_stage")"
OWNER="$(omni_workflow_status_value "${LIFECYCLE}" "stages.${STAGE}.owner")"
if [[ "${CURRENT_STAGE}" != "${STAGE}" ]]; then
  echo "Current stage is ${CURRENT_STAGE}, not ${STAGE}" >&2
  exit 1
fi
if [[ "${OWNER}" != "${ROLE}" ]]; then
  echo "Stage ${STAGE} requires role ${OWNER}" >&2
  exit 1
fi
if ! "${SCRIPT_DIR}/workflow-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}" >/dev/null; then
  echo "Workflow gates are not satisfied" >&2
  exit 1
fi
omni_set_workflow_value "${LIFECYCLE}" "stages.${STAGE}.status" "completed"
omni_update_workflow_timestamps "${LIFECYCLE}" "${STAGE}"
next=""
case "${STAGE}" in
  intake) next="clarification" ;;
  clarification) next="design" ;;
  design) next="delivery" ;;
  delivery) next="testing" ;;
  testing) next="acceptance" ;;
  acceptance) next="" ;;
esac
if [[ -n "${next}" ]]; then
  omni_set_workflow_value "${LIFECYCLE}" "current_stage" "${next}"
  omni_set_workflow_value "${LIFECYCLE}" "stages.${next}.status" "in_progress"
  omni_update_workflow_timestamps "${LIFECYCLE}" "${next}"
else
  omni_set_workflow_value "${LIFECYCLE}" "status" "completed"
fi
echo "Advanced ${PROJECT_NAME} workflow stage ${STAGE}"
