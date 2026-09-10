return {
  "saghen/blink.cmp",
  version = "1.*", -- prebuilt binary releases; avoids needing a Rust toolchain to build from source
  dependencies = { "rafamadriz/friendly-snippets" }, -- prebuilt snippet library, no LuaSnip needed
  event = { "BufReadPre", "BufNewFile", "InsertEnter" },
  opts = {
    keymap = { preset = "default" }, -- Enter/Tab/Ctrl-Space/Ctrl-y etc. Tab tried accepting completions too; reverted, C-y stays the accept key.
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true },
      menu = { auto_show = true },
    },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" }, -- falls back to Lua impl instead of hard-failing
    signature = {
      enabled = true,
      -- Prefer showing below the cursor ('s'outh) instead of the default
      -- north-first priority, which covers the line above the cursor —
      -- exactly the line with the function call itself on a multi-line
      -- argument list. Falls back to 'n' if there's no room below.
      window = { direction_priority = { "s", "n" } },
    },
  },
  opts_extend = { "sources.default" },
}
