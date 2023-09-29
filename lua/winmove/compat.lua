-- Neovim compatibility module
local compat = {}

---@param value string
---@return boolean
function compat.has(value)
    return vim.fn.has(value) == 1
end

if compat.has("nvim-0.9.0") then
    compat.print = vim.print
else
    compat.print = vim.pretty_print
end

return compat
