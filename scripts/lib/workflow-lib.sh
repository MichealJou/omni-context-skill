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

omni_workflow_title() {
  local lifecycle_file="$1"
  omni_workflow_status_value "${lifecycle_file}" "title"
}

omni_workflow_next_stage() {
  case "$1" in
    intake) printf 'clarification\n' ;;
    clarification) printf 'design\n' ;;
    design) printf 'delivery\n' ;;
    delivery) printf 'testing\n' ;;
    testing) printf 'acceptance\n' ;;
    *) printf '\n' ;;
  esac
}

omni_autopilot_state_path() {
  local workflow_dir="$1"
  printf '%s\n' "${workflow_dir}/autopilot-state.toml"
}

omni_autopilot_write_state() {
  local file="$1"
  local status="$2"
  local stage="$3"
  local last_action="$4"
  local blocker="$5"
  local next_step="$6"
  cat > "${file}" <<EOF
status = "${status}"
stage = "${stage}"
last_action = "${last_action}"
blocker = "${blocker}"
next_step = "${next_step}"
updated_at = "$(date +%F)"
EOF
}

omni_sync_workflow_registry() {
  local workspace_root="$1"
  local project_name="$2"
  local workflow_id="$3"
  local lifecycle_file="$4"
  local registry="${workspace_root}/.omnicontext/shared/workflows/registry.toml"
  [[ -f "${registry}" ]] || return 0
  python3 - "$registry" "$lifecycle_file" "$project_name" "$workflow_id" <<'PY'
import sys, tomllib
from pathlib import Path
registry = Path(sys.argv[1])
lifecycle = tomllib.loads(Path(sys.argv[2]).read_text())
project_name = sys.argv[3]
workflow_id = sys.argv[4]
status = lifecycle.get("status", "")
current_stage = lifecycle.get("current_stage", "")
language = lifecycle.get("language", "")
title = lifecycle.get("title", "")
path_value = f"projects/{project_name}/workflows/{workflow_id}"
lines = registry.read_text().splitlines()
blocks, current = [], []
for line in lines:
    if line.strip() == "[[workflows]]":
        if current:
            blocks.append(current)
        current = [line]
    else:
        current.append(line)
if current:
    blocks.append(current)
updated = False
new_blocks = []
for block in blocks:
    text = "\n".join(block)
    if f'workflow_id = "{workflow_id}"' in text:
        new_blocks.append([
            "[[workflows]]",
            f'workflow_id = "{workflow_id}"',
            f'project_name = "{project_name}"',
            f'title = "{title}"',
            f'status = "{status}"',
            f'current_stage = "{current_stage}"',
            f'language = "{language}"',
            f'path = "{path_value}"',
        ])
        updated = True
    elif text.strip():
        new_blocks.append(block)
if not updated:
    new_blocks.append([
        "[[workflows]]",
        f'workflow_id = "{workflow_id}"',
        f'project_name = "{project_name}"',
        f'title = "{title}"',
        f'status = "{status}"',
        f'current_stage = "{current_stage}"',
        f'language = "{language}"',
        f'path = "{path_value}"',
    ])
out = []
for idx, block in enumerate(new_blocks):
    if idx:
      out.append("")
    out.extend(block)
registry.write_text("\n".join(out).strip() + "\n")
PY
}

omni_append_handoff_stage_update() {
  local project_dir="$1"
  local stage="$2"
  local message="$3"
  local handoff="${project_dir}/handoff.md"
  [[ -f "${handoff}" ]] || return 0
  if rg -q "^## Workflow Updates$" "${handoff}" 2>/dev/null; then
    printf '\n- %s: %s\n' "${stage}" "${message}" >> "${handoff}"
  else
    printf '\n## Workflow Updates\n\n- %s: %s\n' "${stage}" "${message}" >> "${handoff}"
  fi
}

omni_autopilot_primary_platform() {
  local project_dir="$1"
  local platforms="${project_dir}/standards/testing-platforms.toml"
  [[ -f "${platforms}" ]] || return 0
  python3 - "$platforms" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text())
for item in data.get("platforms", []):
    if item.get("enabled"):
        print(item.get("id", ""))
        break
PY
}

