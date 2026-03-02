#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
RUN_ID=""
OUTPUT=""

shift 2 || true
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: export-test-report.sh <workspace-root> <project-name> [--run-id id] [--output path]" >&2
  exit 1
fi

TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
RUNS_DIR="${TESTS_DIR}/runs"
SUITES_DIR="${TESTS_DIR}/suites"
REPORTS_DIR="${TESTS_DIR}/reports"
mkdir -p "${REPORTS_DIR}"

if [[ -z "${OUTPUT}" ]]; then
  if [[ -n "${RUN_ID}" ]]; then
    OUTPUT="${REPORTS_DIR}/test-report-${RUN_ID}.xlsx"
  else
    OUTPUT="${REPORTS_DIR}/test-report-latest.xlsx"
  fi
fi

result="$(python3 "${SCRIPT_DIR}/lib/test_excel_sync.py" report "${PROJECT_NAME}" "${RUNS_DIR}" "${SUITES_DIR}" "${OUTPUT}" ${RUN_ID:+"${RUN_ID}"})"
resolved_output="${result%%|*}"
resolved_run="${result#*|}"

echo "Exported Excel test report for ${PROJECT_NAME}"
echo "- Run: ${resolved_run}"
echo "- Output: ${resolved_output}"
