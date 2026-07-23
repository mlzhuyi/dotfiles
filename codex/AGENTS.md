# Codex Global Configuration

## 文档生成
- 日期和年份必须使用系统提供的当前日期，不要根据训练数据推断

## 浏览器
- 需要网页检索、页面抓取或浏览器自动化时，使用 `agent-browser` skill
- 普通查资料、搜索内容和抓取页面时，默认使用无头浏览器，不启动 `chrome-auto`
- 仅在需要已登录的 cookie/session 或验证真实 Chrome 渲染时，启动：`zsh -ic 'pgrep -f remote-debugging-port=9222 >/dev/null || (chrome-auto &) ; sleep 1.5'`
- `chrome-auto` alias 使用独立的 `~/.chrome-automation` user-data-dir 和 9222 CDP 端口，不影响日常 Chrome
- 使用 `agent-browser connect 9222` 或 Playwright `connectOverCDP` 接管真实 Chrome

## OpenAI Developer Docs MCP
- `openaiDeveloperDocs` 是用户明确禁用的 MCP；缺少对应工具表示“有意禁用”，不是“尚未安装”
- 禁止执行 `codex mcp add openaiDeveloperDocs`，也禁止删除或修改其 `enabled = false` 配置
- 需要 OpenAI/Codex 文档时，优先使用本地 Codex manual helper；不可用时仅从 OpenAI 官方网页检索

## 图表格式
- 架构图使用 PlantUML（系统架构、组件关系、部署拓扑）
- 流程图和时序图使用 Mermaid（业务流程、数据流、状态图、ER 图）

<!-- wodouyao:begin -->
## Wodouyao terminal integration

When the `WODOUYAO_ID` environment variable is set, you are running inside a
Wodouyao canvas terminal. Use the `wodouyao` skill to collaborate with other
terminals on the canvas:

- `wodouyao peers` — list wired peer terminal ids
- `wodouyao spawn --name N --command C` — create a new terminal (auto-wired)
- `wodouyao send <peer> "<text>"` — leave a message in a peer inbox
- `wodouyao inbox` / `wodouyao read <msg>` — receive and read messages
- `wodouyao tail <peer>` — fetch a peer's recent output
- `wodouyao whoami` / `wodouyao hello --name N --kind K` — identity

Wires on the canvas act as an ACL — only directly connected peers are
reachable. Full reference is in the `wodouyao` skill.
<!-- wodouyao:end -->
