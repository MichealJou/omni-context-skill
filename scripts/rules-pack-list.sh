#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/rules-pack-lib.sh"
for pack in $(omni_rules_pack_names); do
  echo "- ${pack}: $(omni_rules_pack_description "${pack}")"
done
