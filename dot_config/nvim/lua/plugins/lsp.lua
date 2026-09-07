vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf })
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = ev.buf })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf })
  end,
})

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig", -- just registers default vim.lsp.config() entries; no .setup() call needed
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls", "ts_ls", "eslint", "html", "cssls", "marksman", "basedpyright", "ruff",
        "sqls",
      },
      -- sqls (Go binary via `go install`) instead of sqlls (npm): sqlls pulls in sqlite3,
      -- a native addon that needs node-gyp, which needs Python's distutils. This machine's
      -- Python is 3.14 everywhere (venv and system), and distutils was removed in 3.12 with
      -- no older Python installed to fall back to, so sqlls's install fails at that C-compile
      -- step. sqls sidesteps it entirely by never touching node-gyp.
      -- gdscript isn't a Mason package (it's Godot's own built-in LSP server, reached over
      -- TCP), so it's enabled directly below rather than listed here.
      -- automatic_enable defaults to true: calls vim.lsp.enable() for every Mason-installed package
      -- name that also matches a registered lspconfig name. "stylua" is one such collision (it ships
      -- an experimental `--lsp` mode) but it's a formatter, not something we want attached as a client.
      automatic_enable = { exclude = { "stylua" } },
    },
    config = function(_, opts)
      -- Force blink.cmp to load now (even if its own lazy trigger hasn't fired yet) so every
      -- server config below advertises full completion capabilities from the moment it starts.
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      vim.lsp.config("*", { capabilities = capabilities })

      require("mason-lspconfig").setup(opts)

      -- Godot's editor ships its own LSP server over TCP (Editor Settings > Network >
      -- Language Server), not something Mason installs, so it's enabled separately here.
      vim.lsp.enable("gdscript")
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = { ensure_installed = { "stylua", "prettier", "sql-formatter" } }, -- ruff already installed via mason-lspconfig above
  },
}
