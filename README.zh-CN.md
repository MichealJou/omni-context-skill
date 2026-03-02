# OmniContext

OmniContext 是一套可复用的工作区知识管理 skill，适用于 Codex、Claude Code、Qoder、Trae 等编程工具。

它提供：

- 基于 `.omnicontext/` 的文件协议
- 面向共享知识、个人知识、项目知识的模板
- 面向多种编程工具的轻量入口适配
- `init` 和 `status` 两个最小可用脚本

## 仓库包含内容

- `SKILL.md`：skill 触发条件与工作流规则
- `agents/openai.yaml`：skill 列表/UI 元数据
- `references/`：多语言参考文档入口，默认读取 `references/zh-CN/`
- `scripts/`：最小工作区自动化脚本
- `templates/`：生成真实 `.omnicontext/` 所需的模板文件

## 仓库结构

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

## 这个仓库不包含什么

- 真实业务知识
- 密钥、Token、凭证
- 某个具体项目的 handoff 历史

这些内容应该放在目标工作区的 `.omnicontext/` 目录里。

## 推荐接入流程

1. 将这个 skill 安装或拷贝到你的编程环境中
2. 在真实工作区中创建 `.omnicontext/`
3. 基于 `templates/` 填充 `workspace.toml`、`INDEX.md` 和项目基础文件
4. 为实际使用的编程工具放入对应的 adapter 入口文件
5. 先在一个真实工作区验证结构，再继续扩展自动化

## 快速安装

```bash
./scripts/install-skill.sh
```

默认会安装到：

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## 已包含脚本

- `scripts/omni-context [--lang zh-CN|en|ja] <command> ...`
  统一入口，分发 `init`、`sync`、`status`、`new-project`、`new-doc`。不传 `--lang` 时默认中文。

- `scripts/init-workspace.sh [workspace-root]`
  初始化一个最小可用的 `.omnicontext/` 目录，并尽量从 Git 仓库推断项目列表。
- `scripts/sync-workspace.sh [workspace-root]`
  保守地刷新工作区模式、补充新项目映射、重建缺失的项目核心文档，并重写顶层 `INDEX.md`，但不会删除手写项目内容。
- `scripts/status-workspace.sh [workspace-root]`
  检查必需文件、正式项目映射和未纳管残留目录。
- `scripts/check-skill.sh`
  校验 skill 自身结构、核心脚本、模板，以及 `references/zh-CN|en|ja` 三套文档是否齐全同步。
- `scripts/new-project.sh <workspace-root> <project-name> <source-path>`
  显式注册一个新项目，生成该项目的基础 OmniContext 文档，并刷新工作区索引。
- `scripts/new-doc.sh <workspace-root> <project-name> <doc-type> <doc-title> [slug]`
  在 `technical`、`design`、`product`、`runbook` 或 `wiki` 下创建项目文档，并自动补入对应索引。

## 语言生成

- 默认生成中文 README 入口、模板、提示词和脚本输出
- 如果用户或工作区明确指定英文或日文，可通过 `--lang en` 或 `--lang ja` 切换
- `init`、`sync`、`status`、`new-project`、`new-doc` 都会按当前语言生成或输出内容

## 维护建议

- 每次改 `references/zh-CN/` 时，同步更新 `references/en/` 和 `references/ja/`
- 每次改脚本行为时，同步更新 `README`、`SKILL.md` 和对应的 `references/*/automation-behaviors.md`
- 如果仓库使用 Git，默认开启“一个功能完成后立刻做一次最小单提交，并写清提交说明”；如有特殊需要可在配置里关闭
- 提交前运行：

```bash
./scripts/omni-context check
```

## 发布边界

这个仓库应该保持通用性。

- 不把真实项目事实写进这个仓库
- 不把机器专用值和敏感信息写进模板
- 真正的项目知识应写入目标工作区的 `.omnicontext/`

## 最小生成结构

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

## 后续演进

等这套文件协议在真实工作区中跑稳之后，再继续补：

- 更丰富的文档模板与更细的索引维护能力

具体行为设计见 `references/zh-CN/automation-behaviors.md`。

## 默认语言策略

- 仓库首页 `README.md` 默认展示中文
- 默认提示词语言为中文
- 只有当用户明确要求英文或日文，或项目语言策略另有规定时，才切换对应提示词和输出语言
