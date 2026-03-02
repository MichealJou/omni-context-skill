# OmniContext For Claude Code

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

开始工作前：

1. 读取 `.omnicontext/INDEX.md`。
2. 确定 `.omnicontext/projects/` 中哪个项目对应当前任务。
3. 读取该项目的 `overview.md` 和 `handoff.md`。
4. 只有任务依赖工作区级规则时，才读取 `.omnicontext/shared/`。
5. 只有用户偏好相关时，才读取 `.omnicontext/personal/`。

出现有效进展后：

1. 当前状态变化时更新 `handoff.md`。
2. 剩余工作变化时更新 `todo.md`。
3. 做出技术或流程决策时更新 `decisions.md`。

不要把密钥写进 `.omnicontext/`。
