return {
  "abecodes/tabout.nvim",
  lazy = false,
  priority = 1000, -- must load, and set its <Tab> mapping, before blink.cmp does
  opts = {
    -- blink.cmp's own <Tab> keymap already does snippet_forward then falls
    -- back to "the next non-blink keymap" when neither applies — that
    -- fallback is what invokes tabout, so tabout doesn't need its own
    -- pumvisible-based completion check.
    completion = false,
    ignore_beginning = true,
  },
}
