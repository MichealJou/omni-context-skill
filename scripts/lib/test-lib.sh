#!/usr/bin/env bash

omni_test_suite_fingerprint() {
  local file="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  else
    python3 - "$file" <<'PY'
import hashlib, sys
from pathlib import Path
print(hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PY
  fi
}

omni_test_case_statuses() {
  printf '%s\n' draft confirmed external_locked ad_hoc_user
}

omni_test_case_precedence() {
  printf '%s\n' ad_hoc_user confirmed external_locked draft
}

omni_test_effective_status_allowed() {
  case "$1" in
    ad_hoc_user|confirmed|external_locked) return 0 ;;
    *) return 1 ;;
  esac
}

omni_test_required_count() {
  rg -c '^\- \[required\]' "$1" 2>/dev/null || true
}

omni_test_required_pass_count() {
  rg -c '^\- \[required-pass\]' "$1" 2>/dev/null || true
}

omni_test_optional_pass_count() {
  rg -c '^\- \[optional-pass\]' "$1" 2>/dev/null || true
}

omni_test_suite_source_status() {
  rg -o '^\-\s+source_status:\s+.+$' "$1" 2>/dev/null | sed 's/^- source_status: //; s/^\-\s\+source_status:\s\+//'
}

omni_test_suite_platform() {
  rg -o '^\-\s+platform:\s+.+$' "$1" 2>/dev/null | sed 's/^- platform: //; s/^\-\s\+platform:\s\+//'
}

omni_test_run_field() {
  local file="$1"
  local field="$2"
  rg -o "^\-\s+${field}:\s+.+$" "$file" 2>/dev/null | sed "s/^- ${field}: //; s/^-\s\+${field}:\s\+//"
}
