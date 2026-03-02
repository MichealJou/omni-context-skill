#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: workflow-status.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
if [[ -z "${WORKFLOW_ID}" ]]; then
  WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
fi
LIFECYCLE="${PROJECT_DIR}/workflows/${WORKFLOW_ID}/lifecycle.toml"
if [[ ! -f "${LIFECYCLE}" ]]; then
  echo "Missing ${LIFECYCLE}" >&2
  exit 1
fi
python3 - "$LIFECYCLE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(f"Workflow: {data.get('workflow_id')}")
print(f"Title: {data.get('title')}")
print(f"Status: {data.get('status')}")
print(f"Current stage: {data.get('current_stage')}")
print("Stages:")
for stage, info in data.get("stages", {}).items():
    print(f"- {stage}: status={info.get('status')} owner={info.get('owner')}")
PY
STATE_FILE="${PROJECT_DIR}/workflows/${WORKFLOW_ID}/autopilot-state.toml"
if [[ -f "${STATE_FILE}" ]]; then
  python3 - "$STATE_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print("Autopilot:")
print(f"- status: {data.get('status', '')}")
print(f"- blocker: {data.get('blocker', '')}")
print(f"- next_step: {data.get('next_step', '')}")
PY
fi
