local layout = {}

local winutil = require("winmove.winutil")
local Mode = require("winmove.mode")

---@class winmove.BoundingBox
---@field top integer
---@field left integer
---@field bottom integer
---@field right integer

---@param win_id integer
---@return integer
---@return integer
local function get_cursor_screen_position(win_id)
    -- Get window position in screen space
    local win_row, win_col = unpack(vim.api.nvim_win_get_position(win_id))

    -- Get cursor position in local window space
    local row, col = vim.fn.winline(), vim.fn.wincol()

    return win_row + row, win_col + col
end

---@param win_id integer
---@return winmove.BoundingBox
local function window_bounding_box(win_id)
    local win_row, win_col = unpack(vim.api.nvim_win_get_position(win_id))
    local win_width = vim.api.nvim_win_get_width(win_id)
    local win_height = vim.api.nvim_win_get_height(win_id)

    return {
        top = win_row,
        left = win_col,
        bottom = win_row + win_height,
        right = win_col + win_width,
    }
end

--- Returns the possible window handle of a neighbor
---@param dir winmove.Direction
---@return integer?
function layout.get_neighbor(dir)
    local neighbor = vim.fn.winnr(dir)
    local cur_win_nr = vim.fn.winnr()

    return cur_win_nr ~= neighbor and vim.fn.win_getid(neighbor) or nil
end

--- Get the neighbor on the opposite side of the screen if the current window
--- was to wrap around
---@param dir winmove.Direction
---@return integer?
function layout.get_wraparound_neighbor(dir)
    if winutil.window_count() == 1 then
        return nil
    end

    local count = 1
    local opposite_dir = winutil.reverse_direction(dir)
    local prev_win_nr = vim.fn.winnr()
    local neighbor = nil

    while count <= winutil.window_count() do
        neighbor = vim.fn.winnr(("%d%s"):format(count, opposite_dir))

        if neighbor == prev_win_nr then
            break
        end

        count = count + 1
        prev_win_nr = neighbor
    end

    return vim.fn.win_getid(neighbor)
end

--- Apply a function to each neighbor in a direction
---@param dir winmove.Direction
---@param func fun(win_id: integer): boolean, boolean
function layout.apply_to_neighbors(dir, func)
    local neighbor_win_id = layout.get_neighbor(dir)
    local count, applied = 0, 0

    while neighbor_win_id do
        local continue, did_apply = func(neighbor_win_id)
        applied = applied + (did_apply and 1 or 0)

        if not continue then
            break
        end

        count = count + 1
        local next_neighbor = vim.fn.win_getid(vim.fn.winnr(("%d%s"):format(count + 1, dir)))

        if next_neighbor == neighbor_win_id then
            break
        end

        neighbor_win_id = next_neighbor
    end

    return count, applied
end

--- Determine if two windows are siblings in the same row or column
---@param win_id1 integer
---@param win_id2 integer
---@return boolean
function layout.are_siblings(win_id1, win_id2)
    local win_layout = vim.fn.winlayout()

    local function _are_siblings(node, parent, win_id)
        local type, data = unpack(node)

        if type == "leaf" then
            if data == win_id and parent then
                for _, sibling in ipairs(parent[2]) do
                    if sibling[2] == win_id2 then
                        return true
                    end
                end
            end
        else
            for _, child in ipairs(data) do
                if _are_siblings(child, node, win_id) then
                    return true
                end
            end
        end
    end

    return _are_siblings(win_layout, nil, win_id1)
end

-- Find the distances to the extents of the target window
---@param pos integer
---@param extents integer[]
---@param dirs winmove.Direction[]
---@return winmove.Direction
local function relative_dir_by_extents(pos, extents, dirs)
    local dist1 = math.abs(pos - extents[1])
    local dist2 = math.abs(pos - extents[2])

    return dirs[dist1 < dist2 and 1 or 2]
end

--- Find the relative direction of a move/split based on the cursor's distance
--- to the extents of the target window
---@param source_win_id integer
---@param target_win_id integer
---@param dir winmove.Direction
---@param mode winmove.Mode?
---@return winmove.Direction
function layout.get_sibling_relative_dir(source_win_id, target_win_id, dir, mode)
    local grow, gcol
    local bbox = window_bounding_box(target_win_id)

    if mode == Mode.Move then
        grow, gcol = get_cursor_screen_position(source_win_id)
    else
        -- Not in move mode, move relative to the middle of the window in global
        -- coordinates
        local win_row, win_col = unpack(vim.api.nvim_win_get_position(source_win_id))
        local height = bbox.bottom - bbox.top
        local width = bbox.right - bbox.left

        grow, gcol = win_row + height / 2, win_col + width / 2
    end

    local vertical = winutil.is_horizontal(dir)
    local pos = 0
    local extents = {} ---@type integer[]
    local dirs = {} ---@type table<winmove.Direction>

    if vertical then
        pos = grow
        extents = { bbox.top, bbox.bottom }
        dirs = { "k", "j" }
    else
        pos = gcol
        extents = { bbox.left, bbox.right }
        dirs = { "h", "l" }
    end

    return relative_dir_by_extents(pos, extents, dirs)
end

---@param win_id integer
---@param pos integer
---@param dir winmove.Direction
---@return integer
local function find_target_window_in_tab(win_id, pos, dir)
    local function _find_target_window_in_tab(win_layout, _dir)
        local type, data = win_layout[1], win_layout[2]

        if type == "leaf" then
            local leaf_bbox = window_bounding_box(data)

            if pos >= leaf_bbox.top and pos <= leaf_bbox.bottom then
                -- Leaf bounding box contains cursor position
                return data
            end
        elseif type == "row" then
            local idx = _dir == "h" and 1 or #data

            -- Recurse into the left- or right-most subtree
            return _find_target_window_in_tab(data[idx], _dir)
        elseif type == "col" then
            for _, subtree in ipairs(data) do
                local _win_id = _find_target_window_in_tab(subtree, _dir)

                if _win_id then
                    return _win_id
                end
            end
        end
    end

    -- Find target tabpage number
    local tab_id = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(win_id))
    local tab_count = vim.fn.tabpagenr("$")
    local target_tab_id = tab_id + (dir == "h" and -1 or 1)

    -- Wrap tab pages
    if target_tab_id > tab_count then
        target_tab_id = 1
    elseif target_tab_id < 1 then
        target_tab_id = tab_count
    end

    local target_tab_win_layout = vim.fn.winlayout(target_tab_id)
    local revdir = winutil.reverse_direction(dir)

    return _find_target_window_in_tab(target_tab_win_layout, revdir)
end

---@param source_win_id integer
---@param dir winmove.HorizontalDirection
---@return integer
---@return winmove.VerticalDirection
function layout.get_target_window_in_tab(source_win_id, dir)
    local grow, _ = get_cursor_screen_position(source_win_id)
    local target_win_id = find_target_window_in_tab(source_win_id, grow, dir)
    local bbox = window_bounding_box(target_win_id)
    local reldir = relative_dir_by_extents(grow, { bbox.top, bbox.bottom }, { "k", "j" })

    ---@cast reldir winmove.VerticalDirection
    return target_win_id, reldir
end

return layout
