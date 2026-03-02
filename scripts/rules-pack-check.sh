#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/rules-pack-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
FILE="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}/standards/rules-pack.toml"
if [[ ! -f "${FILE}" ]]; then
  echo "Missing ${FILE}" >&2
  exit 1
fi
base_pack="$(python3 - "$FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
mods = data.get("customization", {}).get("add", [])
remove = set(data.get("customization", {}).get("remove", []))
print(data.get("base_pack", "default-balanced"))
for item in mods:
    print(item)
for item in remove:
    print(f"remove:{item}")
PY
)"
pack="$(printf '%s\n' "${base_pack}" | sed -n '1p')"
mods=()
for mod in $(omni_rules_pack_required_modules "${pack}"); do mods+=("${mod}"); done
while IFS= read -r mod; do
  [[ -n "${mod}" ]] || continue
  if [[ "${mod}" == remove:* ]]; then
    target="${mod#remove:}"
    mods=($(printf '%s\n' "${mods[@]}" | grep -Fxv "${target}"))
  else
    mods+=("${mod}")
  fi
done < <(printf '%s\n' "${base_pack}" | sed -n '2,$p')
if omni_rules_pack_validate "${pack}" "${mods[@]}"; then
  echo "Rules pack: OK"
else
  rc=$?
  echo "Rules pack: WARNING"
  omni_rules_pack_validate "${pack}" "${mods[@]}" || true
  exit 2
fi
