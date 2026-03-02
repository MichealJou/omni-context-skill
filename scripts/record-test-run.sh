#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
SUITE_ID="${3:-}"
TITLE="${4:-}"
RUN_ID="${5:-$(date +%Y%m%d-%H%M%S)}"
if [[ -z "${TITLE}" ]]; then
  echo "Usage: record-test-run.sh <workspace-root> <project-name> <suite-id> <run-title> [run-id]" >&2
  exit 1
fi
TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
TARGET="${TESTS_DIR}/runs/${RUN_ID}.md"
mkdir -p "${TESTS_DIR}/runs"
cp "${SKILL_ROOT}/templates/test-run.md" "${TARGET}"
python3 - "$TARGET" "$TITLE" "$SUITE_ID" "$RUN_ID" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
for src, dst in {
    "replace-with-run-title": sys.argv[2],
    "replace-with-suite-id": sys.argv[3],
    "replace-with-run-id": sys.argv[4],
}.items():
    text = text.replace(src, dst)
path.write_text(text)
PY
echo "Recorded test run ${RUN_ID}"
