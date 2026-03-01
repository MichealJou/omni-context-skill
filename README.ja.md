# OmniContext

OmniContext は、Codex、Claude Code、Qoder、Trae などのコーディングツール向けに再利用できるワークスペース知識管理 skill です。

提供するもの：

- `.omnicontext/` を中心としたファイルベースのプロトコル
- 共有知識、個人知識、プロジェクト知識のテンプレート
- 複数ツール向けの薄いアダプタ入口
- `init` と `status` の最小スクリプト

## このリポジトリに含まれるもの

- `SKILL.md`: skill の発火条件とワークフロールール
- `agents/openai.yaml`: skill 一覧や UI 用のメタデータ
- `references/`: プロトコル、設定、言語、アダプタ、更新ルール
- `scripts/`: 最小限のワークスペース自動化
- `templates/`: 実際の `.omnicontext/` を生成するためのテンプレート

## リポジトリ構成

```text
omni-context-skill/
  SKILL.md
  README.md
  README.en.md
  README.zh-CN.md
  README.ja.md
  agents/
    openai.yaml
  references/
  scripts/
  templates/
```

## このリポジトリに含めないもの

- 実プロジェクトの知識そのもの
- 秘密情報、トークン、認証情報
- 特定プロジェクトの handoff 履歴

それらは対象ワークスペースの `.omnicontext/` に置くべきです。

## 推奨導入フロー

1. この skill をコーディング環境にインストールまたは配置する
2. 実際のワークスペース内に `.omnicontext/` を作成する
3. `templates/` を使って `workspace.toml`、`INDEX.md`、初期プロジェクトファイルを作る
4. 利用するコーディングツールに対応したアダプタファイルを追加する
5. まず 1 つの実ワークスペースで構成を検証し、その後に自動化を拡張する

## 同梱スクリプト

- `scripts/init-workspace.sh [workspace-root]`
  最小構成の `.omnicontext/` を生成し、可能であれば Git リポジトリからプロジェクト一覧を推定します。
- `scripts/sync-workspace.sh [workspace-root]`
  ワークスペースモードを保守的に更新し、新しいプロジェクトマッピングを追加し、欠けている基本ドキュメントを補完し、トップレベルの `INDEX.md` を再構築します。既存の手書きプロジェクト内容は自動削除しません。
- `scripts/status-workspace.sh [workspace-root]`
  必須ファイル、管理対象プロジェクト、未マッピングの残留ディレクトリを確認します。

## 公開時の境界

このリポジトリは汎用のまま保つべきです。

- 実プロジェクトの事実はこのリポジトリに入れない
- マシン固有値や秘密情報をテンプレートに入れない
- 実際のワークスペース知識は対象の `.omnicontext/` に保存する

## 最小生成構成

```text
.omnicontext/
  workspace.toml
  INDEX.md
  shared/
    standards.md
    language-policy.md
  personal/
    preferences.md
  projects/
    <project-name>/
      overview.md
      handoff.md
      todo.md
      decisions.md
```

## 次の進化

このファイルプロトコルが実ワークスペースで安定してから、次を追加します。

- `new-project`
- `new-doc`

設計方針は `references/automation-behaviors.md` を参照してください。
