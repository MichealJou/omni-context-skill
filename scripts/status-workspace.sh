#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

WORKSPACE_ROOT="${1:-$(pwd)}"
WORKSPACE_ROOT="$(cd "${WORKSPACE_ROOT}" && pwd)"
OMNI_ROOT="${WORKSPACE_ROOT}/.omnicontext"
language="$(omni_resolve_language "${WORKSPACE_ROOT}")"

if [[ ! -d "${OMNI_ROOT}" ]]; then
  case "${language}" in
    zh-CN) echo "在 ${WORKSPACE_ROOT} 中未找到 OmniContext" >&2 ;;
    ja) echo "${WORKSPACE_ROOT} に OmniContext が見つかりません" >&2 ;;
    *) echo "OmniContext not found in ${WORKSPACE_ROOT}" >&2 ;;
  esac
  exit 1
fi

workspace_toml="${OMNI_ROOT}/workspace.toml"
if [[ ! -f "${workspace_toml}" ]]; then
  case "${language}" in
    zh-CN) echo "缺少 ${workspace_toml}" >&2 ;;
    ja) echo "${workspace_toml} がありません" >&2 ;;
    *) echo "Missing ${workspace_toml}" >&2 ;;
  esac
  exit 1
fi

workspace_name="$(sed -n 's/^workspace_name = "\(.*\)"/\1/p' "${workspace_toml}")"
mode="$(sed -n 's/^mode = "\(.*\)"/\1/p' "${workspace_toml}")"

mapped_names=()
mapped_paths=()
while IFS='|' read -r name knowledge_path; do
  [[ -n "${name}" ]] || continue
  mapped_names+=("${name}")
  mapped_paths+=("${knowledge_path}")
done < <(
  awk '
    /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
      in_block=1
      name=""
      knowledge_path=""
      next
    }
    /^\[/ && $0 !~ /^\[\[project_mappings\]\]/ {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
      in_block=0
    }
    in_block && /^name = / {
      line=$0
      sub(/^name = "/, "", line)
      sub(/"$/, "", line)
      name=line
    }
    in_block && /^knowledge_path = / {
      line=$0
      sub(/^knowledge_path = "/, "", line)
      sub(/"$/, "", line)
      knowledge_path=line
    }
    END {
      if (in_block && name != "" && knowledge_path != "") print name "|" knowledge_path
    }
  ' "${workspace_toml}"
)

case "${language}" in
  zh-CN)
    echo "工作区: ${workspace_name}"
    echo "模式: ${mode}"
    echo "OmniContext 根目录: ${OMNI_ROOT}"
    ;;
  ja)
    echo "ワークスペース: ${workspace_name}"
    echo "モード: ${mode}"
    echo "OmniContext ルート: ${OMNI_ROOT}"
    ;;
  *)
    echo "Workspace: ${workspace_name}"
    echo "Mode: ${mode}"
    echo "OmniContext root: ${OMNI_ROOT}"
    ;;
esac

required_files=(
  "${OMNI_ROOT}/INDEX.md"
  "${OMNI_ROOT}/shared/standards.md"
  "${OMNI_ROOT}/shared/language-policy.md"
  "${OMNI_ROOT}/personal/preferences.md"
  "${OMNI_ROOT}/workspace.toml"
)

missing_required=0
echo
case "${language}" in
  zh-CN) echo "必需文件:" ;;
  ja) echo "必須ファイル:" ;;
  *) echo "Required files:" ;;
esac
for file in "${required_files[@]}"; do
  if [[ -f "${file}" ]]; then
    case "${language}" in
      zh-CN|ja) echo "- OK ${file#${WORKSPACE_ROOT}/}" ;;
      *) echo "- OK ${file#${WORKSPACE_ROOT}/}" ;;
    esac
  else
    case "${language}" in
      zh-CN) echo "- 缺失 ${file#${WORKSPACE_ROOT}/}" ;;
      ja) echo "- 不足 ${file#${WORKSPACE_ROOT}/}" ;;
      *) echo "- MISSING ${file#${WORKSPACE_ROOT}/}" ;;
    esac
    missing_required=1
  fi
done

echo
case "${language}" in
  zh-CN) echo "项目:" ;;
  ja) echo "プロジェクト:" ;;
  *) echo "Projects:" ;;
esac
project_dirs_found=0
for idx in "${!mapped_names[@]}"; do
  project_dirs_found=1
  project_name="${mapped_names[$idx]}"
  project_dir="${OMNI_ROOT}/${mapped_paths[$idx]}"
  echo "- ${project_name}"
  for doc in overview.md handoff.md todo.md decisions.md; do
    if [[ -f "${project_dir}/${doc}" ]]; then
      echo "  OK ${doc}"
    else
      case "${language}" in
        zh-CN) echo "  缺失 ${doc}" ;;
        ja) echo "  不足 ${doc}" ;;
        *) echo "  MISSING ${doc}" ;;
      esac
      missing_required=1
    fi
  done
done

if [[ "${project_dirs_found}" -eq 0 ]]; then
  case "${language}" in
    zh-CN) echo "- 未发现已映射项目" ;;
    ja) echo "- マッピング済みプロジェクトがありません" ;;
    *) echo "- No mapped projects found" ;;
  esac
  missing_required=1
fi

echo
case "${language}" in
  zh-CN) echo "workspace.toml 中的映射:" ;;
  ja) echo "workspace.toml のマッピング:" ;;
  *) echo "Mappings from workspace.toml:" ;;
esac
if [[ "${#mapped_names[@]}" -eq 0 ]]; then
  echo "- None"
else
  for name in "${mapped_names[@]}"; do
    echo "- ${name}"
  done
fi

echo
case "${language}" in
  zh-CN) echo "未映射的项目目录:" ;;
  ja) echo "未マッピングのプロジェクトディレクトリ:" ;;
  *) echo "Unmapped project directories:" ;;
esac
unmapped_found=0
while IFS= read -r -d '' project_dir; do
  rel_path="${project_dir#${OMNI_ROOT}/}"
  is_mapped=0
  for mapped_path in "${mapped_paths[@]}"; do
    if [[ "${rel_path}" == "${mapped_path}" ]]; then
      is_mapped=1
      break
    fi
  done
  if [[ "${is_mapped}" -eq 0 ]]; then
    unmapped_found=1
    echo "- ${rel_path}"
  fi
done < <(find "${OMNI_ROOT}/projects" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

if [[ "${unmapped_found}" -eq 0 ]]; then
  echo "- None"
fi

echo
if [[ "${missing_required}" -eq 0 ]]; then
  case "${language}" in
    zh-CN) echo "状态: OK" ;;
    ja) echo "ステータス: OK" ;;
    *) echo "Status: OK" ;;
  esac
else
  case "${language}" in
    zh-CN) echo "状态: INCOMPLETE" ;;
    ja) echo "ステータス: INCOMPLETE" ;;
    *) echo "Status: INCOMPLETE" ;;
  esac
  exit 2
fi
