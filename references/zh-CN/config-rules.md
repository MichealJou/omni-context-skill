# 配置规则

共享配置文件是 `.omnicontext/workspace.toml`。

## 目标

- 描述如何解释当前工作区
- 支持单项目、多项目和自动探测模式
- 把机器差异和用户差异隔离在共享配置之外

## 推荐字段

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

## 模式

`auto`
- 默认模式
- 工具会保守地检查工作区并推断项目映射

`single`
- 当整个工作区由一个主代码库主导时使用

`multi`
- 当工作区包含多个项目根目录或仓库时使用

## 项目映射

当自动发现不够可靠时，补充显式映射：

```toml
[[project_mappings]]
name = "snapflow-web"
source_path = "snapflow-web"
knowledge_path = "projects/snapflow-web"
type = "app"
```

## 本地覆盖配置

这些文件应只存在于本机，通常不应进入共享版本控制：

- `.omnicontext/machine.local.toml`
- `.omnicontext/user.local.toml`

适合用于：

- 绝对路径
- 机器专用二进制路径
- 语言与格式偏好，默认中文，除非用户或工作区策略覆盖
- 不应影响队友的个人默认值
