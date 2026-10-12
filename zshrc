# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="self"

# proxy list
alias proxy='export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890'
alias unproxy='unset all_proxy && unset https_proxy && unset http_proxy'

export GO111MODULE=on
export GOSUMDB=sum.golang.google.cn
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git autojump extract zsh-autosuggestions zsh-syntax-highlighting gem bundler ruby rake)

#autojump_conf
[[ -s ~/.autojump/etc/profile.d/autojump.sh ]] && . ~/.autojump/etc/profile.d/autojump.sh

# User configuration

# export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# export MANPATH="/usr/local/man:$MANPATH"

# Prioritize Homebrew binaries over system binaries
export PATH="/opt/homebrew/bin:$PATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# p4 config
export P4CONFIG=.p4config

alias agi="ag --hidden --ignore .git"

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias chrome="\"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome\" --allow-file-access-from-files"
# chrome-auto: 浏览器自动化专用 Chrome 实例（独立 user-data-dir，CDP 端口 9222，不污染日常 Chrome）
# 用法: agent-browser connect 9222  /  Playwright connectOverCDP('http://localhost:9222')
alias chrome-auto="\"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome\" --remote-debugging-port=9222 --user-data-dir=$HOME/.chrome-automation --allow-file-access-from-files --no-first-run --no-default-browser-check"
# 每个自动化实例一个 profile 目录。同一目录不能开两个实例，所以并行任务必须用不同端口。
chrome-auto-profile() {
  local port="${1:-9222}"
  if [[ "$port" == "9222" ]]; then
    print -r -- "$HOME/.chrome-automation"
  else
    print -r -- "$HOME/.chrome-automation-$port"
  fi
}
# 该端口上是否已有可用的 CDP 端点（而不是恰好占着端口的路人服务）。
chrome-cdp-ready() {
  curl -fsS --max-time 1 "http://127.0.0.1:${1:-9222}/json/version" 2>/dev/null \
    | grep -q '"webSocketDebuggerUrl"'
}
# chrome-auto-start [port]：启动（或复用）一个可见的自动化 Chrome。
# 默认 9222。并行验收时给每个任务一个端口：chrome-auto-start 9223
# 新端口的 profile 是全新的，需要在该窗口里登录一次。
chrome-auto-start() {
  local port="${1:-9222}"
  local profile_dir
  profile_dir="$(chrome-auto-profile "$port")"
  local log_file="$profile_dir/chrome-auto.log"
  local chrome_app="/Applications/Google Chrome.app"
  local i

  # 端口上已有实例就直接复用；同 profile 不能开第二个实例。
  if chrome-cdp-ready "$port"; then
    return 0
  fi

  # 双保险：-j 隐藏启动已经不抢焦点了，这里再记一次当前前台应用并还回去，
  # 以防将来某版 Chrome 的启动行为变化又开始自我激活。
  local prev_app
  prev_app=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)

  mkdir -p "$profile_dir"
  # 通过 macOS LaunchServices 启动，避免调用 shell 退出时执行器回收整个子进程树；
  # nohup/disown 只能忽略 SIGHUP，无法绕过父级进程监督器的 descendant cleanup。
  # 启动即可见，与 agent-browser 自建实例的行为保持一致（用户要求"能看见"优先）。
  # Chrome 被拉起时会自己 activate，抢走用户正在打字的应用的焦点——这一点消除不了
  # （实测 open -g 压不住），所以启动完成后会把焦点还原回去，作为补救。
  /usr/bin/open -g -na "$chrome_app" --args \
    --remote-debugging-port="$port" \
    --user-data-dir="$profile_dir" \
    --allow-file-access-from-files \
    --no-first-run \
    --no-default-browser-check \
    >>"$log_file" 2>&1 || {
      print -u2 "chrome-auto 启动命令失败，日志见 $log_file"
      return 1
    }

  for i in {1..40}; do
    if chrome-cdp-ready "$port"; then
      break
    fi
    sleep 0.25
  done

  if ! chrome-cdp-ready "$port"; then
    print -u2 "chrome-auto 启动失败：CDP $port 未就绪，日志见 $log_file"
    return 1
  fi

  # 把焦点还给启动前的应用。窗口仍然可见（在后台），需要看时用 chrome-front $port。
  if [[ -n "$prev_app" ]]; then
    osascript -e "tell application \"System Events\" to set frontmost of (first process whose name is \"$prev_app\") to true" 2>/dev/null
  fi
  return 0
}
# 端口认领：多个任务并行时，靠 mkdir 的原子性分配端口，避免两个任务挤进同一个浏览器。
# 约定：9222 是用户自己的窗口，agent 的并行任务从 9223 起用。
chrome-auto-claim() {
  local task="${1:?用法: chrome-auto-claim <任务名> [起始端口]}"
  local base="${2:-9223}"
  local pool_end=$((base + 7))
  local lock_root="$HOME/.chrome-automation-ports"
  local d p

  mkdir -p "$lock_root"

  # 同一个任务重复认领：返回它已经占用的端口，避免重复起实例。
  for d in "$lock_root"/*(N/); do
    if [[ "$(cat "$d/owner" 2>/dev/null)" == "$task" ]]; then
      print -r -- "${d:t}"
      return 0
    fi
  done

  for (( p = base; p <= pool_end; p++ )); do
    if [[ -d "$lock_root/$p" ]]; then
      # 锁还在但实例已不在（agent 崩了没释放）→ 回收僵尸锁，否则端口池会被耗尽。
      if chrome-cdp-ready "$p"; then
        continue
      fi
      rm -rf "$lock_root/$p"
    fi
    # mkdir 是原子的：并发认领时只有一个任务能创建成功。
    if mkdir "$lock_root/$p" 2>/dev/null; then
      print -r -- "$task" > "$lock_root/$p/owner"
      date +%s > "$lock_root/$p/since"
      if ! chrome-auto-start "$p"; then
        rm -rf "$lock_root/$p"
        print -u2 "端口 $p 起实例失败，已释放"
        return 1
      fi
      print -r -- "$p"
      return 0
    fi
  done

  print -u2 "端口池 $base-$pool_end 已满；先 chrome-auto-release <任务名> 释放，或 chrome-auto-list 查看占用"
  return 1
}
# chrome-auto-release <任务名>：释放认领记录。不关浏览器 —— 窗口留着，下次复用就不用再弹一次。
chrome-auto-release() {
  local task="${1:?用法: chrome-auto-release <任务名>}"
  local lock_root="$HOME/.chrome-automation-ports"
  local d found=0
  for d in "$lock_root"/*(N/); do
    if [[ "$(cat "$d/owner" 2>/dev/null)" == "$task" ]]; then
      rm -rf "$d"
      found=1
      print -r -- "已释放端口 ${d:t}（浏览器窗口保留）"
    fi
  done
  (( found )) || print -u2 "没有找到任务 $task 的认领记录"
}
chrome-auto-list() {
  local lock_root="$HOME/.chrome-automation-ports"
  local d
  if [[ ! -d "$lock_root" ]] || [[ -z "$(ls -A "$lock_root" 2>/dev/null)" ]]; then
    print "当前没有端口被认领"
    return 0
  fi
  print "端口   任务                认领时间"
  local since ts
  for d in "$lock_root"/*(N/); do
    since="$(cat "$d/since" 2>/dev/null)"
    ts=""
    [[ -n "$since" ]] && ts="$(date -r "$since" '+%H:%M:%S' 2>/dev/null)"
    printf "%-6s %-19s %s\n" "${d:t}" "$(cat "$d/owner" 2>/dev/null)" "${ts:--}"
  done
}
# chrome-front [port]：把某个自动化 Chrome 窗口置前。
# 用途：需要人工观测或手动登录（密码/验证码）时，让用户能看到并操作正确的那个窗口。
chrome-front() {
  local port="${1:-9222}"
  local chrome_pid
  # 用 lsof 找监听该端口的进程：pgrep -f 在本机匹配不到 Chrome 的长命令行
  # （实测两种写法都返回空），会退化成"激活任意一个 Chrome"，也就是最该避免的切错窗口。
  chrome_pid=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null | head -1)

  if [[ -z "$chrome_pid" ]]; then
    print -u2 "未找到监听 $port 的 Chrome，请先运行 chrome-auto-start $port"
    return 1
  fi

  # 按 PID 精确置前，避免多个 Chrome 实例时激活到日常浏览器。
  # 先 set visible：隐藏启动（open -j）的实例必须显式显示出来才会出现窗口。
  if ! osascript \
      -e 'tell application "System Events"' \
      -e "set visible of (first process whose unix id is $chrome_pid) to true" \
      -e "set frontmost of (first process whose unix id is $chrome_pid) to true" \
      -e 'end tell' 2>/dev/null; then
    # 无辅助功能权限时的回退；可能激活到日常 Chrome，故打印提示。
    print -u2 "System Events 置前失败（需辅助功能权限），回退到 open -a"
    /usr/bin/open -a "/Applications/Google Chrome.app" 2>/dev/null || {
      print -u2 "置前失败，请手动切换到自动化 Chrome 窗口"
      return 1
    }
  fi
  return 0
}
alias be="bundle exec"
alias vim="ge nvim"
alias v="vim"
alias gcz="git add . && git cz"
export VISUAL=nvim
export EDITOR="$VISUAL"
export GIT_EDITOR="$VISUAL"
alias gup=gplr

# claude
cc() { claude --append-system-prompt "$(cat "$HOME/.claude/zh-prompt.txt")" "$@"; }
alias ccd="cc --dangerously-skip-permissions"

# codex
alias cx="codex -a never --sandbox workspace-write"
alias cxd="codex --dangerously-bypass-approvals-and-sandbox"

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Load external tools
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# 仅交互式 shell 加载 scm_breeze：非交互（如 Claude Code 快照）下加载会因
# exec_scmb_expand_args 进快照、_safe_eval 没进，导致每条命令报 _safe_eval not found
[[ -o interactive ]] && [ -s "$HOME/.scm_breeze/scm_breeze.sh" ] && source "$HOME/.scm_breeze/scm_breeze.sh"

export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"

# Wodouyao 桌面 App 网页入口（带 token 打开）
alias wdyweb='open "http://127.0.0.1:20002/#token=$(cat ~/.wodouyao/web-token)"'
