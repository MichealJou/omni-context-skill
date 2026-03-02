#!/usr/bin/env bash

omni_runtime_kinds() {
  printf '%s\n' mysql postgres redis browser miniapp mq service
}

omni_runtime_is_dangerous_db_op() {
  local op
  op="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  case "${op}" in
    DROP|TRUNCATE|DELETE|ALTER|UPDATE) return 0 ;;
    *) return 1 ;;
  esac
}

omni_runtime_is_dangerous_redis_op() {
  local op
  op="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  case "${op}" in
    DEL|UNLINK|FLUSHDB|FLUSHALL|MSET|EVAL) return 0 ;;
    *) return 1 ;;
  esac
}

omni_runtime_dep_field() {
  local runtime_file="$1"
  local dep_id="$2"
  local field="$3"
  python3 - "$runtime_file" "$dep_id" "$field" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
dep_id = sys.argv[2]
field = sys.argv[3]
for dep in data.get("dependencies", []):
    if dep.get("id") == dep_id:
        value = dep.get(field, "")
        if isinstance(value, bool):
            print("true" if value else "false")
        else:
            print(value)
        break
PY
}

omni_runtime_dep_exists() {
  local runtime_file="$1"
  local dep_id="$2"
  [[ -n "$(omni_runtime_dep_field "$runtime_file" "$dep_id" "id")" ]]
}

omni_runtime_client_for_kind() {
  case "$1" in
    mysql) printf '%s\n' mysqldump ;;
    postgres) printf '%s\n' pg_dump ;;
    redis) printf '%s\n' redis-cli ;;
    browser) printf '%s\n' open ;;
    miniapp) printf '%s\n' open ;;
    service) printf '%s\n' curl ;;
    mq) printf '%s\n' nc ;;
    *) printf '%s\n' '' ;;
  esac
}

omni_runtime_dependency_for_platform() {
  local runtime_file="$1"
  local platform="$2"
  python3 - "$runtime_file" "$platform" <<'PY'
import sys, tomllib
from pathlib import Path
runtime = tomllib.loads(Path(sys.argv[1]).read_text())
platform = sys.argv[2]
target_kind = {
    "web": "browser",
    "backend": "service",
    "miniapp": "miniapp",
}.get(platform, "")
for dep in runtime.get("dependencies", []):
    if dep.get("enabled") and dep.get("kind") == target_kind:
        print(dep.get("id", ""))
        break
PY
}

omni_runtime_dependency_url() {
  local runtime_file="$1"
  local dep_id="$2"
  python3 - "$runtime_file" "$dep_id" <<'PY'
import sys, tomllib
from pathlib import Path
runtime = tomllib.loads(Path(sys.argv[1]).read_text())
dep_id = sys.argv[2]
for dep in runtime.get("dependencies", []):
    if dep.get("id") == dep_id:
        print(dep.get("entry_url", "") or dep.get("url", ""))
        break
PY
}

omni_browser_executable() {
  local candidates=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
  )
  local path
  for path in "${candidates[@]}"; do
    if [[ -x "${path}" ]]; then
      printf '%s\n' "${path}"
      return 0
    fi
  done
  return 1
}
