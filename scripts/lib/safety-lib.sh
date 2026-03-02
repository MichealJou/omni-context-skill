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

omni_backup_extension_for_kind() {
  case "$1" in
    mysql|postgres) printf '%s\n' sql ;;
    redis) printf '%s\n' rdb ;;
    *) printf '%s\n' txt ;;
  esac
}

omni_backup_record_file() {
  local workspace_root="$1"
  local project_name="$2"
  printf '%s/.omnicontext/projects/%s/docs/runbook/backup-record.md\n' "${workspace_root}" "${project_name}"
}

omni_has_matching_backup_record() {
  local workspace_root="$1"
  local project_name="$2"
  local dependency_id="$3"
  local object_name="$4"
  local action_name="$5"
  local record_file
  record_file="$(omni_backup_record_file "${workspace_root}" "${project_name}")"
  [[ -f "${record_file}" ]] || return 1
  python3 - "$record_file" "$dependency_id" "$object_name" "$action_name" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text().splitlines()
dep, obj, act = sys.argv[2:5]
current = {}
for line in text:
    if line.startswith("## "):
        current = {}
    elif line.startswith("- dependency:"):
        current["dependency"] = line.split(":",1)[1].strip()
    elif line.startswith("- object:"):
        current["object"] = line.split(":",1)[1].strip()
    elif line.startswith("- action:"):
        current["action"] = line.split(":",1)[1].strip()
    elif line.startswith("- backup_path:"):
        current["backup_path"] = line.split(":",1)[1].strip()
        if current.get("dependency") == dep and current.get("object") == obj and current.get("action") == act and current.get("backup_path"):
            print(current["backup_path"])
            raise SystemExit(0)
raise SystemExit(1)
PY
}
