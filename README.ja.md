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
- `references/`: 多言語リファレンスの入口。既定では `references/zh-CN/` を読みます
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

## クイックインストール

```bash
./scripts/install-skill.sh
```

デフォルトのインストール先:

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## 同梱スクリプト

- `scripts/omni-context [--lang zh-CN|en|ja] <command> ...`
  `init`、`sync`、`status`、`new-project`、`new-doc` をまとめる共通入口です。指定しない場合は中国語が既定です。

- `scripts/init-workspace.sh [workspace-root]`
  最小構成の `.omnicontext/` を生成し、可能であれば Git リポジトリからプロジェクト一覧を推定します。
- `scripts/sync-workspace.sh [workspace-root]`
  ワークスペースモードを保守的に更新し、新しいプロジェクトマッピングを追加し、欠けている基本ドキュメントを補完し、トップレベルの `INDEX.md` を再構築します。既存の手書きプロジェクト内容は自動削除しません。
- `scripts/status-workspace.sh [workspace-root]`
  必須ファイル、管理対象プロジェクト、未マッピングの残留ディレクトリを確認します。
- `scripts/check-skill.sh`
  skill 自体の構造、主要スクリプト、テンプレート、および `references/zh-CN|en|ja` の同期状態を検証します。
- `scripts/new-project.sh <workspace-root> <project-name> <source-path>`
  新しいプロジェクトを明示的に登録し、基本ドキュメントを生成してワークスペース索引を更新します。
- `scripts/new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]`
  `technical`、`design`、`product`、`runbook`、`wiki` のいずれかに文書を作成し、対応する索引に追記します。

## 言語対応生成

- 生成されるプロンプト、テンプレート、スクリプト出力の既定言語は中国語です
- ユーザーまたはワークスペース方針に応じて `--lang en` または `--lang ja` に切り替えます
- `init`、`sync`、`status`、`new-project`、`new-doc` はすべて現在の言語設定を反映します

## メンテナンス方針

- `references/zh-CN/` を更新したら、同じ変更を `references/en/` と `references/ja/` にも反映します
- スクリプトの挙動が変わったら、README、`SKILL.md`、対応する `references/*/automation-behaviors.md` も更新します
- リポジトリで Git を使う場合は、この規則を既定で有効にし、1 つの機能が完了するごとに最小単位でコミットし、説明的なメッセージを書きます。必要なら設定で無効化できます
- 既定では各 commit 後に自動 push します。毎回 push したくない場合だけ設定で明示的に無効化します
- コミット前に次を実行します:

```bash
./scripts/omni-context check
```

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

- より豊富な文書テンプレートと、より細かい索引保守機能

設計方針はまず `references/README.md` を参照してください。現在の詳細な既定リファレンスは `references/zh-CN/automation-behaviors.md` にあります。

## 既定の言語方針

- リポジトリの既定ランディングは中国語の `README.md`
- 既定のプロンプト言語は中国語
- 英語または日本語に切り替えるのは、ユーザー要求またはワークスペース方針がある場合のみ
