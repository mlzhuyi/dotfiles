---
name: browser-session-stability
description: "Run reliable browser automation by preserving login sessions, reusing auth safely, and separating API requests from UI actions. Use whenever browser automation, authenticated testing, login/consent/authorization pages, or repeated login failures are involved."
---

# Browser Session Stability

Use this skill with `agent-browser` whenever a task needs authenticated requests, real rendering, or browser interaction. Keep one predictable session and avoid making the user log in repeatedly. The rules apply to any website, not only a particular project.

## Decide whether a browser is needed

- For API/data verification, use direct API, logs, or database access first. Do not open a page just to submit data or obtain a token.
- Use a browser only for DOM/style/real-rendering/interaction evidence, or when an authenticated same-origin request must reuse browser state.
- If a visible page is required, state the exact target and navigate only to that target.

## Stable session lifecycle

1. Pick one session name for the task and pass it on **every** command: `agent-browser --session <name> <command>`. Do not use the `connect` subcommand (measured on 0.33.0: `connect 9222` prints `✓ Done` but the next command still drives a freshly launched browser on a random high port). A command with no `--session` runs on a session literally named `default` — which is also where other, unconfigured agents on this machine land. Derive the name once with `agent-browser session id --scope worktree --prefix <task>`.
2. On this machine the lifecycle mode is fixed: **attach to the visible automation Chrome on CDP 9222**, and let the config do it. `~/.agent-browser/config.json` sets `autoConnect: true` and `headed: true`. Do not use `--restore` to give a session a browser of its own — that instance gets a throwaway profile and no login state, so the user can neither watch it nor sign into it, and because it is a *new* browser it also pops a window and steals the user's focus. For the normal case do **not** pass `--cdp`: auto-connect outranks it and the CLI errors with "Cannot use --auto-connect and --cdp together". To deliberately drive a different instance, turn auto-connect off for that command instead: `--auto-connect false --cdp <port>`. Do not mix modes or create a second ad-hoc session after a failure.
3. For a visible Chrome with an existing login, use: `zsh -ic 'chrome-auto-start'` to make sure the instance is up; verify `http://127.0.0.1:9222/json/version`; then `agent-browser --session <name> ...`; list tabs; then act on an existing tab. Do not navigate until the target is explicit. Keep that same session name for the rest of the task — never drop back to a bare command, and never introduce a session name that was not the one you started with. If you ever do see `[agent-browser] launched browser`, you are driving a browser of your own instead of the user's — a configuration fault to fix, not a normal step.
4. Do not confuse CDP attachment with launching a new browser. If the port you need cannot be reached, inspect port/startup state and report it; do not silently fall back to a blank browser or another profile.
5. After navigation or any page-changing action, wait and snapshot again; earlier refs are stale.

### Which browser am I actually driving?

Session contexts are fully isolated (separate cookies, localStorage, tabs), and which browser a session drives is decided by the port it resolves — auto-connect's 9222 by default, or whatever a `--auto-connect false --cdp <port>` names. So one command that drops the `--session` flag silently drives a different, almost certainly logged-out browser. "The user sees a logged-in page while I see a login form" is this failure — not a lost session, not a backend restart, not expired cookies.

Before blaming the app, the cookies, or a service restart, run these read-only checks and compare against what the user says they see:

```bash
agent-browser session                       # which session am I on?
agent-browser session list                  # how many exist, which one is current?
agent-browser --session <name> get cdp-url  # which Chrome is this session attached to?
agent-browser --session <name> get url      # what page is that Chrome actually on?
agent-browser --session <name> tab list     # which tabs does the session think it has?
curl -s 127.0.0.1:9222/json/list            # which targets does the real browser expose?
```

- `cdp-url` points somewhere other than the port you meant → you are on the wrong instance. Re-run with the correct `--session`, naming the port with `--auto-connect false --cdp <port>` if it is not 9222. Do not log in again.
- `cdp-url` is a random high port (not `9222`) → agent-browser launched a browser for itself: headless, throwaway profile, no login state, invisible to the user. Nothing observed there describes what the user sees. Re-attach to 9222 and check the config file before investigating the app at all.
- The session's active tab is missing from `/json/list` → a **dead target**. `eval` and `snapshot` against it keep returning the old DOM, which is how a closed login page goes on "proving" the app signed the user out. Re-list tabs, switch to a target that exists in `/json/list`, then re-check.
- Two sessions both attached to the same port but on different pages → different tabs; list tabs and use the one the user is looking at.
- Only when `cdp-url` **and** the URL are both right may you treat a login page as a genuine auth loss.

### Concurrent tasks: one browser per task, one port per browser

Two tasks that share a port share **one browser and one set of tabs**. A new session does not get a private page: it opens its own `about:blank` in the user's window, and its "current tab" follows what is active in that browser. Measured: three fresh sessions all reported the identical tab set, `t1` was the user's own page in all three, and all three ended up current on the same `about:blank` — so a `click` in one session lands wherever another session last navigated, with no error.

