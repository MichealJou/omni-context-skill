#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/test-lib.sh"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
SUITE_ID="${3:-}"
shift 3 || true

RUN_ID="$(date +%Y%m%d-%H%M%S)"
DEPENDENCY_ID=""
MODE="auto"
PLATFORM=""

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --dependency) DEPENDENCY_ID="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" || -z "${SUITE_ID}" ]]; then
  echo "Usage: collect-test-evidence.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--dependency dep-id] [--mode auto|browser|api|service|miniapp] [--platform web|backend|miniapp]" >&2
  exit 1
fi

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
RUNTIME_FILE="${PROJECT_DIR}/standards/runtime.toml"
SUITE_FILE="${PROJECT_DIR}/tests/suites/${SUITE_ID}.md"
RUNS_DIR="${PROJECT_DIR}/tests/runs"
ARTIFACTS_DIR="${PROJECT_DIR}/tests/artifacts"
mkdir -p "${RUNS_DIR}" "${ARTIFACTS_DIR}"

[[ -f "${SUITE_FILE}" ]] || { echo "Missing suite ${SUITE_ID}" >&2; exit 1; }
[[ -f "${RUNTIME_FILE}" ]] || { echo "Missing runtime.toml" >&2; exit 1; }

suite_status="$(omni_test_suite_source_status "${SUITE_FILE}")"
if ! omni_test_effective_status_allowed "${suite_status}"; then
  echo "Suite ${SUITE_ID} is draft-only and cannot be used for formal evidence collection" >&2
  exit 2
fi

suite_platform="$(omni_test_suite_platform "${SUITE_FILE}")"
PLATFORM="${PLATFORM:-${suite_platform}}"

if [[ -z "${DEPENDENCY_ID}" ]]; then
  DEPENDENCY_ID="$(python3 - "$RUNTIME_FILE" "$PLATFORM" <<'PY'
import sys, tomllib
from pathlib import Path
runtime = tomllib.loads(Path(sys.argv[1]).read_text())
platform = sys.argv[2]
target_kind = {
    "web": "browser",
    "backend": "service",
    "miniapp": "miniapp",
}.get(platform, "")
for dep in runtime.get("dependencies", []):
    if dep.get("enabled") and dep.get("kind") == target_kind:
        print(dep.get("id", ""))
        break
PY
)"
fi

[[ -n "${DEPENDENCY_ID}" ]] || { echo "No runtime dependency matched platform ${PLATFORM}" >&2; exit 2; }
[[ -n "$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "id")" ]] || { echo "Unknown dependency ${DEPENDENCY_ID}" >&2; exit 2; }

kind="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "kind")"
entry_url="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "entry_url")"
url="$(omni_runtime_dep_field "${RUNTIME_FILE}" "${DEPENDENCY_ID}" "url")"
target_url="${entry_url:-${url}}"

case "${MODE}" in
  auto)
    case "${PLATFORM}" in
      web) MODE="browser" ;;
      backend) MODE="api" ;;
      miniapp) MODE="miniapp" ;;
      *) MODE="browser" ;;
    esac
    ;;
esac

case "${MODE}" in
  browser|miniapp)
    [[ -n "${target_url}" ]] || { echo "Missing target URL for ${DEPENDENCY_ID}" >&2; exit 2; }
    ARTIFACT="${ARTIFACTS_DIR}/${RUN_ID}.png"
    LOG_FILE="${ARTIFACTS_DIR}/${RUN_ID}.log"
    if ! python3 - "$target_url" "$ARTIFACT" "$MODE" <<'PY' 2>"${LOG_FILE}"
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

url, artifact, mode = sys.argv[1:4]
Path(artifact).parent.mkdir(parents=True, exist_ok=True)
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto(url, wait_until="networkidle", timeout=20000)
    page.screenshot(path=artifact, full_page=True)
    browser.close()
PY
    then
      ARTIFACT="${LOG_FILE}"
      [[ -s "${ARTIFACT}" ]] || printf '%s\n' "browser runtime failed without stderr output" > "${ARTIFACT}"
      "${SCRIPT_DIR}/execute-test-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --mode "${MODE}" --platform "${PLATFORM}" --evidence "${ARTIFACT}" >/dev/null
      RUN_FILE="${RUNS_DIR}/${RUN_ID}.md"
      python3 - "$RUN_FILE" <<'PY'
import sys
import re
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
text = re.sub(r"^- run_status:.*$", "- run_status: blocked_runtime", text, flags=re.M)
text = text.replace("- failed_step:", "- failed_step: launch-browser-runtime")
text = text.replace("- observed_behavior:", "- observed_behavior: browser runtime could not start")
text = text.replace("- suspected_root_cause:", "- suspected_root_cause: playwright browser dependency is missing or unusable")
text = text.replace("- recommended_next_step:", "- recommended_next_step: install playwright browsers or provide another executable browser runtime")
text = text.replace("## Findings\n\n- ", "## Findings\n\n- browser smoke evidence collection failed")
path.write_text(text)
PY
      echo "Browser evidence collection failed for ${SUITE_ID}" >&2
      echo "Run: ${RUN_ID}" >&2
      echo "Artifact: ${ARTIFACT}" >&2
      exit 2
    fi
    FINDING="Collected ${MODE} screenshot evidence from ${target_url}"
    ;;
  api|service)
    [[ -n "${target_url}" ]] || { echo "Missing target URL for ${DEPENDENCY_ID}" >&2; exit 2; }
    ARTIFACT="${ARTIFACTS_DIR}/${RUN_ID}.txt"
    python3 - "$target_url" "$ARTIFACT" <<'PY'
import sys, requests
from pathlib import Path
url, artifact = sys.argv[1:3]
resp = requests.get(url, timeout=15)
resp.raise_for_status()
Path(artifact).write_text(resp.text[:10000])
PY
    FINDING="Collected service response evidence from ${target_url}"
    ;;
  *)
    echo "Unsupported mode ${MODE}" >&2
    exit 2
    ;;
esac

"${SCRIPT_DIR}/execute-test-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --mode "${MODE}" --platform "${PLATFORM}" --evidence "${ARTIFACT}" >/dev/null

RUN_FILE="${RUNS_DIR}/${RUN_ID}.md"
python3 - "$RUN_FILE" "$FINDING" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
finding = sys.argv[2]
text = path.read_text()
text = text.replace("- run_status:", "- run_status: evidence_collected")
if "## Findings\n\n- " in text:
    text = text.replace("## Findings\n\n- ", f"## Findings\n\n- {finding}")
path.write_text(text)
PY

echo "Collected evidence for ${SUITE_ID}"
echo "Run: ${RUN_ID}"
echo "Artifact: ${ARTIFACT}"
