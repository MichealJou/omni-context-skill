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
PLATFORM="web"
DEPENDENCY_ID=""
FALLBACK_NOTE=""

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --dependency) DEPENDENCY_ID="$2"; shift 2 ;;
    --fallback-note) FALLBACK_NOTE="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" || -z "${SUITE_ID}" ]]; then
  echo "Usage: run-browser-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform web|miniapp] [--dependency dep-id]" >&2
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

source_status="$(omni_test_suite_source_status "${SUITE_FILE}")"
if ! omni_test_effective_status_allowed "${source_status}"; then
  echo "Suite ${SUITE_ID} is draft-only and cannot be used for formal browser testing" >&2
  exit 2
fi

suite_platform="$(omni_test_suite_platform "${SUITE_FILE}")"
PLATFORM="${PLATFORM:-${suite_platform:-web}}"
if [[ "${PLATFORM}" != "web" && "${PLATFORM}" != "miniapp" ]]; then
  echo "Browser suite only supports web or miniapp platform" >&2
  exit 2
fi

if [[ -z "${DEPENDENCY_ID}" ]]; then
  DEPENDENCY_ID="$(omni_runtime_dependency_for_platform "${RUNTIME_FILE}" "${PLATFORM}")"
fi
[[ -n "${DEPENDENCY_ID}" ]] || { echo "No runtime dependency matched platform ${PLATFORM}" >&2; exit 2; }

target_url="$(omni_runtime_dependency_url "${RUNTIME_FILE}" "${DEPENDENCY_ID}")"
[[ -n "${target_url}" ]] || { echo "Missing target URL for ${DEPENDENCY_ID}" >&2; exit 2; }

"${SCRIPT_DIR}/execute-test-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --mode "${PLATFORM/web/browser}" --platform "${PLATFORM}" --evidence "pending-evidence" >/dev/null

RESULT_JSON="${ARTIFACTS_DIR}/${RUN_ID}.browser.json"
LOG_FILE="${ARTIFACTS_DIR}/${RUN_ID}.browser.log"
STEPS_JSON="$(omni_test_suite_steps_json "${SUITE_FILE}")"

python3 - "$target_url" "$RESULT_JSON" "$LOG_FILE" "$ARTIFACTS_DIR" "$RUN_ID" "$STEPS_JSON" "$PLATFORM" <<'PY'
import json
import sys
from pathlib import Path

url, result_json, log_file, artifacts_dir, run_id, steps_json, platform = sys.argv[1:8]
result_path = Path(result_json)
log_path = Path(log_file)
artifacts = Path(artifacts_dir)
result = {
    "status": "failed",
    "artifact": str(log_path),
    "failed_step": "",
    "observed": "",
    "root_cause": "",
    "next_step": "",
    "required_result": "FAIL",
    "optional_result": "FAIL",
}

def write_result():
    result_path.write_text(json.dumps(result, ensure_ascii=False))

try:
    from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError
except Exception as exc:
    log_path.write_text(str(exc))
    result.update({
        "status": "blocked_runtime",
        "observed": "browser runtime could not start",
        "root_cause": "playwright dependency is unavailable",
        "next_step": "run omni-context setup-test-runtime <workspace-root> <project-name> --platform web",
    })
    write_result()
    raise SystemExit(0)

steps = json.loads(steps_json)
if not steps:
    steps = [{"action": "goto", "value": "/"}]

def locator_for(page, value):
    if value.startswith("text="):
        return page.get_by_text(value.split("=", 1)[1], exact=False)
    if value.startswith("role="):
        role_spec = value.split("=", 1)[1]
        if ":" in role_spec:
            role_name, name = role_spec.split(":", 1)
            return page.get_by_role(role_name, name=name)
        return page.get_by_role(role_spec)
    return page.locator(value)

def full_url(base, target):
    if target.startswith("http://") or target.startswith("https://"):
        return target
    if target.startswith("/"):
        return base.rstrip("/") + target
    return base.rstrip("/") + "/" + target

