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
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start) -- no-ops safely if no parser for this filetype
        vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()"
      end,
    })
  end,
}
