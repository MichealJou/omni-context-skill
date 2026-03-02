# Config Rules

The shared config file is `.omnicontext/workspace.toml`.

## Goals

- Describe how to interpret the current workspace
- Support single-project, multi-project, and auto-detect modes
- Keep machine-specific and user-specific differences out of shared config

## Recommended Fields

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

## Modes

`auto`
- Default mode
- The tool inspects the workspace and infers project mappings conservatively

`single`
- Use when one main codebase owns the workspace

`multi`
- Use when the workspace contains multiple project roots or repositories

## Project Mapping

When discovery is not enough, add explicit mappings:

```toml
[[project_mappings]]
name = "snapflow-web"
source_path = "snapflow-web"
knowledge_path = "projects/snapflow-web"
type = "app"
```

## Local Overrides

These files should exist only on the local machine and should usually stay out of shared version control:

- `.omnicontext/machine.local.toml`
- `.omnicontext/user.local.toml`

Use them for:

- absolute paths
- machine-specific binaries
- language and formatting preferences, with Chinese as the default unless user or workspace policy overrides it
- personal defaults that should not affect teammates
