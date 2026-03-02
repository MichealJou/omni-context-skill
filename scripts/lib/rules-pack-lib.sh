#!/usr/bin/env bash

omni_rules_core_modules() {
  printf '%s\n' prd adr acceptance-criteria test-cases change-safety
}

omni_rules_pack_names() {
  printf '%s\n' default-balanced fast-delivery high-security design-driven backend-stability
}

omni_rules_pack_description() {
  case "$1" in
    default-balanced) printf '平衡型标准交付\n' ;;
    fast-delivery) printf '快速迭代\n' ;;
    high-security) printf '高安全\n' ;;
    design-driven) printf '设计驱动\n' ;;
    backend-stability) printf '后端稳态\n' ;;
    *) printf '%s\n' "$1" ;;
  esac
}

omni_rules_pack_required_modules() {
  case "$1" in
    default-balanced)
      printf '%s\n' prd adr acceptance-criteria test-cases change-safety iso-12207-lifecycle nist-ssdf
      ;;
    fast-delivery)
      printf '%s\n' prd acceptance-criteria test-cases change-safety scrum-lite
      ;;
    high-security)
      printf '%s\n' prd adr acceptance-criteria test-cases change-safety backup-recovery least-privilege nist-ssdf owasp-asvs
      ;;
    design-driven)
      printf '%s\n' prd adr acceptance-criteria test-cases change-safety e2e-browser
      ;;
    backend-stability)
      printf '%s\n' prd adr acceptance-criteria test-cases change-safety backup-recovery least-privilege nist-ssdf
      ;;
    *)
      return 1
      ;;
  esac
}

omni_rules_pack_recommended_modules() {
  case "$1" in
    default-balanced) printf '%s\n' owasp-asvs istqb-governance test-pyramid ;;
    fast-delivery) printf '%s\n' adr ;;
    high-security) printf '%s\n' istqb-governance ;;
    design-driven) printf '%s\n' owasp-asvs test-pyramid ;;
    backend-stability) printf '%s\n' istqb-governance ;;
    *) return 1 ;;
  esac
}

omni_rules_pack_validate() {
  local base_pack="$1"
  shift
  local modules=("$@")
  local module
  local missing=0
  for module in $(omni_rules_core_modules); do
    if ! printf '%s\n' "${modules[@]}" | grep -Fxq "${module}"; then
      printf 'missing-core|%s\n' "${module}"
      missing=1
    fi
  done
  if [[ "${base_pack}" == "design-driven" ]] && ! printf '%s\n' "${modules[@]}" | grep -Fxq "e2e-browser"; then
    printf 'missing-design-test|e2e-browser\n'
    missing=1
  fi
  if [[ "${base_pack}" == "backend-stability" ]] && ! printf '%s\n' "${modules[@]}" | grep -Fxq "backup-recovery"; then
    printf 'missing-backup|backup-recovery\n'
    missing=1
  fi
  return "${missing}"
}

omni_rules_pack_base_pack() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
print(data.get("base_pack", "default-balanced"))
PY
}

omni_rules_pack_custom_modules() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for item in data.get("customization", {}).get(sys.argv[2], []):
    print(item)
PY
}

omni_rules_pack_resolved_modules() {
  local file="$1"
  python3 - "$file" <<'PY'
import sys, tomllib
from pathlib import Path

required = {
    "default-balanced": ["prd", "adr", "acceptance-criteria", "test-cases", "change-safety", "iso-12207-lifecycle", "nist-ssdf"],
    "fast-delivery": ["prd", "acceptance-criteria", "test-cases", "change-safety", "scrum-lite"],
    "high-security": ["prd", "adr", "acceptance-criteria", "test-cases", "change-safety", "backup-recovery", "least-privilege", "nist-ssdf", "owasp-asvs"],
    "design-driven": ["prd", "adr", "acceptance-criteria", "test-cases", "change-safety", "e2e-browser"],
    "backend-stability": ["prd", "adr", "acceptance-criteria", "test-cases", "change-safety", "backup-recovery", "least-privilege", "nist-ssdf"],
}
recommended = {
    "default-balanced": ["owasp-asvs", "istqb-governance", "test-pyramid"],
    "fast-delivery": ["adr"],
    "high-security": ["istqb-governance"],
    "design-driven": ["owasp-asvs", "test-pyramid"],
    "backend-stability": ["istqb-governance"],
}
data = tomllib.loads(Path(sys.argv[1]).read_text())
base = data.get("base_pack", "default-balanced")
mods = set(required.get(base, [])) | set(recommended.get(base, []))
mods |= set(data.get("customization", {}).get("add", []))
mods -= set(data.get("customization", {}).get("remove", []))
for item in sorted(mods):
    print(item)
PY
}
