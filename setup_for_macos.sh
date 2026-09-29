#!/usr/bin/env zsh
set -eu
setopt pipefail

repo_dir="${0:A:h}"
dry_run=0

usage() {
  print "Usage: ./setup.sh [--dry-run]"
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    -h|--help) usage; exit 0 ;;
    *) print -u2 "Unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

section() {
  print
  print "==> $1"
}

run() {
  print -r -- "+ ${(q)@}"
  (( dry_run )) || "$@"
}

retry() {
  local max_attempts="$1"
  shift
  local attempt=1

  until run "$@"; do
    if (( attempt >= max_attempts )); then
      return 1
    fi
    print -u2 "Retrying ($(( attempt + 1 ))/$max_attempts): $*"
    sleep $(( attempt * 2 ))
    attempt=$(( attempt + 1 ))
  done
}

ensure_dir() {
  [[ -d "$1" ]] || run mkdir -p "$1"
}

link_file() {
  local source_path="$1"
  local target_path="$2"
  local target_dir="${target_path:h}"

  ensure_dir "$target_dir"

  if [[ -L "$target_path" ]] && [[ "$(readlink "$target_path")" == "$source_path" ]]; then
    print "ok: $target_path"
    return
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    local backup_path="${target_path}.before-dotfiles"
    if [[ -e "$backup_path" || -L "$backup_path" ]]; then
      print -u2 "Refusing to replace $target_path; backup already exists: $backup_path"
      return 1
    fi
    run mv "$target_path" "$backup_path"
  fi

  run ln -s "$source_path" "$target_path"
}

clone_if_missing() {
  local repository="$1"
  local target_path="$2"

  if [[ -d "$target_path/.git" ]]; then
    print "ok: $target_path"
  elif [[ -e "$target_path" ]]; then
    print -u2 "Refusing to clone over existing path: $target_path"
    return 1
  else
    run git clone --depth 1 "$repository" "$target_path"
  fi
}

ensure_npm_global() {
  local command_name="$1"
  local package_name="$2"

  if (( dry_run )); then
    run npm install -g "$package_name"
    return
  fi

  if npm list -g --depth=0 "$package_name" >/dev/null 2>&1; then
    print "ok: $command_name"
  else
    run npm install -g "$package_name"
  fi
}

ensure_claude_marketplace() {
  local marketplace="$1"
  local source="$2"

  if (( dry_run )); then
    run claude plugin marketplace add "$source"
    return
  fi

  if claude plugin marketplace list 2>/dev/null | grep -Fq "$marketplace"; then
    print "ok: Claude marketplace $marketplace"
  else
    run claude plugin marketplace add "$source"
  fi
}

ensure_claude_plugin() {
  local plugin="$1"

  if (( dry_run )); then
    run claude plugin install "$plugin"
    return
  fi

  if claude plugin list 2>/dev/null | grep -Fq "$plugin"; then
    print "ok: Claude plugin $plugin"
  else
    run claude plugin install "$plugin"
  fi
}

ensure_codex_marketplace() {
  local marketplace="$1"
  local source="$2"

  if (( dry_run )); then
    run codex plugin marketplace add "$source"
    return
  fi

  if codex plugin marketplace list 2>/dev/null | grep -Fq "$marketplace"; then
    print "ok: Codex marketplace $marketplace"
  else
    run codex plugin marketplace add "$source"
  fi
}

ensure_codex_plugin() {
  local plugin="$1"

  if (( dry_run )); then
    run codex plugin add "$plugin"
    return
  fi

  if codex plugin list 2>/dev/null | grep -F "$plugin" | grep -Fq "installed,"; then
    print "ok: Codex plugin $plugin"
  else
    run codex plugin add "$plugin"
  fi
}

