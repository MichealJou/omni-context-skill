#!/usr/bin/env bash

omni_normalize_language() {
  local value="${1:-}"
  case "${value}" in
    zh|zh-CN|zh_CN|cn|CN)
      printf 'zh-CN\n'
      ;;
    ja|ja-JP|ja_JP|jp|JP)
      printf 'ja\n'
      ;;
    en|en-US|en_US|en-GB|en_GB)
      printf 'en\n'
      ;;
    *)
      printf 'zh-CN\n'
      ;;
  esac
}

omni_read_toml_value() {
  local file="$1"
  local key="$2"
  if [[ -f "${file}" ]]; then
    sed -n "s/^${key} = \"\\(.*\\)\"/\\1/p" "${file}" | head -n 1
  fi
}

omni_read_toml_bool() {
  local file="$1"
  local key="$2"
  if [[ -f "${file}" ]]; then
    sed -n "s/^${key} = \\(true\\|false\\)$/\\1/p" "${file}" | head -n 1
  fi
}

omni_find_workspace_root() {
  local start_dir="${1:-$(pwd)}"
  local current_dir=""

  current_dir="$(cd "${start_dir}" && pwd)"
  while [[ "${current_dir}" != "/" ]]; do
    if [[ -f "${current_dir}/.omnicontext/workspace.toml" || -f "${current_dir}/.omnicontext/user.local.toml" ]]; then
      printf '%s\n' "${current_dir}"
      return 0
    fi
    current_dir="$(dirname "${current_dir}")"
  done

  return 1
}

omni_resolve_git_bool() {
  local workspace_root="${1:-}"
  local key="$2"
  local default_value="${3:-false}"
  local omni_root="${workspace_root}/.omnicontext"
  local user_local="${omni_root}/user.local.toml"
  local workspace_toml="${omni_root}/workspace.toml"
  local value=""

  value="$(omni_read_toml_bool "${user_local}" "${key}")"
  if [[ -n "${value}" ]]; then
    printf '%s\n' "${value}"
    return
  fi

  value="$(omni_read_toml_bool "${workspace_toml}" "${key}")"
  if [[ -n "${value}" ]]; then
    printf '%s\n' "${value}"
    return
  fi

  printf '%s\n' "${default_value}"
}

omni_resolve_language() {
  local workspace_root="${1:-}"
  local explicit="${2:-${OMNI_CONTEXT_LANGUAGE:-}}"
  local omni_root="${workspace_root}/.omnicontext"
  local user_local="${omni_root}/user.local.toml"
  local workspace_toml="${omni_root}/workspace.toml"
  local value=""

  if [[ -n "${explicit}" ]]; then
    omni_normalize_language "${explicit}"
    return
  fi

  value="$(omni_read_toml_value "${user_local}" "language")"
  if [[ -n "${value}" && "${value}" != "auto" ]]; then
    omni_normalize_language "${value}"
    return
  fi

  value="$(omni_read_toml_value "${workspace_toml}" "default_language")"
  if [[ -n "${value}" ]]; then
    omni_normalize_language "${value}"
    return
  fi

  printf 'zh-CN\n'
}

omni_doc_type_label() {
  local lang="$1"
  local doc_type="$2"
  case "${lang}" in
    zh-CN)
      case "${doc_type}" in
        technical) printf '技术文档\n' ;;
        design) printf '设计文档\n' ;;
        product) printf '产品文档\n' ;;
        runbook) printf '运行手册\n' ;;
        wiki) printf '项目 Wiki\n' ;;
        *) printf '%s\n' "${doc_type}" ;;
      esac
      ;;
    ja)
      case "${doc_type}" in
        technical) printf '技術文書\n' ;;
        design) printf '設計文書\n' ;;
        product) printf 'プロダクト文書\n' ;;
        runbook) printf '運用手順書\n' ;;
        wiki) printf 'プロジェクト Wiki\n' ;;
        *) printf '%s\n' "${doc_type}" ;;
      esac
      ;;
    *)
      case "${doc_type}" in
        technical) printf 'Technical Docs\n' ;;
        design) printf 'Design Docs\n' ;;
        product) printf 'Product Docs\n' ;;
        runbook) printf 'Runbook Docs\n' ;;
        wiki) printf 'Wiki\n' ;;
        *) printf '%s\n' "${doc_type}" ;;
      esac
      ;;
  esac
}

omni_write_overview() {
  local file="$1"
  local lang="$2"
  local project_name="$3"
  case "${lang}" in
    zh-CN)
      cat > "${file}" <<EOF
# 概览

## 摘要

- 项目名称: ${project_name}
- 目标:
- 范围:

## 结构

- 主要目录:
- 关键入口:
- 上下游系统:

## 运行

- 安装:
- 启动:
- 测试:
- 构建:

## 约束

- 运行时或平台约束:
- 非显式依赖:
- 已知边界:
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# 概要

## 要約

- プロジェクト名: ${project_name}
- 目的:
- 範囲:

## 構成

