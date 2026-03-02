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
PLATFORM="backend"
DEPENDENCY_ID=""

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --dependency) DEPENDENCY_ID="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" || -z "${SUITE_ID}" ]]; then
  echo "Usage: run-api-suite.sh <workspace-root> <project-name> <suite-id> [--run-id id] [--platform backend] [--dependency dep-id]" >&2
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
  echo "Suite ${SUITE_ID} is draft-only and cannot be used for formal API testing" >&2
  exit 2
fi

if [[ -z "${DEPENDENCY_ID}" ]]; then
  DEPENDENCY_ID="$(omni_runtime_dependency_for_platform "${RUNTIME_FILE}" "backend")"
fi
[[ -n "${DEPENDENCY_ID}" ]] || { echo "No runtime dependency matched backend platform" >&2; exit 2; }

target_url="$(omni_runtime_dependency_url "${RUNTIME_FILE}" "${DEPENDENCY_ID}")"
[[ -n "${target_url}" ]] || { echo "Missing target URL for ${DEPENDENCY_ID}" >&2; exit 2; }

"${SCRIPT_DIR}/execute-test-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --mode "api" --platform "${PLATFORM}" --evidence "pending-evidence" >/dev/null

RESULT_JSON="${ARTIFACTS_DIR}/${RUN_ID}.api.json"
ARTIFACT_FILE="${ARTIFACTS_DIR}/${RUN_ID}.api.txt"
STEPS_JSON="$(omni_test_suite_steps_json "${SUITE_FILE}")"

python3 - "$target_url" "$RESULT_JSON" "$ARTIFACT_FILE" "$STEPS_JSON" <<'PY'
import json
import sys
from pathlib import Path
from urllib.parse import urljoin

import requests

base_url, result_json, artifact_file, steps_json = sys.argv[1:5]
result_path = Path(result_json)
artifact_path = Path(artifact_file)
result = {
    "status": "failed",
    "artifact": str(artifact_path),
    "failed_step": "",
    "observed": "",
    "root_cause": "",
    "next_step": "",
    "required_result": "FAIL",
    "optional_result": "FAIL",
}

def write_result():
    result_path.write_text(json.dumps(result, ensure_ascii=False))

steps = json.loads(steps_json)
if not steps:
    steps = [{"action": "request", "value": "GET /"}]

session = requests.Session()
response = None
pending_headers = {}
pending_json = None
pending_data = None
pending_timeout = 15

def json_path_get(data, dotted):
    cur = data
    for part in dotted.split("."):
        if isinstance(cur, list):
            try:
                idx = int(part)
            except ValueError as exc:
                raise AssertionError(f"json path segment {part} is not a list index") from exc
            if idx < 0 or idx >= len(cur):
                raise AssertionError(f"json index out of range for path: {dotted}")
            cur = cur[idx]
        elif isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            raise AssertionError(f"missing expected json path: {dotted}")
    return cur

