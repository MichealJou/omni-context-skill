# 自动化行为

这里定义 OmniContext 自动化的目标行为。`install-skill`、`init`、`sync`、`status`、`new-project`、`new-doc` 已经有保守实现，其余仍然是设计目标。除非用户或项目策略另有要求，面向操作者的默认语言应为中文。

目前还包括：
- `git-finish`：按 Git 规则执行“一个功能一提交”，并默认在提交后自动 push

## `init`

目的：
- 在当前工作区创建新的 `.omnicontext/` 目录
- 保守推断工作区模式
- 从模板生成最小必需文件

预期行为：
- 如果已存在 `.omnicontext/`，默认避免覆盖
- 扫描可能的项目根目录，例如 Git 仓库和主要应用/服务目录
- 写入 `workspace.toml`
- 写入 `INDEX.md`
- 创建 `shared/standards.md`
- 创建 `personal/preferences.md`
- 为每个发现到或经用户确认的项目创建目录
- 按当前激活语言生成标题和面向操作者的文本，默认中文

## `sync`

目的：
- 根据当前工作区状态刷新 OmniContext 元数据

预期行为：
- 使用 `workspace.toml` 重新扫描工作区
- 检测新增或移除的项目根目录
- 更新 `INDEX.md`
- 默认只补充缺失项目目录，不自动删除已有笔记
- 尽量保留手写内容
- 对重建后的摘要和控制台输出使用当前激活语言

## `status`

目的：
- 报告当前 OmniContext 的健康状态和覆盖情况

预期输出：
- 工作区模式
- 发现到的项目列表
- 已映射项目列表
- 缺失的必需文件
- 过期或无法解析的映射
- 已本地化的状态输出文本，默认中文

## `new-project`

目的：
- 有意识地增加一个新的项目知识区域

预期行为：
- 创建 `projects/<project-name>/`
- 生成 `overview.md`、`handoff.md`、`todo.md`、`decisions.md`
- 将项目追加进 `INDEX.md`
- 需要时为 `workspace.toml` 添加或更新 `[[project_mappings]]`
- 使用当前激活语言生成初始项目记录

## `new-doc`

目的：
- 仅在工作区真正需要时创建附加文档

当前支持的目标：
- 技术文档
- 设计文档
- 产品文档
- 运行手册
- Wiki 页面
- 文档骨架应按当前激活语言生成

## 安全规则

- 不要把密钥写进 `.omnicontext/`
- 未经明确要求，不要自动删除已有项目笔记
- 优先采用增量生成，而不是破坏性重写
- 保留 `machine.local.toml`、`user.local.toml` 这类本地覆盖文件
