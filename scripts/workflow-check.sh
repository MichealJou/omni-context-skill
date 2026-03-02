#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/workflow-lib.sh"
source "${SCRIPT_DIR}/lib/test-lib.sh"
source "${SCRIPT_DIR}/lib/rules-pack-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
WORKFLOW_ID="${3:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: workflow-check.sh <workspace-root> <project-name> [workflow-id]" >&2
  exit 1
fi
PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
if [[ -z "${WORKFLOW_ID}" ]]; then
  WORKFLOW_ID="$(omni_current_workflow_id "${PROJECT_DIR}")"
fi
WORKFLOW_DIR="${PROJECT_DIR}/workflows/${WORKFLOW_ID}"
LIFECYCLE="${WORKFLOW_DIR}/lifecycle.toml"
if [[ ! -f "${LIFECYCLE}" ]]; then
  echo "Missing ${LIFECYCLE}" >&2
  exit 1
fi
status=0
RULES_PACK="${PROJECT_DIR}/standards/rules-pack.toml"
STANDARDS_MAP="${PROJECT_DIR}/standards/standards-map.md"
DECISIONS_FILE="${PROJECT_DIR}/decisions.md"
TESTS_DIR="${PROJECT_DIR}/tests"
PLATFORMS_FILE="${PROJECT_DIR}/standards/testing-platforms.toml"
CURRENT_STAGE="$(omni_workflow_status_value "${LIFECYCLE}" "current_stage")"
for stage in $(omni_workflow_stages); do
  doc="$(omni_stage_doc_path "${WORKFLOW_DIR}" "${stage}")"
  if [[ ! -f "${doc}" ]]; then
    echo "- MISSING ${doc}"
    status=1
    continue
  fi
  while IFS= read -r heading; do
    if ! rg -Fq "${heading}" "${doc}"; then
      echo "- MISSING heading ${heading} in ${doc}"
      status=1
    fi
  done < <(omni_workflow_required_headings)
done

if [[ -f "${RULES_PACK}" ]]; then
  while IFS= read -r module; do
    [[ -z "${module}" ]] && continue
    case "${module}" in
      prd)
        clarification_doc="$(omni_stage_doc_path "${WORKFLOW_DIR}" "clarification")"
        if ! rg -q '^\-\s' "${clarification_doc}" 2>/dev/null; then
          echo "- PRD module requires scoped clarification content"
          status=1
        fi
        ;;
      adr)
        if [[ ! -f "${DECISIONS_FILE}" ]] || ! rg -q '^\-\s' "${DECISIONS_FILE}" 2>/dev/null; then
          echo "- ADR module requires at least one project decision entry"
          status=1
        fi
        ;;
      acceptance-criteria)
        clarification_doc="$(omni_stage_doc_path "${WORKFLOW_DIR}" "clarification")"
        acceptance_doc="$(omni_stage_doc_path "${WORKFLOW_DIR}" "acceptance")"
        if ! rg -q 'Acceptance|验收' "${clarification_doc}" 2>/dev/null && ! rg -q 'Acceptance|验收' "${acceptance_doc}" 2>/dev/null; then
          echo "- Acceptance Criteria module requires explicit acceptance content"
          status=1
        fi
        ;;
      test-cases)
        if [[ "${CURRENT_STAGE}" == "testing" ]]; then
          if [[ ! -d "${TESTS_DIR}/suites" ]] || ! find "${TESTS_DIR}/suites" -type f -name '*.md' | grep -q .; then
            echo "- Test Cases module requires at least one test suite"
            status=1
          fi
        fi
        ;;
      e2e-browser)
        if [[ "${CURRENT_STAGE}" == "testing" ]]; then
          if [[ -f "${PLATFORMS_FILE}" ]] && rg -q '^id = "web"$' "${PLATFORMS_FILE}" 2>/dev/null; then
            if [[ ! -d "${TESTS_DIR}/suites" ]] || ! rg -l '^- platform: web$' "${TESTS_DIR}/suites" 2>/dev/null | grep -q .; then
              echo "- E2E Browser module requires at least one web test suite"
              status=1
            fi
          fi
        fi
        ;;
      iso-12207-lifecycle)
        if [[ ! -f "${STANDARDS_MAP}" ]] || ! rg -q 'ISO/IEC/IEEE 12207' "${STANDARDS_MAP}" 2>/dev/null; then
          echo "- ISO lifecycle module requires standards-map alignment"
          status=1
        fi
        ;;
      nist-ssdf)
        if [[ ! -f "${STANDARDS_MAP}" ]] || ! rg -q 'NIST SSDF' "${STANDARDS_MAP}" 2>/dev/null; then
          echo "- NIST SSDF module requires standards-map alignment"
          status=1
        fi
        ;;
      owasp-asvs)
        if [[ ! -f "${STANDARDS_MAP}" ]] || ! rg -q 'OWASP ASVS' "${STANDARDS_MAP}" 2>/dev/null; then
          echo "- OWASP ASVS module requires standards-map alignment"
          status=1
        fi
        ;;
      istqb-governance)
        if [[ ! -f "${STANDARDS_MAP}" ]] || ! rg -q 'ISTQB|IEEE 29119' "${STANDARDS_MAP}" 2>/dev/null; then
          echo "- ISTQB governance module requires standards-map alignment"
          status=1
        fi
        ;;
      change-safety)
        if [[ -f "${PROJECT_DIR}/standards/runtime.toml" ]] && rg -q 'kind = "(mysql|postgres|redis)"' "${PROJECT_DIR}/standards/runtime.toml" 2>/dev/null; then
          if [[ ! -f "${PROJECT_DIR}/docs/runbook/index.md" ]]; then
            echo "- Change Safety module requires a runbook index for recovery notes"
            status=1
          fi
        fi
        ;;
    esac
  done < <(omni_rules_pack_resolved_modules "${RULES_PACK}")
fi

TESTING_STATUS="$(omni_workflow_status_value "${LIFECYCLE}" "stages.testing.status")"
if [[ "${TESTING_STATUS}" == "completed" || "${TESTING_STATUS}" == "in_progress" ]]; then
  if ! "${SCRIPT_DIR}/test-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" >/dev/null 2>&1; then
    echo "- Testing evidence is incomplete"
    status=1
  fi
fi

if [[ "${status}" -eq 0 ]]; then
  echo "Workflow check: OK"
else
  echo "Workflow check: INCOMPLETE"
fi
exit "${status}"
