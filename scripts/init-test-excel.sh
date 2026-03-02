#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"

if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: init-test-excel.sh <workspace-root> <project-name>" >&2
  exit 1
fi

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
TESTS_DIR="${PROJECT_DIR}/tests"
CASES_FILE="${TESTS_DIR}/cases/standard-test-cases.xlsx"
REPORT_FILE="${TESTS_DIR}/reports/test-report-template.xlsx"

mkdir -p "${TESTS_DIR}/cases" "${TESTS_DIR}/reports" "${TESTS_DIR}/artifacts" "${TESTS_DIR}/runs" "${TESTS_DIR}/suites"

python3 "${SCRIPT_DIR}/lib/xlsx_template.py" report "${REPORT_FILE}" >/dev/null
python3 "${SCRIPT_DIR}/lib/test_excel_sync.py" cases "${TESTS_DIR}/suites" "${CASES_FILE}" >/dev/null

echo "Initialized Excel test assets for ${PROJECT_NAME}"
echo "- Cases: ${CASES_FILE}"
echo "- Report: ${REPORT_FILE}"
