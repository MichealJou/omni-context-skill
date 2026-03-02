#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"
source "${SCRIPT_DIR}/lib/test-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: workflow-check.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
if [[ -z "${WORKFLOW_ID}" ]]; then
  WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
fi
WORKFLOW_DIR="${PROJECT_DIR}/workflows/${WORKFLOW_ID}"
LIFECYCLE="${WORKFLOW_DIR}/lifecycle.toml"
if [[ ! -f "${LIFECYCLE}" ]]; then
  echo "Missing ${LIFECYCLE}" >&2
  exit 1
fi
status=0
for stage in $(omni_workflow_stages); do
  doc="$(omni_stage_doc_path "${WORKFLOW_DIR}" "${stage}")"
  if [[ ! -f "${doc}" ]]; then
    echo "- MISSING ${doc}"
    status=1
    continue
  fi
  while IFS= read -r heading; do
    if ! rg -Fq "${heading}" "${doc}"; then
      echo "- MISSING heading ${heading} in ${doc}"
      status=1
    fi
  done < <(omni_workflow_required_headings)
done

TESTING_STATUS="$(omni_workflow_status_value "${LIFECYCLE}" "stages.testing.status")"
if [[ "${TESTING_STATUS}" == "completed" || "${TESTING_STATUS}" == "in_progress" ]]; then
  if ! "${SCRIPT_DIR}/test-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" >/dev/null 2>&1; then
    echo "- Testing evidence is incomplete"
    status=1
  fi
fi

if [[ "${status}" -eq 0 ]]; then
  echo "Workflow check: OK"
else
  echo "Workflow check: INCOMPLETE"
fi
exit "${status}"
