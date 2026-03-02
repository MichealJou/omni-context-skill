#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_SKILL_DEST="${CODEX_HOME:-$HOME/.codex}/skills/omni-context"
DEFAULT_BIN_DIR="${HOME}/.local/bin"

SKILL_DEST="${DEFAULT_SKILL_DEST}"
BIN_DIR="${DEFAULT_BIN_DIR}"
FORCE="false"

usage() {
  cat <<EOF
Usage:
  install-global.sh [--force] [--skill-dest DIR] [--bin-dir DIR]

Default skill destination:
  ${DEFAULT_SKILL_DEST}

Default global bin directory:
  ${DEFAULT_BIN_DIR}

Behavior:
  1. Install or refresh the OmniContext skill files
  2. Create a global omni-context launcher in the bin directory

Examples:
  install-global.sh
  install-global.sh --force
  install-global.sh --bin-dir "\$HOME/bin"
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE="true"
      shift
      ;;
    --skill-dest)
      SKILL_DEST="$2"
      shift 2
      ;;
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${FORCE}" == "true" && -e "${SKILL_DEST}" ]]; then
  rm -rf "${SKILL_DEST}"
fi

if [[ ! -e "${SKILL_DEST}" ]]; then
  "${SCRIPT_DIR}/install-skill.sh" "${SKILL_DEST}" >/dev/null
fi

mkdir -p "${BIN_DIR}"

LAUNCHER="${BIN_DIR}/omni-context"
cat > "${LAUNCHER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec bash "${SKILL_DEST}/scripts/omni-context" "\$@"
EOF
chmod +x "${LAUNCHER}"

echo "Installed OmniContext global launcher"
echo "- Skill: ${SKILL_DEST}"
echo "- Command: ${LAUNCHER}"
echo
echo "If '${BIN_DIR}' is not in PATH, add this to your shell profile:"
echo "export PATH=\"${BIN_DIR}:\$PATH\""