omni_autopilot_prepare_testing_assets() {
  local workspace_root="$1"
  local project_name="$2"
  local workflow_id="$3"
  local project_dir="${workspace_root}/.omnicontext/projects/${project_name}"
  local tests_dir="${project_dir}/tests"
  local suite_count=0
  if [[ -d "${tests_dir}/suites" ]]; then
    suite_count="$(find "${tests_dir}/suites" -type f -name '*.md' | wc -l | tr -d ' ')"
  fi
  if [[ "${suite_count}" != "0" ]]; then
    local effective_suite=""
    effective_suite="$(find "${tests_dir}/suites" -type f -name '*.md' | sort | tail -n 1 || true)"
    local latest_run=""
    latest_run="$(find "${tests_dir}/runs" -type f -name '*.md' 2>/dev/null | sort | tail -n 1 || true)"
    if [[ -n "${effective_suite}" ]] && [[ -z "${latest_run}" ]]; then
      local source_status platform mode
      source_status="$(omni_test_suite_source_status "${effective_suite}")"
      if omni_test_effective_status_allowed "${source_status}"; then
        platform="$(omni_test_suite_platform "${effective_suite}")"
        local runner
        runner="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        case "${platform}" in
          backend)
            "${runner}/run-api-suite.sh" "${workspace_root}" "${project_name}" "$(basename "${effective_suite}" .md)" --platform backend >/dev/null 2>&1 || true
            ;;
          miniapp)
            "${runner}/collect-test-evidence.sh" "${workspace_root}" "${project_name}" "$(basename "${effective_suite}" .md)" --platform miniapp >/dev/null 2>&1 || true
            ;;
          *)
            "${runner}/collect-test-evidence.sh" "${workspace_root}" "${project_name}" "$(basename "${effective_suite}" .md)" --platform web >/dev/null 2>&1 || true
            ;;
        esac
      fi
    fi
    return 0
  fi
  local title="${workflow_id} smoke tests"
  local suite_id="${workflow_id}-smoke"
  "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/init-test-suite.sh" "${workspace_root}" "${project_name}" "${title}" "${suite_id}" >/dev/null
  local suite_file="${tests_dir}/suites/${suite_id}.md"
  local platform
  platform="$(omni_autopilot_primary_platform "${project_dir}")"
  python3 - "$suite_file" "$platform" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
platform = sys.argv[2]
text = path.read_text()
text = text.replace("- platform:", f"- platform: {platform}")
text = text.replace("- execution_target:", "- execution_target: autopilot-generated")
text = text.replace("- interaction_requirement:", "- interaction_requirement: confirm-before-formal-testing")
text = text.replace("- [required] ", "- [required] Confirm formal required test case with user")
text = text.replace("- [optional] ", "- [optional] Add exploratory coverage notes")
path.write_text(text)
PY
}

