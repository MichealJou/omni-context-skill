# replace-with-suite-title

- suite_id: replace-with-suite-id
- source_status: draft
- platform:
- execution_target:
- interaction_requirement:

## Required Cases

- [required] 

## Optional Cases

- [optional] 

## Preconditions

- 

## Steps

- [step] goto: /
- [step] wait_for: text=Ready
- [step] click: text=Ready

API 示例：

- [step] set_header: Accept: application/json
- [step] request: GET /
- [step] expect_status: 200
- [step] expect_status_range: 200-299
- [step] expect_text: ok
- [step] expect_header: Content-Type: application/json
- [step] expect_json_key: data.items
- [step] expect_json_value: status="ok"
- [step] expect_json_array_length: data.items=2

## Notes

- 
