# テストモデル

テストはハードゲートです。

要件:

- ケースがある
- 実行記録がある
- required ケースがすべて通る
- 証拠参照がある

前面クライアントは実ユーザーに近い操作で検証します。

Web と miniapp の正式 suite は DevTools 優先実行器を使います。Playwright は許可された条件で主実行が失敗した場合のフォールバックです。

正式 run は非 draft suite を使い、現在の suite 指紋に固定されます。

推奨 API suite step action:

- `set_header`
- `set_json`
- `set_body`
- `set_timeout`
- `request`
- `expect_status`
- `expect_status_range`
- `expect_text`
- `expect_header`
- `expect_json_key`
- `expect_json_value`
- `expect_json_array_length`
