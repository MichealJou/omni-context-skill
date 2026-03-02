# OmniContext

OmniContext は、実プロジェクトの中に `.omnicontext/` 交付制御レイヤーを作成して維持するための再利用可能な skill リポジトリです。

## 現在の対象範囲

- ワークスペース知識
- ライフサイクルワークフロー
- 役割規範
- ルールパック
- skill バンドル
- テストのハードゲート
- 実行時依存接続
- データ安全保護

## リポジトリ内容

- `SKILL.md`
- `agents/openai.yaml`
- `references/`
- `scripts/`
- `templates/`

実際の業務知識はこのリポジトリではなく、対象ワークスペースに保存します。

## クイックインストール

```bash
./scripts/install-skill.sh
```

既定のインストール先:

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## 統一 CLI

```bash
./scripts/omni-context <command> ...
```

主なコマンド:

- `init`
- `sync`
- `status`
- `check`
- `git-finish`
- `new-project`
- `new-doc`
- `init-project-standards`
- `role-status`
- `runtime-status`
- `start-workflow`
- `workflow-status`
- `workflow-check`
- `advance-stage`
- `skip-stage`
- `list-workflows`
- `rules-pack-init`
- `rules-pack-status`
- `rules-pack-check`
- `rules-pack-list`
- `bundle-status`
- `bundle-install`
- `bundle-check`
- `init-test-suite`
- `collect-test-evidence`
- `execute-test-suite`
- `record-test-run`
- `test-status`
- `backup-object`
- `danger-check`
- `record-dangerous-op`
- `autopilot-run`
- `autopilot-status`

## 既定ルール

- 既定言語は中国語
- 既定で簡潔な対話
- 既定で機能単位コミット
- 既定で commit 後 push
- 既定でテストはハードゲート
- 既定で全工程自動実行を有効
- フロント系テストは既定で実ユーザー操作を要求
- 正式テスト実行は suite 指紋に固定され、draft 用例は受け付けません
- Web/API テストは正式判定の前に実行証跡を採取できます
- ローカルの危険な DB/Redis 操作は既定で先にバックアップ
- autopilot は段階要約を自動補完し、testing では草稿テスト資産を作った上で阻塞理由を返します

## 境界

- 実プロジェクトの事実は skill リポジトリに置かない
- 秘密情報やマシン固有値はテンプレートに置かない
- チーム固有ルールを汎用 skill に書き込まない

## 次に読むもの

最初に:

- `references/README.md`
- その後、別言語要求がなければ `references/zh-CN/`
