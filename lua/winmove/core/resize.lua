local resize = {}

local util = require("winmove.util")

---@param dir winmove.Direction
local function is_at_edge(dir)
    return vim.fn.winnr(dir) == vim.fn.winnr()
end

---@param dir winmove.Direction
---@param count integer
---@param opposite_anchor boolean
function resize.resize(dir, count, opposite_anchor)
    local vertical = util.win.is_vertical(dir) and "vertical " or ""
    local sign = (dir == "l" or dir == "j") and "+" or "-"
    local at_edge = is_at_edge(dir)

    -- If we are at the edge of the terminal window, reverse the sign
    if at_edge then
        sign = sign == "+" and "-" or "+"
    end

    vim.cmd(("%sresize %s%d"):format(vertical, sign, count or 1))
end

return resize
