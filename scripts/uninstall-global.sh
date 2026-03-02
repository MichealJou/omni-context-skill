#!/usr/bin/env bash
set -euo pipefail

DEFAULT_SKILL_DEST="${CODEX_HOME:-$HOME/.codex}/skills/omni-context"
DEFAULT_BIN_DIR="${HOME}/.local/bin"

SKILL_DEST="${DEFAULT_SKILL_DEST}"
BIN_DIR="${DEFAULT_BIN_DIR}"
KEEP_PATH="false"

usage() {
  cat <<EOF
Usage:
  uninstall-global.sh [--keep-path] [--skill-dest DIR] [--bin-dir DIR]

Examples:
  uninstall-global.sh
  uninstall-global.sh --keep-path
  uninstall-global.sh --bin-dir "\$HOME/bin"
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --keep-path)
      KEEP_PATH="true"
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

rm -f "${BIN_DIR}/omni" "${BIN_DIR}/omni-context"
rm -rf "${SKILL_DEST}"

cleanup_path() {
  local bin_dir="$1"
  local line="export PATH=\"${bin_dir}:\$PATH\""
  local profiles=(
    "${HOME}/.zshrc"
    "${HOME}/.bashrc"
    "${HOME}/.bash_profile"
    "${HOME}/.profile"
  )
  local profile
  local tmp

  for profile in "${profiles[@]}"; do
    [[ -f "${profile}" ]] || continue
    tmp="$(mktemp)"
    grep -Fvx "${line}" "${profile}" > "${tmp}" || true
    mv "${tmp}" "${profile}"
  done
}

echo "Uninstalled OmniContext global launchers"
echo "- Removed commands: ${BIN_DIR}/omni, ${BIN_DIR}/omni-context"
echo "- Removed skill: ${SKILL_DEST}"

if [[ "${KEEP_PATH}" != "true" ]]; then
  cleanup_path "${BIN_DIR}"
  echo "- Removed PATH updates for ${BIN_DIR} where found"
else
  echo "- Kept PATH configuration"
fi
