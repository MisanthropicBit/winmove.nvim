local resize = {}

local layout = require("winmove.layout")
local winutil = require("winmove.winutil")

---@enum winmove.ResizeAnchor
resize.anchor = {
    TopLeft = "top_left",
    BottomRight = "bottom_right",
}

---@param dir winmove.Direction
local function is_at_edge(dir)
    return vim.fn.winnr(dir) == vim.fn.winnr()
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

---@param dir winmove.Direction
---@param get_dimension_func fun(win_id: integer): integer
---@param min_dimension fun(): integer
---@return boolean
local function can_resize(dir, get_dimension_func, min_dimension)
    local neighbor_count, applied = layout.apply_to_neighbors(dir, function(neighbor_win_id)
        local dimension = get_dimension_func(neighbor_win_id)

        return true, dimension <= min_dimension()
    end)

    if neighbor_count == 0 then
        -- No neighbors, check the window itself
        return get_dimension_func(0) > min_dimension()
    end

    -- All neighbors are at minimal width/height so we cannot resize
    return neighbor_count ~= applied
end

--- Adjust neighbors in the direction the current window is being resized
---@param dir winmove.Direction
---@param get_dimension fun(win_id: integer): integer
---@param get_min_dimension fun(): integer
---@param count integer
---@param anchor winmove.ResizeAnchor
local function adjust_neighbors_in_direction(dir, get_dimension, get_min_dimension, count, anchor)
    layout.apply_to_neighbors(dir, function(neighbor_win_id)
        local dimension = get_dimension(neighbor_win_id)
        local min_dimension = get_min_dimension()

        if dimension <= min_dimension then
            winutil.win_id_context_call(
                neighbor_win_id,
                resize.resize_window,
                neighbor_win_id,
                dir,
                count,
                anchor
            )

            return true, true
        end

        return false, false
    end)
end

---@param value any
---@return boolean
function resize.is_valid_anchor(value)
    return value == nil or (value == resize.anchor.TopLeft or value == resize.anchor.BottomRight)
end

---@param win_id integer
---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.ResizeAnchor?
function resize.resize_window(win_id, dir, count, anchor)
    if count < 1 then
        return
    end

    local horizontal = winutil.is_horizontal(dir)
    local is_full_dimension, resize_func, get_dimension, get_min_dimension, edges

    if horizontal then
        is_full_dimension = winutil.is_full_width
        resize_func = vim.fn.win_move_separator
        get_dimension = vim.api.nvim_win_get_width
        get_min_dimension = function()
            return math.max(vim.opt_local.winwidth:get(), vim.go.winminwidth)
        end
        edges = { "l", "h" }
    else
        is_full_dimension = winutil.is_full_height
        resize_func = vim.fn.win_move_statusline
        get_dimension = vim.api.nvim_win_get_height
        get_min_dimension = function()
            return math.max(vim.opt_local.winheight:get(), vim.go.winminheight)
        end
        edges = { "j", "k" }
    end

    if is_full_dimension(win_id) then
        return
    elseif not can_resize(dir, get_dimension, get_min_dimension) then
        return
    end

    local _anchor = anchor or resize.anchor.TopLeft
    local top_left = _anchor == resize.anchor.TopLeft

    if not top_left then
        local neighbor_dir = neighbor_dir_table[horizontal][top_left]
        win_id = vim.fn.winnr(neighbor_dir)
    elseif is_at_edge(edges[1]) then
        local neighbor_dir = neighbor_dir_table[horizontal][not top_left]
        win_id = vim.fn.winnr(neighbor_dir)
    end

    if dir == edges[2] then
        count = -count
    end

    resize_func(win_id, count)
    adjust_neighbors_in_direction(dir, get_dimension, get_min_dimension, count, _anchor)
end

return resize
