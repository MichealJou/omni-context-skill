# OmniContext For Claude Code

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

开始工作前：

1. 读取 `.omnicontext/INDEX.md`。
2. 确定 `.omnicontext/projects/` 中哪个项目对应当前任务。
3. 读取该项目的 `overview.md` 和 `handoff.md`。
4. 如果任务进入正式流程，再读取项目 `standards/` 下的角色、规则包、技能包、运行时、测试平台和标准映射文件。
5. 如果流程已启动，再读取 `workflows/current.toml`、当前 `lifecycle.toml` 和当前阶段文档。
6. 如果任务处于 testing 阶段，再读取 `tests/index.md`、当前 suite 和 run。
7. 只有任务依赖工作区级规则时，才读取 `.omnicontext/shared/`。
8. 只有用户偏好相关时，才读取 `.omnicontext/personal/`。

出现有效进展后：

1. 当前状态变化时更新 `handoff.md`。
2. 剩余工作变化时更新 `todo.md`。
3. 做出技术或流程决策时更新 `decisions.md`。
4. 流程推进时同步更新 workflow 状态文件。

默认保持简洁输出。不要修改测试用例，不要把密钥写进 `.omnicontext/`。
