# OmniContext

OmniContext 是一套可复用的 skill 仓库，用来在真实项目里创建和维护 `.omnicontext/` 交付控制层。

## 当前能力

- 工作区知识层
- 生命周期流程层
- 角色规范层
- 规则组合层
- 技能组合层
- 测试硬门禁层
- 运行时依赖接入层
- 数据安全保护层

## 仓库包含内容

- `SKILL.md`
- `agents/openai.yaml`
- `references/`
- `scripts/`
- `templates/`

真实项目数据不放在 skill 仓库里，而是放在目标项目的 `.omnicontext/`。

## 快速安装

```bash
./scripts/install-skill.sh
```

默认安装到：

```text
${CODEX_HOME:-~/.codex}/skills/omni-context
```

## 统一命令入口

```bash
./scripts/omni-context <command> ...
```

常用命令：

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
- `record-test-run`
- `test-status`
- `backup-object`
- `danger-check`
- `record-dangerous-op`
- `autopilot-run`
- `autopilot-status`

## 默认规则

- 默认中文
- 默认交互简洁
- 默认最小单提交
- 默认每次提交后自动 push
- 默认测试为硬门禁
- 默认支持自动推进完整流程

## 使用边界

- 不在 skill 仓库里存真实业务知识
- 不在模板里存密钥、Token、机器私有值
- 不把团队项目事实写死在 skill 中

## 参考入口

先读：

- `references/README.md`
- 默认中文再读：`references/zh-CN/`

详细协议、规则组合、技能组合、测试、安全和自动执行说明都在 `references/` 中。
