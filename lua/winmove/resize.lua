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

---@param horizontal boolean
---@param sign integer
---@param count integer
---@param winnr integer?
local function _resize(horizontal, sign, count, winnr)
    local _win_id = winnr and tostring(winnr) or ""
    local _vertical = horizontal and "vertical " or ""

    vim.cmd(("%s%sresize %s%d"):format(_vertical, _win_id, sign > 0 and "+" or "-", count or 1))
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

---@type table<boolean, table<boolean, winmove.Direction>>
local neighbor_dir_table = {
    [true] = {
        [true] = "l",
        [false] = "h",
    },
    [false] = {
        [true] = "j",
        [false] = "k",
    },
}

---@param win_id integer
---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.ResizeAnchor?
---@diagnostic disable-next-line: unused-local
function resize.resize_window(win_id, dir, count, anchor)
    if count < 1 then
        return
    end

    local horizontal = winutil.is_horizontal(dir)
    local is_full_dimension = winutil[horizontal and "is_full_width" or "is_full_height"]

    if is_full_dimension(win_id) then
        return
    end

    local sign = (dir == "l" or dir == "j") and 1 or -1
    local winnr = vim.fn.winnr()
    local top_left = (anchor or resize.anchor.TopLeft) == resize.anchor.TopLeft
    local edges = horizontal and { "l", "h" } or { "j", "k" }

    if is_at_edge(edges[1]) and top_left then
        -- If we are at the right or bottom edge with a top-left anchor, flip
        -- the sign. E.g. if we are the right side and moving right, the sign
        -- is +, so we need to flip the sign to minus to decrease the width of
        -- the window
        sign = sign * -1
    elseif not is_at_edge(edges[2]) then
        -- Vim's/Neovim's resize command behaves a bit strangely. It seems to
        -- prefer to resize in the direction of a sibling in the window layout.
        --
        -- So if we are resizing in the direction of a non-sibling and we are next
        -- to a sibling in the opposite direction, instead resize the non-sibling
        -- in the reverse proportion. For example, if we are making the current
        -- window bigger instead make the non-sibling window smaller
        local neighbor_dir = neighbor_dir_table[horizontal][top_left]
        local neighbor_winnr = vim.fn.winnr(neighbor_dir)
        local is_sibling = layout.are_siblings(win_id, vim.fn.win_getid(neighbor_winnr))

        if not is_sibling then
            if top_left then
                -- Flip the sign for top-left anchor. E.g. if the neighbor
                -- below is not a sibling and we are resizing down then we need
                -- to decrease the height of the neighbor, but with a
                -- bottom-right anchor, a non-sibling neighbor above, and
                -- resizing up, we would already be decreasing the height of
                -- the neighbor as intended
                sign = sign * -1
            end

            -- Not a sibling, resize the neighbor instead
            winnr = neighbor_winnr
        else
            -- Neighbor is a sibling, resize the current window and flip the
            -- sign for same reason as above but for the bottom-right anchor
            if not top_left then
                winnr = neighbor_winnr
            end
        end
    end

    _resize(horizontal, sign, count, winnr)
end

--- Resize a window according to a percentage of the total width/height of the editor
---@param win_id integer
---@param percentage number
---@param horizontal boolean
function resize.resize_window_to_percentage(win_id, percentage, horizontal)
    -- Idea
    -- 80%w => Set to 80% of width in both directions (down to a minimim for other windows?)
    -- 80%l => Set to 80% of width to the right (down to a minimim for other
    -- windows?) and otherwise in the other direction if it is not possible to
    -- go 80% width in one direction
    local editor_size, dimension, dir1, dir2

    if horizontal then
        editor_size = winutil.editor_width()
        dimension = vim.api.nvim_win_get_width(win_id)
        dir1, dir2 = "l", "h"
    else
        editor_size = winutil.editor_height()
        dimension = vim.api.nvim_win_get_height(win_id)
        dir1, dir2 = "j", "k"
    end

    local target_size = editor_size * percentage / 100.0

    if target_size < 1 then
        message.error("Cannot resize window to less than 1% of editor size")
        return
    end

    local size_diff = target_size - dimension

    if size_diff == 0 then
        return
    end

    -- Handle (literal) edge cases
    if horizontal then
        local is_at_right_edge = is_at_edge("l")

        if is_at_right_edge or is_at_edge("h") then
            local dir = is_at_right_edge and dir2 or dir1
            dir = size_diff > 0 and dir or winutil.reverse_direction(dir)
            resize.resize_window(win_id, dir, math.abs(size_diff), resize.anchor.TopLeft)
            return
        end
    else
        local is_at_bottom_edge = is_at_edge("j")

        if is_at_bottom_edge or is_at_edge("k") then
            local dir = is_at_bottom_edge and dir2 or dir1
            dir = size_diff > 0 and dir or winutil.reverse_direction(dir)
            resize.resize_window(win_id, dir, math.abs(size_diff), resize.anchor.BottomRight)
            return
        end
    end

    if size_diff < 0 then
        dir1, dir2 = dir2, dir1
    end

    resize.resize_window(win_id, dir1, math.abs(math.floor(size_diff / 2)), resize.anchor.TopLeft)
    resize.resize_window(win_id, dir2, math.abs(math.ceil(size_diff / 2)), resize.anchor.BottomRight)
end

return resize
