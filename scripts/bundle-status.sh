#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bundle-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
shift 2 || true
STAGE=""
ROLE=""
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --stage) STAGE="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done
SKILLS_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/skills.toml"
if [[ ! -f "${SKILLS_FILE}" ]]; then
  echo "Missing ${SKILLS_FILE}" >&2
  exit 1
fi
PROJECT_TYPE="$(python3 - "$SKILLS_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(data.get("project_type", "project"))
PY
)"
bundle_items="$(printf '%s\n' $(omni_bundle_base_for_project_type "${PROJECT_TYPE}") $(omni_bundle_for_stage "${PROJECT_TYPE}" "${STAGE}") $(omni_bundle_for_role "${ROLE}") | sed '/^$/d' | awk '!seen[$0]++')"
echo "Bundle items:"
while IFS= read -r item; do
  [[ -n "${item}" ]] || continue
  status="missing"
  if omni_bundle_is_installed "${item}"; then status="installed"; fi
  echo "- ${item}: ${status}"
done < <(printf '%s\n' "${bundle_items}")
