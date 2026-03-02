#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

language="$(omni_normalize_language "${OMNI_CONTEXT_LANGUAGE:-zh-CN}")"

required_scripts=(
  "scripts/omni-context"
  "scripts/install-skill.sh"
  "scripts/init-workspace.sh"
  "scripts/sync-workspace.sh"
  "scripts/status-workspace.sh"
  "scripts/new-project.sh"
  "scripts/new-doc.sh"
  "scripts/check-skill.sh"
  "scripts/git-finish.sh"
  "scripts/lib/omnicontext-l10n.sh"
)

required_templates=(
  "templates/workspace.toml"
  "templates/INDEX.md"
  "templates/overview.md"
  "templates/handoff.md"
  "templates/todo.md"
  "templates/decisions.md"
  "templates/shared-standards.md"
  "templates/shared-language-policy.md"
  "templates/personal-preferences.md"
  "templates/machine.local.toml"
  "templates/user.local.toml"
  "templates/codex-AGENTS.md"
  "templates/claude-CLAUDE.md"
  "templates/trae-TRAE.md"
  "templates/qoder-QODER.md"
)

required_reference_dirs=(
  "references/zh-CN"
  "references/en"
  "references/ja"
)

say() {
  case "${language}" in
    zh-CN) printf '%s\n' "$1" ;;
    ja) printf '%s\n' "$2" ;;
    *) printf '%s\n' "$3" ;;
  esac
}

report_missing() {
  local path="$1"
  case "${language}" in
    zh-CN) printf -- '- 缺失 %s\n' "${path}" ;;
    ja) printf -- '- 不足 %s\n' "${path}" ;;
    *) printf -- '- MISSING %s\n' "${path}" ;;
  esac
}

report_ok() {
  local path="$1"
  printf -- '- OK %s\n' "${path}"
}

status=0

say "OmniContext 技能校验" "OmniContext スキル検証" "OmniContext Skill Check"
say "检查核心脚本：" "主要スクリプトを確認:" "Checking core scripts:"
for path in "${required_scripts[@]}"; do
  if [[ -e "${SKILL_ROOT}/${path}" ]]; then
    report_ok "${path}"
  else
    report_missing "${path}"
    status=1
  fi
done

say "" "" ""
say "检查模板：" "テンプレートを確認:" "Checking templates:"
for path in "${required_templates[@]}"; do
  if [[ -e "${SKILL_ROOT}/${path}" ]]; then
    report_ok "${path}"
  else
    report_missing "${path}"
    status=1
  fi
done

say "" "" ""
say "检查 Git 默认策略：" "Git の既定ポリシーを確認:" "Checking Git defaults:"
workspace_git_defaults="$(cd "${SKILL_ROOT}" && rg -N '^auto_push_after_commit = (true|false)$' templates/workspace.toml -or '$1' | head -n 1)"
user_git_defaults="$(cd "${SKILL_ROOT}" && rg -N '^auto_push_after_commit = (true|false)$' templates/user.local.toml -or '$1' | head -n 1)"

if [[ "${workspace_git_defaults}" == "true" ]]; then
  report_ok "templates/workspace.toml:auto_push_after_commit=true"
else
  report_missing "templates/workspace.toml:auto_push_after_commit=true"
  status=1
fi

if [[ "${user_git_defaults}" == "true" ]]; then
  report_ok "templates/user.local.toml:auto_push_after_commit=true"
else
  report_missing "templates/user.local.toml:auto_push_after_commit=true"
  status=1
fi

say "" "" ""
say "检查 references 目录：" "references ディレクトリを確認:" "Checking reference directories:"
for path in "${required_reference_dirs[@]}"; do
  if [[ -d "${SKILL_ROOT}/${path}" ]]; then
    report_ok "${path}"
  else
    report_missing "${path}"
    status=1
  fi
done

zh_files="$(cd "${SKILL_ROOT}" && find references/zh-CN -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
en_files="$(cd "${SKILL_ROOT}" && find references/en -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
ja_files="$(cd "${SKILL_ROOT}" && find references/ja -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"

say "" "" ""
say "检查多语言 references 文件集合：" "多言語 references のファイル集合を確認:" "Checking multilingual reference file sets:"

if [[ "${zh_files}" == "${en_files}" && "${zh_files}" == "${ja_files}" ]]; then
  say "- 通过：zh-CN / en / ja 文件集合一致" "- OK: zh-CN / en / ja のファイル集合は一致しています" "- OK: zh-CN / en / ja file sets match"
else
  status=1
  say "- 不一致：zh-CN / en / ja 文件集合不同" "- 不一致: zh-CN / en / ja のファイル集合が一致しません" "- MISMATCH: zh-CN / en / ja file sets differ"
  say "  zh-CN:" "  zh-CN:" "  zh-CN:"
  printf '%s\n' "${zh_files}" | sed 's/^/    /'
  say "  en:" "  en:" "  en:"
  printf '%s\n' "${en_files}" | sed 's/^/    /'
  say "  ja:" "  ja:" "  ja:"
  printf '%s\n' "${ja_files}" | sed 's/^/    /'
fi

say "" "" ""
if [[ "${status}" -eq 0 ]]; then
  say "结果：OK" "結果: OK" "Result: OK"
else
  say "结果：INCOMPLETE" "結果: INCOMPLETE" "Result: INCOMPLETE"
fi

exit "${status}"
