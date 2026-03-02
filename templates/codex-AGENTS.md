# OmniContext For Codex

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

在这个仓库里工作时：

1. 先读 `.omnicontext/INDEX.md`。
2. 根据当前任务或改动文件识别目标项目。
3. 在做实质性修改前，先读 `.omnicontext/projects/<project>/overview.md` 和 `.omnicontext/projects/<project>/handoff.md`。
4. 如果任务进入正式流程，再读：
   - `.omnicontext/projects/<project>/standards/roles.toml`
   - `.omnicontext/projects/<project>/standards/rules-pack.toml`
   - `.omnicontext/projects/<project>/standards/skills.toml`
   - `.omnicontext/projects/<project>/standards/runtime.toml`
   - `.omnicontext/projects/<project>/standards/testing-platforms.toml`
   - `.omnicontext/projects/<project>/standards/standards-map.md`
5. 如果已有流程实例，再读：
   - `.omnicontext/projects/<project>/workflows/current.toml`
   - 当前 workflow 的 `lifecycle.toml`
   - 当前阶段文档
6. 如果处于 testing 阶段，再读：
   - `.omnicontext/projects/<project>/tests/index.md`
   - 当前 suite
   - 当前 run
7. 只有共享规范或架构规则相关时，才读 `.omnicontext/shared/`。
8. 只有用户偏好会影响输出或流程时，才读 `.omnicontext/personal/`。
9. 有持续性进展后，更新相关的 `handoff.md`、`todo.md`、`decisions.md` 或 workflow 文件。
10. 默认简洁输出，只给结论、阻塞点和下一步。
11. 测试执行不得修改测试用例；前台客户端测试必须真实模拟用户交互。
12. 不要把密钥、Token 或私密凭证写进 `.omnicontext/`。