Measured in the same run: concurrent activity navigated the user's **own** tab away from the page they were reading. Sharing a browser does not merely inconvenience the other task, it edits what the user is looking at.

- Default to **one task at a time** on 9222.
- Need real parallelism? **Claim a port, don't pick one.** `port=$(zsh -ic "chrome-auto-claim <task>")` returns a free port from the pool (9223+), starts its visible window, and records the claim. Then put `--auto-connect false --cdp <port>` on every command of that task (the `--auto-connect false` is required — auto-connect outranks `--cdp` and would otherwise pull the task back to 9222). Each port gets its own profile directory (`~/.chrome-automation-<port>`), its own window, and its own tabs. A fresh profile starts logged out — the user signs in there once, exactly as they did for 9222.
- **Claiming is idempotent per task name, so use one stable name for the whole task.** Call it as often as you like with the same name and you get the same port and the same browser; a *different* name claims a *second* port and pops a second window. Use the task's stable session id as that name (`agent-browser session id --scope worktree --prefix <task>`) so a restarted or resumed agent rejoins its own port instead of claiming a new one. Never mint a fresh name just to get a "clean" browser — that is how the user ends up with windows multiplying.
- `zsh -ic 'chrome-auto-release <task>'` frees a claim; the window deliberately stays so the next run reuses it. The pool is finite (8 ports) and a full pool is an error, so release tasks that are finished. `zsh -ic 'chrome-auto-list'` shows who holds what.
- If a task genuinely must share one browser, give it its own tab (`tab new --label <task>`), put `tab <label>` on every command, and close it when done. That prevents cross-talk between pages, but not focus stealing.
- Never leave tabs behind: close what you opened (`tab close <label>`), so the user's window does not fill up with your `about:blank`s.

### Do not steal the user's focus

Starting a browser or activating a tab brings Chrome to the front and cuts off whatever the user is typing in another app. `open -g` alone does not prevent it — Chrome activates itself on launch (measured: frontmost became `Google Chrome`). `chrome-auto-start` therefore launches **hidden** (`open -g -j`), and the frontmost app never changes (measured: frontmost stayed `iTerm2` across a full launch). Re-activating the previously frontmost app afterwards is kept only as a belt-and-braces fallback. "It switches away and switches back" is *not* an acceptable outcome — the keystrokes in between still land in Chrome or break the user's IME composition.

The cost is deliberate: a newly started instance has **no window on screen** until you bring it forward. That is what lets you start a browser mid-task without interrupting the user.

- To show it — or to hand it to the user to sign in — call `zsh -ic 'chrome-front <port>'`, which sets that process visible and frontmost. Use it only when the user actually needs to look at or type into the window; that is the login handoff below, not a "so you can see it" step.
- Prefer reusing an already-running instance over starting a new one.
- A command that names **no** port does not pop anything: `autoConnect` sends it to the already-running 9222. Dropping `autoConnect` was tried on 2026-09-29 and made every such call launch a fresh headed temp-profile window — measured: two unrelated sessions each popped one within 12 seconds, each stealing the user's focus mid-typing. That is why the config keeps `autoConnect: true` and parallel tasks opt out explicitly instead.

### Do not narrate a cause you have not verified

A symptom seen twice is not a rule. "Login drops every time the backend restarts" was invented from two observations and zero tests, and it sent the investigation to the wrong place.

- Report observation and location only: session name, `cdp-url`, URL, tab. Name a cause only after a check has ruled out the alternatives above.
- When the user says "I'm looking right at it and it's logged in", that is strong evidence about reality. Re-check your own context first instead of arguing — and do not spend a turn agreeing with them before you have checked.

### The automation browser is the one you must reuse

On this setup, the Chrome on port `9222` is the automation instance: a dedicated profile with its own `--user-data-dir`, kept separate from the user's everyday Chrome. The user maintains it deliberately and signs into sites there for automation, so treat its login state as real and reusable. Keep the two windows distinct in your reporting.

Never accept an automation instance the user cannot see. If a session is driving anything else — a random-port browser, a throwaway temp profile, a different `--user-data-dir` — say so and fix the attach before doing more work. Evidence collected in a browser the user cannot open is not evidence about what they will see, and a login form in that browser is an artifact of your own instance, never of their session.

This is a local convention, not a general law. On a machine where CDP attaches to the user's ordinary Chrome instead, do not carry the assumption over — when it matters, check the `--user-data-dir` the CDP target is actually running with rather than assuming either way.

A login form in *this* browser is therefore **your** problem first, not the environment's:

- The first and usually correct explanation is that you are driving the wrong instance — a drifted session, a bare command, or a browser that a new session name launched. Run the identity checks above before anything else.
- Never explain the login form away with "the user is probably signed in on their other Chrome", "the profile got reset", or "the session expired". You cannot see their other browser or their history, and inventing a cause you cannot observe is the same failure as "login drops every time the backend restarts".
- Only after `cdp-url` and `url` both check out may you report a missing session — report the observation and ask, never a theory, then continue into the login/consent classification below like any other unauthenticated page.

