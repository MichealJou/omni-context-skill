#!/usr/bin/env bash

omni_backup_filename() {
  local project_name="$1"
  local environment="$2"
  local object="$3"
  local action="$4"
  local ext="${5:-txt}"
  printf '%s-%s-%s-%s-%s.%s\n' "$(date +%Y%m%d)" "${project_name}" "${environment}" "${object// /_}" "${action// /_}" "${ext}"
}

omni_is_prod_env() {
  [[ "$1" == "prod" ]]
}
