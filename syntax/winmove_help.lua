if vim.fn.exists("b:current_syntax") == 1 then
    return
end

vim.cmd([[
    syntax match WinmoveHelpLhs /\v^\s*\zs.{-}\ze\s+.+/
    highlight default link WinmoveHelpLhs Special
]])

vim.b.current_syntax = "winmove_help"
