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

1. Pass **both** the session name and the port on **every** command: `agent-browser --session <name> --cdp 9222 <command>`. Measured on 0.33.0, the session remembers **neither** on its own:

   - Drop `--cdp` and the next command silently drives a **private instance** instead — your first command talks to the shared signed-in browser, your second to a blank one. There is no warning.
   - `connect <port>` does not stick either: it answers `✓ Done`, yet the next command still launches a fresh browser on a random port. It does print `[agent-browser] relaunched browser` on the way, which is easy to miss in the surrounding output.
   - Drop `--session` and you land on a session literally named `default`, which is also where other unconfigured agents on this machine land.

   Derive the name once with `agent-browser session id --scope worktree --prefix <task>`.
2. `~/.agent-browser/config.json` sets exactly one thing that matters here: `headed: true`. There is **no `autoConnect`**. So the port you name decides everything, and there are two outcomes:

   - **Name `--cdp 9222`** → you drive the long-lived shared instance (persistent profile, the one the user keeps signed in).
   - **Name no port** → agent-browser launches a **private instance for your session**: visible, a throwaway profile, **logged out**.

   Both are headed and on screen. Pick deliberately — see *Which instance to use* below.
3. A session name is effectively **a browser**, not just a label: the first command on a new session name launches a window and takes the user's focus. So pick **one stable session name per task** (`agent-browser session id --scope worktree --prefix <task>`) and pass it on every command. Minting a new name mid-task gains nothing and costs the user another window. A command with no `--session` runs on a session literally named `default`.
4. Do not use `--restore`. It gives the session a throwaway-profile browser of its own — which is what naming no port already does — plus state files on disk that the token rules below forbid.
5. Do not confuse attaching to a port with launching a browser. If the port you need is unreachable, inspect port/startup state and report it; do not silently fall back to a blank browser or another profile.
6. After navigation or any page-changing action, wait and snapshot again; earlier refs are stale.

### Which browser am I actually driving?

Session contexts are fully isolated (separate cookies, localStorage, tabs), and the browser a session drives is decided by the port you name: `--cdp 9222` for the shared instance, or nothing at all for a private one of your own. So one command that drops the `--session` flag silently drives a different browser, and one that drops the port silently moves you from the user's signed-in instance to a blank private one. "The user sees a logged-in page while I see a login form" is this failure — not a lost session, not a backend restart, not expired cookies.

Before blaming the app, the cookies, or a service restart, run these read-only checks and compare against what the user says they see:

```bash
agent-browser session                       # which session am I on?
agent-browser session list                  # how many exist, which one is current?
agent-browser --session <name> get cdp-url  # which Chrome is this session attached to?
agent-browser --session <name> get url      # what page is that Chrome actually on?
agent-browser --session <name> tab list     # which tabs does the session think it has?
curl -s 127.0.0.1:9222/json/list            # which targets does the real browser expose?
```

- `cdp-url` points somewhere other than the port you meant → you are on the wrong instance. Re-run with the correct `--session` and `--cdp <port>`. Do not log in again.
- `cdp-url` is a random high port (not `9222`) → this session is on its own private instance: visible, throwaway profile, **logged out**. That is correct and intended for a task that needs no login. If you expected the user's session, you simply forgot `--cdp 9222` — fix that instead of investigating the app.
- The session's active tab is missing from `/json/list` → a **dead target**. `eval` and `snapshot` against it keep returning the old DOM, which is how a closed login page goes on "proving" the app signed the user out. Re-list tabs, switch to a target that exists in `/json/list`, then re-check.
- Two sessions both attached to the same port but on different pages → different tabs; list tabs and use the one the user is looking at.
- Only when `cdp-url` **and** the URL are both right may you treat a login page as a genuine auth loss.

### Concurrent tasks: one browser per task, one port per browser

Two tasks that share a port share **one browser and one set of tabs**. A new session does not get a private page: it opens its own `about:blank` in that shared window, and its "current tab" follows what is active in that browser. Measured: three fresh sessions all reported the identical tab set, `t1` was the same shared page in all three, and all three ended up current on the same `about:blank` — so a `click` in one session lands wherever another session last navigated, with no error.

Measured in the same run: concurrent activity navigated the user's **own** tab away from the page they were reading. Sharing a browser does not merely inconvenience the other task, it edits what the user is looking at.

The simplest isolation is free: **a task that names no port already has its own browser.** Concurrency is only a problem for tasks that must share 9222's login state.

