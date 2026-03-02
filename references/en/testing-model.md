# Testing Model

Testing is a hard gate.

Requirements:

- cases exist
- runs exist
- all required cases pass
- evidence is referenced

Interactive clients must be tested through real user-like actions.

Web and miniapp formal suites should use the DevTools-first executor. Playwright is only a fallback path when the primary execution fails in an allowed condition.

Formal runs must use non-draft suites and stay bound to the current suite fingerprint.

Recommended API suite step actions:

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