try:
    for index, step in enumerate(steps, start=1):
        action = step["action"].strip().lower()
        value = step["value"].strip()
        step_name = f"{index}:{action}"
        if action == "set_header":
            if ":" not in value:
                raise ValueError("set_header must use Header: Value")
            header, header_value = [x.strip() for x in value.split(":", 1)]
            pending_headers[header] = header_value
        elif action == "set_json":
            pending_json = json.loads(value)
        elif action == "set_body":
            pending_data = value
        elif action == "set_timeout":
            pending_timeout = float(value)
        if action == "request":
            parts = value.split(" ", 1)
            method = parts[0].upper()
            path = parts[1] if len(parts) > 1 else "/"
            target = urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))
            request_kwargs = {"timeout": pending_timeout}
            if pending_headers:
                request_kwargs["headers"] = dict(pending_headers)
            if pending_json is not None:
                request_kwargs["json"] = pending_json
            elif pending_data is not None:
                request_kwargs["data"] = pending_data
            response = session.request(method, target, **request_kwargs)
            artifact_path.write_text(
                json.dumps(
                    {
                        "url": target,
                        "request_headers": dict(pending_headers),
                        "request_json": pending_json,
                        "request_body": pending_data,
                        "status_code": response.status_code,
                        "headers": dict(response.headers),
                        "body": response.text[:10000],
                    },
                    ensure_ascii=False,
                    indent=2,
                )
            )
            pending_json = None
            pending_data = None
        elif action == "expect_status":
            if response is None:
                raise ValueError("expect_status requires a prior request step")
            expected = int(value)
            if response.status_code != expected:
                raise AssertionError(f"expected status {expected}, got {response.status_code}")
        elif action == "expect_status_range":
            if response is None:
                raise ValueError("expect_status_range requires a prior request step")
            if "-" not in value:
                raise ValueError("expect_status_range must use min-max")
            low, high = [int(x.strip()) for x in value.split("-", 1)]
            if not (low <= response.status_code <= high):
                raise AssertionError(f"expected status in range {low}-{high}, got {response.status_code}")
        elif action == "expect_text":
            if response is None:
                raise ValueError("expect_text requires a prior request step")
            if value not in response.text:
                raise AssertionError(f"missing expected text: {value}")
        elif action == "expect_header":
            if response is None:
                raise ValueError("expect_header requires a prior request step")
            if ":" not in value:
                raise ValueError("expect_header must use Header: Value")
            header, expected_value = [x.strip() for x in value.split(":", 1)]
            actual = response.headers.get(header)
            if actual != expected_value:
                raise AssertionError(f"expected header {header}={expected_value}, got {actual}")
        elif action == "expect_json_key":
            if response is None:
                raise ValueError("expect_json_key requires a prior request step")
            data = response.json()
            json_path_get(data, value)
        elif action == "expect_json_value":
            if response is None:
                raise ValueError("expect_json_value requires a prior request step")
            if "=" not in value:
                raise ValueError("expect_json_value must use path=value")
            path, expected_raw = [x.strip() for x in value.split("=", 1)]
            actual = json_path_get(response.json(), path)
            try:
                expected = json.loads(expected_raw)
            except json.JSONDecodeError:
                expected = expected_raw
            if actual != expected:
                raise AssertionError(f"expected json value {path}={expected!r}, got {actual!r}")
        elif action == "expect_json_array_length":
            if response is None:
                raise ValueError("expect_json_array_length requires a prior request step")
            if "=" not in value:
                raise ValueError("expect_json_array_length must use path=len")
            path, expected_len = [x.strip() for x in value.split("=", 1)]
            actual = json_path_get(response.json(), path)
            if not isinstance(actual, list):
                raise AssertionError(f"json path is not a list: {path}")
            if len(actual) != int(expected_len):
                raise AssertionError(f"expected json array length {path}={expected_len}, got {len(actual)}")
        else:
            raise ValueError(f"unsupported API step action: {action}")
    result.update({
        "status": "passed",
        "observed": "api suite completed successfully",
        "root_cause": "",
        "next_step": "proceed with workflow validation",
        "required_result": "PASS",
        "optional_result": "PASS",
    })
    write_result()
except requests.RequestException as exc:
    artifact_path.write_text(str(exc))
    result.update({
        "status": "blocked_runtime",
        "failed_step": step_name,
        "observed": "api runtime request failed",
        "root_cause": str(exc),
        "next_step": "run omni-context setup-test-runtime <workspace-root> <project-name> --platform backend and verify runtime.toml",
    })
    write_result()
except Exception as exc:
    result.update({
        "status": "failed",
        "failed_step": step_name,
        "observed": str(exc),
        "root_cause": "api suite assertion failed",
        "next_step": "fix the service behavior or update the confirmed test case through the proper workflow",
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
    finding = "api suite executed successfully" if status == "passed" else "api suite execution produced a formal failure record"
    text = text.replace("## Findings\n\n- ", f"## Findings\n\n- {finding}", 1)
run_path.write_text(text)
PY

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

"${SCRIPT_DIR}/export-test-report.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" --run-id "${RUN_ID}" >/dev/null 2>&1 || true

case "${status}" in
  passed)
    echo "Executed API suite ${SUITE_ID}"
    echo "Run: ${RUN_ID}"
    echo "Artifact: ${artifact}"
    ;;
  blocked_runtime)
    echo "API suite runtime blocked for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 2
    ;;
  *)
    echo "API suite failed for ${SUITE_ID}" >&2
    echo "Run: ${RUN_ID}" >&2
    echo "Artifact: ${artifact}" >&2
    exit 1
    ;;
esac