section "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  if (( dry_run )); then
    print "+ install Homebrew"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew_formulae=(
  autojump
  the_silver_searcher
  mercurial
  go
  graphviz
  delve
  golangci-lint
  gopls
  ttyd
  universal-ctags
  neovim
  gotags
  python
  node
  tig
  gnu-sed
  yazi
  ffmpeg-full
  sevenzip
  jq
  poppler
  fd
  ripgrep
  fzf
  zoxide
  resvg
  imagemagick-full
  tokei
)
run brew install "${brew_formulae[@]}"
run brew install --cask google-chrome claude-code font-symbols-only-nerd-font
run brew link --force --overwrite ffmpeg-full imagemagick-full

section "Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  if (( dry_run )); then
    print "+ install Oh My Zsh"
  else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
fi

zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ensure_dir "$zsh_custom/plugins"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$zsh_custom/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git \
  "$zsh_custom/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/scmbreeze/scm_breeze.git "$HOME/.scm_breeze"

# Run SCM Breeze's profile/config setup once, before ~/.zshrc becomes managed.
if [[ ! -f "$HOME/.git.scmbrc" ]]; then
  run bash "$HOME/.scm_breeze/install.sh"
fi

link_file "$repo_dir/self.zsh-theme" "$HOME/.oh-my-zsh/themes/self.zsh-theme"
link_file "$repo_dir/zshrc" "$HOME/.zshrc"
link_file "$repo_dir/zshenv" "$HOME/.zshenv"
[[ -f "$repo_dir/zshrc.local" ]] && link_file "$repo_dir/zshrc.local" "$HOME/.zshrc.local"

section "Go and GVM"
# Homebrew provides a current Go toolchain. GVM remains available for projects
# that need to switch versions, and registers the Homebrew Go as its system Go.
if [[ ! -s "$HOME/.gvm/scripts/gvm" ]]; then
  if (( dry_run )); then
    print "+ install GVM"
  else
    GVM_NO_UPDATE_PROFILE=1 bash < <(
      curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer
    )
  fi
fi

section "Rust"
if ! command -v rustc >/dev/null 2>&1; then
  if (( dry_run )); then
    print "+ install rustup"
  else
    curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
      | sh -s -- -y --no-modify-path
  fi
fi
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
link_file "$repo_dir/rust.config.toml" "$HOME/.cargo/config.toml"

section "Neovim"
ensure_dir "$HOME/.config/nvim/lua"
link_file "$repo_dir/vimrc" "$HOME/.config/nvim/init.vim"
link_file "$repo_dir/coc-settings.json" "$HOME/.config/nvim/coc-settings.json"
link_file "$repo_dir/avante_config.lua" "$HOME/.config/nvim/lua/avante_config.lua"

python_host="$HOME/.local/share/nvim/python3"
if [[ ! -x "$python_host/bin/python" ]]; then
  run python3 -m venv "$python_host"
  run "$python_host/bin/python" -m pip install --upgrade pip pynvim
fi

plug_vim="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [[ ! -f "$plug_vim" ]]; then
  ensure_dir "${plug_vim:h}"
  run curl -fLo "$plug_vim" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
run nvim --headless "+PlugInstall --sync" +qa
run nvim --headless \
  "+CocInstall -sync coc-lists coc-go coc-diagnostic coc-highlight coc-rust-analyzer" +qa
ensure_npm_global instant-markdown-d instant-markdown-d

section "Terminal and font"
link_file "$repo_dir/tmux.conf" "$HOME/.tmux.conf"
link_file "$repo_dir/tmux.conf.local" "$HOME/.tmux.conf.local"
ensure_dir "$HOME/Library/Fonts"
font_source="$repo_dir/Monaco Nerd Font Mono.otf"
font_target="$HOME/Library/Fonts/Monaco Nerd Font Mono.otf"
if [[ ! -f "$font_target" ]] || ! cmp -s "$font_source" "$font_target"; then
  run cp "$font_source" "$font_target"
else
  print "ok: $font_target"
fi

