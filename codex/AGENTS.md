# Codex Global Configuration

## 文档生成
- 日期和年份必须使用系统提供的当前日期，不要根据训练数据推断

## 浏览器
- 浏览器/UI 不是线上问题排障的默认数据源。先按“需求与代码 -> 直接接口响应 -> 日志 -> 数据库”补证据；只有 DOM、样式、真实渲染或浏览器事件无法替代时才启动浏览器。
- 需要网页检索、页面抓取或浏览器自动化时，使用 `$browser-session-stability`；该 Skill 是 Codex/Claude 共用的会话、登录态和 API/UI 分流规范。
- 必须复用登录态时，固定使用持久化会话并遵循 Skill 的连接顺序；禁止新建空会话、切换 profile、随机导航或反复要求登录。
- 只读取本次请求所需的单个认证字段，禁止导出或回显 Cookie/localStorage/Token；API 与 UI 分流、Token 安全存储和副作用确认规则详见该 Skill。

## 交付 / 验收
- 把工作交回用户之前（写"下一步""你可以做的"也算），以及在验收周期内每轮被质疑后重新举证时，先走 `$feature-acceptance`；该 Skill 是 Codex/Claude 共用的验收流程规范。

## 飞书文档
- 涉及 `feishu.cn` / `larksuite.com` 的文档、知识库或云盘对象时，优先使用 `lark-doc`、`lark-shared` 和 `lark-cli`；不要因为需要登录或已有 Cookie 就改走浏览器。
- Wiki 链接必须先通过 `wiki spaces get_node` 解析 `obj_type` 与真实 `obj_token`，不得直接把 `/wiki/` 路径 token 当作文档 token。
- 文档写入前确认用户意图；长文按章节分段写入，写入后必须用 `docs +fetch` 回读并核对标题、关键内容及图片/文件标签顺序。失败时保留现状并从原文档续写，不要静默重复创建。

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
