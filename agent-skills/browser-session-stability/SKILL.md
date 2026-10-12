---
name: browser-session-stability
description: "通过持久化登录会话、安全复用 auth、分离 API 请求与 UI 操作，可靠地执行浏览器自动化。凡是涉及浏览器自动化、需要登录态的测试、登录 / consent / 授权页面，或反复登录失败（browser automation, authenticated testing, login/consent/authorization pages, repeated login failures）的场景都应使用。"
---

# 浏览器会话稳定性

只要任务需要已认证请求、真实渲染或浏览器交互，就配合 `agent-browser` 使用本 skill。保持一个可预测的 session，不要让用户反复登录。这些规则适用于任何网站，不只是某个特定项目。

## 决定是否需要浏览器

- 做 API / 数据校验时，先用直接的 API、日志或数据库访问。不要为了提交数据或拿一个 token 就打开页面。
- 只在需要 DOM / 样式 / 真实渲染 / 交互证据，或必须复用浏览器状态发同源请求时，才使用浏览器。
- 如果确实需要可见页面，写明确切目标，并且只导航到那一个目标。

## 稳定的 session 生命周期

1. **每一条**命令都要同时带上 session 名和端口：`agent-browser --session <name> --cdp 9222 <command>`。在 0.33.0 上实测，session 自己**两者都不记**：

   - 漏掉 `--cdp`，下一条命令会静默驱动一个 **private instance**——你的第一条命令还在跟共享的已登录浏览器对话，第二条就在跟一个空白浏览器对话。没有任何警告。
   - `connect <port>` 也不生效：它回 `✓ Done`，但下一条命令照样在随机端口起一个新浏览器。它确实会打印 `[agent-browser] relaunched browser`，只是混在周围输出里很容易漏看。
   - 漏掉 `--session`，你会落到一个字面名为 `default` 的 session 上，而这台机器上其他没配置的 agent 也落在那里。

   用 `agent-browser session id --scope worktree --prefix <task>` 把名字推导一次。

2. `~/.agent-browser/config.json` 在这里只设置一件要紧的事：`headed: true`。**没有 `autoConnect`**。所以你指定的端口决定一切，结果只有两种：

   - **写 `--cdp 9222`** → 你驱动的是长期存活的 shared instance（持久化 profile，用户保持登录的那个）。
   - **不写端口** → agent-browser 为你的 session 起一个 **private instance**：可见、一次性 profile、**未登录**。

   两者都是 headed、都在屏幕上。要有意识地选——见下面的 *该用哪个 instance*。

3. session 名实际上**就是一个浏览器**，不只是个标签：新 session 名上的第一条命令会拉起一个窗口并抢走用户的 focus。所以每个任务**只固定用一个 session 名**（`agent-browser session id --scope worktree --prefix <task>`），每条命令都带上它。任务中途新造名字毫无收益，只会再花掉用户一个窗口。不带 `--session` 的命令会跑在一个字面名为 `default` 的 session 上。

4. 不要用 `--restore`。它给 session 一个自己的 throwaway-profile 浏览器——而那正是不指定端口时已经发生的事——外加磁盘上的状态文件，而下面的 token 规则禁止这类文件。

5. 不要把「连到一个端口」和「启动一个浏览器」搞混。如果需要的端口不可达，检查端口 / 启动状态并报告；不要静默退回到一个空白浏览器或另一个 profile。

6. 导航或任何会改变页面的操作之后，等待并重新 snapshot；之前的 refs 已经失效。

### 我实际驱动的是哪个浏览器？

各 session 上下文完全隔离（独立的 cookies、localStorage、标签页），而一个 session 驱动哪个浏览器，由你指定的端口决定：`--cdp 9222` 是 shared instance，什么都不写就是你自己私有的一个。所以漏掉 `--session` 的那条命令会静默驱动另一个浏览器，漏掉端口的那条会把你从用户的已登录 instance 悄悄挪到一个空白的 private instance。「用户看到的是已登录页面，而我看到的是登录表单」就是这个失败——不是 session 丢了，不是后端重启，也不是 cookie 过期。

在把锅甩给应用、cookie 或服务重启之前，跑这些只读检查，并与用户说他看到的东西对照：

```bash
agent-browser session                       # 我在哪个 session 上？
agent-browser session list                  # 有几个、哪个是当前的？
agent-browser --session <name> get cdp-url  # 这个 session 挂在哪个 Chrome 上？
agent-browser --session <name> get url      # 那个 Chrome 实际停在哪一页？
agent-browser --session <name> tab list     # 这个 session 认为自己有哪些标签页？
curl -s 127.0.0.1:9222/json/list            # 真实浏览器暴露了哪些 target？
```

