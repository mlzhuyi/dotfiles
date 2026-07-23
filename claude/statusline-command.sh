#!/usr/bin/env zsh
# Vital HUD statusline — self-contained (Mac/Linux).
# Reads Claude Code session JSON on stdin, prints a one-line status:
#
#   [Model] | <ctx-bar> NN% | cost $X | <budget-bar> NN% left $Y <pool> | 📁 dir 🌿 branch | ⏱ dur
#
# The gateway balance is fetched inline from ${ANTHROPIC_BASE_URL}/user/balance
# (cached 60s in /tmp) using ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY. No
# plugin, no hook, no node. If neither key / base URL is set, the balance part
# is simply omitted and everything else still works.

# `statusline-command.sh legend` (or -h/--help) prints the legend and exits —
# so users can recall what each part means without digging up the docs.
if [ "${1:-}" = "legend" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat <<'LEGEND'
Vital HUD 状态栏图例 —— 整行从左到右

  [Opus 4.8] | █░░░░ 29% 58k/200k | cost $0.1234 ↑1.2M ↓5.3k | ██░░░ 52% left $123.45 【示例】演示资源池 | 📁 demo-proj | 🌿 main | ⏱ 1m 23s / ⏱ 5m 0s

  1. [Opus 4.8]        — 当前模型显示名(青色加粗)
  2. █░░░░ 29%         — 上下文窗口占用率：<50% 绿、<80% 黄、≥80% 红
     58k/200k          — 上下文已用 token / 窗口总量
  3. cost $0.1234      — 本 session 累计 API 花费(美元),为 0 不显示
     ↑1.2M ↓5.3k       — 本 session 累计 token：↑输入(含 cache 读写) ↓输出
  4. ██░░░ 52%         — 网关预算池已用比例：≥80% 黄、≥95% 红(无 allocated 不显示)
  5. left $123.45      — 网关剩余余额：负数/停用 红+⚠、<$10 黄、否则绿
  6. 【示例】演示资源池 — 余额所属资源池名(pool_name),无则省略
  7. 📁 demo-proj      — 当前目录名(仅末段)
  8. 🌿 main           — git 分支：有未提交改动 红、干净 绿(超 15 字截断)
  9. ⏱ 1m 23s / 5m 0s  — 本轮 API 耗时 / 本 session 总耗时

  · 窄屏自动精简,只保留 模型 + 上下文 + cost + 余额。
  · 余额三段(预算条/余额/资源池)需配好 ANTHROPIC_BASE_URL + AUTH_TOKEN/API_KEY
    且接口可达才显示;否则静默省略,不影响其余。
  · 用官方 Claude.ai 订阅(Pro/Max/Team,未配 AUTH_TOKEN/API_KEY,请求不到预算池)时,
    上述余额段自动替换为「官方 5h NN%(Xh Ym) 7d NN%(Xd Yh)」(倒计时内部带空格)——用量数据来自 Claude Code
    自带的 rate_limits 字段(5小时/7天用量占比 + 重置倒计时),同样 <80% 绿、<95% 黄、否则红。
LEGEND
  exit 0
fi

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_used_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size_tok=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // empty')
total_duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
session_id=$(echo "$input" | jq -r '.session_id // "default"')

# Compact token count: 850 / 9.5k / 120k / 1.2M
format_tok() {
  awk -v n="$1" 'BEGIN{
    if (n >= 1000000)  { v = n / 1000000; if (v >= 100) printf "%.0fM", v; else printf "%.1fM", v }
    else if (n >= 1000){ v = n / 1000;    if (v >= 100) printf "%.0fk", v; else printf "%.1fk", v }
    else               { printf "%d", n }
  }'
}

# Last directory name only
dir_name="${cwd:t}"
[ -z "$dir_name" ] && dir_name="~"

# Git branch (truncated to 15 chars)
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    branch_display="$branch"
    [ "${#branch}" -gt 15 ] && branch_display="${branch[1,15]}…"
    if git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
      git_info=" | 🌿 %F{red}${branch_display}%f"
    else
      git_info=" | 🌿 %F{green}${branch_display}%f"
    fi
  fi
