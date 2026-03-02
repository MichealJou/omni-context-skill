# OmniContext 使用手册

语言:
- [简体中文说明](README.zh-CN.md)
- [English guide](README.en.md)
- [日本語ガイド](README.ja.md)

如果你直接打开仓库首页，默认就从这份中文使用手册开始。

## 这是什么

OmniContext 是一套放在项目里的交付控制层。它不替代业务代码，也不替代你原来的仓库结构。它做的是：

- 统一项目知识入口
- 管理需求到验收的 workflow
- 管理项目规范、规则包、技能包
- 管理正式测试、运行时依赖和危险操作保护
- 给不同开发 agent 提供同一套上下文

真实数据放在项目自己的 `.omnicontext/`。

## 先看两个目录

### skill 仓库

```text
omni-context-skill/
```

放：

- 脚本
- 模板
- references
- 校验器

### 项目实例

```text
<workspace>/.omnicontext/
```

放：

- 项目规范
- workflow
- tests
- docs / wiki
- runtime / rules / bundle

## 怎么用

先安装全局命令：

```bash
./scripts/install-global.sh
```

安装后常用的只有这几个：

```bash
omni update-skills
omni init <workspace>
omni check
omni init-test-excel <workspace> <project>
omni sync-test-cases-excel <workspace> <project>
omni export-test-report <workspace> <project> --run-id <run-id>
```

这几个命令分别做什么：

- `update-skills`：更新本机 skills 仓库，不改当前项目文档
- `init`：初始化工作区 `.omnicontext/`
- `check`：检查当前 skill 仓库结构
- `init-test-excel`：生成标准测试用例和测试报告 Excel 模板
- `sync-test-cases-excel`：把 `tests/suites/*.md` 同步到 Excel 用例清单
- `export-test-report`：把一次测试 run 导出成 Excel 报告

## 第一次接入一个工作区

### 1. 初始化工作区

```bash
./scripts/omni-context init /path/to/workspace
```

作用：

- 创建 `.omnicontext/`
- 建立共享层、个人层、项目层
- 生成基础配置和入口文件

### 2. 检查工作区状态

```bash
./scripts/omni-context status /path/to/workspace
```

作用：

- 看项目映射是否正确
- 看 `.omnicontext` 结构是否完整

### 3. 给项目初始化规范

```bash
./scripts/omni-context init-project-standards /path/to/workspace my-project webapp
```

作用：

- 扫描项目已有规范
- 生成 `standards/`
- 生成 `roles.toml`
- 生成 `runtime.toml`
- 生成 `testing-platforms.toml`

### 4. 初始化规则包

```bash
./scripts/omni-context rules-pack-init /path/to/workspace my-project default-balanced
```

常用预置包：

- `default-balanced`
- `fast-delivery`
- `high-security`
- `design-driven`
- `backend-stability`

### 5. 启动 workflow

```bash
./scripts/omni-context start-workflow /path/to/workspace my-project "Feature Delivery"
```

## 日常工作流

### 看总诊断

```bash
./scripts/omni-context project-doctor /path/to/workspace my-project
```

这是日常总入口。默认输出很短，只看：

- roles
- rules
- bundle
- runtime
- workflow
- tests

### 看 workflow

```bash
./scripts/omni-context workflow-status /path/to/workspace my-project
./scripts/omni-context workflow-check /path/to/workspace my-project
```

### 推进阶段

```bash
./scripts/omni-context advance-stage /path/to/workspace my-project design architecture
```

如果要跳过：

```bash
./scripts/omni-context skip-stage /path/to/workspace my-project design architecture "reason" "risk" "authority"
```

### 自动推进

```bash
./scripts/omni-context autopilot-run /path/to/workspace my-project
./scripts/omni-context autopilot-status /path/to/workspace my-project
```

规则：

- 默认持续推进到完成
- 只在真正阻塞时停下
- testing 阶段会自动尝试准备或执行正式测试

## 正式测试怎么用

## 测试规则

- testing 是硬门禁
- 正式测试只认非 `draft` suite
- run 会绑定 suite 指纹
- 不允许偷偷改用例后继续复用旧 run

### 1. 建 suite

```bash
./scripts/omni-context init-test-suite /path/to/workspace my-project homepage-smoke
```

### 2. 准备测试运行时

```bash
./scripts/omni-context setup-test-runtime /path/to/workspace my-project --platform web
./scripts/omni-context setup-test-runtime /path/to/workspace my-project --platform backend
```

规则：

- `web / miniapp`：默认准备浏览器运行时
- `backend`：只检查接口目标，不安装浏览器

### 3. Web 正式执行

优先走 DevTools：

```bash
./scripts/omni-context run-browser-suite-devtools /path/to/workspace my-project homepage-smoke --platform web
```

说明：

- 每一步按 suite 执行
- 动态定位页面元素
- 自动截图留证
- 失败会生成正式 failure run

Playwright 回退执行器：

```bash
./scripts/omni-context run-browser-suite /path/to/workspace my-project homepage-smoke --platform web
```

通常不需要手动跑，`collect-test-evidence` 会自动调度。

### 4. Backend 正式执行

```bash
./scripts/omni-context run-api-suite /path/to/workspace my-project health-check --platform backend
```

支持的步骤包括：

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

### 5. 统一采集证据

```bash
./scripts/omni-context collect-test-evidence /path/to/workspace my-project homepage-smoke --platform web
```

行为：

- `web / miniapp`：先 DevTools，必要时回退 Playwright
- `backend`：走 API 执行器

### 6. 看测试状态

```bash
./scripts/omni-context test-status /path/to/workspace my-project
```

## 数据库 / Redis 安全规则

高风险操作默认受保护：

- 删表
- 删数据
- 改表
- 批量更新
- Redis 大范围删除或清空

### 本地环境

- 允许执行
- 但必须先备份

### 正式环境

- 自动流程必须停下
- 必须说明要做什么
- 必须说明影响对象
- 必须说明为什么要做
- 必须等用户确认

### 常用命令

```bash
./scripts/omni-context backup-object /path/to/workspace my-project mysql_main users delete
./scripts/omni-context danger-check /path/to/workspace my-project mysql_main delete users
./scripts/omni-context record-dangerous-op /path/to/workspace my-project mysql_main delete users /path/to/backup.sql
```

## Git 规则

默认规则：

- 最小单提交
- 每次完成一个功能边界就提交
- 默认自动 push

手动收口命令：

```bash
./scripts/omni-context git-finish /path/to/repo "feat: your change"
```

## 推荐日常用法

### 新项目接入

```bash
init
status
init-project-standards
rules-pack-init
start-workflow
project-doctor
```

### 开发中

```bash
workflow-status
workflow-check
project-doctor
```

### 测试前

```bash
setup-test-runtime
test-status
```

### 想直接让它推进

```bash
autopilot-run
autopilot-status
```

## 当前版本建议

如果你不确定先跑什么，默认就这三条：

```bash
./scripts/omni-context project-doctor <workspace> <project>
./scripts/omni-context workflow-status <workspace> <project>
./scripts/omni-context test-status <workspace> <project>
```

这三条已经足够看出项目当前缺什么、卡在哪、下一步该做什么。
