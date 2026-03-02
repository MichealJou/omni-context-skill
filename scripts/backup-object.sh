#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"
source "${SCRIPT_DIR}/lib/safety-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
DEPENDENCY_ID="${3:-}"
OBJECT_NAME="${4:-}"
ACTION_NAME="${5:-}"
if [[ -z "${ACTION_NAME}" ]]; then
  echo "Usage: backup-object.sh <workspace-root> <project-name> <dependency-id> <object> <action>" >&2
  exit 1
fi
RUNTIME_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/runtime.toml"
kind="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "kind")"
environment="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "environment")"
host="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "host")"
port="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "port")"
database="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "database")"
user="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "user")"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"
mkdir -p "${BACKUP_DIR}"
ext="$(omni_backup_extension_for_kind "${kind}")"
filename="$(omni_backup_filename "${PROJECT_NAME}" "${environment:-local}" "${OBJECT_NAME}" "${ACTION_NAME}" "${ext}")"
TARGET="${BACKUP_DIR}/${filename}"
RECORD_FILE="$(omni_backup_record_file "${WORKSPACE_ROOT}" "${PROJECT_NAME}")"
mkdir -p "$(dirname "${RECORD_FILE}")"
if [[ ! -f "${RECORD_FILE}" ]]; then
  cp "${SCRIPT_DIR}/../templates/backup-record.md" "${RECORD_FILE}"
fi
created=0
case "${kind}" in
  mysql)
    if command -v mysqldump >/dev/null 2>&1 && [[ -n "${database}" ]]; then
      mysqldump ${host:+-h "${host}"} ${port:+-P "${port}"} ${user:+-u "${user}"} "${database}" > "${TARGET}" 2>/dev/null || true
      [[ -s "${TARGET}" ]] && created=1
    fi
    ;;
  postgres)
    if command -v pg_dump >/dev/null 2>&1 && [[ -n "${database}" ]]; then
      pg_dump ${host:+-h "${host}"} ${port:+-p "${port}"} ${user:+-U "${user}"} -d "${database}" > "${TARGET}" 2>/dev/null || true
      [[ -s "${TARGET}" ]] && created=1
    fi
    ;;
  redis)
    if command -v redis-cli >/dev/null 2>&1; then
      redis-cli ${host:+-h "${host}"} ${port:+-p "${port}"} --rdb "${TARGET}" >/dev/null 2>&1 || true
      [[ -s "${TARGET}" ]] && created=1
    fi
    ;;
esac
if [[ "${created}" -ne 1 ]]; then
  printf '%s\n' "-- Backup placeholder for ${DEPENDENCY_ID} ${OBJECT_NAME} ${ACTION_NAME}" > "${TARGET}"
fi
{
  echo
  echo "## $(date +%F) ${ACTION_NAME} ${OBJECT_NAME}"
  echo
  echo "- dependency: ${DEPENDENCY_ID}"
  echo "- environment: ${environment:-local}"
  echo "- object: ${OBJECT_NAME}"
  echo "- action: ${ACTION_NAME}"
  echo "- backup_path: ${TARGET}"
} >> "${RECORD_FILE}"
echo "${TARGET}"
