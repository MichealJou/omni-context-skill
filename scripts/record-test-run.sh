#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
SUITE_ID="${3:-}"
TITLE="${4:-}"
RUN_ID="${5:-$(date +%Y%m%d-%H%M%S)}"
shift 5 || true
MODE=""
PLATFORM=""
EVIDENCE=""
SOURCE_STATUS=""
FAILED_STEP=""
OBSERVED=""
ROOT_CAUSE=""
NEXT_STEP=""
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --evidence) EVIDENCE="$2"; shift 2 ;;
    --source-status) SOURCE_STATUS="$2"; shift 2 ;;
    --failed-step) FAILED_STEP="$2"; shift 2 ;;
    --observed) OBSERVED="$2"; shift 2 ;;
    --root-cause) ROOT_CAUSE="$2"; shift 2 ;;
    --next-step) NEXT_STEP="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
if [[ -z "${TITLE}" ]]; then
  echo "Usage: record-test-run.sh <workspace-root> <project-name> <suite-id> <run-title> [run-id]" >&2
  exit 1
fi
TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
TARGET="${TESTS_DIR}/runs/${RUN_ID}.md"
SUITE_FILE="${TESTS_DIR}/suites/${SUITE_ID}.md"
if [[ ! -f "${SUITE_FILE}" ]]; then
  echo "Missing suite ${SUITE_ID}" >&2
  exit 1
fi
mkdir -p "${TESTS_DIR}/runs"
cp "${SKILL_ROOT}/templates/test-run.md" "${TARGET}"
python3 - "$TARGET" "$TITLE" "$SUITE_ID" "$RUN_ID" "$MODE" "$PLATFORM" "$EVIDENCE" "$SOURCE_STATUS" "$FAILED_STEP" "$OBSERVED" "$ROOT_CAUSE" "$NEXT_STEP" <<'PY'
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
if sys.argv[5]:
    text = text.replace("- execution_mode:", f"- execution_mode: {sys.argv[5]}")
    text = text.replace("- interaction_mode:", f"- interaction_mode: {'real_user_flow' if sys.argv[5] in {'browser','miniapp'} else 'service_request_flow'}")
if sys.argv[6]:
    text = text.replace("- platform:", f"- platform: {sys.argv[6]}")
if sys.argv[7]:
    text = text.replace("- evidence:", f"- evidence: {sys.argv[7]}")
if sys.argv[8]:
    text = text.replace("- suite_source_status:", f"- suite_source_status: {sys.argv[8]}")
if sys.argv[9]:
    text = text.replace("- failed_step:", f"- failed_step: {sys.argv[9]}")
if sys.argv[10]:
    text = text.replace("- observed_behavior:", f"- observed_behavior: {sys.argv[10]}")
if sys.argv[11]:
    text = text.replace("- suspected_root_cause:", f"- suspected_root_cause: {sys.argv[11]}")
if sys.argv[12]:
    text = text.replace("- recommended_next_step:", f"- recommended_next_step: {sys.argv[12]}")
path.write_text(text)
PY
echo "Recorded test run ${RUN_ID}"
