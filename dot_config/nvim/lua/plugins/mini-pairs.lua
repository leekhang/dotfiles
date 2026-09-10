return {
  "nvim-mini/mini.pairs",
  version = false, -- standalone module repo, not the full mini.nvim bundle
  main = "mini.pairs",
  event = "InsertEnter",
  opts = {}, -- defaults already auto-close/skip-over (), [], {}, "", '', ``
}
