#!/usr/bin/env bash
set -euo pipefail
WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
REGISTRY="${WORKSPACE_ROOT}/.omnicontext/shared/workflows/registry.toml"
if [[ ! -f "${REGISTRY}" ]]; then
  echo "No workflow registry" >&2
  exit 1
fi
python3 - "$REGISTRY" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for item in data.get("workflows", []):
    print(f"- {item.get('project_name')} :: {item.get('workflow_id')} :: {item.get('current_stage')} :: {item.get('status')}")
PY
