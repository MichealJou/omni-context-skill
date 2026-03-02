#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
WORKSPACE_TOML="${OMNI_ROOT}/workspace.toml"
INDEX_FILE="${OMNI_ROOT}/INDEX.md"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

if [[ ! -f "${WORKSPACE_TOML}" ]]; then
  echo "Missing ${WORKSPACE_TOML}" >&2
  exit 1
fi

workspace_name="$(sed -n 's/^workspace_name = "\(.*\)"/\1/p' "${WORKSPACE_TOML}")"
current_mode="$(sed -n 's/^mode = "\(.*\)"/\1/p' "${WORKSPACE_TOML}")"

discovered_projects=()
while IFS= read -r project_path; do
  case "${project_path}" in
    .omnicontext|.omnicontext/*|.local-tools|.local-tools/*)
      continue
      ;;
  esac
  discovered_projects+=("${project_path}")
done < <(
  find "${WORKSPACE_ROOT}" -mindepth 1 -maxdepth 3 -type d -name .git -prune \
    | sed "s#${WORKSPACE_ROOT}/##" \
    | sed 's#/.git$##' \
    | sort -u
)

if [[ "${#discovered_projects[@]}" -eq 0 ]]; then
  discovered_projects=("$(basename "${WORKSPACE_ROOT}")")
fi

mapped_names=()
mapped_source_paths=()
while IFS='|' read -r name source_path; do
  [[ -n "${name}" ]] || continue
  mapped_names+=("${name}")
  mapped_source_paths+=("${source_path}")
done < <(
  awk '
    /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && source_path != "") print name "|" source_path
      in_block=1
      name=""
      source_path=""
      next
    }
    /^\[/ && $0 !~ /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && source_path != "") print name "|" source_path
      in_block=0
    }
    in_block && /^name = / {
      line=$0
      sub(/^name = "/, "", line)
      sub(/"$/, "", line)
      name=line
    }
    in_block && /^source_path = / {
      line=$0
      sub(/^source_path = "/, "", line)
      sub(/"$/, "", line)
      source_path=line
    }
    END {
      if (in_block && name != "" && source_path != "") print name "|" source_path
    }
  ' "${WORKSPACE_TOML}"
)

desired_count="${#discovered_projects[@]}"
if [[ "${#mapped_names[@]}" -gt "${desired_count}" ]]; then
  desired_count="${#mapped_names[@]}"
fi

if [[ "${desired_count}" -le 1 ]]; then
  desired_mode="single"
else
  desired_mode="multi"
fi

if [[ "${current_mode}" != "${desired_mode}" ]]; then
  python3 - "${WORKSPACE_TOML}" "${desired_mode}" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
mode = sys.argv[2]
text = path.read_text()
old = None
for line in text.splitlines():
    if line.startswith("mode = "):
        old = line
        break
if old is None:
    raise SystemExit("mode field not found")
path.write_text(text.replace(old, f'mode = "{mode}"', 1))
PY
fi

added_projects=()
for project_path in "${discovered_projects[@]}"; do
  mapped=0
  for existing_path in "${mapped_source_paths[@]}"; do
    if [[ "${existing_path}" == "${project_path}" ]]; then
      mapped=1
      break
    fi
  done

  if [[ "${mapped}" -eq 0 ]]; then
    project_name="$(basename "${project_path}")"
    cat >> "${WORKSPACE_TOML}" <<EOF

[[project_mappings]]
name = "${project_name}"
source_path = "${project_path}"
knowledge_path = "projects/${project_name}"
type = "project"
EOF
    mapped_names+=("${project_name}")
    mapped_source_paths+=("${project_path}")
    added_projects+=("${project_name}|${project_path}")
  fi
done

ensure_project_docs() {
  local project_name="$1"
  local project_dir="${OMNI_ROOT}/projects/${project_name}"
  mkdir -p "${project_dir}"
  local handoff_status=""
  local handoff_recent=""
  local handoff_next=""
  local decision_context=""
  local decision_text=""
  local decision_rationale=""
  local decision_consequence=""
  case "${language}" in
    zh-CN)
      handoff_status='由 OmniContext sync 初始化'
      handoff_recent='sync 自动补齐了项目记录'
      handoff_next='补充项目目标和关键入口'
      decision_context='OmniContext sync 补齐了缺失的项目记录。'
      decision_text='先采用最小文档集。'
      decision_rationale='在流程证明有效之前，先控制维护成本。'
      decision_consequence='仅在真实需求出现后再增加文档类型。'
      ;;
    ja)
      handoff_status='OmniContext sync により初期化'
      handoff_recent='sync が不足していたプロジェクト記録を作成した'
      handoff_next='プロジェクトの目的と主要エントリーポイントを補完する'
      decision_context='OmniContext sync が不足していたプロジェクト記録を作成した。'
      decision_text='最小限の文書セットから開始する。'
      decision_rationale='ワークフローの有効性が確認できるまで保守コストを抑えるため。'
      decision_consequence='実際の必要性が出てから文書種別を追加する。'
      ;;
    *)
      handoff_status='Initialized by OmniContext sync'
      handoff_recent='OmniContext project records were created by sync'
      handoff_next='Fill in project purpose and entry points'
      decision_context='OmniContext sync created missing project records.'
      decision_text='Start with the minimum document set.'
      decision_rationale='Keep maintenance cost low until the workflow proves useful.'
      decision_consequence='Add more document types only when real use requires them.'
      ;;
  esac

  if [[ ! -f "${project_dir}/overview.md" ]]; then
    omni_write_overview "${project_dir}/overview.md" "${language}" "${project_name}"
  fi

  if [[ ! -f "${project_dir}/handoff.md" ]]; then
    omni_write_handoff \
      "${project_dir}/handoff.md" \
      "${language}" \
      "${handoff_status}" \
      "${handoff_recent}" \
      "${handoff_next}"
  fi

  if [[ ! -f "${project_dir}/todo.md" ]]; then
    omni_write_todo "${project_dir}/todo.md" "${language}"
  fi

  if [[ ! -f "${project_dir}/decisions.md" ]]; then
    omni_write_decisions \
      "${project_dir}/decisions.md" \
      "${language}" \
      "OmniContext sync initialization" \
      "${decision_context}" \
      "${decision_text}" \
      "${decision_rationale}" \
      "${decision_consequence}"
  fi
}

for project_name in "${mapped_names[@]}"; do
  ensure_project_docs "${project_name}"
done

omni_write_workspace_index_header "${INDEX_FILE}" "${language}" "${workspace_name}" "${desired_mode}"

if [[ -f "${OMNI_ROOT}/shared/docs/index.md" ]]; then
  omni_append_workspace_index_shared_docs "${INDEX_FILE}" "${language}"
fi
omni_append_workspace_index_personal_header "${INDEX_FILE}" "${language}"

for idx in "${!mapped_names[@]}"; do
  project_name="${mapped_names[$idx]}"
  project_path="${mapped_source_paths[$idx]}"
  include_managed_docs=0
  if [[ -d "${OMNI_ROOT}/projects/${project_name}/docs" ]]; then
    include_managed_docs=1
  fi
  omni_append_workspace_index_project "${INDEX_FILE}" "${language}" "${project_name}" "${project_path}" "${include_managed_docs}"
done
omni_append_workspace_index_notes "${INDEX_FILE}" "${language}"

case "${language}" in
  zh-CN)
    echo "已同步 ${OMNI_ROOT} 下的 OmniContext"
    echo "模式: ${desired_mode}"
    ;;
  ja)
    echo "${OMNI_ROOT} の OmniContext を同期しました"
    echo "モード: ${desired_mode}"
    ;;
  *)
    echo "Synced OmniContext at ${OMNI_ROOT}"
    echo "Mode: ${desired_mode}"
    ;;
esac
if [[ "${#added_projects[@]}" -gt 0 ]]; then
  case "${language}" in
    zh-CN) echo "新增项目映射:" ;;
    ja) echo "追加されたプロジェクトマッピング:" ;;
    *) echo "Added project mappings:" ;;
  esac
  for item in "${added_projects[@]}"; do
    name="${item%%|*}"
    path="${item#*|}"
    echo "- ${name} (${path})"
  done
else
  case "${language}" in
    zh-CN) echo "新增项目映射:" ;;
    ja) echo "追加されたプロジェクトマッピング:" ;;
    *) echo "Added project mappings:" ;;
  esac
  echo "- None"
fi

stale_mappings=0
case "${language}" in
  zh-CN) echo "映射项目缺失的源路径:" ;;
  ja) echo "マッピング済みプロジェクトで欠落しているソースパス:" ;;
  *) echo "Missing source paths for mapped projects:" ;;
esac
for idx in "${!mapped_names[@]}"; do
  project_name="${mapped_names[$idx]}"
  project_path="${mapped_source_paths[$idx]}"
  if [[ ! -d "${WORKSPACE_ROOT}/${project_path}" ]]; then
    stale_mappings=1
    echo "- ${project_name} (${project_path})"
  fi
done
if [[ "${stale_mappings}" -eq 0 ]]; then
  echo "- None"
fi
