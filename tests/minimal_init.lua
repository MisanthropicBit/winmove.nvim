vim.opt.rtp:append(".")
vim.opt.rtp:append("~/.vim-plug/plenary.nvim")
vim.cmd.runtime({ "plugin/plenary.vim", bang = true })
vim.cmd.runtime({ "plugin/winmove.lua", bang = false })

-- vim.opt.rtp:append("~/.vim-plug/plenary.nvim")
-- vim.opt.rtp:append("~/.vim-plug/nvim-nio")
-- vim.opt.rtp:append("~/.vim-plug/neotest")
-- vim.opt.rtp:append("../neotest-busted")