- 主要ディレクトリ:
- 主要エントリーポイント:
- 関連する上流・下流システム:

## 実行

- インストール:
- 起動:
- テスト:
- ビルド:

## 制約

- ランタイムまたはプラットフォーム制約:
- 暗黙的な依存関係:
- 既知の境界:
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# Overview

## Summary

- Project name: ${project_name}
- Purpose:
- Scope:

## Structure

- Main directories:
- Important entry points:
- Related upstream/downstream systems:

## Runbook

- Install:
- Start:
- Test:
- Build:

## Constraints

- Runtime or platform constraints:
- Non-obvious dependencies:
- Known boundaries:
EOF
      ;;
  esac
}

omni_write_handoff() {
  local file="$1"
  local lang="$2"
  local status_line="$3"
  local recent_line="$4"
  local next_line="$5"
  case "${lang}" in
    zh-CN)
      cat > "${file}" <<EOF
# 交接

## 当前状态

- 状态: ${status_line}
- 当前分支或工作区域:
- 当前重点:

## 最近进展

- ${recent_line}

## 下一步

- ${next_line}

## 风险与阻塞

- 暂无记录

## 指引

- 关键文件:
- 关键命令:
- 相关文档:
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# 引き継ぎ

## 現在の状態

- ステータス: ${status_line}
- 現在のブランチまたは作業領域:
- 現在の重点:

## 最近の進捗

- ${recent_line}

## 次のアクション

- ${next_line}

## リスクとブロッカー

- まだ記録なし

## 参照先

- 主要ファイル:
- 主要コマンド:
- 関連ドキュメント:
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# Handoff

## Current State

- Status: ${status_line}
- Active branch or working area:
- Current focus:

## Recent Progress

- ${recent_line}

## Next Steps

- ${next_line}

## Risks And Blockers

- None recorded yet

## Pointers

- Key files:
- Key commands:
- Related docs:
EOF
      ;;
  esac
}

omni_write_todo() {
  local file="$1"
  local lang="$2"
  case "${lang}" in
    zh-CN)
      cat > "${file}" <<'EOF'
# 待办

## 进行中

- [ ] 补充概览信息

## 即将开始

- [ ] 补充当前项目文档

## 延后

- [ ] 仅在需要时再新增更多 OmniContext 文档
EOF
      ;;
    ja)
      cat > "${file}" <<'EOF'
# Todo

## 進行中

- [ ] 概要情報を補完する

## 次に行うこと

- [ ] 現在のプロジェクト文書を追加する

## 保留

- [ ] 必要になるまで OmniContext 文書を増やしすぎない
EOF
      ;;
    *)
      cat > "${file}" <<'EOF'
# Todo

## Active

- [ ] Fill in overview details

## Upcoming

- [ ] Add current project-specific documentation

## Deferred

- [ ] Add more OmniContext docs only when needed
EOF
      ;;
  esac
}

omni_write_decisions() {
  local file="$1"
  local lang="$2"
  local title="$3"
  local context="$4"
  local decision="$5"
  local rationale="$6"
  local consequence="$7"
  case "${lang}" in
    zh-CN)
      cat > "${file}" <<EOF
# 决策

## 决策记录

### YYYY-MM-DD - ${title}

- 背景: ${context}
- 决策: ${decision}
- 原因: ${rationale}
- 影响: ${consequence}
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# 決定事項

## 決定ログ

### YYYY-MM-DD - ${title}

- 背景: ${context}
- 決定: ${decision}
- 理由: ${rationale}
- 影響: ${consequence}
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# Decisions

## Decision Log

### YYYY-MM-DD - ${title}

- Context: ${context}
- Decision: ${decision}
- Rationale: ${rationale}
- Consequence: ${consequence}
EOF
      ;;
  esac
}

omni_write_workspace_index_header() {
  local file="$1"
  local lang="$2"
  local workspace_name="$3"
  local mode="$4"
  case "${lang}" in
    zh-CN)
      cat > "${file}" <<EOF
# OmniContext 索引

## 工作区

