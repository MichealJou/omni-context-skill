#!/usr/bin/env bash

omni_workflow_stages() {
  printf '%s\n' intake clarification design delivery testing acceptance
}

omni_stage_number() {
  case "$1" in
    intake) printf '01' ;;
    clarification) printf '02' ;;
    design) printf '03' ;;
    delivery) printf '04' ;;
    testing) printf '05' ;;
    acceptance) printf '06' ;;
    *) return 1 ;;
  esac
}

omni_stage_owner_default() {
  local project_dir="$1"
  local stage="$2"
  local roles_file="${project_dir}/standards/roles.toml"
  local owner=""
  if [[ -f "${roles_file}" ]]; then
    owner="$(python3 - "$roles_file" "$stage" <<'PY'
import sys, tomllib
from pathlib import Path
path = Path(sys.argv[1])
stage = sys.argv[2]
data = tomllib.loads(path.read_text())
print(data.get("stage_owners", {}).get(stage, ""))
PY
)"
  fi
  if [[ -n "${owner}" ]]; then
    printf '%s\n' "${owner}"
    return
  fi
  case "${stage}" in
    intake|clarification) printf 'product\n' ;;
    design) printf 'architecture\n' ;;
    delivery) printf 'development\n' ;;
    testing) printf 'testing\n' ;;
    acceptance) printf 'product\n' ;;
    *) printf 'coordinator\n' ;;
  esac
}

omni_workflow_dir() {
  local project_dir="$1"
  local workflow_id="$2"
  printf '%s\n' "${project_dir}/workflows/${workflow_id}"
}

omni_current_workflow_id() {
  local project_dir="$1"
  local file="${project_dir}/workflows/current.toml"
  if [[ -f "${file}" ]]; then
    python3 - "$file" <<'PY'
import sys, tomllib
from pathlib import Path
path = Path(sys.argv[1])
data = tomllib.loads(path.read_text())
print(data.get("active_workflow_id", ""))
PY
  fi
}

omni_stage_doc_path() {
  local workflow_dir="$1"
  local stage="$2"
  local num
  num="$(omni_stage_number "${stage}")"
  printf '%s\n' "${workflow_dir}/${num}-${stage}.md"
}

omni_write_workflow_current() {
  local file="$1"
  local workflow_id="$2"
  cat > "${file}" <<EOF
active_workflow_id = "${workflow_id}"
EOF
}

omni_write_workflow_lifecycle() {
  local file="$1"
  local workflow_id="$2"
  local project_name="$3"
  local title="$4"
  local language="$5"
  local created_at
  created_at="$(date +%F)"
  cat > "${file}" <<EOF
version = 1
workflow_id = "${workflow_id}"
project_name = "${project_name}"
title = "${title}"
language = "${language}"
status = "in_progress"
current_stage = "intake"
created_at = "${created_at}"
updated_at = "${created_at}"

[stages.intake]
status = "in_progress"
owner = "product"
updated_at = "${created_at}"

[stages.clarification]
status = "not_started"
owner = "product"

[stages.design]
status = "not_started"
owner = "architecture"

[stages.delivery]
status = "not_started"
owner = "development"

[stages.testing]
status = "not_started"
owner = "testing"

[stages.acceptance]
status = "not_started"
owner = "product"
EOF
}

omni_update_workflow_stage_owner() {
  local lifecycle_file="$1"
  local stage="$2"
  local owner="$3"
  python3 - "$lifecycle_file" "$stage" "$owner" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
stage = sys.argv[2]
owner = sys.argv[3]
lines = path.read_text().splitlines()
target = f"[stages.{stage}]"
for i, line in enumerate(lines):
    if line.strip() == target:
        for j in range(i + 1, min(i + 5, len(lines))):
            if lines[j].startswith("owner = "):
                lines[j] = f'owner = "{owner}"'
                path.write_text("\n".join(lines) + "\n")
                raise SystemExit(0)
path.write_text("\n".join(lines) + "\n")
PY
}

omni_workflow_status_value() {
  local lifecycle_file="$1"
  local dotted="$2"
  python3 - "$lifecycle_file" "$dotted" <<'PY'
import sys, tomllib
from pathlib import Path
path = Path(sys.argv[1])
keys = sys.argv[2].split(".")
data = tomllib.loads(path.read_text())
cur = data
for key in keys:
    cur = cur.get(key, {})
if isinstance(cur, dict):
    print("")
else:
    print(cur)
PY
}

omni_set_workflow_value() {
  local lifecycle_file="$1"
  local dotted="$2"
  local value="$3"
  python3 - "$lifecycle_file" "$dotted" "$value" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
dotted = sys.argv[2]
value = sys.argv[3]
lines = path.read_text().splitlines()
parts = dotted.split(".")
if len(parts) == 1:
    key = parts[0]
    for i, line in enumerate(lines):
      if line.startswith(f"{key} = "):
        lines[i] = f'{key} = "{value}"'
        break
elif len(parts) == 3 and parts[0] == "stages":
    target = f"[stages.{parts[1]}]"
    key = parts[2]
    for i, line in enumerate(lines):
        if line.strip() == target:
            inserted = False
            for j in range(i + 1, len(lines)):
                if lines[j].startswith("[") and j > i + 1:
                    lines.insert(j, f'{key} = "{value}"')
                    inserted = True
                    break
                if lines[j].startswith(f"{key} = "):
                    lines[j] = f'{key} = "{value}"'
                    inserted = True
                    break
            if not inserted:
                lines.append(f'{key} = "{value}"')
            break
path.write_text("\n".join(lines) + "\n")
PY
}

omni_update_workflow_timestamps() {
  local lifecycle_file="$1"
  local stage="$2"
  local now
  now="$(date +%F)"
  omni_set_workflow_value "${lifecycle_file}" "updated_at" "${now}"
  omni_set_workflow_value "${lifecycle_file}" "stages.${stage}.updated_at" "${now}"
}

omni_write_stage_doc() {
  local file="$1"
  local language="$2"
  local stage="$3"
  local title="$4"
  case "${language}" in
    zh-CN)
      cat > "${file}" <<EOF
# ${title}

## Goal

- 

## Inputs

- 

## Decisions / Notes

- 

## Checklist

- [ ] 

## Risks

- 

## Exit Criteria

- 

## Status Record

- status:
- owner:
- notes:
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# ${title}

## Goal

- 

## Inputs

- 

## Decisions / Notes

- 

## Checklist

- [ ] 

## Risks

- 

## Exit Criteria

- 

## Status Record

- status:
- owner:
- notes:
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# ${title}

## Goal

- 

## Inputs

- 

## Decisions / Notes

- 

## Checklist

- [ ] 

## Risks

- 

## Exit Criteria

- 

## Status Record

- status:
- owner:
- notes:
EOF
      ;;
  esac
}

omni_workflow_required_headings() {
  printf '%s\n' "## Goal" "## Inputs" "## Decisions / Notes" "## Checklist" "## Risks" "## Exit Criteria" "## Status Record"
}
