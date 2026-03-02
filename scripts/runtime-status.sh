#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: runtime-status.sh <workspace-root> <project-name>" >&2
  exit 1
fi
RUNTIME_FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/runtime.toml"
if [[ ! -f "${RUNTIME_FILE}" ]]; then
  echo "Missing ${RUNTIME_FILE}" >&2
  exit 1
fi
status=0
project_name="$(python3 - "$RUNTIME_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(data.get("project_name", ""))
PY
)"
echo "Project: ${project_name}"
while IFS='|' read -r dep_id kind enabled environment host port database endpoint; do
  [[ -n "${dep_id}" ]] || continue
  [[ "${dep_id}" == replace-with-* ]] && continue
  client="$(omni_runtime_client_for_kind "${kind}")"
  client_status="n/a"
  if [[ -n "${client}" ]]; then
    if command -v "${client}" >/dev/null 2>&1; then
      client_status="available"
    else
      client_status="missing"
      if [[ "${enabled}" == "true" ]]; then status=2; fi
    fi
  fi
  reachability="n/a"
  if [[ "${enabled}" == "true" ]]; then
    case "${kind}" in
      service|browser|miniapp)
        if [[ -n "${endpoint}" ]]; then
          if curl -fsS --max-time 3 "${endpoint}" >/dev/null 2>&1; then
            reachability="reachable"
          else
            reachability="unreachable"
            status=2
          fi
        fi
        ;;
      redis|mysql|postgres)
        if [[ -n "${host}" && -n "${port}" && "${port}" != "0" ]]; then
          if nc -z "${host}" "${port}" >/dev/null 2>&1; then
            reachability="reachable"
          else
            reachability="unreachable"
            status=2
          fi
        fi
        ;;
    esac
  fi
  printf -- "- %s: kind=%s enabled=%s env=%s client=%s reachability=%s" "${dep_id}" "${kind}" "${enabled}" "${environment}" "${client_status}" "${reachability}"
  [[ -n "${host}" ]] && printf " host=%s" "${host}"
  [[ "${port}" != "0" && -n "${port}" ]] && printf " port=%s" "${port}"
  [[ -n "${database}" ]] && printf " database=%s" "${database}"
  [[ -n "${endpoint}" ]] && printf " endpoint=%s" "${endpoint}"
  printf "\n"
done < <(python3 - "$RUNTIME_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for dep in data.get("dependencies", []):
    print("|".join([
        str(dep.get("id", "")),
        str(dep.get("kind", "")),
        "true" if dep.get("enabled") else "false",
        str(dep.get("environment", "")),
        str(dep.get("host", "")),
        str(dep.get("port", 0)),
        str(dep.get("database", "")),
        str(dep.get("entry_url", "") or dep.get("url", "")),
    ]))
PY
)
exit "${status}"
