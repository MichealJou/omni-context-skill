#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"
source "${SCRIPT_DIR}/lib/rules-pack-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: autopilot-run.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
if [[ -z "${WORKFLOW_ID}" ]]; then
  WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
fi
WORKFLOW_DIR="${PROJECT_DIR}/workflows/${WORKFLOW_ID}"
LIFECYCLE="${WORKFLOW_DIR}/lifecycle.toml"
STATE_FILE="$(omni_autopilot_state_path "${WORKFLOW_DIR}")"
rules_next_step() {
  local stage="$1"
  case "${stage}" in
    intake) printf '%s\n' "fill in request context and business goal" ;;
    clarification) printf '%s\n' "clarify scope, acceptance, and unresolved items" ;;
    design) printf '%s\n' "capture implementation direction, risks, and decisions" ;;
    delivery) printf '%s\n' "record implementation scope and affected code paths" ;;
    testing) printf '%s\n' "confirm non-draft test cases and record formal execution evidence" ;;
    acceptance) printf '%s\n' "write acceptance conclusion and residual follow-up" ;;
    *) printf '%s\n' "complete the current stage requirements" ;;
  esac
}
while true; do
  current_stage="$(omni_workflow_status_value "${LIFECYCLE}" "current_stage")"
  workflow_status="$(omni_workflow_status_value "${LIFECYCLE}" "status")"
  if [[ "${workflow_status}" == "completed" || -z "${current_stage}" ]]; then
    omni_autopilot_write_state "${STATE_FILE}" "completed" "" "workflow completed" "none" "none"
    echo "Autopilot: completed"
    break
  fi
  owner="$(omni_workflow_status_value "${LIFECYCLE}" "stages.${current_stage}.owner")"
  omni_autofill_stage_doc "${PROJECT_DIR}" "${WORKFLOW_DIR}" "${LIFECYCLE}" "${current_stage}"
  if [[ "${current_stage}" == "testing" ]]; then
    omni_autopilot_prepare_testing_assets "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}"
    omni_autofill_stage_doc "${PROJECT_DIR}" "${WORKFLOW_DIR}" "${LIFECYCLE}" "${current_stage}"
  fi
  check_output="$("${SCRIPT_DIR}/workflow-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}" 2>&1 || true)"
  if [[ "${check_output}" != *"Workflow check: OK"* ]]; then
    next_step="$(rules_next_step "${current_stage}")"
    blocker="$(printf '%s' "${check_output}" | sed '/^Workflow check: INCOMPLETE$/d' | sed '/^$/d' | tail -n 1)"
    [[ -n "${blocker}" ]] || blocker="workflow-check failed"
    if [[ "${current_stage}" == "testing" ]]; then
      test_output="$("${SCRIPT_DIR}/test-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" 2>&1 || true)"
      test_blocker="$(printf '%s' "${test_output}" | sed '/^Test status: INCOMPLETE$/d' | sed '/^$/d' | tail -n 1)"
      [[ -n "${test_blocker}" ]] && blocker="${test_blocker}"
    fi
    if [[ "${blocker}" == *"ADR module requires"* ]]; then
      next_step="add a project decision entry before continuing"
    elif [[ "${blocker}" == *"Acceptance Criteria module requires"* ]]; then
      next_step="write explicit acceptance criteria in clarification or acceptance"
    elif [[ "${blocker}" == *"E2E Browser module requires"* ]]; then
      next_step="create a web suite and execute a browser-based formal run"
    elif [[ "${blocker}" == *"Change Safety module requires"* ]]; then
      next_step="add runbook recovery notes for risky runtime changes"
    fi
    omni_autopilot_write_state "${STATE_FILE}" "blocked" "${current_stage}" "autofilled stage and evaluated gates" "${blocker}" "${next_step}"
    echo "Autopilot blocked at ${current_stage}"
    exit 2
  fi
  "${SCRIPT_DIR}/advance-stage.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${current_stage}" "${owner}" >/dev/null
  omni_autopilot_write_state "${STATE_FILE}" "running" "${current_stage}" "advanced stage ${current_stage}" "none" "continue to next stage"
done
