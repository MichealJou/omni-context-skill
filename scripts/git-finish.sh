#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/omnicontext-l10n.sh"

usage() {
  cat <<'EOF'
Usage:
  git-finish.sh <repo-root> <commit-message> [--all|<path>...]

Examples:
  git-finish.sh /path/to/repo "feat: add project sync"
  git-finish.sh /path/to/repo "docs: update rules" README.md SKILL.md
  git-finish.sh /path/to/repo "chore: snapshot changes" --all
EOF
}

if [[ "${#}" -lt 2 ]]; then
  usage >&2
  exit 1
fi

REPO_INPUT="${1}"
COMMIT_MESSAGE="${2}"
shift 2

if [[ -z "${COMMIT_MESSAGE}" ]]; then
  echo "Commit message must not be empty" >&2
  exit 1
fi

REPO_ROOT="$(cd "${REPO_INPUT}" && git rev-parse --show-toplevel)"
WORKSPACE_ROOT="$(omni_find_workspace_root "${REPO_ROOT}" || true)"
if [[ -z "${WORKSPACE_ROOT}" ]]; then
  WORKSPACE_ROOT="${REPO_ROOT}"
fi

language="$(omni_resolve_language "${WORKSPACE_ROOT}")"
minimal_feature_commits="$(omni_resolve_git_bool "${WORKSPACE_ROOT}" "minimal_feature_commits" "true")"
auto_push_after_commit="$(omni_resolve_git_bool "${WORKSPACE_ROOT}" "auto_push_after_commit" "true")"

say() {
  case "${language}" in
    zh-CN) printf '%s\n' "$1" ;;
    ja) printf '%s\n' "$2" ;;
    *) printf '%s\n' "$3" ;;
  esac
}

if [[ -z "$(git -C "${REPO_ROOT}" status --short)" ]]; then
  say "没有需要提交的变更" "コミットする変更がありません" "No changes to commit"
  exit 1
fi

if [[ "${minimal_feature_commits}" == "true" && "${#}" -eq 0 ]]; then
  say "未指定文件路径，按默认规则将使用 --all 提交当前工作区全部变更" "パス指定がないため、既定ルールに従って --all で現在の変更をまとめてコミットします" "No paths were provided; the default behavior will commit all current changes with --all"
  set -- --all
fi

if [[ "${1:-}" == "--all" ]]; then
  git -C "${REPO_ROOT}" add -A
else
  for path in "$@"; do
    git -C "${REPO_ROOT}" add -- "${path}"
  done
fi

if [[ -z "$(git -C "${REPO_ROOT}" diff --cached --name-only)" ]]; then
  say "暂存区没有可提交内容" "ステージ済みの変更がありません" "No staged changes to commit"
  exit 1
fi

if [[ "${auto_push_after_commit}" == "true" ]]; then
  current_branch="$(git -C "${REPO_ROOT}" symbolic-ref --quiet --short HEAD || true)"
  upstream_ref="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  origin_remote="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  if [[ -z "${upstream_ref}" && -z "${origin_remote}" ]]; then
    say "默认开启了自动 push，但仓库没有可用的上游或 origin 远端" "自動 push が有効ですが、利用可能な upstream または origin がありません" "Auto-push is enabled by default, but the repository has no upstream or origin remote"
    exit 1
  fi
  if [[ -z "${current_branch}" ]]; then
    say "无法确定当前分支，不能执行自动 push" "現在のブランチを特定できないため、自動 push を実行できません" "Cannot determine the current branch, so auto-push cannot run"
    exit 1
  fi
fi

git -C "${REPO_ROOT}" commit -m "${COMMIT_MESSAGE}"

say "已创建提交：" "コミットを作成しました:" "Created commit:"
git -C "${REPO_ROOT}" log -1 --oneline

if [[ "${auto_push_after_commit}" == "true" ]]; then
  if git -C "${REPO_ROOT}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git -C "${REPO_ROOT}" push
  else
    git -C "${REPO_ROOT}" push -u origin "${current_branch}"
  fi
  say "已按默认规则自动 push" "既定ルールに従って自動 push しました" "Auto-pushed by default rule"
else
  say "已提交，本次未自动 push（配置已关闭）" "コミットしましたが、自動 push は無効化されています" "Committed without auto-push because configuration disabled it"
fi
