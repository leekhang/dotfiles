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

-- Sync OS and Neovim clipboard after Neovim has been booted up
vim.schedule(function()
  vim.o.clipboard = 'unnamed'
end)

-- Misc. options
vim.opt.encoding = 'utf-8'
vim.opt.smartcase = true
