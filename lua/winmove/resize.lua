local resize = {}

local layout = require("winmove.layout")
local winutil = require("winmove.winutil")

---@alias winmove.Sign "+" | "-"
---@alias winmove.Anchor "top_left" | "bottom_right"

---@param dir winmove.Direction
local function is_at_edge(dir)
    return vim.fn.winnr(dir) == vim.fn.winnr()
end

---@param vertical boolean
---@param sign string
---@param count integer
---@param winnr integer?
local function _resize(vertical, sign, count, winnr)
    local _win_id = winnr and tostring(winnr) or ""
    local _vertical = vertical and "vertical " or ""

    vim.cmd(("%s%sresize %s%d"):format(_vertical, _win_id, sign, count or 1))
end

local function flip_sign(sign)
    return sign == "+" and "-" or "+"
end

--- Adjust sign if at an edge
---@param edge winmove.Direction
---@param dir winmove.Direction
---@param sign winmove.Sign
---@return winmove.Sign
local function check_edge(edge, dir, sign)
    if is_at_edge(edge) then
        if dir == edge or dir == winutil.reverse_direction(edge) then
            return flip_sign(sign)
        end
    end

    return sign
end

---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.Anchor
function resize.resize_window(win_id, dir, count, anchor)
    local vertical = winutil.is_vertical(dir)
    local sign = (dir == "l" or dir == "j") and "+" or "-" ---@type winmove.Sign

    sign = check_edge("j", dir, sign)
    sign = check_edge("l", dir, sign)

    local winnr = vim.fn.winnr()
    local neighbor_win_nr1 = vim.fn.winnr(dir)
    local neighbor_win_nr2 = vim.fn.winnr(winutil.reverse_direction(dir))
    local neighbor_win_id1 = vim.fn.win_getid(neighbor_win_nr1)
    local neighbor_win_id2 = vim.fn.win_getid(neighbor_win_nr2)

    local is_sibling1 = layout.are_siblings(win_id, neighbor_win_id1)
    local is_sibling2 = layout.are_siblings(win_id, neighbor_win_id2)

    -- Vim's/Neovim's resize command behaves a bit strangely. It seems to
    -- prefer to resize in the horizontal/vertical direction of a sibling in
    -- the window layout.
    --
    -- So if we are resizing in the direction of a non-sibling and we are next
    -- to a sibling in the opposite direction, instead resize the non-sibling
    -- in the reverse proportion. For example, if we are making the current
    -- window bigger instead make the non-sibling window smaller
    if is_sibling1 ~= is_sibling2 then
        winnr = is_sibling1 and neighbor_win_nr2 or neighbor_win_nr1
        sign = flip_sign(sign)
    end

    _resize(vertical, sign, count, winnr)
end

return resize
