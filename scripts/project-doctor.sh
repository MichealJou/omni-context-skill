#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"

if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: project-doctor.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi

overall=0
check_block() {
  local label="$1"
  shift
  local output rc
  output="$("$@" 2>&1)" && rc=0 || rc=$?
  if [[ "${rc}" -eq 0 ]]; then
    echo "- ${label}: OK"
  else
    overall=2
    local detail
    detail="$(printf '%s' "${output}" | sed '/^$/d' | sed 's/^Rules pack: WARNING$/rules warning/; s/^Bundle check: WARNING$/bundle warning/; s/^Test status: INCOMPLETE$/tests incomplete/; s/^Workflow check: INCOMPLETE$/workflow incomplete/' | tail -n 1)"
    if [[ "${label}" == "runtime" ]]; then
      if printf '%s' "${output}" | grep -q 'reachability=unreachable'; then
        detail="runtime target unreachable"
      elif printf '%s' "${output}" | grep -q 'client=missing'; then
        detail="runtime client missing"
      fi
    elif [[ "${label}" == "test-runtime" ]]; then
      if printf '%s' "${output}" | grep -q 'browser suite executor requires a local Chrome-compatible browser'; then
        detail="browser runtime not ready"
      elif printf '%s' "${output}" | grep -q 'missing service endpoint'; then
        detail="backend test endpoint missing"
      elif printf '%s' "${output}" | grep -q 'missing backend dependency'; then
        detail="backend runtime dependency missing"
      fi
    fi
    [[ -n "${detail}" ]] || detail="failed"
    echo "- ${label}: ${detail}"
  fi
}

echo "Project doctor: ${PROJECT_NAME}"

check_block "roles" "${SCRIPT_DIR}/role-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}"
check_block "rules" "${SCRIPT_DIR}/rules-pack-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}"
check_block "bundle" "${SCRIPT_DIR}/bundle-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}"
check_block "runtime" "${SCRIPT_DIR}/runtime-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}"
check_block "test-runtime" "${SCRIPT_DIR}/setup-test-runtime.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" --check-only
check_block "workflow" "${SCRIPT_DIR}/workflow-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" ${WORKFLOW_ID:+"${WORKFLOW_ID}"}
check_block "tests" "${SCRIPT_DIR}/test-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}"

if [[ "${overall}" -eq 0 ]]; then
  echo "Doctor status: OK"
else
  echo "Doctor status: ATTENTION"
fi

exit "${overall}"