`chrome-auto-start` and `chrome-front` are shell functions from the user's `zshrc`, not `agent-browser` subcommands. They load only in a shell that has sourced `~/.zshrc`, so call them as `zsh -ic 'chrome-auto-start'` / `zsh -ic 'chrome-front'` — do not conclude they are missing just because a bare non-interactive shell cannot see them. `chrome-auto-start [port]` defaults to 9222 and restores the previously frontmost app afterwards. Do not substitute a headless browser of your own.

## Authentication and tokens

- Reuse the stable session's cookies/localStorage. Read only the one required token field in page context; never dump all cookies or storage.
- Prefer same-origin `fetch` in an already-authenticated page context for protected API calls. This avoids copying tokens into shell arguments.
- For repeated API checks within one Agent task, retain the token only in process memory and reuse it without asking the user again. Do not put short-lived tokens in a keychain, file, environment committed to disk, skill, transcript, logs, or command output.
- If the process or session ends, or the token expires, reacquire it from the same stable authenticated browser context. Do not reuse a stale token from a previous task.
- If an API-only task has no in-memory token and no authenticated context, stop and report the missing session; do not open a random frontend page merely to obtain a token. This gate is about *starting* a browser to get a token. It is never a reason to abandon a browser flow you already opened for legitimate evidence.
- A session loss is an operational failure: restore/reconnect the same session first, then re-run the identity checks to confirm you are back on the same browser rather than a fresh blank one. Do not ask for a token that was already obtained during the current task unless it expired or the user explicitly chooses to re-authenticate.

### When a login, consent, or authorization page appears

**Prove which browser you are looking at first.** Run the read-only identity checks in *Which browser am I actually driving?* before classifying anything. A login form reached on a drifted session, or on the wrong profile, is not an auth event at all — classifying it first is precisely how this skill fails. Classify only once `cdp-url` and `url` are confirmed on the intended browser.

**Complete it yourself** — the page only needs a click, and the session already carries the identity:

- OAuth/SSO consent screens, internal 一键授权 pages
- "Continue as `<already signed-in account>`", already-remembered account buttons, "同意并授权"
- Scope or risk confirmations plainly implied by the task you were given
- A device-authorization confirmation **only when the code on screen matches the code you requested in this task**

Click through, confirm the flow completed, then resume the original task. Do not ask the user, and do not stop to investigate alternatives. After clicking a login or authorize entry point, run `tab list` before snapshotting — OAuth and SSO flows frequently open a new tab or popup, and snapshotting the old tab forever is the usual reason a login form "never appears".

**Hand off to the user** — the next step needs something only a human has:

- Password entry, MFA/OTP/SMS, passkey, CAPTCHA
- Several accounts listed and the correct one is ambiguous
- Terms or permission choices that need a business decision
- Authority with real-world reach you cannot justify from the task itself: granting a new device, production write scope, bulk export
- A device-authorization confirmation whose code you did not request — you cannot verify who started that flow

**Never route around the prompt.** Do not go read backend auth config, extract a token from another source, switch profile, open a second session, or call an auth endpoint by hand. That is the "avoid disturbing the user" instinct; it costs more time than asking and still ends in the handoff anyway.

### Handing off a login to the user

Do all of this in one turn, then stop:

1. Bring the visible browser window to the front and leave it on the exact login/consent URL: switch that tab (`agent-browser --session <name> tab <tN>`), then `zsh -ic 'chrome-front 9222'` — it fronts the Chrome process holding that port, so multiple instances cannot make it front the wrong one. This handoff is the one place stealing focus is intended. Report the URL.
2. State in one sentence what the user must do, and what to reply when finished.
3. End the turn. Do not run unrelated investigation while waiting.

When the user replies, re-check authentication on that same session and resume the original task from the step that was blocked. Do not re-plan from the start or re-ask for anything you already have.

## API/UI separation and side effects

- Keep data creation, updates, and acceptance tests on APIs unless the user explicitly asks to validate the UI form itself.
- Use the UI only for the visual or interaction assertion that requires it; do not mix UI navigation into an API-only test.
- Before an external, business-level side effect (send, approve, delete, publish — not the auth-consent clicks already classified above), restate the exact target and environment. Keep local test actions local.

## Failure reporting

Classify failures precisely: CDP unavailable, session unauthenticated, target navigation failed, API/business error, or rendering/interaction failure. Include the next safe action and avoid speculative retries.

For "session unauthenticated", always resolve it into one of three states before reporting, because two of them are not failures at all:

- `consent-clickable` — a consent page is on screen and you can finish it yourself. Go do that instead of reporting.
- `awaiting-human` — a credential step is blocking; the user has been handed off per the template above. Say so in one line and wait.
- `unauthenticated-no-path` — no session, no login URL, and no browser evidence requirement. Only this state is a stop-and-report.

Never leave the user with a bare "没有登录态" and no indication of which state you are in.
