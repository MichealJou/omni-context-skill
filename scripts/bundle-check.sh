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
"${SCRIPT_DIR}/bundle-status.sh" "${WORKSPACE_ROOT}" "${PROJECT_NAME}" ${STAGE:+--stage "${STAGE}"} ${ROLE:+--role "${ROLE}"} | tee /tmp/omni-bundle-status.$$ >/dev/null
if rg -q 'missing$' /tmp/omni-bundle-status.$$; then
  echo "Bundle check: WARNING"
  rm -f /tmp/omni-bundle-status.$$
  exit 2
fi
echo "Bundle check: OK"
rm -f /tmp/omni-bundle-status.$$