- `cdp-url` 指向的不是你想要的端口 → 你在错误的 instance 上。带上正确的 `--session` 和 `--cdp <port>` 重跑。不要重新登录。
- `cdp-url` 是一个随机高位端口、不是 `9222` → 这个 session 在自己的 private instance 上：可见、一次性 profile、**未登录**。对不需要登录的任务来说这是正确且预期的。如果你本意是要用户的 session，那你就是忘了 `--cdp 9222`——去修这个，而不是去查应用。
- session 的活动标签页不在 `/json/list` 里 → 这是一个 **dead target**。对它 `eval` 和 `snapshot` 会一直返回旧 DOM，一个已经关掉的登录页就是这样「证明」应用把用户登出了。重新列标签页，切到 `/json/list` 里存在的 target，再重新检查。
- 两个 session 都连在同一个端口但页面不同 → 是不同的标签页；列出标签页，用用户正在看的那个。
- 只有当 `cdp-url` **和** URL 都正确时，你才可以把登录页当成真实的 auth 丢失。

### 并发任务：一个任务一个浏览器，一个浏览器一个端口

共享一个端口的两个任务共享**一个浏览器和一套标签页**。新 session 并不会拿到一个私有页面：它在那扇共享窗口里开自己的 `about:blank`，而它的「当前标签页」跟着那个浏览器里处于活动状态的东西走。实测：三个全新 session 报告了完全相同的标签页集合，`t1` 在三个里都是同一个共享页面，三个最终都停在同一个 `about:blank` 上——所以一个 session 里的 `click` 会落在另一个 session 最后导航到的地方，而且不报错。

同一次实测里：并发活动把用户**自己**的标签页从他正在读的页面上导航走了。共享一个浏览器不只是打扰另一个任务，它会改动用户正在看的东西。

最简单的隔离是免费的：**不指定端口的任务本来就有自己的浏览器。** 并发只对必须共享 9222 登录态的任务才是问题。

- **一个任务一个浏览器。** 要么给每个并发任务各自的 session 名、让它起一个 private instance，要么把需要 9222 的任务串行化。
- 需要同时有多个**已登录**的 instance？`zsh -ic 'chrome-auto-claim <task>'` 从池子里发一个端口，每个都有自己的**持久化** profile（`~/.chrome-automation-<port>`），因此每个都能各自保持登录。它按 task 名幂等——复用一个固定名字就能拿到同一个端口和浏览器；**换一个**名字会占用**第二个**端口并弹出**第二个**窗口，所以绝不要每次运行都新造名字。`zsh -ic 'chrome-auto-release <task>'` 释放它；`chrome-auto-list` 显示持有者。全新 profile 起始是未登录的——用户在其中登录一次，就像他为 9222 做的那样。
- 如果任务确实必须共享一个浏览器，给它一个自己带标签的 tab（`tab new --label <task>`），每条命令都带上 `tab <label>`，用完关掉。这能防止页面之间串扰——但防不了创建这个 tab 所要付出的 focus 抢占（见下），也防不了忘记关导致的堆积。

### 不要抢走用户的 focus

实测本机——会消耗用户 focus 的完整动作清单：

| 动作 | 会不会 steal focus？ |
|---|---|
| **新 session 名上的第一条命令**（它会拉起一个窗口） | **会** |
| 窗口已存在的 session 上的 `open` / `snapshot` / `get` / `eval` / `console` | 不会 |
| `tab new` | **会** |
| 切换标签页（`tab <tN>`） | **会** |
| `tab close` / `tab list` | 不会 |

创建标签页会激活它的窗口——这就是「focus 从我的终端跳走了」和「多出一个 stray `about:blank`」这两个症状背后的同一个机制。一个动作，两个症状。没有任何东西能把 focus 还回去：这些是 agent-browser 自己的动作，外面没有套一层恢复 focus 的包装（不像 `chrome-auto-start`，它会在启动后把之前最前的应用恢复回来），所以 focus 会一直留在 Chrome 上，直到用户自己点回来——如果他们正在打字，那就是打字打到一半。

于是只有两项成本由你控制：

