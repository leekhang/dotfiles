return {
  "saghen/blink.cmp",
  version = "1.*", -- prebuilt binary releases; avoids needing a Rust toolchain to build from source
  dependencies = { "rafamadriz/friendly-snippets" }, -- prebuilt snippet library, no LuaSnip needed
  event = { "BufReadPre", "BufNewFile", "InsertEnter" },
  opts = {
    keymap = { preset = "default" }, -- Enter/Tab/Ctrl-Space/Ctrl-y etc.
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true },
      menu = { auto_show = true },
    },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" }, -- falls back to Lua impl instead of hard-failing
    signature = { enabled = true },
  },
  opts_extend = { "sources.default" },
}
