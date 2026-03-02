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
WORKFLOW_DIR="${PROJECT_DIR}/workflows/${WORKFLOW_ID}"
LIFECYCLE="${WORKFLOW_DIR}/lifecycle.toml"
current_stage="$(omni_workflow_status_value "${LIFECYCLE}" "current_stage")"
workflow_status="$(omni_workflow_status_value "${LIFECYCLE}" "status")"
echo "Workflow: ${WORKFLOW_ID}"
echo "Status: ${workflow_status}"
echo "Current stage: ${current_stage}"
LATEST_SUITE="$(find "${PROJECT_DIR}/tests/suites" -type f -name '*.md' 2>/dev/null | sort | tail -n 1 || true)"
LATEST_RUN="$(find "${PROJECT_DIR}/tests/runs" -type f -name '*.md' 2>/dev/null | sort | tail -n 1 || true)"
STATE_FILE="$(omni_autopilot_state_path "${WORKFLOW_DIR}")"
if [[ -f "${STATE_FILE}" ]]; then
  python3 - "$STATE_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(f"Autopilot status: {data.get('status', '')}")
print(f"Last action: {data.get('last_action', '')}")
print(f"Blocker: {data.get('blocker', '')}")
print(f"Next step: {data.get('next_step', '')}")
PY
else
  if "${SCRIPT_DIR}/workflow-check.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${WORKFLOW_ID}" >/dev/null 2>&1; then
    echo "Autopilot status: idle"
    echo "Last action: none"
    echo "Blocker: none"
    echo "Next step: run autopilot"
  else
    echo "Autopilot status: blocked"
    echo "Last action: none"
    echo "Blocker: workflow-check failed"
    echo "Next step: resolve current workflow gate"
  fi
fi
if [[ -n "${LATEST_SUITE}" ]]; then
  echo "Latest suite: $(basename "${LATEST_SUITE}")"
fi
if [[ -n "${LATEST_RUN}" ]]; then
  echo "Latest run: $(basename "${LATEST_RUN}")"
  evidence="$(rg -o '^\-\s+evidence:\s+.+$' "${LATEST_RUN}" 2>/dev/null | sed 's/^- evidence: //; s/^\-\s\+evidence:\s\+//')"
  [[ -n "${evidence}" ]] && echo "Latest evidence: ${evidence}"
fi
