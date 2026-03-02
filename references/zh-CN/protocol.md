# OmniContext 协议

OmniContext 是一套保存在 `.omnicontext/` 下的工作区本地知识层。

## 最小结构

```text
.omnicontext/
  workspace.toml
  INDEX.md
  shared/
  personal/
  projects/
    <project-name>/
      overview.md
      handoff.md
      todo.md
      decisions.md
```

## 目录职责

`shared/`
- 适用于同一工作区多个项目的共享知识
- 例如：术语表、规范、架构原则、通用工具说明

`personal/`
- 个人但非敏感的偏好和工作约定
- 例如：写作偏好、命名习惯、重复使用的检查清单

`projects/<project-name>/`
- 某个项目或仓库专属的知识
- 存放执行上下文、决策记录和运行说明

## 核心文档

`INDEX.md`
- 整棵 OmniContext 树的入口文件
- 列出活跃项目和共享知识文件

`overview.md`
- 稳定的项目概览：目标、边界、主要目录、运行/测试入口

`handoff.md`
- 当前状态：最近进展、进行中的工作、下一步、阻塞项

`todo.md`
- 仍处于开放状态、可直接执行的事项

`decisions.md`
- 持久化的设计与实现决策，以及对应原因

## 扩展路径

只有当最小集合被证明有价值后再扩展。典型的下一层文件包括：

- `wiki/index.md`
- `docs/technical/index.md`
- `docs/design/index.md`
- `docs/runbook/index.md`

只有当工作区确实需要时，才增加这些文件。
