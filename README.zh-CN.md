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

## 使用手册

- [完整使用手册](MANUAL.zh-CN.md)

## 全局安装

```bash
./scripts/install-global.sh
```

如果 `~/.local/bin` 已经在 `PATH` 里，安装后可以直接用：

```bash
omni-context <command> ...
```

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
- `create-demo-workspace`
- `git-finish`
- `new-project`
- `new-doc`
- `init-project-standards`
- `project-doctor`
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
- `setup-test-runtime`
- `run-browser-suite-devtools`
- `run-browser-suite`
- `run-api-suite`
- `execute-test-suite`
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
- Web/小程序前台测试默认要求真实交互执行
- 正式测试只认非 draft 用例，执行记录会绑定 suite 指纹，防止偷偷改用例
- Web 正式测试默认走 DevTools 主执行器，并在失败时自动回退到 Playwright
- Backend 正式测试默认走 API 执行器，不安装浏览器运行时
- Web/API 测试现在支持先采集真实运行证据，再进入正式判定
- API suite 支持更细的断言步骤，包括 header、json value、json array length 和状态码区间
- 本地危险数据库/Redis 操作默认先备份
- 危险操作现在会识别“具体对象”的备份记录，不再只看 backups 目录
- autopilot 会自动补阶段摘要，并在 testing 阶段生成草稿测试资产后再给出阻塞说明

## 快速演示

```bash
scripts/omni-context create-demo-workspace /tmp/omni-demo
cd /tmp/omni-demo/demo-web && python3 -m http.server 38080
```

然后在另一个终端执行：

```bash
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context collect-test-evidence /tmp/omni-demo demo-web homepage-smoke --platform web

# 或直接走 DevTools 主执行器
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context run-browser-suite-devtools /tmp/omni-demo demo-web homepage-smoke --platform web

# Backend 正式执行
/Users/program/code/code_work_flow/omni-context-skill/scripts/omni-context run-api-suite /tmp/omni-demo demo-api health-check --platform backend
```

日常总诊断：

```bash
scripts/omni-context project-doctor /path/to/workspace my-app
```

## 使用边界

- 不在 skill 仓库里存真实业务知识
- 不在模板里存密钥、Token、机器私有值
- 不把团队项目事实写死在 skill 中

## 参考入口

先读：

- `references/README.md`
- 默认中文再读：`references/zh-CN/`

详细协议、规则组合、技能组合、测试、安全和自动执行说明都在 `references/` 中。
