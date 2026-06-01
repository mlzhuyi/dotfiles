. "$HOME/.cargo/env"

# Claude Code 的 shell 快照会过滤掉单下划线开头的函数(_encode/_decode),
# 却保留依赖它们的 gvm setValueForKeyFakeAssocArray，于是 precmd 钩子每条命令都报
# "command not found: _encode"。补 gvm 真函数也不行——它的 _encode 还依赖 $HEXDUMP_PATH
# 等只有 gvm 完整初始化才设置的变量(否则第 289 行变成 `echo -n .. | -e ...` 报 `-e`)。
# 这里只在 Claude 环境放一个自包含安全桩，让钩子跑完不报错；该上报在非交互工具 shell 里
# 本就无意义，原样返回无害。交互式 shell 不进此分支，gvm 会正常加载真函数覆盖它。
# 待 Claude Code 修好快照对单下划线函数的过滤后即可删除本段。
if [[ -n "$CLAUDECODE" ]]; then
  _encode() { printf '%s' "$1"; }
  _decode() { printf '%s' "$1"; }
fi
