#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_DEST="${CODEX_HOME:-$HOME/.codex}/skills/omni-context"
DEST="${1:-${DEFAULT_DEST}}"

usage() {
  cat <<EOF
Usage:
  install-skill.sh [destination]

Default destination:
  ${DEFAULT_DEST}

Examples:
  install-skill.sh
  install-skill.sh /tmp/skills/omni-context
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mkdir -p "$(dirname "${DEST}")"

if [[ -e "${DEST}" ]]; then
  echo "Destination already exists: ${DEST}" >&2
  exit 1
fi

mkdir -p "${DEST}"

for path in \
  "${SKILL_ROOT}/SKILL.md" \
  "${SKILL_ROOT}/README.md" \
  "${SKILL_ROOT}/README.en.md" \
  "${SKILL_ROOT}/README.zh-CN.md" \
  "${SKILL_ROOT}/README.ja.md" \
  "${SKILL_ROOT}/agents" \
  "${SKILL_ROOT}/references" \
  "${SKILL_ROOT}/scripts" \
  "${SKILL_ROOT}/templates"; do
  cp -R "${path}" "${DEST}/"
done

echo "Installed OmniContext skill"
echo "- Source: ${SKILL_ROOT}"
echo "- Destination: ${DEST}"
echo
echo "Next steps:"
echo "- Restart Codex if it is already running"
echo "- Read ${DEST}/README.md"
echo "- Run ${DEST}/scripts/omni-context --help"
