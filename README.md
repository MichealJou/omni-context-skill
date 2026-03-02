# OmniContext

语言:
- [简体中文](README.zh-CN.md)
- [English](README.en.md)
- [日本語](README.ja.md)

OmniContext 是一套可复用的工作区知识管理 skill，适用于 Codex、Claude Code、Qoder、Trae 等编程工具。

它提供：
- 基于 `.omnicontext/` 的文件协议
- 面向共享知识、个人知识、项目知识的模板
- 面向多种编程工具的轻量入口适配
- `references/` 多语言入口，默认中文参考文档
- `init`、`sync`、`status`、`new-project`、`new-doc` 五个基础动作
- `check` 校验命令，用于维护三语言 references 和核心结构
- 按语言环境生成中文、英文、日文文档与提示词，默认中文
- 一个统一 CLI 入口：`scripts/omni-context`

完整说明：
- [中文说明](README.zh-CN.md)
- [English guide](README.en.md)
- [日本語ガイド](README.ja.md)

快速安装：
```bash
./scripts/install-skill.sh
```
