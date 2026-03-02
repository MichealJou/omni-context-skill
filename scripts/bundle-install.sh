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
TMP_ROOT="${TMPDIR:-/tmp}/omni-bundle-install.$$"
mkdir -p "${TMP_ROOT}"
cleanup() {
  rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT
for item in $(omni_bundle_resolve_items "${WORKSPACE_ROOT}" "${PROJECT_TYPE}" "${STAGE}" "${ROLE}"); do
  [[ -n "${item}" ]] || continue
  if omni_bundle_is_installed "${item}"; then
    continue
  fi
  source_type="$(omni_bundle_source_type "${WORKSPACE_ROOT}" "${item}")"
  src="$(omni_bundle_source_path "${WORKSPACE_ROOT}" "${item}")"
  repo="$(omni_bundle_source_repo "${WORKSPACE_ROOT}" "${item}")"
  skill_path="$(omni_bundle_source_skill_path "${WORKSPACE_ROOT}" "${item}")"
  case "${source_type}" in
    local|system)
      if [[ -n "${src}" && -d "${src}" ]]; then
        cp -R "${src}" "${CODEX_SKILLS}/${item}"
        echo "Installed ${source_type} skill ${item}"
      else
        echo "Missing install source for ${item}"
      fi
      ;;
    github)
      if [[ -z "${repo}" ]]; then
        echo "Missing GitHub repo for ${item}"
        continue
      fi
      clone_dir="${TMP_ROOT}/${item}"
      git clone "https://github.com/${repo}.git" "${clone_dir}" >/dev/null 2>&1
      install_source="${clone_dir}"
      if [[ -n "${skill_path}" ]]; then
        install_source="${clone_dir}/${skill_path}"
      fi
      if [[ -d "${install_source}" ]]; then
        cp -R "${install_source}" "${CODEX_SKILLS}/${item}"
        echo "Installed github skill ${item}"
      else
        echo "Missing skill path for ${item}: ${skill_path}"
      fi
      ;;
    *)
      echo "Unknown source type for ${item}: ${source_type:-unset}"
      ;;
  esac
done
