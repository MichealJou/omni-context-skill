#!/usr/bin/env bash

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
