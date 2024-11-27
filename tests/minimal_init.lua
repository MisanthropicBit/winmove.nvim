vim.opt.rtp:append(".")
vim.opt.rtp:append("./lua_modules/lua/plenary.nvim")

vim.cmd.runtime({ "plugin/plenary.vim", bang = true })
