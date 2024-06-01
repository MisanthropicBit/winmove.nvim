vim.opt.rtp:append(".")
vim.opt.rtp:append("~/.vim-plug/plenary.nvim")
vim.cmd.runtime({ "plugin/plenary.vim", bang = true })
vim.cmd.runtime({ "plugin/winmove.lua", bang = false })
