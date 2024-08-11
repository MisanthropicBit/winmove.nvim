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

---@param horizontal boolean
---@param sign integer
---@param count integer
---@param winnr integer?
local function _resize(horizontal, sign, count, winnr)
    local win_id = winnr and tostring(winnr) or ""
    local vertical = horizontal and "vertical " or ""
    vim.print(count <= 0 and 1 or count)

    vim.cmd(
        ("%s%sresize %s%d"):format(
            vertical,
            win_id,
            sign > 0 and "+" or "-",
            count <= 0 and 1 or count
        )
    )
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

--- Adjust right-hand side sibling neighbors when using a bottom-right corner
---@param win_id integer
---@param rev_dir winmove.Direction
---@param count integer
local function adjust_neighbors_bottom_right_anchor(win_id, rev_dir, count)
    layout.apply_to_neighbors("l", function(neighbor_win_id)
        local neighbor_is_sibling = layout.are_siblings(win_id, neighbor_win_id)

        if neighbor_is_sibling then
            -- Adjust sibling in the opposite direction
            winutil.win_id_context_call(
                neighbor_win_id,
                resize.resize_window,
                neighbor_win_id,
                rev_dir,
                count,
                resize.anchor.BottomRight,
                true
            )
        else
            return false, false
        end

        return true, true
    end)
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
                anchor,
                nil
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
---@param ignore_neighbors boolean?
function resize.resize_window(win_id, dir, count, anchor, ignore_neighbors)
    if count < 1 then
        return
    end

    local horizontal = winutil.is_horizontal(dir)
    local is_full_dimension, get_dimension, get_min_dimension, edges

    -- TODO: Make local width/height values take priority?
    if horizontal then
        is_full_dimension = winutil.is_full_width
        get_dimension = vim.api.nvim_win_get_width
        get_min_dimension = function()
            return math.max(vim.opt_local.winwidth:get(), vim.go.winminwidth)
        end
        edges = { "l", "h" }
    else
        is_full_dimension = winutil.is_full_height
        get_dimension = vim.api.nvim_win_get_height
        get_min_dimension = function()
            return math.max(vim.opt_local.winheight:get(), vim.go.winminheight)
        end
        edges = { "j", "k" }
    end

    if is_full_dimension(win_id) then
        return
    end

    local sign = (dir == "l" or dir == "j") and 1 or -1
    local winnr = vim.fn.win_id2win(win_id)
    local _anchor = anchor or resize.anchor.TopLeft
    local top_left = _anchor == resize.anchor.TopLeft

    if not can_resize(dir, get_dimension, get_min_dimension) then
        return
    end

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

            -- Check if the opposite neighbor is a sibling since a resize
            -- towards a non-sibling will actually resize the neighbor instead
            -- of the current window and if the opposite neighbor is a sibling,
            -- vim/neovim will drag both (or more) siblings towards it or push
            -- them.
            --
            -- For example, resize to the left with a bottom-right corner
            -- towards a non-sibling will decrease the size of the non-sibling
            -- neighbor but move the current window and an opposite sibling
            -- neighbor window with it.
            --
            -- To compensate, we resize the opposite neighbor in the other
            -- direction with an opposite anchor. This is only relevant when
            -- using the bottom-right corner
            if not ignore_neighbors and not top_left then
                local rev_dir = winutil.reverse_direction(dir)

                -- For a bottom-right anchor, always resize neighbors on the right since we
                -- are actually resizing a non-sibling neighbor that might push/pull siblings
                -- neighbors on the right
                adjust_neighbors_bottom_right_anchor(win_id, rev_dir, count)
            end
        else
            -- Neighbor is a sibling, resize the current window and flip the
            -- sign for same reason as above but for the bottom-right anchor
            if not top_left then
                winnr = neighbor_winnr
            end
        end
    end

    -- Resize the main window
    _resize(horizontal, sign, count, winnr)

    if not ignore_neighbors then
        -- TODO: Skip first neighbor if non-sibling?
        adjust_neighbors_in_direction(dir, get_dimension, get_min_dimension, count, _anchor)
    end
end

return resize