fi

# Context bar (5 blocks + % + absolute tokens)
ctx_tok=""
if [ -n "$ctx_used_tok" ] && [ -n "$ctx_size_tok" ] && [ "$ctx_size_tok" != "0" ]; then
  ctx_tok=" %F{245}$(format_tok "$ctx_used_tok")/$(format_tok "$ctx_size_tok")%f"
fi
ctx_bar=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
  filled=$(( ctx_int * 5 / 100 ))
  empty=$(( 5 - filled ))
  bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done
  if [ "$ctx_int" -lt 50 ]; then
    ctx_bar="%F{green}${bar} ${ctx_int}%%%f${ctx_tok}"
  elif [ "$ctx_int" -lt 80 ]; then
    ctx_bar="%F{yellow}${bar} ${ctx_int}%%%f${ctx_tok}"
  else
    ctx_bar="%F{88}${bar} ${ctx_int}%%%f${ctx_tok}"
  fi
fi

# Session cost
cost_info=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  cost_fmt=$(printf "%.4f" "$cost_usd")
  cost_info=" | %F{yellow}cost \$${cost_fmt}%f"
fi

# Session cumulative tokens (incremental transcript parse).
# The stdin JSON has no session-total token field, so we sum message.usage
# from the transcript JSONL. A per-session cache in /tmp stores the running
# totals plus a consumed-line count, so each refresh only parses newly
# appended lines (`wc -l` counts newlines, so a partially written trailing
# line is naturally left for the next refresh). The same assistant message
# appears once per content block with identical usage — dedupe by message.id
# (duplicates are near-adjacent, a small window of recent ids is enough).
tok_info=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  tok_cache="/tmp/hud_tok_cache_${session_id}.txt"
  tok_lines=0; tok_in=0; tok_out=0; seen_ids=""
  if [ -f "$tok_cache" ]; then
    cache_head=$(sed -n '1p' "$tok_cache" 2>/dev/null)
    tok_lines=$(echo "$cache_head" | awk '{print $1+0}')
    tok_in=$(echo "$cache_head" | awk '{print $2+0}')
    tok_out=$(echo "$cache_head" | awk '{print $3+0}')
    seen_ids=$(sed -n '2p' "$tok_cache" 2>/dev/null)
  fi
  total_lines=$(wc -l < "$transcript_path" 2>/dev/null | tr -d '[:space:]')
  total_lines=${total_lines:-0}
  if [ "$total_lines" -lt "$tok_lines" ]; then
    tok_lines=0; tok_in=0; tok_out=0; seen_ids=""
  fi
  if [ "$total_lines" -gt "$tok_lines" ]; then
    # A missing id is emitted as "-" so no field is ever empty — a leading
    # empty field would be collapsed by IFS and shift the numbers into the
    # wrong variables.
    while IFS=$'\t' read -r mid m_in m_out; do
      [ -z "$m_out" ] && continue
      if [ "$mid" != "-" ]; then
        case " $seen_ids " in *" $mid "*) continue ;; esac
        seen_ids="$seen_ids $mid"
      fi
      tok_in=$(( tok_in + m_in ))
      tok_out=$(( tok_out + m_out ))
    done < <(sed -n "$(( tok_lines + 1 )),${total_lines}p" "$transcript_path" \
      | jq -Rr 'fromjson? | select(.message.usage != null)
          | [ (.message.id // "-"),
              ((.message.usage.input_tokens // 0)
               + (.message.usage.cache_creation_input_tokens // 0)
               + (.message.usage.cache_read_input_tokens // 0)),
              (.message.usage.output_tokens // 0) ] | @tsv' 2>/dev/null)
    # Keep only the most recent ids — duplicates never appear far apart.
    seen_ids=$(echo "$seen_ids" | awk '{ s = (NF > 32) ? NF - 31 : 1;
      for (i = s; i <= NF; i++) printf "%s%s", $i, (i < NF) ? " " : "" }')
    tok_lines=$total_lines
    { echo "$tok_lines $tok_in $tok_out"; echo "$seen_ids"; } > "$tok_cache" 2>/dev/null
  fi
  if [ "$tok_in" -gt 0 ] || [ "$tok_out" -gt 0 ]; then
    tok_info=" %F{245}↑$(format_tok "$tok_in") ↓$(format_tok "$tok_out")%f"
  fi
fi

# Duration
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

# LLM balance (cached 60s) — key is ANTHROPIC_AUTH_TOKEN or ANTHROPIC_API_KEY.
balance_amt=""
budget_bar_info=""
api_key="${ANTHROPIC_AUTH_TOKEN:-${ANTHROPIC_API_KEY:-}}"
if [ -n "$api_key" ] && [ -n "$ANTHROPIC_BASE_URL" ]; then
  key_suffix="${api_key: -8}"
  cache_file="/tmp/llm_balance_cache_${key_suffix}.json"
  now=$(date +%s)
  cache_age=999
  if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
    cache_age=$(( now - cache_mtime ))
  fi
  if [ "$cache_age" -ge 60 ]; then
    curl -s --max-time 3 "${ANTHROPIC_BASE_URL}/user/balance" \
      -H "Authorization: Bearer ${api_key}" \
      > "$cache_file" 2>/dev/null || rm -f "$cache_file"
  fi
  if [ -f "$cache_file" ]; then
    is_active=$(jq -r '.is_active' "$cache_file" 2>/dev/null)
    allocated=$(jq -r '.allocated // "0"' "$cache_file" 2>/dev/null)
    total_used=$(jq -r '.total_used // "0"' "$cache_file" 2>/dev/null)
    pool_name=$(jq -r '.pool_name // ""' "$cache_file" 2>/dev/null)
    balance=$(jq -r '.balance // ""' "$cache_file" 2>/dev/null)

    if [ -n "$balance" ]; then
      # Budget usage bar (5 blocks + %). awk for float math — present on every
      # Mac/Linux, unlike bc.
      if [ -n "$allocated" ] && [ "$allocated" != "0" ]; then
        used_pct_b=$(awk -v u="$total_used" -v a="$allocated" 'BEGIN{ if(a+0==0){print 0}else{printf "%d", u*100/a} }' 2>/dev/null)
        used_pct_b=${used_pct_b:-0}
        if [ "$used_pct_b" -ge 100 ]; then
          used_pct_b=100; filled_b=5; empty_b=0
        else
          filled_b=$(( used_pct_b * 5 / 100 ))
          empty_b=$(( 5 - filled_b ))
        fi
        bar_color="%F{green}"
        [ "$used_pct_b" -ge 80 ] && bar_color="%F{yellow}"
        [ "$used_pct_b" -ge 95 ] && bar_color="%F{88}"
        blocks=""
        for (( i=0; i<filled_b; i++ )); do blocks+="█"; done
        for (( i=0; i<empty_b; i++ )); do blocks+="░"; done
        budget_bar_info=" ${bar_color}${blocks} ${used_pct_b}%%%f"
      fi

      # Balance amount (always show, text label)
      bal_num=$(printf "%.2f" "$balance" 2>/dev/null)
      is_neg=$(awk -v b="$balance" 'BEGIN{print (b+0<0)?1:0}' 2>/dev/null)
      is_low=$(awk -v b="$balance" 'BEGIN{print (b+0>=0 && b+0<10)?1:0}' 2>/dev/null)
      if [ "$is_active" = "false" ] || [ "$is_neg" = "1" ]; then
        bal_color="%F{88}"
        bal_prefix="⚠ left"
      elif [ "$is_low" = "1" ]; then
        bal_color="%F{yellow}"
        bal_prefix="left"
      else
        bal_color="%F{green}"
        bal_prefix="left"
      fi
      pool_suffix=""
      [ -n "$pool_name" ] && pool_suffix=" %F{245}${pool_name}%f"
      balance_amt=" |${budget_bar_info} ${bal_color}${bal_prefix} \$${bal_num}%f${pool_suffix}"
    fi
  fi
fi

# Official Claude.ai subscription usage (rate_limits.five_hour/seven_day) —
# only shown when the gateway pool balance above is unavailable (no
# ANTHROPIC_AUTH_TOKEN/API_KEY, or the token doesn't map to a budget pool).
# Claude Code puts this on stdin for Pro/Max/Team subscribers after the
# session's first API response; absent entirely for API-key/gateway users.
if [ -z "$balance_amt" ]; then
  five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
  seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
  five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  if [ -n "$five_h_pct" ] || [ -n "$seven_d_pct" ]; then
    now_epoch=$(date +%s)
    rl_parts=""
    for rl_pair in "5h:${five_h_pct}:${five_h_reset}" "7d:${seven_d_pct}:${seven_d_reset}"; do
      rl_label="${rl_pair%%:*}"
      rl_rest="${rl_pair#*:}"
      rl_pct="${rl_rest%%:*}"
      rl_reset="${rl_rest#*:}"
      [ -z "$rl_pct" ] && continue
      rl_int=$(printf "%.0f" "$rl_pct" 2>/dev/null)
      rl_color="%F{green}"
      [ "$rl_int" -ge 80 ] && rl_color="%F{yellow}"
      [ "$rl_int" -ge 95 ] && rl_color="%F{88}"
      reset_suffix=""
      if [ -n "$rl_reset" ] && [ "$rl_reset" != "null" ]; then
        remain=$(( rl_reset - now_epoch ))
        if [ "$remain" -gt 0 ]; then
          rd=$(( remain / 86400 ))
          rh=$(( (remain % 86400) / 3600 ))
          rm=$(( (remain % 3600) / 60 ))
          if [ "$rd" -gt 0 ]; then
            reset_suffix="${rd}d ${rh}h"
          elif [ "$rh" -gt 0 ]; then
            reset_suffix="${rh}h ${rm}m"
          else
            reset_suffix="${rm}m"
          fi
        fi
      fi
      [ -n "$reset_suffix" ] && reset_suffix="%F{245}(${reset_suffix})%f"
      rl_parts="${rl_parts}${rl_color}${rl_label} ${rl_int}%%%f${reset_suffix} "
    done
    balance_amt=" | %F{245}官方%f ${rl_parts% }"
  fi
fi

model_info="%B%F{cyan}[${model}]%f%b"
dir_info="📁 %B%F{45}${dir_name}%f%b"

# Progressive layout — priority: model > ctx > cost > left > dir > branch > budget bar > pool > dur
# In tmux, tput cols reads the outer terminal — use tmux pane width instead
if [ -n "$TMUX" ]; then
  term_width=$(tmux display-message -p '#{pane_width}' 2>/dev/null || tput cols 2>/dev/null || echo 120)
else
  term_width=$(tput cols 2>/dev/null || echo 120)
fi

if [ "$term_width" -ge 140 ]; then
  print -P "${model_info} | ${ctx_bar}${cost_info}${tok_info}${balance_amt} | ${dir_info}${git_info}${dur_info}"
elif [ "$term_width" -ge 120 ]; then
  print -P "${model_info} | ${ctx_bar}${cost_info}${tok_info}${balance_amt} | ${dir_info}${git_info}"
elif [ "$term_width" -ge 100 ]; then
  print -P "${model_info} | ${ctx_bar}${cost_info}${tok_info}${balance_amt} | ${dir_info}${git_info}"
elif [ "$term_width" -ge 80 ]; then
  print -P "${model_info} | ${ctx_bar}${cost_info}${tok_info}${balance_amt} | ${dir_info}${git_info}"
else
  print -P "${model_info} | ${ctx_bar}${cost_info}${balance_amt}"
fi
