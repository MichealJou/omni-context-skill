# OmniContext プロトコル

OmniContext は `.omnicontext/` 配下に保存されるワークスペースローカルの知識レイヤーです。

## 最小構成

```text
.omnicontext/
  workspace.toml
  INDEX.md
  shared/
  personal/
  projects/
    <project-name>/
      overview.md
      handoff.md
      todo.md
      decisions.md
```

## ディレクトリの責務

`shared/`
- 同一ワークスペース内の複数プロジェクトに共通する知識
- 例: 用語集、標準、アーキテクチャ原則、共通ツールメモ

`personal/`
- 個人的だが秘密ではない好みと作業規約
- 例: 文体の好み、命名規則、繰り返し使うチェックリスト

`projects/<project-name>/`
- 1 つのプロジェクトまたはリポジトリに固有の知識
- 実行コンテキスト、決定事項、運用メモを保持する

## 中核文書

`INDEX.md`
- OmniContext 全体の入口
- アクティブなプロジェクトと共有知識ファイルを列挙する

`overview.md`
- 安定したプロジェクト概要: 目的、境界、主要ディレクトリ、実行/テスト入口

`handoff.md`
- 現在状態: 最近の進捗、進行中の作業、次の一手、ブロッカー

`todo.md`
- 未完了のアクション指向項目

`decisions.md`
- 理由付きで残す設計・実装上の決定

## 拡張パス

最小セットが有効だと分かってから拡張します。次に追加しやすい代表例:

- `wiki/index.md`
- `docs/technical/index.md`
- `docs/design/index.md`
- `docs/runbook/index.md`

ワークスペースが本当に必要とするときだけ追加してください。
