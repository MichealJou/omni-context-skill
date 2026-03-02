#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: role-status.sh <workspace-root> <project-name>" >&2
  exit 1
fi
ROLES_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/roles.toml"
if [[ ! -f "${ROLES_FILE}" ]]; then
  echo "Missing ${ROLES_FILE}" >&2
  exit 1
fi
python3 - "$ROLES_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(f"Project: {data.get('project_name')}")
print(f"Type: {data.get('project_type')}")
print("Enabled roles:")
for block in ("core_roles", "extended_roles"):
    for key, value in data.get(block, {}).items():
        if value:
            print(f"- {key}")
print("Stage owners:")
for stage, owner in data.get("stage_owners", {}).items():
    print(f"- {stage}: {owner}")
PY
