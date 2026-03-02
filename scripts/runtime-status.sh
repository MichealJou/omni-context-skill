#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: runtime-status.sh <workspace-root> <project-name>" >&2
  exit 1
fi
RUNTIME_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/runtime.toml"
if [[ ! -f "${RUNTIME_FILE}" ]]; then
  echo "Missing ${RUNTIME_FILE}" >&2
  exit 1
fi
python3 - "$RUNTIME_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(f"Project: {data.get('project_name', '')}")
for dep in data.get("dependencies", []):
    print(f"- {dep.get('id')}: kind={dep.get('kind')} enabled={dep.get('enabled')} env={dep.get('environment')}")
PY
