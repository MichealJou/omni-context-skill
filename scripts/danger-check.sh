#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"
source "${SCRIPT_DIR}/lib/safety-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
DEPENDENCY_ID="${3:-}"
OP_TYPE="${4:-}"
OBJECT_NAME="${5:-}"
if [[ -z "${OBJECT_NAME}" ]]; then
  echo "Usage: danger-check.sh <workspace-root> <project-name> <dependency-id> <operation-type> <object>" >&2
  exit 1
fi
RUNTIME_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/runtime.toml"
if ! omni_runtime_dep_exists "${RUNTIME_FILE}" "${DEPENDENCY_ID}"; then
  echo "Danger check: UNKNOWN_DEPENDENCY"
  exit 1
fi
kind="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "kind")"
environment="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "environment")"
environment="${environment:-local}"
danger=1
case "${kind}" in
  mysql|postgres|service)
    omni_runtime_is_dangerous_db_op "${OP_TYPE}" && danger=0
    ;;
  redis)
    omni_runtime_is_dangerous_redis_op "${OP_TYPE}" && danger=0
    ;;
esac
if [[ "${danger}" -ne 0 ]]; then
  echo "Danger check: SAFE"
  exit 0
fi
if omni_is_prod_env "${environment}"; then
  echo "Danger check: CONFIRMATION_REQUIRED"
  exit 3
fi
backup_path="$(omni_has_matching_backup_record "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${DEPENDENCY_ID}" "${OBJECT_NAME}" "${OP_TYPE}" 2>/dev/null || true)"
if [[ -z "${backup_path}" || ! -f "${backup_path}" ]]; then
  echo "Danger check: BACKUP_REQUIRED"
  exit 2
fi
echo "Danger check: BACKUP_READY"
echo "Backup: ${backup_path}"
exit 0
