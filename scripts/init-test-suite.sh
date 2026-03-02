#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
TITLE="${3:-}"
SUITE_ID="${4:-}"
if [[ -z "${PROJECT_NAME}" || -z "${TITLE}" ]]; then
  echo "Usage: init-test-suite.sh <workspace-root> <project-name> <suite-title> [suite-id]" >&2
  exit 1
fi
if [[ -z "${SUITE_ID}" ]]; then
  SUITE_ID="$(printf '%s' "${TITLE}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g; s/-\{2,\}/-/g; s/^-//; s/-$//')"
fi
TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
mkdir -p "${TESTS_DIR}/suites" "${TESTS_DIR}/runs"
cp "${SKILL_ROOT}/templates/tests-index.md" "${TESTS_DIR}/index.md"
TARGET="${TESTS_DIR}/suites/${SUITE_ID}.md"
cp "${SKILL_ROOT}/templates/test-suite.md" "${TARGET}"
python3 - "$TARGET" "$TITLE" "$SUITE_ID" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("replace-with-suite-title", sys.argv[2]).replace("replace-with-suite-id", sys.argv[3])
path.write_text(text)
PY
"${SCRIPT_DIR}/init-test-excel.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" >/dev/null
"${SCRIPT_DIR}/sync-test-cases-excel.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" >/dev/null
echo "Initialized test suite ${SUITE_ID}"
