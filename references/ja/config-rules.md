# 設定規則

共有設定ファイルは `.omnicontext/workspace.toml` です。

## 目的

- 現在のワークスペースをどのように解釈するかを記述する
- 単一プロジェクト、複数プロジェクト、自動検出モードをサポートする
- マシン固有差分とユーザー固有差分を共有設定から分離する

## 推奨フィールド

```toml
version = 1
workspace_name = "example-workspace"
mode = "auto"
knowledge_root = ".omnicontext"

[discovery]
scan_git_repos = true
scan_depth = 3
ignore = [".git", "node_modules", "dist", "build", "target"]

[shared]
path = "shared"

[personal]
path = "personal"

[projects]
path = "projects"

[localization]
default_language = "zh-CN"
supported_languages = ["zh-CN", "en", "ja"]
```

## モード

`auto`
- 既定モード
- ツールがワークスペースを保守的に調べ、プロジェクトマッピングを推定する

`single`
- 1 つの主要コードベースがワークスペース全体を占める場合に使う

`multi`
- ワークスペースに複数のプロジェクトルートまたはリポジトリがある場合に使う

## プロジェクトマッピング

自動検出だけでは不十分なときは、明示的なマッピングを追加します。

```toml
[[project_mappings]]
name = "snapflow-web"
source_path = "snapflow-web"
knowledge_path = "projects/snapflow-web"
type = "app"
```

## ローカル上書き

次のファイルはローカルマシンにだけ存在し、通常は共有バージョン管理に含めません。

- `.omnicontext/machine.local.toml`
- `.omnicontext/user.local.toml`

用途:

- 絶対パス
- マシン固有のバイナリ設定
- 言語と書式の好み。既定は中国語で、ユーザーまたはワークスペース方針がある場合のみ上書きする
- チームメイトに影響させるべきでない個人既定値
