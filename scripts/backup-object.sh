#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
environment="$(python3 - "$RUNTIME_FILE" "$DEPENDENCY_ID" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
dep_id = sys.argv[2]
for dep in data.get("dependencies", []):
    if dep.get("id") == dep_id:
        print(dep.get("environment", "local"))
        break
PY
)"
BACKUP_DIR="${WORKSPACE_ROOT}/backups"
mkdir -p "${BACKUP_DIR}"
filename="$(omni_backup_filename "${PROJECT_NAME}" "${environment:-local}" "${OBJECT_NAME}" "${ACTION_NAME}" "sql")"
TARGET="${BACKUP_DIR}/${filename}"
printf '%s\n' "-- Backup placeholder for ${DEPENDENCY_ID} ${OBJECT_NAME} ${ACTION_NAME}" > "${TARGET}"
echo "${TARGET}"
