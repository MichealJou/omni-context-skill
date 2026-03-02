# 本地化规则

OmniContext 应基于一套共享协议支持多语言输出。

## 支持语言

- `zh-CN`
- `en`
- `ja`

## 语言解析顺序

按下面顺序选择工作语言：

1. 当前任务中的明确用户要求
2. `.omnicontext/shared/` 中定义的项目或工作区语言策略
3. `.omnicontext/user.local.toml` 中的本地用户默认值
4. 回退到 `zh-CN`

## 影响范围

语言会影响：

- generated handoff text
- wiki and document templates
- tool-facing summaries when the user asked for a specific language
- generated prompts, quick-start snippets, and operator-facing wording

语言不应改变：

- 配置键名
- 文件夹名称
- 协议结构

不同语言下应保持文件和配置结构稳定。

## 推荐策略

使用一套固定目录结构，让内容语言根据上下文变化。

示例：

- 中国区内部项目：`zh-CN`
- 面向全球用户的外部文档：`en`
- 面向日本的交付或协作：`ja`

## 共享策略与本地偏好

工作区或项目级语言要求应写入共享策略文件。
只有在项目没有更强约束时，才用 `user.local.toml` 表达个人默认偏好。

## 语言策略记录位置

建议把语言要求写到：

- `.omnicontext/shared/language-policy.md`：工作区级默认策略
- 项目 `overview.md`：当某个项目与工作区默认策略不同

## 翻译原则

除非业务确实要求完全独立的本地化内容，否则不要维护三套独立知识树。优先采用一套共享结构，再按语言生成内容。

## 按语言区分的提示词模板

工作流保持一致，只调整面向操作者的提示词风格：

- `zh-CN`
  - 默认中文提示词，语气直接、简洁，优先说明当前工作区状态、下一步动作和需要回写的文档
- `en`
  - 使用简洁的操作型英文提示词，明确工作区目标、执行动作和预期回写内容。
- `ja`
  - 日文提示词也应保持简洁，明确目标工作区、执行动作和需要更新的文档。
