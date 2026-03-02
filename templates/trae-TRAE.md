# OmniContext For Trae

默认使用中文。如果用户、项目语言策略或 `user.local.toml` 明确要求英文或日文，再切换对应语言。

把 `.omnicontext/` 作为持久化的工作区知识层。

开始顺序：

1. 读取 `.omnicontext/INDEX.md`。
2. 确定相关项目。
3. 读取该项目的 `overview.md` 和 `handoff.md`。
4. 如果任务进入正式流程，再读取项目 `standards/` 和当前 workflow。
5. 如果是 testing 阶段，再读取测试 suite 和 run。
6. 只有任务需要时才读取共享或个人文件。

收尾顺序：

1. 有持续性进展后更新 `handoff.md`。
2. 开放工作变化时更新 `todo.md`。
3. 出现重要决策时更新 `decisions.md`。
4. 流程推进时更新 workflow 文件。

默认简洁交互。不要修改测试用例，不要把凭证或密钥写进 OmniContext 文件。
