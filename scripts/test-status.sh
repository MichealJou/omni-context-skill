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

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
TESTS_DIR="${PROJECT_DIR}/tests"
PLATFORMS_FILE="${PROJECT_DIR}/standards/testing-platforms.toml"
SUITES_DIR="${TESTS_DIR}/suites"
RUNS_DIR="${TESTS_DIR}/runs"

if [[ ! -d "${SUITES_DIR}" || ! -d "${RUNS_DIR}" ]]; then
  echo "Missing tests/suites or tests/runs" >&2
  exit 2
fi

latest_run="$(find "${RUNS_DIR}" -type f -name '*.md' | sort | tail -n 1)"
if [[ -z "${latest_run}" ]]; then
  echo "No test runs recorded" >&2
  exit 2
fi

platforms=()
if [[ -f "${PLATFORMS_FILE}" ]]; then
  while IFS= read -r line; do
    [[ -n "${line}" ]] && platforms+=("${line}")
  done < <(python3 - "$PLATFORMS_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for item in data.get("platforms", []):
    if item.get("enabled"):
        print(f"{item.get('id','')}|{item.get('required_test_mode','')}")
PY
)
fi

if [[ "${#platforms[@]}" -eq 0 ]]; then
  run_platform="$(omni_test_run_field "${latest_run}" "platform")"
  run_mode="$(omni_test_run_field "${latest_run}" "execution_mode")"
  run_platform="${run_platform:-generic}"
  run_mode="${run_mode:-unspecified}"
  platforms=("${run_platform}|${run_mode}")
fi

status=0
summary_lines=()

check_platform() {
  local platform="$1"
  local required_mode="$2"
  local latest_platform_run
  latest_platform_run="$(find "${RUNS_DIR}" -type f -name '*.md' -print0 | xargs -0 rg -l "^- platform: ${platform}$" 2>/dev/null | sort | tail -n 1 || true)"
  if [[ -z "${latest_platform_run}" ]]; then
    echo "Missing test run for platform ${platform}" >&2
    return 2
  fi

  local suite_id suite_file run_mode run_status run_source_status suite_source_status suite_fingerprint actual_fingerprint evidence required_total required_pass
  suite_id="$(omni_test_run_field "${latest_platform_run}" "suite_id")"
  suite_file="${SUITES_DIR}/${suite_id}.md"
  [[ -f "${suite_file}" ]] || { echo "Missing suite ${suite_id} referenced by ${latest_platform_run##*/}" >&2; return 2; }

  suite_source_status="$(omni_test_suite_source_status "${suite_file}")"
  run_source_status="$(omni_test_run_field "${latest_platform_run}" "suite_source_status")"
  if ! omni_test_effective_status_allowed "${suite_source_status:-draft}"; then
    echo "Suite ${suite_id} for platform ${platform} is draft-only" >&2
    return 2
  fi
  if [[ "${run_source_status:-}" != "${suite_source_status:-}" ]]; then
    echo "Run ${latest_platform_run##*/} source status does not match suite ${suite_id}" >&2
    return 2
  fi

  suite_fingerprint="$(omni_test_run_field "${latest_platform_run}" "suite_fingerprint")"
  actual_fingerprint="$(omni_test_suite_fingerprint "${suite_file}")"
  if [[ -z "${suite_fingerprint}" || "${suite_fingerprint}" != "${actual_fingerprint}" ]]; then
    echo "Run ${latest_platform_run##*/} is out of sync with suite ${suite_id}" >&2
    return 2
  fi

  run_mode="$(omni_test_run_field "${latest_platform_run}" "execution_mode")"
  if [[ -n "${required_mode}" && "${run_mode}" != "${required_mode}" ]]; then
    echo "Platform ${platform} requires ${required_mode} mode" >&2
    return 2
  fi

  run_status="$(omni_test_run_field "${latest_platform_run}" "run_status")"
  run_status="${run_status%% *}"
  if [[ -n "${run_status}" && "${run_status}" != "passed" && "${run_status}" != "completed" ]]; then
    if [[ "${run_status}" == "blocked_runtime" ]]; then
      blocker="$(rg -o '^\-\s+recommended_next_step:\s+.+$' "${latest_platform_run}" 2>/dev/null | sed 's/^- recommended_next_step: //; s/^\-\s\+recommended_next_step:\s\+//')"
      echo "Run ${latest_platform_run##*/} is blocked by runtime setup for platform ${platform}${blocker:+: ${blocker}}" >&2
    else
      echo "Run ${latest_platform_run##*/} is not completed for platform ${platform}" >&2
    fi
    return 2
  fi

  evidence="$(omni_test_run_field "${latest_platform_run}" "evidence")"
  if [[ -z "${evidence}" || "${evidence}" == "pending-evidence" ]]; then
    echo "Run ${latest_platform_run##*/} is missing real evidence" >&2
    return 2
  fi

  required_total="$(omni_test_required_count "${suite_file}")"
  required_pass="$(rg -c '^\- \[required-pass\]\s+(PASS|OK|SUCCESS):' "${latest_platform_run}" 2>/dev/null || true)"
  [[ -n "${required_total}" ]] || required_total=0
  [[ -n "${required_pass}" ]] || required_pass=0
  if [[ "${required_total}" -eq 0 ]]; then
    echo "Suite ${suite_id} has no required cases" >&2
    return 2
  fi
  if [[ "${required_pass}" -lt "${required_total}" ]]; then
    echo "Required test cases are not all passing for platform ${platform}" >&2
    return 2
  fi
  if rg -q '^\-\s+\[(required-pass|optional-pass)\]\s+PENDING:' "${latest_platform_run}" 2>/dev/null; then
    echo "Run ${latest_platform_run##*/} still contains pending cases" >&2
    return 2
  fi

  summary_lines+=("${platform}: ${required_pass}/${required_total} required passed via ${latest_platform_run##*/}")
  return 0
}

for entry in "${platforms[@]}"; do
  platform="${entry%%|*}"
  required_mode="${entry#*|}"
  if ! check_platform "${platform}" "${required_mode}"; then
    status=2
  fi
done

if [[ "${status}" -eq 0 ]]; then
  echo "Test status: OK"
  for line in "${summary_lines[@]}"; do
    echo "- ${line}"
  done
else
  echo "Test status: INCOMPLETE"
fi

exit "${status}"
