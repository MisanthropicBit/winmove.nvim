local resize = {}

local layout = require("winmove.layout")
local message = require("winmove.message")
local winutil = require("winmove.winutil")

---@alias winmove.Sign "+" | "-"

---@enum winmove.ResizeAnchor
local ResizeAnchor = {
    TopLeft = "top_left",
    BottomRight = "bottom_right",
}

resize.anchor = ResizeAnchor

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
local function check_at_edge(edge, dir, sign)
    if is_at_edge(edge) then
        if dir == edge or dir == winutil.reverse_direction(edge) then
            return flip_sign(sign)
        end
    end

    return sign
end

---@param win_id integer
---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.ResizeAnchor?
---@diagnostic disable-next-line: unused-local
function resize.resize_window(win_id, dir, count, anchor)
    local horizontal = winutil.is_horizontal(dir)
    local is_full_dimension = winutil[horizontal and "is_full_width" or "is_full_height"]

    if is_full_dimension(win_id) then
        return
    end

    ---@type winmove.Sign
    local sign = (dir == "l" or dir == "j") and "+" or "-"
    local _anchor = anchor or resize.anchor.TopLeft

    -- sign = check_at_edge("j", dir, sign)
    -- sign = check_at_edge("l", dir, sign)

    local winnr = vim.fn.winnr()
    local neighbor_win_nr1 = vim.fn.winnr(dir)
    local neighbor_win_nr2 = vim.fn.winnr(winutil.reverse_direction(dir))
    local is_sibling1 = layout.are_siblings(win_id, vim.fn.win_getid(neighbor_win_nr1))
    local is_sibling2 = layout.are_siblings(win_id, vim.fn.win_getid(neighbor_win_nr2))
    local both_are_siblings = is_sibling1 == is_sibling2

    -- Vim's/Neovim's resize command behaves a bit strangely. It seems to
    -- prefer to resize in the horizontal/vertical direction of a sibling in
    -- the window layout.
    --
    -- So if we are resizing in the direction of a non-sibling and we are next
    -- to a sibling in the opposite direction, instead resize the non-sibling
    -- in the reverse proportion. For example, if we are making the current
    -- window bigger instead make the non-sibling window smaller
    if not both_are_siblings then
        winnr = is_sibling1 and neighbor_win_nr2 or neighbor_win_nr1
        sign = flip_sign(sign)
    end

    if _anchor == resize.anchor.BottomRight then
        -- If the anchor is in the bottom right corner then select the other window.
        -- For example, if the we were resizing left and right but the anchor is in
        -- the bottom right corner then we should select the neighbor instead of the
        -- current window
        if horizontal then
            if not is_at_edge("h") and not is_at_edge("l") then
                winnr = dir == "h" and neighbor_win_nr1 or neighbor_win_nr2

                if not both_are_siblings then
                    sign = flip_sign(sign)
                end
            end
        else
            if not is_at_edge("k") and not is_at_edge("j") then
                winnr = dir == "k" and neighbor_win_nr1 or neighbor_win_nr2

                if not both_are_siblings then
                    sign = flip_sign(sign)
                end
            end
        end
    end

    _resize(horizontal, sign, count, winnr)
end

--- Resize a window according to a percentage of the total width/height of the editor
---@param win_id integer
---@param percentage number
---@param dir winmove.Direction
function resize.resize_window_percentage(win_id, percentage, dir)
    -- Idea
    -- 80%w => Set to 80% of width in both directions (down to a minimim for other windows?)
    -- 80%l => Set to 80% of width to the right (down to a minimim for other
    -- windows?) and otherwise in the other direction if it is not possible to
    -- go 80% width in one direction
    local editor_size = winutil.is_horizontal(dir) and winutil.editor_width() or winutil.editor_height()
    local target_size = editor_size * percentage / 100.0

    if target_size < 1 then
        message.error("Cannot resize window to less than 1% of editor size")
        return
    end

    local size_diff = target_size - vim.api.nvim_win_get_width(win_id)

    if size_diff == 0 then
        return
    end

    local resize_dir = size_diff > 1 and dir or winutil.reverse_direction(dir)
    local anchor = (dir == "h" or dir == "k") and "bottom_right" or "top_left"

    resize.resize_window(win_id, resize_dir, size_diff, anchor)
end

return resize
