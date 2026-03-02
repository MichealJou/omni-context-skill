# 适配层规则

工具适配文件应该只是轻量入口，不应该演变成独立知识系统。

## 目标

所有支持的编程工具都应读取同一套 `.omnicontext/` 数据，只保留最少量的工具特有措辞。

## 必须行为

每个适配文件都应要求工具：

1. 先读 `.omnicontext/INDEX.md`
2. 从任务内容或当前工作区域识别目标项目
3. 读取该项目的 `overview.md` 和 `handoff.md`
4. 只有共享规范或架构相关时才读取 `shared/`
5. 只有用户偏好相关时才读取 `personal/`
6. 在产生可持续变化后更新 `handoff.md`、`todo.md` 或 `decisions.md`

## 适配层边界

适配文件可以提到 `AGENTS.md`、`CLAUDE.md` 这类工具约定，但不应重新定义：

- 目录结构
- 配置语义
- 文档职责
- 更新规则

这些内容应统一由 OmniContext 协议和共享参考文档定义。

## 当前支持的入口文件

- `tools/codex/AGENTS.md`
- `tools/claude-code/CLAUDE.md`
- `tools/trae/TRAE.md`
- `tools/qoder/QODER.md`

只有在存在真实工具目标时，才继续增加新的适配层。