- 工作区名称: ${workspace_name}
- 模式: ${mode}
- 知识根目录: \`.omnicontext\`

## 共享知识

- \`shared/standards.md\`
- \`shared/language-policy.md\`
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# OmniContext インデックス

## ワークスペース

- ワークスペース名: ${workspace_name}
- モード: ${mode}
- 知識ルート: \`.omnicontext\`

## 共有知識

- \`shared/standards.md\`
- \`shared/language-policy.md\`
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# OmniContext Index

## Workspace

- Workspace name: ${workspace_name}
- Mode: ${mode}
- Knowledge root: \`.omnicontext\`

## Shared Knowledge

- \`shared/standards.md\`
- \`shared/language-policy.md\`
EOF
      ;;
  esac
}

omni_append_workspace_index_shared_docs() {
  local file="$1"
  local lang="$2"
  case "${lang}" in
    zh-CN)
      cat >> "${file}" <<'EOF'
- `shared/docs/index.md`
EOF
      ;;
    ja)
      cat >> "${file}" <<'EOF'
- `shared/docs/index.md`
EOF
      ;;
    *)
      cat >> "${file}" <<'EOF'
- `shared/docs/index.md`
EOF
      ;;
  esac
}

omni_append_workspace_index_personal_header() {
  local file="$1"
  local lang="$2"
  case "${lang}" in
    zh-CN)
      cat >> "${file}" <<'EOF'

## 个人知识

- `personal/preferences.md`

## 项目
EOF
      ;;
    ja)
      cat >> "${file}" <<'EOF'

## 個人知識

- `personal/preferences.md`

## プロジェクト
EOF
      ;;
    *)
      cat >> "${file}" <<'EOF'

## Personal Knowledge

- `personal/preferences.md`

## Projects
EOF
      ;;
  esac
}

omni_append_workspace_index_project() {
  local file="$1"
  local lang="$2"
  local project_name="$3"
  local project_path="$4"
  local include_managed_docs="${5:-0}"
  case "${lang}" in
    zh-CN)
      cat >> "${file}" <<EOF

- 项目名称: ${project_name}
  - 源路径: ${project_path}
  - 概览: \`projects/${project_name}/overview.md\`
  - 交接: \`projects/${project_name}/handoff.md\`
  - 待办: \`projects/${project_name}/todo.md\`
  - 决策: \`projects/${project_name}/decisions.md\`
EOF
      if [[ "${include_managed_docs}" == "1" ]]; then
        cat >> "${file}" <<EOF
  - 管理文档: \`projects/${project_name}/docs/\`
EOF
      fi
      ;;
    ja)
      cat >> "${file}" <<EOF

- プロジェクト名: ${project_name}
  - ソースパス: ${project_path}
  - 概要: \`projects/${project_name}/overview.md\`
  - 引き継ぎ: \`projects/${project_name}/handoff.md\`
  - Todo: \`projects/${project_name}/todo.md\`
  - 決定事項: \`projects/${project_name}/decisions.md\`
EOF
      if [[ "${include_managed_docs}" == "1" ]]; then
        cat >> "${file}" <<EOF
  - 管理ドキュメント: \`projects/${project_name}/docs/\`
EOF
      fi
      ;;
    *)
      cat >> "${file}" <<EOF

- Project name: ${project_name}
  - Source path: ${project_path}
  - Overview: \`projects/${project_name}/overview.md\`
  - Handoff: \`projects/${project_name}/handoff.md\`
  - Todo: \`projects/${project_name}/todo.md\`
  - Decisions: \`projects/${project_name}/decisions.md\`
EOF
      if [[ "${include_managed_docs}" == "1" ]]; then
        cat >> "${file}" <<EOF
  - Managed docs: \`projects/${project_name}/docs/\`
EOF
      fi
      ;;
  esac
}

omni_append_workspace_index_notes() {
  local file="$1"
  local lang="$2"
  case "${lang}" in
    zh-CN)
      cat >> "${file}" <<'EOF'

## 说明

- 发现规则: 优先根据 Git 仓库推断项目根目录
- 缺失文档: 初始化后继续补充共享和项目细节
- 后续设置: 如有需要，将工具入口模板复制到宿主工具对应位置
EOF
      ;;
    ja)
      cat >> "${file}" <<'EOF'

## メモ

- 検出ルール: 可能な場合は Git リポジトリからプロジェクトルートを推定する
- 不足ドキュメント: 初期化後に共有情報とプロジェクト詳細を追記する
- 後続設定: 必要に応じてツール用アダプタをホストツールの所定位置へコピーする
EOF
      ;;
    *)
      cat >> "${file}" <<'EOF'

## Notes

- Discovery assumptions: project roots inferred from Git repositories when available
- Missing documentation: fill shared and project details after initialization
- Follow-up setup: copy tool adapter files into the host tool locations if needed
EOF
      ;;
  esac
}

omni_write_doc_template() {
  local file="$1"
  local lang="$2"
  local project_name="$3"
  local doc_type="$4"
  local doc_title="$5"
  local doc_type_label
  doc_type_label="$(omni_doc_type_label "${lang}" "${doc_type}")"

  case "${lang}" in
    zh-CN)
      cat > "${file}" <<EOF
# ${doc_title}

## 摘要

- 项目: ${project_name}
- 类型: ${doc_type_label}
- 状态: 草稿

## 背景

- 

## 细节

- 

## 后续

- 
EOF
      ;;
    ja)
      cat > "${file}" <<EOF
# ${doc_title}

## 要約

- プロジェクト: ${project_name}
- 種別: ${doc_type_label}
- ステータス: Draft

## 背景

- 

## 詳細

- 

## 次の対応

- 
EOF
      ;;
    *)
      cat > "${file}" <<EOF
# ${doc_title}

## Summary

- Project: ${project_name}
- Type: ${doc_type_label}
- Status: Draft

## Context

- 

## Details

- 

## Follow-up

- 
EOF
      ;;
  esac
}
