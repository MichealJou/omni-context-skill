#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_SKILL_DEST="${CODEX_HOME:-$HOME/.codex}/skills/omni-context"
DEFAULT_BIN_DIR="${HOME}/.local/bin"

SKILL_DEST="${DEFAULT_SKILL_DEST}"
BIN_DIR="${DEFAULT_BIN_DIR}"
FORCE="false"
SKIP_PATH_UPDATE="false"

usage() {
  cat <<EOF
Usage:
  install-global.sh [--force] [--skip-path-update] [--skill-dest DIR] [--bin-dir DIR]

Default skill destination:
  ${DEFAULT_SKILL_DEST}

Default global bin directory:
  ${DEFAULT_BIN_DIR}

Behavior:
  1. Install or refresh the OmniContext skill files
  2. Create global omni and omni-context launchers in the bin directory

Examples:
  install-global.sh
  install-global.sh --force
  install-global.sh --skip-path-update
  install-global.sh --bin-dir "\$HOME/bin"
EOF
}

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE="true"
      shift
      ;;
    --skip-path-update)
      SKIP_PATH_UPDATE="true"
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

write_launcher() {
  local launcher_path="$1"
  cat > "${launcher_path}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec bash "${SKILL_DEST}/scripts/omni-context" "\$@"
EOF
  chmod +x "${launcher_path}"
}

LAUNCHER="${BIN_DIR}/omni-context"
SHORT_LAUNCHER="${BIN_DIR}/omni"
write_launcher "${LAUNCHER}"
write_launcher "${SHORT_LAUNCHER}"

update_path() {
  local bin_dir="$1"
  local line="export PATH=\"${bin_dir}:\$PATH\""
  local profiles=(
    "${HOME}/.zshrc"
    "${HOME}/.bashrc"
    "${HOME}/.bash_profile"
    "${HOME}/.profile"
  )
  local profile

  for profile in "${profiles[@]}"; do
    if [[ -f "${profile}" ]]; then
      if grep -Fq "${bin_dir}" "${profile}"; then
        echo "- PATH already contains ${bin_dir} in ${profile}"
        return 0
      fi
      printf '\n%s\n' "${line}" >> "${profile}"
      echo "- Added PATH update to ${profile}"
      return 0
    fi
  done

  printf '%s\n' "${line}" > "${HOME}/.zshrc"
  echo "- Created ${HOME}/.zshrc with PATH update"
}

echo "Installed OmniContext global launchers"
echo "- Skill: ${SKILL_DEST}"
echo "- Commands: ${LAUNCHER}, ${SHORT_LAUNCHER}"

if [[ "${SKIP_PATH_UPDATE}" != "true" ]]; then
  echo "- Updating shell PATH profiles"
  update_path "${BIN_DIR}"
else
  echo "- Skipped PATH update"
fi

echo
echo "You can now run:"
echo "- omni --help"
echo "- omni-context --help"
