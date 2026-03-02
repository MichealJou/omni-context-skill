# OmniContext For Qoder

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

OmniContext 通过 `.omnicontext/` 提供共享工作区上下文。

必读顺序：

1. `.omnicontext/INDEX.md`
2. `.omnicontext/projects/<project>/overview.md`
3. `.omnicontext/projects/<project>/handoff.md`
4. 正式流程任务再读：
   - `standards/roles.toml`
   - `standards/rules-pack.toml`
   - `standards/skills.toml`
   - `standards/runtime.toml`
   - `standards/testing-platforms.toml`
   - `standards/standards-map.md`
5. 如果已有 workflow，再读 `workflows/current.toml`、`lifecycle.toml` 和当前阶段文档
6. testing 阶段再读 `tests/index.md`、suite、run
7. 仅在需要时再读相关的共享或个人文件

必须回写的内容：

1. 完成有意义的工作后更新 `handoff.md`
2. 开放任务变化时更新 `todo.md`
3. 做出非平凡选择时更新 `decisions.md`
4. 流程推进时更新 workflow 文件

默认简洁输出。不要修改测试用例，不要把密钥写进 `.omnicontext/`。
