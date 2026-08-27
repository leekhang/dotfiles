return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    scope = {
      enabled = true, -- highlights the current nested block using treesitter
      show_start = false, -- don't underline the parent/opening line
      show_end = false, -- don't underline the closing line
    },
  },
}
