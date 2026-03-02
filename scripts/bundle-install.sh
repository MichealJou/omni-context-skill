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
PROJECT_TYPE="$(python3 - "$SKILLS_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(data.get("project_type", "project"))
PY
)"
CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "${CODEX_SKILLS}"
for item in $(omni_bundle_base_for_project_type "${PROJECT_TYPE}") $(omni_bundle_for_stage "${PROJECT_TYPE}" "${STAGE}") $(omni_bundle_for_role "${ROLE}"); do
  [[ -n "${item}" ]] || continue
  if omni_bundle_is_installed "${item}"; then
    continue
  fi
  src="$(omni_bundle_source_path "${item}")"
  if [[ -n "${src}" && -d "${src}" ]]; then
    cp -R "${src}" "${CODEX_SKILLS}/${item}"
    echo "Installed local skill ${item}"
  else
    echo "Missing install source for ${item}"
  fi
done
