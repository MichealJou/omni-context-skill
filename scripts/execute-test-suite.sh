#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
SUITE_ID="${3:-}"
shift 3 || true
RUN_ID="$(date +%Y%m%d-%H%M%S)"
MODE=""
PLATFORM=""
EVIDENCE=""
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --evidence) EVIDENCE="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
if [[ -z "${PROJECT_NAME}" || -z "${SUITE_ID}" ]]; then
  echo "Usage: execute-test-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--mode browser|api|service|miniapp] [--platform web|backend|miniapp] [--evidence path]" >&2
  exit 1
fi
SUITE_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests/suites/${SUITE_ID}.md"
RUN_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests/runs/${RUN_ID}.md"
[[ -f "${SUITE_FILE}" ]] || { echo "Missing suite ${SUITE_ID}" >&2; exit 1; }
source_status="$(omni_test_suite_source_status "${SUITE_FILE}")"
if ! omni_test_effective_status_allowed "${source_status}"; then
  echo "Suite ${SUITE_ID} is draft-only and cannot be used for formal testing" >&2
  exit 2
fi
suite_platform="$(omni_test_suite_platform "${SUITE_FILE}")"
PLATFORM="${PLATFORM:-${suite_platform}}"
MODE="${MODE:-${PLATFORM/browser/browser}}"
MODE="${MODE:-browser}"
if [[ "${PLATFORM}" == "web" && "${MODE}" != "browser" ]]; then
  echo "Web platform requires browser mode" >&2
  exit 2
fi
if [[ "${PLATFORM}" == "miniapp" && "${MODE}" != "miniapp" ]]; then
  echo "Miniapp platform requires miniapp mode" >&2
  exit 2
fi
cp "${SKILL_ROOT}/templates/test-run.md" "${RUN_FILE}"
python3 - "$SUITE_FILE" "$RUN_FILE" "$SUITE_ID" "$RUN_ID" "$MODE" "$PLATFORM" "$EVIDENCE" "$source_status" <<'PY'
import sys, re
from pathlib import Path
suite = Path(sys.argv[1]).read_text()
run_path = Path(sys.argv[2])
suite_id, run_id, mode, platform, evidence, source_status = sys.argv[3:]
required = [line.split('] ',1)[1] if '] ' in line else '' for line in suite.splitlines() if line.startswith('- [required]')]
optional = [line.split('] ',1)[1] if '] ' in line else '' for line in suite.splitlines() if line.startswith('- [optional]')]
text = run_path.read_text()
text = text.replace("replace-with-run-title", f"Execute {suite_id}")
text = text.replace("replace-with-run-id", run_id)
text = text.replace("replace-with-suite-id", suite_id)
text = text.replace("- platform:", f"- platform: {platform}")
text = text.replace("- execution_mode:", f"- execution_mode: {mode}")
interaction = "real_user_flow" if mode in {"browser", "miniapp"} else "service_request_flow"
text = text.replace("- interaction_mode:", f"- interaction_mode: {interaction}")
text = text.replace("- suite_source_status:", f"- suite_source_status: {source_status}")
text = text.replace("- evidence:", f"- evidence: {evidence}")
req_lines = "\n".join(f"- [required-pass] PENDING: {item}" for item in required) or "- [required-pass] "
opt_lines = "\n".join(f"- [optional-pass] PENDING: {item}" for item in optional) or "- [optional-pass] "
text = re.sub(r"## Results\n\n(?:- \[required-pass\].*\n?)(?:- \[optional-pass\].*\n?)?", f"## Results\n\n{req_lines}\n{opt_lines}\n", text, flags=re.M)
run_path.write_text(text)
PY
echo "Prepared executable test run ${RUN_ID}"
echo "Mode: ${MODE}"
echo "Platform: ${PLATFORM}"
echo "Rule: do not modify suite cases during execution; record failures and root cause instead"
