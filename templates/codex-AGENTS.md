# OmniContext For Codex

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

在这个仓库里工作时：

1. 先读 `.omnicontext/INDEX.md`。
2. 根据当前任务或改动文件识别目标项目。
3. 在做实质性修改前，先读 `.omnicontext/projects/<project>/overview.md` 和 `.omnicontext/projects/<project>/handoff.md`。
4. 只有共享规范或架构规则相关时，才读 `.omnicontext/shared/`。
5. 只有用户偏好会影响输出或流程时，才读 `.omnicontext/personal/`。
6. 有持续性进展后，更新相关的 `handoff.md`、`todo.md` 或 `decisions.md`。
7. 不要把密钥、Token 或私密凭证写进 `.omnicontext/`。
