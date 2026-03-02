#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/test-lib.sh"

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

if [[ -z "${PLATFORM}" ]]; then
  SUITE_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests/suites/${SUITE_ID}.md"
  [[ -f "${SUITE_FILE}" ]] || { echo "Missing suite ${SUITE_ID}" >&2; exit 1; }
  PLATFORM="$(omni_test_suite_platform "${SUITE_FILE}")"
fi

if [[ "${MODE}" == "auto" ]]; then
  case "${PLATFORM}" in
    backend) MODE="api" ;;
    miniapp) MODE="miniapp" ;;
    *) MODE="browser" ;;
  esac
fi

case "${MODE}" in
  browser|miniapp)
    primary=("${SCRIPT_DIR}/run-browser-suite-devtools.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --platform "${PLATFORM:-web}")
    if [[ -n "${DEPENDENCY_ID}" ]]; then
      primary+=(--dependency "${DEPENDENCY_ID}")
    fi
    if "${primary[@]}"; then
      exit 0
    fi
    run_file="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/tests/runs/${RUN_ID}.md"
    should_fallback="false"
    if [[ -f "${run_file}" ]]; then
      run_status="$(omni_test_run_field "${run_file}" "run_status")"
      observed="$(omni_test_run_field "${run_file}" "observed_behavior")"
      case "${run_status}" in
        blocked_runtime) should_fallback="true" ;;
      esac
      if [[ "${observed}" == *"unsupported_step_action"* || "${observed}" == *"locator_resolution_failed"* ]]; then
        should_fallback="true"
      fi
    fi
    if [[ "${should_fallback}" == "true" ]]; then
      fallback=("${SCRIPT_DIR}/run-browser-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --platform "${PLATFORM:-web}" --fallback-note "devtools primary execution failed; playwright fallback executed")
      if [[ -n "${DEPENDENCY_ID}" ]]; then
        fallback+=(--dependency "${DEPENDENCY_ID}")
      fi
      exec "${fallback[@]}"
    fi
    exit 1
    ;;
  api|service)
    cmd=("${SCRIPT_DIR}/run-api-suite.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" "${SUITE_ID}" --run-id "${RUN_ID}" --platform "${PLATFORM:-backend}")
    if [[ -n "${DEPENDENCY_ID}" ]]; then
      cmd+=(--dependency "${DEPENDENCY_ID}")
    fi
    exec "${cmd[@]}"
    ;;
  *)
    echo "Unsupported mode ${MODE}" >&2
    exit 2
    ;;
esac