try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        for index, step in enumerate(steps, start=1):
            action = step["action"].strip().lower()
            value = step["value"].strip()
            step_name = f"{index}:{action}"
            try:
                if action == "goto":
                    page.goto(full_url(url, value), wait_until="networkidle", timeout=20000)
                elif action == "wait_for":
                    if value.startswith("text="):
                        page.get_by_text(value.split("=", 1)[1], exact=False).wait_for(timeout=10000)
                    else:
                        page.locator(value).wait_for(timeout=10000)
                elif action == "click":
                    locator_for(page, value).click(timeout=10000)
                elif action == "fill":
                    if "=>" not in value:
                        raise ValueError("fill step must use selector => value")
                    selector, content = [item.strip() for item in value.split("=>", 1)]
                    locator_for(page, selector).fill(content, timeout=10000)
                elif action == "press":
                    page.keyboard.press(value, timeout=10000)
                elif action == "assert_text":
                    target = value.split("=", 1)[1] if value.startswith("text=") else value
                    page.get_by_text(target, exact=False).wait_for(timeout=10000)
                elif action == "screenshot":
                    name = value.replace("/", "-")
                    artifact = artifacts / f"{run_id}-{name}.png"
                    page.screenshot(path=str(artifact), full_page=True)
                    result["artifact"] = str(artifact)
                else:
                    raise ValueError(f"unsupported step action: {action}")
            except PlaywrightTimeoutError:
                screenshot = artifacts / f"{run_id}-failure.png"
                page.screenshot(path=str(screenshot), full_page=True)
                result.update({
                    "status": "failed",
                    "artifact": str(screenshot),
                    "failed_step": step_name,
                    "observed": f"step timed out while executing {value}",
                    "root_cause": "target element or expected text was not reachable in time",
                    "next_step": "inspect the failing page state and verify the test case still matches the UI",
                })
                write_result()
                browser.close()
                raise SystemExit(0)
            except Exception as exc:
                screenshot = artifacts / f"{run_id}-failure.png"
                page.screenshot(path=str(screenshot), full_page=True)
                result.update({
                    "status": "failed",
                    "artifact": str(screenshot),
                    "failed_step": step_name,
                    "observed": str(exc),
                    "root_cause": "browser step execution failed",
                    "next_step": "fix the UI/runtime issue or update the confirmed test case through the proper workflow",
                })
                write_result()
                browser.close()
                raise SystemExit(0)
        if result["artifact"] == str(log_path):
            final = artifacts / f"{run_id}-final.png"
            page.screenshot(path=str(final), full_page=True)
            result["artifact"] = str(final)
        result.update({
            "status": "passed",
            "failed_step": "",
            "observed": "browser suite completed successfully",
            "root_cause": "",
            "next_step": "proceed with workflow validation",
            "required_result": "PASS",
            "optional_result": "PASS",
        })
        write_result()
        browser.close()
except SystemExit:
    pass
except Exception as exc:
    log_path.write_text(str(exc))
    result.update({
        "status": "blocked_runtime",
        "artifact": str(log_path),
        "observed": "browser runtime could not complete suite execution",
        "root_cause": str(exc),
        "next_step": "run omni-context setup-test-runtime <workspace-root> <project-name> --platform web",
    })
    write_result()
PY

python3 - "$RUNS_DIR/${RUN_ID}.md" "$RESULT_JSON" <<'PY'
import json
import re
import sys
from pathlib import Path

run_path = Path(sys.argv[1])
result = json.loads(Path(sys.argv[2]).read_text())
text = run_path.read_text()
status = result["status"]
required_marker = "[required-pass] PASS" if result["required_result"] == "PASS" else "[required-pass] FAIL"
optional_marker = "[optional-pass] PASS" if result["optional_result"] == "PASS" else "[optional-pass] FAIL"
text = re.sub(r"^- run_status:.*$", f"- run_status: {status}", text, flags=re.M)
text = re.sub(r"^- evidence:.*$", f"- evidence: {result['artifact']}", text, flags=re.M)
text = re.sub(r"^- failed_step:.*$", f"- failed_step: {result.get('failed_step', '')}", text, flags=re.M)
text = re.sub(r"^- observed_behavior:.*$", f"- observed_behavior: {result.get('observed', '')}", text, flags=re.M)
text = re.sub(r"^- suspected_root_cause:.*$", f"- suspected_root_cause: {result.get('root_cause', '')}", text, flags=re.M)
text = re.sub(r"^- recommended_next_step:.*$", f"- recommended_next_step: {result.get('next_step', '')}", text, flags=re.M)
text = re.sub(r"(?m)^\- \[required-pass\] PENDING:", f"- {required_marker}:", text)
text = re.sub(r"(?m)^\- \[optional-pass\] PENDING:", f"- {optional_marker}:", text)
if "## Findings\n\n- " in text:
    finding = "browser suite executed successfully" if status == "passed" else "browser suite execution produced a formal failure record"
    text = text.replace("## Findings\n\n- ", f"## Findings\n\n- {finding}", 1)
run_path.write_text(text)
PY

if [[ -n "${FALLBACK_NOTE}" ]]; then
  python3 - "$RUNS_DIR/${RUN_ID}.md" "$FALLBACK_NOTE" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
note = sys.argv[2]
text = path.read_text()
if "## Findings\n\n- " in text:
    text = text.replace("## Findings\n\n- ", f"## Findings\n\n- {note}\n- ", 1)
path.write_text(text)
PY
fi

status="$(python3 - "$RESULT_JSON" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1]).read())["status"])
PY
)"
artifact="$(python3 - "$RESULT_JSON" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1]).read())["artifact"])
PY
)"

case "${status}" in
  passed)
    echo "Executed browser suite ${SUITE_ID}"
    echo "Run: ${RUN_ID}"
    echo "Artifact: ${artifact}"
    ;;
  blocked_runtime)
    echo "Browser suite runtime blocked for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 2
    ;;
  *)
    echo "Browser suite failed for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 1
    ;;
esac
