#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
DEPENDENCY_ID="${3:-}"
OP_TYPE="${4:-}"
OBJECT_NAME="${5:-}"
BACKUP_PATH="${6:-}"
if [[ -z "${BACKUP_PATH}" ]]; then
  echo "Usage: record-dangerous-op.sh <workspace-root> <project-name> <dependency-id> <operation-type> <object> <backup-path>" >&2
  exit 1
fi
LOG_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/docs/runbook/dangerous-op-log.md"
mkdir -p "$(dirname "${LOG_FILE}")"
if [[ ! -f "${LOG_FILE}" ]]; then
  cp "${SKILL_ROOT}/templates/dangerous-op-log.md" "${LOG_FILE}"
fi
{
  echo
  echo "## $(date +%F) ${OP_TYPE} ${OBJECT_NAME}"
  echo
  echo "- dependency: ${DEPENDENCY_ID}"
  echo "- object: ${OBJECT_NAME}"
  echo "- action: ${OP_TYPE}"
  echo "- backup: ${BACKUP_PATH}"
} >> "${LOG_FILE}"
echo "Recorded dangerous operation"
