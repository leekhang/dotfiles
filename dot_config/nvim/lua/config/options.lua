-- ============================================================================
-- UI/Display
-- ============================================================================
vim.opt.termguicolors = true      -- Enable 24-bit RGB colors in the terminal
vim.opt.number = true             -- Show absolute line numbers
vim.opt.relativenumber = true     -- Show relative line numbers (hybrid with number=true)
vim.opt.numberwidth = 4           -- Minimum width of number column
vim.opt.signcolumn = "yes:1"      -- Always show sign column with width of 1
vim.opt.showtabline = 2             -- 0: never, 1: only if >= 2 tabs, 2: always
vim.opt.cursorline = false        -- Don't highlight the current line
vim.opt.wrap = false              -- Don't wrap long lines
vim.opt.breakindent = true        -- Wrapped lines preserve indentation
vim.opt.ruler = true              -- Show cursor position in command line
vim.opt.showtabline = 0           -- Never show the tab line
vim.opt.cmdheight = 1             -- Height of command line area
vim.opt.pumheight = 10            -- Maximum height of popup menu
vim.opt.fillchars = { eob = " " } -- Hide ~ characters on empty lines
vim.o.winborder = "rounded"       -- Use rounded borders for floating windows

vim.cmd("set expandtab")
vim.cmd("set tabstop=3")
vim.cmd("set softtabstop=3")
vim.cmd("set shiftwidth=3")

-- vim.opt.termguicolors = false
-- colorscheme is set by the github-nvim-theme plugin spec (lua/plugins/catppuccin.lua)

-- ============================================================================
-- Functional 
-- ============================================================================
-- Line numbering
vim.opt.number = true
-- Undo options
vim.opt.undofile = true

-- Sync OS and Neovim clipboard over OSC 52. This box is a headless VM
-- reached over SSH with no X11/Wayland session, so the usual
-- 'unnamed'/'unnamedplus' approach (shelling out to xclip/xsel/wl-copy)
-- has no display server to talk to and silently does nothing. OSC 52
-- instead sends/reads clipboard data as a terminal escape sequence, so it
-- travels back through the SSH connection itself to the terminal on the
-- Mac (Ghostty), which supports it out of the box.
vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}
vim.opt.clipboard = "unnamedplus"

-- Misc. options
vim.opt.encoding = 'utf-8'
vim.opt.smartcase = true
