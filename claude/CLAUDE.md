# Claude Code Global Configuration

## 文档生成
- 日期年份必须使用系统提供的 `Today's date`，不要用训练数据中的旧年份

## Shell Environment
- Prefer dedicated tools (Glob, Read, Write, Edit) over shell commands

## MCP Tools

### Web 搜索和页面抓取
- WebSearch 和 WebFetch 无法使用，所有类似场景改用 `agent-browser` skill

## 浏览器自动化
- 需要驱动真实 Chrome 时由 Claude 自己启动：`zsh -ic 'pgrep -f remote-debugging-port=9222 >/dev/null || (chrome-auto &) ; sleep 1.5'`
- `chrome-auto` alias 已在 `~/.zshrc`，独立 user-data-dir `~/.chrome-automation`，CDP 端口 9222，不污染日常 Chrome
- 用 `agent-browser connect 9222` 或 Playwright `connectOverCDP` 接管

## Diagram Format
- **架构图**: 用 PlantUML（系统架构、组件关系、部署拓扑）
- **流程图/时序图**: 用 Mermaid（业务流程、数据流、状态图、ER图）

<!-- wodouyao:begin -->
## Wodouyao terminal integration

When the `WODOUYAO_ID` environment variable is set, you are running inside a
Wodouyao canvas terminal. Use the `wodouyao` skill to collaborate with other
terminals on the canvas:

- `wodouyao peers` — list wired peer terminal ids
- `wodouyao spawn --name N --command C` — create a new terminal (auto-wired)
- `wodouyao send <peer> "<text>" Enter` — drive input on a peer
- `wodouyao read <peer>` — fetch a peer's recent output
- `wodouyao whoami` / `wodouyao hello --name N --kind K` — identity

Wires on the canvas act as an ACL — only directly connected peers are
reachable. Full reference is in the `wodouyao` skill.
<!-- wodouyao:end -->