- **启动成本——每个任务只付一次。** 整个任务用一个 session 名，这样窗口只创建一次，而不是每条命令一次。让 instance 长期存活；不要每个任务起一个停一个。
- **标签页成本——完全避免。** 留在一个标签页里：用 `open` 导航，或者在 SPA 里用 `eval "location.hash='#/path'"`（实测：这样走四条路由从未抢占 focus）。到达另一个页面**不是**切换标签页的理由。如果任务确实需要同时看到两个页面，`tab new` 一次，做完立刻关掉多出来的那个——不要留下 `about:blank`。
- `zsh -ic 'chrome-front 9222'` 会把监听该端口的进程调到前台——用在用户确实需要看、或需要往窗口里输入的时候（下面的登录交接），绝不要把它当作「让你也看看」的一步。那个交接是唯一一处有意抢占 focus 的地方。
- 优先复用一个已经起来的 instance，而不是再起一个。

### 不要讲一个你没验证过的原因

一个症状看到两次不构成规律。「后端每次重启登录态就掉」是凭两次观察、零次测试编出来的，它把调查带到了错的地方。

- 只报告观察和位置：session 名、`cdp-url`、URL、tab。只有在某个检查排除了上面那些替代项之后，才给原因。
- 当用户说「我正盯着它，它是登录着的」，那是关于现实的强证据。先重新检查你自己的上下文，而不是争辩——也不要在检查之前先花一轮去附和他。

### 该用哪个 instance

这台机器上有两种。两者都是 headed、都在屏幕上——**哪个都不是 headless**：

- **shared instance，在 `9222` 上**（`~/.chrome-automation`，一个与用户日常 Chrome 分开的持久化 profile）。用户为自动化保持它登录，所以把它的登录态当作真实且可复用的。用 `--cdp 9222` 访问它。**它不是一个特权浏览器或私人浏览器**——它只是一个恰好长期存活且已经登录的普通自动化 instance，和 `chrome-auto-claim` 发出去的那些端口属于同一类资源。所以不要为它发明特殊规则，也不要把它当成脆弱的：要回答的问题永远是*这个动作会不会打扰用户或另一个任务*，绝不是*这个窗口归谁*。（把这点搞反代价很大——曾把 9222 当成「用户的浏览器，别碰」，结果让一个设计的好几轮都跑偏了。）它是*共享*的：并发 session 会在里面撞车并堆积 `about:blank`，所以在那上面一次只跑一个任务。
- **private instance**——不指定端口得到的就是它。一次性 profile、**未登录**、随 session 消失。适合不需要 auth 的任务；任何需要 auth 的任务都不该用它。它每个 session 名要花一个窗口和一次 focus 抢占。

绝不要退回到你自己起的 **headless** 浏览器。用户必须能看着你做什么，并在需要凭据时能亲自登录——在一个他打不开的浏览器里收集到的证据，不是关于他将看到什么的证据。

这是本地约定，不是普遍规律。在 CDP 挂到用户日常 Chrome 的机器上，不要把这里的假设搬过去——必要时去查 CDP target 实际是以什么 `--user-data-dir` 在跑，而不是两种都靠猜。

所以*这个*浏览器里出现登录表单，首先是**你**的问题，不是环境的问题：

- 第一个、通常也是正确的解释是你在错误的 instance 上：一个私有的、未登录的浏览器，而你本意是 `--cdp 9222`；一个漂移的 session；或者一条裸命令。在做任何别的事之前先跑上面的身份检查。
- 绝不要用「用户大概在他的另一个 Chrome 上登录着」「profile 被重置了」「session 过期了」把登录表单解释掉。你看不到他的另一个浏览器，也看不到他的历史，编一个你观察不到的原因，跟「后端每次重启登录态就掉」是同一种失败。
- 只有 `cdp-url` 和 `url` 都对得上，你才可以报告 session 缺失——报告观察并询问，绝不给理论，然后像对待任何其他未认证页面一样，进入下面的登录 / consent 分类。

`zsh -ic 'chrome-auto-start [port]'`（默认 9222）在 shared instance 没起来时把它拉起来。`chrome-auto-start` 和 `chrome-front` 是用户 `zshrc` 里的 shell 函数，不是 `agent-browser` 的子命令——要通过 `zsh -ic '...'` 调用；裸的非交互 shell 看不到它们，但那不代表它们不存在。

## 认证与 token

