-- Global Settings
vim.opt.clipboard = "unnamedplus"
vim.o.number = true
vim.o.relativenumber = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.hlsearch = true
vim.opt.ignorecase = true




-- Keymaps
vim.keymap.set('n', '<C-s>', '<cmd>write<cr>', {desc = 'Save'})
