#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: autopilot-status.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
if [[ -z "${WORKFLOW_ID}" ]]; then
  WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
fi
LIFECYCLE="${PROJECT_DIR}/workflows/${WORKFLOW_ID}/lifecycle.toml"
current_stage="$(omni_workflow_status_value "${LIFECYCLE}" "current_stage")"
workflow_status="$(omni_workflow_status_value "${LIFECYCLE}" "status")"
echo "Workflow: ${WORKFLOW_ID}"
echo "Status: ${workflow_status}"
echo "Current stage: ${current_stage}"
if "${SCRIPT_DIR}/workflow-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}" >/dev/null 2>&1; then
  echo "Blocker: none"
else
  echo "Blocker: workflow-check failed"
fi
