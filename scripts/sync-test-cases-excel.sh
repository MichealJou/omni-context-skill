#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
OUTPUT=""

shift 2 || true
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: sync-test-cases-excel.sh <workspace-root> <project-name> [--output path]" >&2
  exit 1
fi

TESTS_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests"
SUITES_DIR="${TESTS_DIR}/suites"
OUTPUT="${OUTPUT:-${TESTS_DIR}/cases/standard-test-cases.xlsx}"

mkdir -p "${TESTS_DIR}/cases" "${TESTS_DIR}/suites"
python3 "${SCRIPT_DIR}/lib/test_excel_sync.py" cases "${SUITES_DIR}" "${OUTPUT}" >/dev/null

echo "Synchronized Excel test cases for ${PROJECT_NAME}"
echo "- Output: ${OUTPUT}"
