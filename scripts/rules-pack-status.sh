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
python3 - "$FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(f"Project: {data.get('project_name')}")
print(f"Base pack: {data.get('base_pack')}")
for key in ("add", "remove"):
    print(f"{key}: {', '.join(data.get('customization', {}).get(key, [])) or 'None'}")
PY
echo "Resolved modules:"
base_pack="$(python3 - "$FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(data.get("base_pack", "default-balanced"))
PY
)"
for mod in $(omni_rules_pack_required_modules "${base_pack}"); do echo "- ${mod}"; done
