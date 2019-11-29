function _git_prompt_info {
    [[ -n $(whence git_prompt_info) ]] && git_prompt_info
}

local user_host='%{$terminfo[bold]$fg[green]%}%n@%m%{$reset_color%}'
local current_dir='%{$terminfo[bold]$FG[045]%} %~%{$reset_color%}'
local git_info='$(_git_prompt_info)%{$reset_color%}'


PROMPT="${user_host} ${current_dir} ${git_info}:<%D{%Y-%m-%d %T}>
~> "

function preexec() {
  timer=${timer:-$SECONDS}
}

function precmd() {
  if [ $timer ]; then
    timer_show=$(($SECONDS - $timer))
    export RPROMPT="%F{cyan}${timer_show}s %{$reset_color%}"
    unset timer
  else
    unset RPROMPT
  fi
}

ZSH_THEME_GIT_PROMPT_PREFIX="‹%{$FG[192]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="›%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg_bold[red]%} ✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg_bold[green]%} ✔ %{$reset_color%}"
