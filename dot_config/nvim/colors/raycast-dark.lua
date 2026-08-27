-- Raycast Dark colorscheme for Neovim
-- Mirrors the Raycast Dark palette used in Ghostty (host terminal) and Herdr.

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "raycast-dark"

local c = {
  fg = "#ffffff",
  bg = "#1a1a1a",
  cursor = "#cccccc",
  black = "#000000",
  red = "#ff5360",
  green = "#59d499",
  yellow = "#ffc531",
  blue = "#56c2ff",
  magenta = "#cf2f98",
  cyan = "#52eee5",
  white = "#ffffff",
  bright_black = "#4c4c4c",
  bright_red = "#ff6363",
  grey = "#808080",
  bg_alt = "#262626",
  bg_visual = "#3a3a3a",
}

local hl = vim.api.nvim_set_hl

-- Editor UI
hl(0, "Normal", { fg = c.fg, bg = c.bg })
hl(0, "NormalFloat", { fg = c.fg, bg = c.bg_alt })
hl(0, "FloatBorder", { fg = c.bright_black, bg = c.bg_alt })
hl(0, "Cursor", { fg = c.bg, bg = c.cursor })
hl(0, "CursorLine", { bg = c.bg_alt })
hl(0, "CursorLineNr", { fg = c.yellow, bold = true })
hl(0, "LineNr", { fg = c.bright_black })
hl(0, "SignColumn", { bg = c.bg })
hl(0, "Visual", { bg = c.bg_visual })
hl(0, "Search", { fg = c.black, bg = c.yellow })
hl(0, "IncSearch", { fg = c.black, bg = c.red })
hl(0, "Pmenu", { fg = c.fg, bg = c.bg_alt })
hl(0, "PmenuSel", { fg = c.black, bg = c.blue })
hl(0, "StatusLine", { fg = c.fg, bg = c.bg_alt })
hl(0, "StatusLineNC", { fg = c.bright_black, bg = c.bg_alt })
hl(0, "VertSplit", { fg = c.bright_black, bg = c.bg })
hl(0, "WinSeparator", { fg = c.bright_black, bg = c.bg })
hl(0, "MatchParen", { fg = c.yellow, bold = true })
hl(0, "NonText", { fg = c.bright_black })
hl(0, "Whitespace", { fg = c.bright_black })
hl(0, "ColorColumn", { bg = c.bg_alt })
hl(0, "DiffAdd", { fg = c.green, bg = c.bg_alt })
hl(0, "DiffChange", { fg = c.yellow, bg = c.bg_alt })
hl(0, "DiffDelete", { fg = c.red, bg = c.bg_alt })
hl(0, "DiffText", { fg = c.blue, bg = c.bg_alt })

-- Syntax
hl(0, "Comment", { fg = c.grey, italic = true })
hl(0, "Constant", { fg = c.green })
hl(0, "String", { fg = c.yellow })
hl(0, "Character", { fg = c.yellow })
hl(0, "Number", { fg = c.green })
hl(0, "Boolean", { fg = c.green })
hl(0, "Float", { fg = c.green })
hl(0, "Identifier", { fg = c.fg })
hl(0, "Function", { fg = c.blue })
hl(0, "Statement", { fg = c.magenta })
hl(0, "Conditional", { fg = c.magenta })
hl(0, "Repeat", { fg = c.magenta })
hl(0, "Label", { fg = c.magenta })
hl(0, "Operator", { fg = c.fg })
hl(0, "Keyword", { fg = c.magenta })
hl(0, "Exception", { fg = c.magenta })
hl(0, "PreProc", { fg = c.cyan })
hl(0, "Include", { fg = c.cyan })
hl(0, "Define", { fg = c.cyan })
hl(0, "Macro", { fg = c.cyan })
hl(0, "PreCondit", { fg = c.cyan })
hl(0, "Type", { fg = c.cyan })
hl(0, "StorageClass", { fg = c.cyan })
hl(0, "Structure", { fg = c.cyan })
hl(0, "Typedef", { fg = c.cyan })
hl(0, "Special", { fg = c.cyan })
hl(0, "SpecialChar", { fg = c.cyan })
hl(0, "Tag", { fg = c.cyan })
hl(0, "Delimiter", { fg = c.fg })
hl(0, "SpecialComment", { fg = c.grey, italic = true })
hl(0, "Debug", { fg = c.red })
hl(0, "Underlined", { fg = c.blue, underline = true })
hl(0, "Ignore", { fg = c.bright_black })
hl(0, "Error", { fg = c.white, bg = c.red })
hl(0, "Todo", { fg = c.black, bg = c.yellow, bold = true })

-- Treesitter captures
local ts_links = {
  ["@variable"] = "Identifier",
  ["@variable.builtin"] = "Special",
  ["@constant"] = "Constant",
  ["@constant.builtin"] = "Constant",
  ["@string"] = "String",
  ["@number"] = "Number",
  ["@boolean"] = "Boolean",
  ["@function"] = "Function",
  ["@function.builtin"] = "Function",
  ["@method"] = "Function",
  ["@keyword"] = "Keyword",
  ["@keyword.function"] = "Keyword",
  ["@keyword.return"] = "Keyword",
  ["@conditional"] = "Conditional",
  ["@repeat"] = "Repeat",
  ["@type"] = "Type",
  ["@type.builtin"] = "Type",
  ["@property"] = "Identifier",
  ["@field"] = "Identifier",
  ["@parameter"] = "Identifier",
  ["@comment"] = "Comment",
  ["@punctuation.delimiter"] = "Delimiter",
  ["@punctuation.bracket"] = "Delimiter",
  ["@operator"] = "Operator",
  ["@tag"] = "Tag",
  ["@tag.delimiter"] = "Delimiter",
  ["@tag.attribute"] = "Identifier",
  ["@module"] = "Include",
}
for group, target in pairs(ts_links) do
  hl(0, group, { link = target })
end

-- Terminal ANSI palette (used by :terminal / embedded terminal buffers)
vim.g.terminal_color_0 = c.black
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.magenta
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = c.white
vim.g.terminal_color_8 = c.bright_black
vim.g.terminal_color_9 = c.bright_red
vim.g.terminal_color_10 = c.green
vim.g.terminal_color_11 = c.yellow
vim.g.terminal_color_12 = c.blue
vim.g.terminal_color_13 = c.magenta
vim.g.terminal_color_14 = c.cyan
vim.g.terminal_color_15 = c.white