section "Git and global Node tools"
link_file "$repo_dir/czrc" "$HOME/.czrc"
link_file "$repo_dir/config/git/ignore" "$HOME/.config/git/ignore"
ensure_npm_global cz commitizen
ensure_npm_global lint-staged lint-staged
ensure_npm_global husky husky
ensure_npm_global ccusage ccusage
ensure_npm_global gemini @google/gemini-cli
ensure_npm_global codex @openai/codex

section "Claude and Codex"
ensure_dir "$HOME/.claude"
link_file "$repo_dir/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$repo_dir/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$repo_dir/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link_file "$repo_dir/claude/zh-prompt.txt" "$HOME/.claude/zh-prompt.txt"

ensure_dir "$HOME/.codex/rules"
ensure_dir "$HOME/.codex/skills"
ensure_dir "$HOME/.claude/skills"
ensure_dir "$HOME/.agents/skills"
link_file "$repo_dir/agent-skills/browser-session-stability" \
  "$HOME/.codex/skills/browser-session-stability"
link_file "$repo_dir/agent-skills/browser-session-stability" \
  "$HOME/.claude/skills/browser-session-stability"
link_file "$repo_dir/agent-skills/browser-session-stability" \
  "$HOME/.agents/skills/browser-session-stability"
link_file "$repo_dir/agent-skills/feature-acceptance" \
  "$HOME/.codex/skills/feature-acceptance"
link_file "$repo_dir/agent-skills/feature-acceptance" \
  "$HOME/.claude/skills/feature-acceptance"
link_file "$repo_dir/agent-skills/feature-acceptance" \
  "$HOME/.agents/skills/feature-acceptance"
if [[ ! -f "$repo_dir/codex/config.toml" ]]; then
  run cp "$repo_dir/codex/config.toml.example" "$repo_dir/codex/config.toml"
fi
link_file "$repo_dir/codex/config.toml" "$HOME/.codex/config.toml"
link_file "$repo_dir/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$repo_dir/codex/rules/deny-openai-developer-docs-mcp.rules" \
  "$HOME/.codex/rules/deny-openai-developer-docs-mcp.rules"

section "Agent tooling"
# Install the current CLI explicitly; agent-browser install is safe to rerun
# and downloads its matching browser only when needed.
run npm install -g agent-browser@latest
if ! retry 2 agent-browser install; then
  print -u2 "Dedicated Chrome download failed; checking the system Chrome fallback."
fi
run agent-browser doctor --offline --quick
# headed: true —— agent-browser 万一自己启动浏览器，必须可见，不能再出现
# headless + 临时 profile、用户看不见也登录不了的实例。
# autoConnect: true —— 没写端口的调用落到已在运行的 9222，而不是每次弹一个新窗口
# （实测：去掉它之后，两个会话在 12 秒内各弹了一个临时 profile 窗口并抢走用户焦点）。
# 需要独立实例的任务显式绕开：--auto-connect false --cdp <port>。
link_file "$repo_dir/config/agent-browser/config.json" \
  "$HOME/.agent-browser/config.json"

ensure_claude_marketplace agent-browser https://github.com/vercel-labs/agent-browser
ensure_claude_plugin agent-browser@agent-browser
ensure_claude_marketplace context7-marketplace https://github.com/upstash/context7
ensure_claude_plugin context7-plugin@context7-marketplace
ensure_claude_marketplace superpowers-marketplace obra/superpowers-marketplace
ensure_claude_plugin superpowers@superpowers-marketplace

ensure_codex_marketplace context7-marketplace upstash/context7
ensure_codex_plugin context7@context7-marketplace
ensure_codex_plugin superpowers@openai-curated

run npx --yes skills@latest add vercel-labs/agent-browser \
  --global --agent codex --skill agent-browser --yes
if ! command -v lark-cli >/dev/null 2>&1; then
  run npx @larksuite/cli@latest install
fi
run npx --yes skills@latest add alchaincyf/huashu-design \
  --global --agent claude-code codex --skill huashu-design --yes

section "Yazi"
link_file "$repo_dir/config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

print
print "Finished all config tasks. Start a new zsh session to load the changes."
