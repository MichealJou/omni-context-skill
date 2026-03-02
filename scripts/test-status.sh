#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/test-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: test-status.sh <workspace-root> <project-name>" >&2
  exit 1
fi
TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
PLATFORMS_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/testing-platforms.toml"
status=0
if [[ ! -d "${TESTS_DIR}/suites" || ! -d "${TESTS_DIR}/runs" ]]; then
  echo "Missing tests/suites or tests/runs" >&2
  exit 2
fi
latest_run="$(find "${TESTS_DIR}/runs" -type f -name '*.md' | sort | tail -n 1)"
if [[ -z "${latest_run}" ]]; then
  echo "No test runs recorded" >&2
  exit 2
fi
required_pass="$(omni_test_required_pass_count "${latest_run}")"
required_total="$(find "${TESTS_DIR}/suites" -type f -name '*.md' -print0 | xargs -0 rg -c '^\- \[required\]' 2>/dev/null | awk -F: '{if (NF > 1) sum += $2; else sum += $1} END {print sum+0}')"
if [[ "${required_total}" -eq 0 ]]; then
  echo "No required test cases defined" >&2
  status=2
fi
if ! rg -q '^-\s+source_status:\s+(ad_hoc_user|confirmed|external_locked)$' "${TESTS_DIR}/suites"/*.md 2>/dev/null; then
  echo "No effective non-draft test suite is available" >&2
  status=2
fi
if [[ "${required_pass}" -lt "${required_total}" ]]; then
  echo "Required test cases are not all passing" >&2
  status=2
fi
if [[ -f "${PLATFORMS_FILE}" ]]; then
  python3 - "$PLATFORMS_FILE" "$latest_run" <<'PY'
import sys, tomllib
from pathlib import Path
platforms = tomllib.loads(Path(sys.argv[1]).read_text()).get("platforms", [])
run_text = Path(sys.argv[2]).read_text()
missing = []
for item in platforms:
    if not item.get("enabled"):
        continue
    mode = item.get("required_test_mode")
    if mode and mode not in run_text:
        missing.append(f"{item.get('id')} -> {mode}")
if missing:
    print("Missing platform evidence:")
    for line in missing:
        print(f"- {line}")
    raise SystemExit(2)
PY
  rc=$?
  if [[ "${rc}" -ne 0 ]]; then status="${rc}"; fi
fi
if [[ "${status}" -eq 0 ]]; then
  echo "Test status: OK"
else
  echo "Test status: INCOMPLETE"
fi
exit "${status}"