- **One task per browser.** Either give each concurrent task its own session name and let it take a private instance, or serialize the tasks that need 9222.
- Need several **signed-in** instances at once? `zsh -ic 'chrome-auto-claim <task>'` hands out a port from a pool, each with its own **persistent** profile (`~/.chrome-automation-<port>`) so each can hold its own login. It is idempotent per task name — reuse one stable name and you get the same port and browser; a *different* name claims a *second* port and pops a *second* window, so never mint a fresh name per run. `zsh -ic 'chrome-auto-release <task>'` frees it; `chrome-auto-list` shows holders. A fresh profile starts logged out — the user signs in there once, as they did for 9222.
- If a task genuinely must share one browser, give it its own labelled tab (`tab new --label <task>`), put `tab <label>` on every command, and close it when done. That prevents cross-talk between pages — but not the focus steal that creating the tab costs (see below), and not the pile-up if you forget to close it.

### Do not steal the user's focus

Measured on this machine — the complete list of actions that cost the user their focus:

| action | steals focus? |
|---|---|
| the **first command on a new session name** (it launches a window) | **yes** |
| `open` / `snapshot` / `get` / `eval` / `console` on a session whose window already exists | no |
| `tab new` | **yes** |
| switching tabs (`tab <tN>`) | **yes** |
| `tab close` / `tab list` | no |

Creating a tab activates its window — that is the whole mechanism behind both "the focus jumped out of my terminal" and "there is a stray `about:blank`". One action, two symptoms. Nothing brings the focus back: these are agent-browser's own actions with no focus-restoring wrapper around them (unlike `chrome-auto-start`, which restores the previously frontmost app after launching), so focus stays on Chrome until the user clicks back — mid-sentence, if they were typing.

That leaves exactly two costs for you to control:

- **Launch cost — pay it once per task.** Use one session name for the whole task, so a window is created once instead of once per command. Keep instances long-lived; don't start and stop one per task.
- **Tab cost — avoid it entirely.** Stay in one tab: navigate with `open`, or in a SPA with `eval "location.hash='#/path'"` (measured: walking four routes that way never took focus). Reaching a different page is **not** a reason to switch tabs. If the task genuinely needs two pages visible at once, `tab new` once and close the extra the moment you are done — never leave `about:blank`s behind.
- `zsh -ic 'chrome-front 9222'` fronts the process listening on that port — for when the user actually needs to look at or type into a window (the login handoff below), never as a "so you can see it" step. That handoff is the one place stealing focus is intended.
- Prefer reusing an instance that is already up over starting another.

### Do not narrate a cause you have not verified

A symptom seen twice is not a rule. "Login drops every time the backend restarts" was invented from two observations and zero tests, and it sent the investigation to the wrong place.

- Report observation and location only: session name, `cdp-url`, URL, tab. Name a cause only after a check has ruled out the alternatives above.
- When the user says "I'm looking right at it and it's logged in", that is strong evidence about reality. Re-check your own context first instead of arguing — and do not spend a turn agreeing with them before you have checked.

### Which instance to use

Two kinds exist on this machine. Both are headed and on screen — **neither is headless**:

- **The shared instance, on `9222`** (`~/.chrome-automation`, a persistent profile kept separate from the user's everyday Chrome). The user keeps it signed in for automation, so treat its login state as real and reusable. Reach it with `--cdp 9222`. It is *shared*: concurrent sessions collide in it and pile up `about:blank`s, so run one task at a time there.
- **A private instance** — what you get by naming no port. A throwaway profile, **logged out**, gone with the session. Right for a task that needs no auth; wrong for anything that does. It costs one window and one focus steal per session name.

Never fall back to a **headless** browser of your own. The user must be able to watch what you do, and to sign in when a credential step needs them — evidence collected in a browser they cannot open is not evidence about what they will see.

This is a local convention, not a general law. On a machine where CDP attaches to the user's ordinary Chrome instead, do not carry the assumption over — when it matters, check the `--user-data-dir` the CDP target is actually running with rather than assuming either way.

A login form in *this* browser is therefore **your** problem first, not the environment's:

- The first and usually correct explanation is that you are on the wrong instance: a private, logged-out browser where you meant `--cdp 9222`, a drifted session, or a bare command. Run the identity checks above before anything else.
- Never explain the login form away with "the user is probably signed in on their other Chrome", "the profile got reset", or "the session expired". You cannot see their other browser or their history, and inventing a cause you cannot observe is the same failure as "login drops every time the backend restarts".
- Only after `cdp-url` and `url` both check out may you report a missing session — report the observation and ask, never a theory, then continue into the login/consent classification below like any other unauthenticated page.

`zsh -ic 'chrome-auto-start [port]'` (defaults to 9222) brings the shared instance up if it is down. `chrome-auto-start` and `chrome-front` are shell functions from the user's `zshrc`, not `agent-browser` subcommands — call them through `zsh -ic '...'`; a bare non-interactive shell cannot see them, which does not mean they are missing.

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
