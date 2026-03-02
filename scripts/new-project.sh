#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

usage() {
  cat <<'EOF'
Usage:
  new-project.sh <workspace-root> <project-name> <source-path>

Example:
  new-project.sh /path/to/workspace my-app apps/my-app
EOF
}

if [[ "${#}" -lt 3 ]]; then
  usage >&2
  exit 1
fi

WORKSPACE_ROOT="$(cd "${1}" && pwd)"
PROJECT_NAME="${2}"
SOURCE_PATH="${3}"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
WORKSPACE_TOML="${OMNI_ROOT}/workspace.toml"
PROJECT_DIR="${OMNI_ROOT}/projects/${PROJECT_NAME}"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

if [[ ! -f "${WORKSPACE_TOML}" ]]; then
  echo "Missing ${WORKSPACE_TOML}" >&2
  exit 1
fi

if [[ ! -d "${WORKSPACE_ROOT}/${SOURCE_PATH}" ]]; then
  echo "Source path does not exist: ${WORKSPACE_ROOT}/${SOURCE_PATH}" >&2
  exit 1
fi

if ! [[ "${PROJECT_NAME}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Project name must use letters, digits, dot, underscore, or hyphen" >&2
  exit 1
fi

if sed -n 's/^name = "\(.*\)"/\1/p' "${WORKSPACE_TOML}" | grep -Fxq "${PROJECT_NAME}"; then
  echo "Project mapping already exists for ${PROJECT_NAME}" >&2
  exit 1
fi

mkdir -p "${PROJECT_DIR}"

cat >> "${WORKSPACE_TOML}" <<EOF

[[project_mappings]]
name = "${PROJECT_NAME}"
source_path = "${SOURCE_PATH}"
knowledge_path = "projects/${PROJECT_NAME}"
type = "project"
EOF

case "${language}" in
  zh-CN)
    handoff_status='由 OmniContext new-project 创建'
    handoff_recent='new-project 显式创建了项目记录'
    handoff_next='补充项目目标和关键入口'
    decision_context='一个新项目被显式注册到 OmniContext。'
    decision_text='先采用最小文档集。'
    decision_rationale='在流程证明有效之前，先控制维护成本。'
    decision_consequence='仅在真实需求出现后再增加文档类型。'
    ;;
  ja)
    handoff_status='OmniContext new-project により追加'
    handoff_recent='new-project がプロジェクト記録を明示的に作成した'
    handoff_next='プロジェクトの目的と主要エントリーポイントを補完する'
    decision_context='新しいプロジェクトが OmniContext に明示的に登録された。'
    decision_text='最小限の文書セットから開始する。'
    decision_rationale='ワークフローの有効性が確認できるまで保守コストを抑えるため。'
    decision_consequence='実際の必要性が出てから文書種別を追加する。'
    ;;
  *)
    handoff_status='Project added by OmniContext new-project'
    handoff_recent='OmniContext project records were created explicitly by new-project'
    handoff_next='Fill in project purpose and entry points'
    decision_context='A new project was registered explicitly in OmniContext.'
    decision_text='Start with the minimum document set.'
    decision_rationale='Keep maintenance cost low until the workflow proves useful.'
    decision_consequence='Add more document types only when real use requires them.'
    ;;
esac

omni_write_overview "${PROJECT_DIR}/overview.md" "${language}" "${PROJECT_NAME}"
omni_write_handoff \
  "${PROJECT_DIR}/handoff.md" \
  "${language}" \
  "${handoff_status}" \
  "${handoff_recent}" \
  "${handoff_next}"
omni_write_todo "${PROJECT_DIR}/todo.md" "${language}"
omni_write_decisions \
  "${PROJECT_DIR}/decisions.md" \
  "${language}" \
  "OmniContext new-project initialization" \
  "${decision_context}" \
  "${decision_text}" \
  "${decision_rationale}" \
  "${decision_consequence}"

"${SCRIPT_DIR}/sync-workspace.sh" "${WORKSPACE_ROOT}" >/dev/null

case "${language}" in
  zh-CN)
    echo "已将项目加入 OmniContext"
    echo "- 名称: ${PROJECT_NAME}"
    echo "- 源路径: ${SOURCE_PATH}"
    echo "- 知识路径: .omnicontext/projects/${PROJECT_NAME}"
    ;;
  ja)
    echo "プロジェクトを OmniContext に追加しました"
    echo "- 名前: ${PROJECT_NAME}"
    echo "- ソースパス: ${SOURCE_PATH}"
    echo "- ナレッジパス: .omnicontext/projects/${PROJECT_NAME}"
    ;;
  *)
    echo "Added project to OmniContext"
    echo "- Name: ${PROJECT_NAME}"
    echo "- Source path: ${SOURCE_PATH}"
    echo "- Knowledge path: .omnicontext/projects/${PROJECT_NAME}"
    ;;
esac