omni_autofill_stage_doc() {
  local project_dir="$1"
  local workflow_dir="$2"
  local lifecycle_file="$3"
  local stage="$4"
  local doc
  doc="$(omni_stage_doc_path "${workflow_dir}" "${stage}")"
  local owner status title overview handoff decisions tests_index suite_file run_file
  owner="$(omni_workflow_status_value "${lifecycle_file}" "stages.${stage}.owner")"
  status="$(omni_workflow_status_value "${lifecycle_file}" "stages.${stage}.status")"
  title="$(omni_workflow_title "${lifecycle_file}")"
  overview="${project_dir}/overview.md"
  handoff="${project_dir}/handoff.md"
  decisions="${project_dir}/decisions.md"
  tests_index="${project_dir}/tests/index.md"
  suite_file="$(find "${project_dir}/tests/suites" -type f -name '*.md' 2>/dev/null | sort | tail -n 1 || true)"
  run_file="$(find "${project_dir}/tests/runs" -type f -name '*.md' 2>/dev/null | sort | tail -n 1 || true)"
  python3 - "$doc" "$stage" "$status" "$owner" "$title" "$overview" "$handoff" "$decisions" "$tests_index" "$suite_file" "$run_file" <<'PY'
import sys
from pathlib import Path
doc = Path(sys.argv[1])
stage, status, owner, title = sys.argv[2:6]
overview, handoff, decisions, tests_index, suite_file, run_file = map(Path, sys.argv[6:12])
text = doc.read_text()
summary_map = {
    "intake": f"Capture the request context and target outcome for {title}.",
    "clarification": f"Turn the intake into scoped and testable work for {title}.",
    "design": f"Document the implementation and risk shape for {title}.",
    "delivery": f"Track implementation scope and impact points for {title}.",
    "testing": f"Validate {title} against required cases and platform coverage.",
    "acceptance": f"Record the final acceptance conclusion for {title}.",
}
inputs = []
for candidate, label in [(overview, "overview"), (handoff, "handoff"), (decisions, "decisions"), (tests_index, "tests")]:
    if candidate.exists():
        inputs.append(f"- source: {label} ({candidate.name})")
if stage == "testing":
    if suite_file and suite_file.exists():
        inputs.append(f"- suite: {suite_file.name}")
    if str(run_file) not in ("", ".") and run_file.exists():
        inputs.append(f"- run: {run_file.name}")
risks = {
    "intake": "- risk: request context may still be incomplete",
    "clarification": "- risk: scope may still contain ambiguity",
    "design": "- risk: implementation constraints may still need confirmation",
    "delivery": "- risk: code changes may affect adjacent modules",
    "testing": "- risk: formal evidence may still be incomplete if required cases are pending",
    "acceptance": "- risk: residual follow-up items may remain after acceptance",
}
notes = {
    "intake": "- note: autopilot summarized workspace context into this stage",
    "clarification": "- note: autopilot converted current context into execution-oriented scope",
    "design": "- note: autopilot prepared a design-stage placeholder summary from existing docs",
    "delivery": "- note: autopilot prepared a delivery-stage summary from current project context",
    "testing": "- note: autopilot linked available suite and run evidence when present",
    "acceptance": "- note: autopilot prepared acceptance summary placeholders from current workflow state",
}
exit_line = {
    "intake": "- intake context captured and ready for clarification",
    "clarification": "- scope and acceptance direction captured",
    "design": "- design risks and implementation direction captured",
    "delivery": "- implementation impact and checkpoints recorded",
    "testing": "- required evidence and execution status reviewed",
    "acceptance": "- acceptance conclusion and residual risk reviewed",
}
autopilot = [
    "## Autopilot Summary",
    "",
    f"- stage: {stage}",
    f"- owner: {owner}",
    f"- status: {status}",
    f"- goal: {summary_map.get(stage, title)}",
]
if suite_file and suite_file.exists():
    autopilot.append(f"- latest_suite: {suite_file.name}")
if str(run_file) not in ("", ".") and run_file.exists():
    autopilot.append(f"- latest_run: {run_file.name}")
block = "\n".join(autopilot)
if "## Autopilot Summary" in text:
    text = text.split("## Autopilot Summary")[0].rstrip() + "\n\n" + block + "\n"
else:
    text = text.rstrip() + "\n\n" + block + "\n"
text = text.replace("- status:", f"- status: {status}", 1)
text = text.replace("- owner:", f"- owner: {owner}", 1)
text = text.replace("- notes:", f"- notes: autopilot updated this stage summary", 1)
def replace_section(src, heading, body_lines):
    marker = f"{heading}\n\n"
    if marker in src:
        start = src.index(marker) + len(marker)
        rest = src[start:]
        next_idx = rest.find("\n## ")
        end = start + next_idx if next_idx != -1 else len(src)
        return src[:start] + "\n".join(body_lines).rstrip() + "\n" + src[end:]
    return src
text = replace_section(text, "## Goal", [f"- {summary_map.get(stage, title)}"])
text = replace_section(text, "## Inputs", inputs or ["- source: no project inputs found yet"])
text = replace_section(text, "## Decisions / Notes", [notes.get(stage, "- note: autopilot prepared this stage")])
text = replace_section(text, "## Checklist", ["- [x] autopilot stage summary prepared"])
text = replace_section(text, "## Risks", [risks.get(stage, "- risk: stage still needs review")])
text = replace_section(text, "## Exit Criteria", [exit_line.get(stage, "- stage summary prepared")])
text = replace_section(text, "## Status Record", [
    f"- status: {status}",
    f"- owner: {owner}",
    "- notes: autopilot updated this stage summary",
])
doc.write_text(text)
PY
}
