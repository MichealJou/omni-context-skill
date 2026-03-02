#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/runtime-lib.sh"

WORKSPACE_ROOT="$(cd "${1:-$(pwd)}" && pwd)"
PROJECT_NAME="${2:-}"
shift 2 || true

PLATFORM="all"
DO_INSTALL="true"

while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --install) DO_INSTALL="true"; shift ;;
    --check-only) DO_INSTALL="false"; shift ;;
    *) echo "Unknown option $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${PROJECT_NAME}" ]]; then
  echo "Usage: setup-test-runtime.sh <workspace-root> <project-name> [--platform web|backend|miniapp|all] [--check-only]" >&2
  exit 1
fi

PROJECT_DIR="${WORKSPACE_ROOT}/.omnicontext/projects/${PROJECT_NAME}"
RUNTIME_FILE="${PROJECT_DIR}/standards/runtime.toml"
PLATFORMS_FILE="${PROJECT_DIR}/standards/testing-platforms.toml"
[[ -f "${RUNTIME_FILE}" ]] || { echo "Missing runtime.toml" >&2; exit 1; }

has_chrome_devtools="false"
if [[ -f "${HOME}/.codex/config.toml" ]] && rg -q '^\[mcp_servers\.chrome-devtools\]' "${HOME}/.codex/config.toml" 2>/dev/null; then
  has_chrome_devtools="true"
fi

chrome_binary="missing"
if chrome_path="$(omni_browser_executable 2>/dev/null)"; then
  chrome_binary="${chrome_path}"
fi

platforms=()
if [[ -f "${PLATFORMS_FILE}" ]]; then
  while IFS= read -r line; do
    [[ -n "${line}" ]] && platforms+=("${line}")
  done < <(python3 - "$PLATFORMS_FILE" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for item in data.get("platforms", []):
    if item.get("enabled"):
        print(item.get("id", ""))
PY
)
fi

if [[ "${PLATFORM}" != "all" ]]; then
  platforms=("${PLATFORM}")
fi

if [[ "${#platforms[@]}" -eq 0 ]]; then
  echo "Test runtime setup: no enabled platforms"
  exit 0
fi

needs_browser_runtime="false"
for platform in "${platforms[@]}"; do
  case "${platform}" in
    web|miniapp) needs_browser_runtime="true" ;;
  esac
done

playwright_python="missing"
playwright_browser="missing"
if [[ "${needs_browser_runtime}" == "true" ]] && python3 - <<'PY' >/dev/null 2>&1
import importlib
raise SystemExit(0 if importlib.util.find_spec("playwright") else 1)
PY
then
  playwright_python="installed"
fi

if [[ "${needs_browser_runtime}" == "true" && "${playwright_python}" == "installed" ]]; then
  if python3 - <<'PY' >/dev/null 2>&1
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    browser.close()
PY
  then
    playwright_browser="ready"
  fi
fi

if [[ "${DO_INSTALL}" == "true" ]]; then
  if [[ "${needs_browser_runtime}" == "true" && "${playwright_python}" != "installed" ]]; then
    python3 -m pip install playwright
    playwright_python="installed"
  fi
  if [[ "${needs_browser_runtime}" == "true" && "${playwright_browser}" != "ready" ]]; then
    python3 -m playwright install chromium
    if python3 - <<'PY' >/dev/null 2>&1
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    browser.close()
PY
    then
      playwright_browser="ready"
    fi
  fi
fi

status=0
echo "Test runtime setup: ${PROJECT_NAME}"
echo "- chrome_devtools_mcp: ${has_chrome_devtools}"
echo "- chrome_binary: ${chrome_binary}"
echo "- playwright_python: ${playwright_python}"
echo "- playwright_browser: ${playwright_browser}"

for platform in "${platforms[@]}"; do
  case "${platform}" in
    web|miniapp)
      if [[ "${chrome_binary}" != "missing" ]]; then
        echo "- ${platform}: OK"
        if [[ "${playwright_browser}" != "ready" ]]; then
          echo "  note=devtools primary execution available; playwright fallback is not ready"
        fi
      else
        echo "- ${platform}: browser suite executor requires a local Chrome-compatible browser"
        if [[ "${has_chrome_devtools}" == "true" ]]; then
          echo "  note=chrome-devtools MCP is available, but the local Chrome binary is missing"
        fi
        status=2
      fi
      ;;
    backend)
      dep_id="$(omni_runtime_dependency_for_platform "${RUNTIME_FILE}" "backend")"
      if [[ -n "${dep_id}" ]]; then
        url="$(omni_runtime_dependency_url "${RUNTIME_FILE}" "${dep_id}")"
        if [[ -n "${url}" ]]; then
          echo "- backend: OK (${url})"
        else
          echo "- backend: missing service endpoint in runtime.toml"
          status=2
        fi
      else
        echo "- backend: missing backend dependency in runtime.toml"
        status=2
      fi
      ;;
    *)
      echo "- ${platform}: unsupported platform"
      status=2
      ;;
  esac
done

if [[ "${status}" -eq 0 ]]; then
  echo "Setup status: OK"
else
  echo "Setup status: INCOMPLETE"
  echo "Next: omni-context setup-test-runtime ${WORKSPACE_ROOT} ${PROJECT_NAME} --platform ${PLATFORM}"
fi

exit "${status}"
