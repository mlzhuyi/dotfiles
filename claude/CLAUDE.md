# Claude Code Global Configuration

## 文档生成
- 日期年份必须使用系统提供的 `Today's date`，不要用训练数据中的旧年份

## Shell Environment
- **CRITICAL**: ALL Bash commands MUST use `zsh -c "..."` to avoid scm_breeze errors
- Prefer dedicated tools (Glob, Read, Write, Edit) over shell commands

## MCP Tools

### lark-docx (飞书文档)
- 每个会话遇到权限错误时，先调用 `mcp__plugin_lark-docx_lark-mcp-dev__reload_credentials`

## Diagram Format
- **架构图**: 用 PlantUML（系统架构、组件关系、部署拓扑）
- **流程图/时序图**: 用 Mermaid（业务流程、数据流、状态图、ER图）
