-- avante.nvim configuration

-- 使用 claude-code 的环境变量配置
local base_url = os.getenv("ANTHROPIC_BASE_URL") or "https://api.anthropic.com"

require('avante').setup({
  ---@alias Provider "claude" | "openai" | "azure" | "gemini" | "cohere" | "copilot" | string
  provider = "openai", -- 推荐使用 claude
  auto_suggestions = false, -- 自动建议
  providers = {
    openai = {
      endpoint = base_url,
      model = "claude-sonnet-4-5-20250929",
      timeout = 60000, -- Timeout in milliseconds, increase this for reasoning models
      api_key_name = "ANTHROPIC_AUTH_TOKEN",
      extra_request_body = {
        temperature = 0.75,
        max_tokens = 20000, -- claude code 默认 20w, 设置为其1/10
      },
    },
  },
  behaviour = {
    auto_suggestions = false, -- 实验性功能: 自动建议 (默认关闭)
    auto_set_highlight_group = true,
    auto_set_keymaps = true,
    auto_apply_diff_after_generation = false,
    support_paste_from_clipboard = false,
    minimize_diff = true, -- 是否在应用代码块时删除未更改的行
    enable_token_counting = true, -- 是否启用令牌计数。默认为 true。
    enable_cursor_planning_mode = false, -- 是否启用 Cursor 规划模式。默认为 false。
    enable_claude_text_editor_tool_mode = false, -- 是否启用 Claude 文本编辑器工具模式。
  },
  mappings = {
    --- @class AvanteConflictMappings
    diff = {
      ours = "co",
      theirs = "ct",
      all_their = "ca",
      both = "cb",
      cursor = "cc",
      next = "]x",
      prev = "[x",
    },
    suggestion = {
      accept = "<M-l>",
      next = "<M-]>",
      prev = "<M-[>",
      dismiss = "<C-]>",
    },
    jump = {
      next = "]]",
      prev = "[[",
    },
    submit = {
      normal = "<CR>",
      insert = "<C-s>",
    },
    cancel = {
      normal = { "<C-c>", "<Esc>", "q" },
      insert = { "<C-c>" },
    },
    sidebar = {
      apply_all = "A",
      apply_cursor = "a",
      retry_user_request = "r",
      edit_user_request = "e",
      switch_windows = "<Tab>",
      reverse_switch_windows = "<S-Tab>",
      remove_file = "d",
      add_file = "@",
      close = { "<Esc>", "q" },
      close_from_input = nil, -- 例如，{ normal = "<Esc>", insert = "<C-d>" }
    },
  },
  selection = {
    enabled = true,
    hint_display = "delayed",
  },
  windows = {
    ---@type "right" | "left" | "top" | "bottom"
    position = "right", -- 侧边栏的位置
    wrap = true, -- 类似于 vim.o.wrap
    width = 30, -- 默认基于可用宽度的百分比
    sidebar_header = {
      enabled = true, -- true, false 启用/禁用标题
      align = "center", -- left, center, right 用于标题
      rounded = true,
    },
    spinner = {
      editing = { "⡀", "⠄", "⠂", "⠁", "⠈", "⠐", "⠠", "⢀", "⣀", "⢄", "⢂", "⢁", "⢈", "⢐", "⢠", "⣠", "⢤", "⢢", "⢡", "⢨", "⢰", "⣰", "⢴", "⢲", "⢱", "⢸", "⣸", "⢼", "⢺", "⢹", "⣹", "⢽", "⢻", "⣻", "⢿", "⣿" },
      generating = { "·", "✢", "✳", "∗", "✻", "✽" }, -- '生成中' 状态的旋转字符
      thinking = { "🤯", "🙄" }, -- '思考中' 状态的旋转字符
    },
    input = {
      prefix = "> ",
      height = 8, -- 垂直布局中输入窗口的高度
    },
    edit = {
      border = "rounded",
      start_insert = true, -- 打开编辑窗口时开始插入模式
    },
    ask = {
      floating = false, -- 在浮动窗口中打开 'AvanteAsk' 提示
      start_insert = true, -- 打开询问窗口时开始插入模式
      border = "rounded",
      ---@type "ours" | "theirs"
      focus_on_apply = "ours", -- 应用后聚焦的差异
    },
  },
  highlights = {
    ---@type AvanteConflictHighlights
    diff = {
      current = "DiffText",
      incoming = "DiffAdd",
    },
  },
  --- @class AvanteConflictUserConfig
  diff = {
    autojump = true,
    ---@type string | fun(): any
    list_opener = "copen",
    --- 覆盖悬停在差异上时的 'timeoutlen' 设置（请参阅 :help timeoutlen）。
    --- 有助于避免进入以 `c` 开头的差异映射的操作员挂起模式。
    --- 通过设置为 -1 禁用。
    override_timeoutlen = 500,
  },
  suggestion = {
    debounce = 600,
    throttle = 600,
  },
})
