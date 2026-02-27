#!/usr/bin/env zsh

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
total_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

# Last directory name only
dir_name="${cwd:t}"
[ -z "$dir_name" ] && dir_name="~"

# Git branch
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    if git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
      git_info=" | 🌿 %F{red}${branch}%f"
    else
      git_info=" | 🌿 %F{green}${branch}%f"
    fi
  fi
fi

# Context progress bar (10 blocks)
ctx_bar=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
  filled=$(( ctx_int * 10 / 100 ))
  empty=$(( 10 - filled ))
  bar=""
  for i in $(seq 1 $filled); do bar="${bar}█"; done
  for i in $(seq 1 $empty); do bar="${bar}░"; done
  if [ "$ctx_int" -lt 50 ]; then
    ctx_bar="%F{green}${bar} ${ctx_int}%%%f"
  elif [ "$ctx_int" -lt 80 ]; then
    ctx_bar="%F{yellow}${bar} ${ctx_int}%%%f"
  else
    ctx_bar="%F{red}${bar} ${ctx_int}%%%f"
  fi
fi

# Cost
cost_info=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  cost_fmt=$(printf "\$%.4f" "$cost_usd")
  cost_info=" | %F{yellow}${cost_fmt}%f"
fi

# Duration (total_duration_ms = API + tools + local processing)
dur_info=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
  dur_sec=$(( duration_ms / 1000 ))
  dur_min=$(( dur_sec / 60 ))
  dur_rem=$(( dur_sec % 60 ))
  total_dur_suffix=""
  if [ -n "$total_duration_ms" ] && [ "$total_duration_ms" != "0" ]; then
    total_sec=$(( total_duration_ms / 1000 ))
    total_min=$(( total_sec / 60 ))
    total_rem=$(( total_sec % 60 ))
    if [ "$total_min" -gt 0 ]; then
      total_dur_suffix=" / ⏱ ${total_min}m ${total_rem}s"
    else
      total_dur_suffix=" / ⏱ ${total_rem}s"
    fi
  fi
  if [ "$dur_min" -gt 0 ]; then
    dur_info=" | ⏱ ${dur_min}m ${dur_rem}s${total_dur_suffix}"
  else
    dur_info=" | ⏱ ${dur_rem}s${total_dur_suffix}"
  fi
fi

model_info="%B%F{cyan}[${model}]%f%b"
dir_info="📁 %B%F{45}${dir_name}%f%b"

print -P "${model_info} | ${ctx_bar}${cost_info} | ${dir_info}${git_info}${dur_info}"
