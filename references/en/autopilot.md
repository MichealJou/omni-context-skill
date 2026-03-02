# Autopilot

`autopilot-run` keeps going until the workflow completes or a blocker appears.

Default output should stay concise: status, blocker, next step.

During testing, autopilot should prefer the DevTools-first browser executor for web and miniapp projects, and the API executor for backend projects.

Autopilot should also enrich stage documents with short source-based summaries instead of only updating status.
