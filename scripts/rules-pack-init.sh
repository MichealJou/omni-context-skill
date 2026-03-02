#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
PACK_ID="${3:-default-balanced}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: rules-pack-init.sh <workspace-root> <project-name> [pack-id]" >&2
  exit 1
fi
TARGET="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/rules-pack.toml"
cp "${SKILL_ROOT}/templates/rules-pack.toml" "${TARGET}"
python3 - "$TARGET" "$PROJECT_NAME" "$PACK_ID" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("replace-with-project-name", sys.argv[2]).replace("default-balanced", sys.argv[3], 1)
path.write_text(text)
PY
echo "Initialized rules pack ${PACK_ID} for ${PROJECT_NAME}"