- 复用稳定 session 的 cookies / localStorage。只在页面上下文里读取所需的那一个 token 字段；绝不要 dump 全部 cookie 或 storage。
- 对受保护的 API 调用，优先在已认证的页面上下文里发同源 `fetch`。这样避免把 token 复制进 shell 参数。
- 一个 Agent 任务内做重复的 API 检查时，token 只留在进程内存里复用，不要再次询问用户。不要把短命 token 放进 keychain、文件、提交到磁盘的环境变量、skill、transcript、日志或命令输出。
- 如果进程或 session 结束、或 token 过期，从同一个稳定的已认证浏览器上下文重新获取。不要复用上一个任务的陈旧 token。
- 如果纯 API 任务既没有内存中的 token，也没有已认证的上下文，停下并报告 session 缺失；不要为了拿一个 token 就打开一个随便的前端页面。这道闸门管的是*为拿 token 而启动浏览器*。它绝不是放弃一个你已经为正当证据打开的浏览器流程的理由。
- session 丢失是运维失败：先恢复 / 重连同一个 session，再跑身份检查确认你回到了同一个浏览器，而不是一个新的空白浏览器。不要索要当前任务里已经拿到的 token，除非它过期了或用户明确选择重新认证。

### 出现登录、consent 或授权页面时

**先证明你看的是哪个浏览器。** 在分类之前先跑 *我实际驱动的是哪个浏览器？* 里的只读身份检查。在一个漂移的 session 上、或在错误的 profile 上撞到的登录表单，根本不是 auth 事件——先对它分类正是这个 skill 失败的方式。只有在 `cdp-url` 和 `url` 都确认在预期浏览器上之后，才做分类。

**自己走完**——页面只需要一次点击，而 session 已经带着身份：

- OAuth/SSO consent 页面、内部一键授权页
- 「以 `<already signed-in account>` 继续」、已记住的账号按钮、「同意并授权」
- 你被交付的任务显然蕴含的 scope 或风险确认
- 设备授权确认——**仅当屏幕上的码与你在这个任务里请求的码一致时**

点过去，确认流程完成，然后回到原任务。不要问用户，也不要停下来研究替代方案。点击登录或授权入口之后，先跑 `tab list` 再 snapshot——OAuth 和 SSO 流程经常新开标签页或弹窗，而对旧标签页一直 snapshot 正是登录表单「从不出现」的常见原因。

**交接给用户**——下一步需要只有人类才有的东西：

- 密码输入、MFA/OTP/短信、passkey、CAPTCHA
- 列了多个账号且无法确定哪个是对的
- 需要业务决策的条款或权限选择
- 有真实世界影响、你无法从任务本身论证其正当性的权限：授予新设备、生产写权限、批量导出
- 一个码不是你请求的设备授权确认——你无法核实是谁发起了那个流程

**绝不要绕开提示。** 不要去读后端 auth 配置、从别的来源抽 token、切换 profile、开第二个 session，或手工调 auth 接口。那是「避免打扰用户」的本能；它比直接问更费时间，最后还是得交接。

### 把登录交接给用户

以下全部在同一轮做完，然后停下：

1. 把可见的浏览器窗口调到前台，让它停在确切的登录 / consent URL 上：切到那个标签页（`agent-browser --session <name> tab <tN>`），然后 `zsh -ic 'chrome-front 9222'`——它把持有该端口的 Chrome 进程调到前台，所以有多个 instance 也不会调错。这个交接是唯一一处有意抢占 focus 的地方。报告 URL。
2. 用一句话说明用户必须做什么，以及做完后回什么。
3. 结束这一轮。等待时不要跑无关的调查。

用户回复后，在同一个 session 上重新检查认证，并从被阻塞的那一步继续原任务。不要从头重新规划，也不要重新索要你已经有的东西。

## API/UI 分离与副作用

- 数据的创建、更新和验收测试都走 API，除非用户明确要求验证 UI 表单本身。
- 只为那个确实需要的视觉或交互断言使用 UI；不要把 UI 导航混进纯 API 测试。
- 在外部、业务级副作用（发送、审批、删除、发布——不是上面已经分类过的 auth-consent 点击）之前，重述确切目标和环境。把本地测试动作留在本地。

## 失败上报

精确分类失败：CDP 不可用、session 未认证、目标导航失败、API / 业务错误，或渲染 / 交互失败。给出下一步安全动作，避免投机性重试。

对于「session 未认证」，报告前必须归入三种状态之一，因为其中两种根本不是失败：

- `consent-clickable`——consent 页面就在屏幕上，你自己能走完。去做，而不是报告。
- `awaiting-human`——有凭据步骤阻塞；已按上面的模板交接给用户。用一行说明并等待。
- `unauthenticated-no-path`——没有 session、没有登录 URL，也没有浏览器证据需求。只有这个状态才是停下来报告。

绝不要只丢给用户一句「没有登录态」而不说明你在哪个状态。
