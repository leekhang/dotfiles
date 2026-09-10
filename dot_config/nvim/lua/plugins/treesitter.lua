return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main", -- current rewrite; NOT the old master/configs-module API
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-treesitter").install({
      "lua", "javascript", "typescript", "tsx", "jsdoc",
      "html", "css", "markdown", "markdown_inline",
      "python", "json", "bash", "regex", "vim", "vimdoc", "query",
      "sql",
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start) -- no-ops safely if no parser for this filetype
        -- nvim-treesitter's `main` branch ships its own indentexpr, distinct
        -- from (and more complete than) Neovim core's generic
        -- vim.treesitter.indentexpr(). Using core's version here silently
        -- flattened indentation to column 0 for every nested line in
        -- multi-line brackets/blocks — this is the one the README calls for.
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
