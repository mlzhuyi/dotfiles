# Claude Code Global Configuration

## 文档生成
- 日期年份必须使用系统提供的 `Today's date`，不要用训练数据中的旧年份

## Shell Environment
- Prefer dedicated tools (Glob, Read, Write, Edit) over shell commands

## MCP Tools

### Web 搜索和页面抓取
- WebSearch 和 WebFetch 无法使用，所有类似场景统一使用 `$browser-session-stability`（内部调用 `agent-browser`）。
- 普通查资料/搜内容/抓页面按该 Skill 的无头与会话分流规则执行，不在本节重复维护命令细节。

## 浏览器自动化
- 使用 `$browser-session-stability` 处理 agent-browser 的持久化会话、登录态复用、Token 安全和 API/UI 分流；Codex 与 Claude 共用同一份 Skill。
- 接口/数据回归优先直接走 API、日志或数据库；只有 DOM、样式、真实渲染或浏览器事件无法替代时才启动浏览器，并只导航到明确目标。
- 固定复用持久化会话，禁止新建空会话、切换 profile、随机导航或反复要求登录；连接失败先报告并恢复同一会话。

## 交付 / 验收
- 把工作交回用户之前（写"下一步""你可以做的"也算），以及在验收周期内每轮被质疑后重新举证时，先走 `$feature-acceptance`。
- **不必**调用该 skill：纯问答/解释、只读调查取证（读文件、grep、查日志或 API），以及不改变行为的措辞或格式调整（末项为覆盖 skill 中「轻量档」对该情形的默认）。直接给结论。
- 分档判据以该 skill 为准，这里不重复；完整档**必须起独立验收 agent**（不是可选项——大需求的验收靠子代理做隔离与主上下文保护）。拿不准按完整档走。

## 飞书文档
- 涉及 `feishu.cn` / `larksuite.com` 的文档、知识库或云盘对象时，优先使用 `lark-doc`、`lark-shared` 和 `lark-cli`；不要因为需要登录或已有 Cookie 就改走浏览器。
- Wiki 链接必须先通过 `wiki spaces get_node` 解析 `obj_type` 与真实 `obj_token`，不得直接把 `/wiki/` 路径 token 当作文档 token。
- 文档写入前确认用户意图；长文按章节分段写入，写入后必须用 `docs +fetch` 回读并核对标题、关键内容及图片/文件标签顺序。失败时保留现状并从原文档续写，不要静默重复创建。

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
- `wodouyao send <peer> "<text>"` — leave a message in a peer inbox
- `wodouyao inbox` / `wodouyao read <msg>` — receive and read messages
- `wodouyao tail <peer>` — fetch a peer's recent output
- `wodouyao whoami` / `wodouyao hello --name N --kind K` — identity

Wires on the canvas act as an ACL — only directly connected peers are
reachable. Full reference is in the `wodouyao` skill.
<!-- wodouyao:end -->
