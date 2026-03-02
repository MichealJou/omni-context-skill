#!/usr/bin/env bash
set -euo pipefail

os_name="$(uname -s 2>/dev/null || echo unknown)"
platform="unknown"

case "${os_name}" in
  Darwin) platform="macOS" ;;
  Linux) platform="Linux" ;;
  MINGW*|MSYS*|CYGWIN*) platform="Windows-compatible shell" ;;
esac

check_cmd() {
  local label="$1"
  local cmd="$2"
  if command -v "${cmd}" >/dev/null 2>&1; then
    echo "- ${label}: OK ($(command -v "${cmd}"))"
  else
    echo "- ${label}: MISSING"
  fi
}

echo "Platform doctor"
echo "- OS: ${platform} (${os_name})"
check_cmd "bash" "bash"
check_cmd "git" "git"
check_cmd "python3" "python3"
check_cmd "playwright" "playwright"
check_cmd "node" "node"
check_cmd "npm" "npm"

if [[ "${platform}" == "macOS" || "${platform}" == "Linux" ]]; then
  echo "- support mode: native"
  echo "- global install: native shell installer supported"
elif [[ "${platform}" == "Windows-compatible shell" ]]; then
  echo "- support mode: PowerShell + Git Bash backend"
  echo "- global install: bash-compatible shell supported"
else
  echo "- support mode: UNKNOWN"
  echo "- global install: UNKNOWN"
fi
