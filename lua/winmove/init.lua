local winmove = {}

local config = require("winmove.config")
local highlight = require("winmove.highlight")

local api = vim.api
local winmove_version = "0.1.0"
local winmove_mode_activated = false
local augroup = nil

function winmove.version()
    return winmove_version
end

---@alias winmove.Direction "h" | "j" | "k" | "l"

---@class winmove.BoundingBox
---@field top integer
---@field left integer
---@field bottom integer
---@field right integer

---@param dir winmove.Direction
local function is_vertical(dir)
    return dir == "h" or dir == "l"
end

--- Get a leaf's parent or nil if it is not found
---@param win_id integer
---@return table?
local function get_leaf_parent(win_id)
    local layout = vim.fn.winlayout()

    ---@return table?
    local function _find(node, parent)
        local type, data = unpack(node)

        if type == "leaf" then
            if data == win_id then
                return parent
            end
        else
            for _, child in ipairs(data) do
                local found = _find(child, node)

                if found then
                    return found
                end
            end
        end

        return nil
    end

    return _find(layout, nil)
end

--- Determine if two windows are siblings in the same row or column
---@param win_id1 integer
---@param win_id2 integer
---@return boolean
local function are_siblings(win_id1, win_id2)
    local layout = vim.fn.winlayout()

    local function _are_siblings(node, parent, win_id)
        local type, data = unpack(node)

        if type == "leaf" then
            if data == win_id then
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

    return _are_siblings(layout, nil, win_id1)
end

---@return integer
local function window_count()
    return vim.fn.winnr('$')
end

--- Returns the possible window handle of a neighbor
---@param dir winmove.Direction
---@return integer?
local function get_neighbor(dir)
    local neighbor = vim.fn.winnr(dir)
    local cur_win_nr = vim.fn.winnr()

    return cur_win_nr ~= neighbor and vim.fn.win_getid(neighbor) or nil
end

---@param dir winmove.Direction
---@return winmove.Direction
local function reverse_direction(dir)
    return ({
        h = "l",
        l = "h",
        j = "k",
        k = "j",
    })[dir]
end

--- Get the neighbor on the opposite side of the screen if the current window
--- was to wrap around
---@param dir winmove.Direction
---@return integer?
local function get_wraparound_neighbor(dir)
    if window_count() == 1 then
        return nil
    end

    local count = 1
    local opposite_dir = reverse_direction(dir)
    local prev_win_nr = vim.fn.winnr()
    local neighbor = nil

    while count <= window_count() do
        neighbor = vim.fn.winnr(("%d%s"):format(count, opposite_dir))

        if neighbor == prev_win_nr then
            break
        end

        count = count + 1
        prev_win_nr = neighbor
    end

    return vim.fn.win_getid(neighbor)
end

---@param winnr integer
---@return integer
---@return integer
local function get_cursor_screen_position(winnr)
    local win_row, win_col = unpack(vim.fn.win_screenpos(winnr))
    local row, col = unpack(vim.api.nvim_win_get_cursor(winnr))

    return win_row + row, win_col + col + 1
end

---@param win_id integer
---@return winmove.BoundingBox
local function window_bounding_box(win_id)
    local win_row, win_col = unpack(vim.fn.win_screenpos(win_id))
    local win_width = vim.api.nvim_win_get_width(win_id)
    local win_height = vim.api.nvim_win_get_height(win_id)

    return {
        top = win_row,
        left = win_col,
        bottom = win_row + win_height,
        right = win_col + win_width
    }
end

-- local function move_siblings(source_win, target_win, dir)
--     local vertical = is_vertical(reldir)
--     local rightbelow = reldir == "j" or reldir == "l"

--     if dir == "j" then
--     end

--     vim.fn.win_splitmove(
--         vim.api.nvim_win_get_number(source_win),
--         vim.api.nvim_win_get_number(target_win),
--         { vertical = vertical, rightbelow = rightbelow }
--     )
-- end

--- Call a window-related function in the current window without triggering any events
---@param func function
---@param ... any
local function wincall_no_events(func, ...)
    local saved_eventignore = vim.opt_global.eventignore:get()

    vim.opt_global.eventignore = {
        "WinEnter",
        "WinLeave",
        "WinScrolled",
        "WinResized",
    }

    func(...)

    vim.opt_global.eventignore = saved_eventignore
end

local function move_window(source_win_id, target_win_id, dir)
    wincall_no_events(
        vim.fn.win_splitmove,
        source_win_id,
        target_win_id,
        {
            vertical = is_vertical(dir),
            rightbelow = dir == "h" or dir == "k",
        }
    )
end

--- Find the relative direction of a move/split based on the cursor's distance
--- to the extents of the target window
---@param source_win_id integer
---@param target_win_id integer
---@param dir winmove.Direction
---@return winmove.Direction
local function get_sibling_relative_dir(source_win_id, target_win_id, dir)
    local grow, gcol = get_cursor_screen_position(source_win_id)
    local bbox = window_bounding_box(target_win_id)
    local vertical = is_vertical(dir)
    local pos = 0
    local extents = {} ---@type table<integer>
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

    -- Find the distances to the extents of the target window
    local dist1 = math.abs(pos - extents[1])
    local dist2 = math.abs(pos - extents[2])
    local reldir = dirs[dist1 < dist2 and 1 or 2] ---@type winmove.Direction

    return reldir
end

--- Move a window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.move_window(source_win_id, dir)
    -- Only one window
    if window_count() == 1 then
        return
    end

    local target_win_id = get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            target_win_id = get_wraparound_neighbor(dir)
            dir = reverse_direction(dir)
        else
            return
        end
    end

    ---@diagnostic disable-next-line:param-type-mismatch
    if not are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        dir = get_sibling_relative_dir(source_win_id, target_win_id, dir)
    end

    wincall_no_events(
        vim.fn.win_splitmove,
        source_win_id,
        target_win_id,
        { vertical = is_vertical(dir), rightbelow = dir == "j" or dir == "l" }
    )
end

--- Split a window into another window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.split_into(source_win_id, dir)
    -- Only one window
    if window_count() == 1 then
        return
    end

    local target_win_id = get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            target_win_id = get_wraparound_neighbor(dir)
        else
            return
        end
    end

    local split_options = {
        vertical = is_vertical(dir),
        rightbelow = dir == "h" or dir == "k",
    }

    ---@diagnostic disable-next-line:param-type-mismatch
    if are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        local reldir = get_sibling_relative_dir(source_win_id, target_win_id, dir)

        split_options.vertical = not split_options.vertical
        split_options.rightbelow = reldir == "l" or reldir == "j"
    end

    wincall_no_events(
        vim.fn.win_splitmove,
        source_win_id,
        target_win_id,
        split_options
    )
end

function winmove.move_far(source_win_id, dir)
    -- TODO: Is this necessary?
    wincall_no_events(function()
        vim.cmd("wincmd " .. dir:upper())
    end)
end

local move_column

--- Recursively move a row into a target window
---@param target_win_id integer
---@param dir winmove.Direction
---@param row table
local function move_row(target_win_id, dir, row)
    for _, node in ipairs(row) do
        local type, data = unpack(node)

        if type == "leaf" then
            move_window(data, target_win_id, dir)

            -- Set this node as the target window and put siblings to the right
            target_win_id, dir = data, "l"
        elseif type == "row" then
            assert(false, "Row inside row?")
        elseif type == "col" then
            move_column(target_win_id, dir, node)
        end
    end
end

--- Recursively move a column into a target window
---@param target_win_id integer
---@param dir winmove.Direction
---@param column table
move_column = function(target_win_id, dir, column)
    for _, node in ipairs(column) do
        local type, data = unpack(node)

        if type == "leaf" then
            move_window(data, target_win_id, dir)

            -- Set this node as the target window and put siblings below
            target_win_id, dir = data, "j"
        elseif type == "row" then
            move_row(target_win_id, dir, node)
        elseif type == "col" then
            assert(false, "Column inside column?")
        end
    end
end

-- TODO: Rename function
function winmove.move_into_col_or_row(win_id, dir)
    local parent_node = get_leaf_parent(win_id)

    if parent_node == nil then
        return
    end

    local first_child = nil

    if #parent_node[2] == 1 then
        -- Only one leaf in parent node
        first_child = parent_node[2][1][2]
    else
        first_child = parent_node[2][1][2]
    end

    if are_siblings(win_id, first_child) then
        -- Nodes are siblings, move window out into a row or column
        first_child = parent_node[2][1][2]
    else
        -- Source window and target are not siblings so split on the other
        -- side of the target to move beyond it
        dir = reverse_direction(dir)
        local target_node_parent = get_leaf_parent(win_id)
        first_child = target_node_parent[2][1][2]
    end

    -- Split with the first child node in the parent
    wincall_no_events(
        vim.fn.win_splitmove,
        win_id,
        first_child,
        { vertical = is_vertical(dir), rightbelow = dir == "l" or dir == "j" }
    )

    for _, node in ipairs(parent_node[2]) do
        local node_win_id = node[2]

        -- Don't split the current window again
        if node_win_id ~= win_id and node_win_id ~= first_child then
            vim.print(node[2])
            wincall_no_events(
                vim.fn.win_splitmove,
                node_win_id,
                first_child,
                {
                    vertical = not is_vertical(dir),
                    rightbelow = dir == "l" or dir == "j",
                }
            )
        end
    end
end

function winmove.show_help()
end

---@param keys string
---@param win_id integer
local function move_mode_key_handler(keys, win_id)
    local mappings = config.mappings
    vim.print(keys)

    -- TODO: Clean up this big if
    if keys == mappings.left then
        winmove.move_window(win_id, "h")
    elseif keys == mappings.down then
        winmove.move_window(win_id, "j")
    elseif keys == mappings.up then
        winmove.move_window(win_id, "k")
    elseif keys == mappings.right then
        winmove.move_window(win_id, "l")
    elseif keys == mappings.split_left then
        winmove.split_into(win_id, "h")
    elseif keys == mappings.split_down then
        winmove.split_into(win_id, "j")
    elseif keys == mappings.split_up then
        winmove.split_into(win_id, "k")
    elseif keys == mappings.split_right then
        winmove.split_into(win_id, "l")
    elseif keys == mappings.far_left then
        winmove.move_far(win_id, "h")
    elseif keys == mappings.far_down then
        winmove.move_far(win_id, "j")
    elseif keys == mappings.far_up then
        winmove.move_far(win_id, "k")
    elseif keys == mappings.far_right then
        winmove.move_far(win_id, "l")
    elseif keys == mappings.column_left then
        winmove.move_into_col_or_row(win_id, "h")
    elseif keys == mappings.column_down then
        winmove.move_into_col_or_row(win_id, "j")
    elseif keys == mappings.column_up then
        winmove.move_into_col_or_row(win_id, "k")
    elseif keys == mappings.column_right then
        winmove.move_into_col_or_row(win_id, "l")
    elseif keys == mappings.help then
        winmove.show_help()
    end
end

--- Set a move mode keymap for a buffer
---@param win_id integer
---@param bufnr integer
---@param lhs string
---@param rhs fun(keys: string, win_id: integer)
---@param desc string
local function set_move_mode_keymap(win_id, bufnr, lhs, rhs, desc)
    local function rhs_handler()
        rhs(lhs, win_id)
    end

    -- TODO: Escape lhs(?)
    api.nvim_buf_set_keymap(bufnr, "n", lhs, '', {
        noremap = true,
        desc = desc,
        nowait = true,
        callback = rhs_handler,
    })
end

--- Get all existing normal mode keymaps for a buffer as a table indexed by lhs
---@param bufnr integer
---@return table
local function get_existing_keymaps(bufnr)
    local existing_buf_keymaps = api.nvim_buf_get_keymap(bufnr, "n")
    local keymaps = {}

    for _, map in ipairs(existing_buf_keymaps) do
        if map.lhs then
            keymaps[map.lhs] = {
                rhs = map.rhs or '',
                expr = map.expr == 1,
                callback = map.callback,
                noremap = map.noremap == 1,
                script = map.script == 1,
                silent = map.silent == 1,
                nowait = map.nowait == 1,
            }
        end
    end

    return keymaps
end

--- Whether or not a string has a prefix
---@param str string
---@param prefix string
---@return boolean
local function has_prefix(str, prefix)
    return str:sub(1, #prefix) == prefix
end

--- Generate keymap descriptions for all move mode mappings
---@param name string
---@return string
local function generate_keymap_description(name)
    -- TODO: Handle typos and superfluous elements
    if name == "quit" then
        return "Quit move mode"
    elseif name == "help" then
        return "Show help"
    elseif has_prefix(name, "split") then
        return ("Split a window %s into another window"):format(name)
    elseif has_prefix(name, "far") then
        return ("Move a window as far %s as possible and maximize it"):format(name)
    else
        return "Move a window " .. name
    end
end

-- Auto-generate keymap descriptions for all mappings
local keymap_descriptions = {}

for name, _ in pairs(config.mappings) do
    keymap_descriptions[name] = generate_keymap_description(name)
end

function winmove.start_move_mode()
    -- Only one window
    if window_count() == 1 then
        return
    end

    local cur_win_id = api.nvim_get_current_win()
    local bufnr = api.nvim_get_current_buf()
    local mappings = config.mappings

    highlight.highlight_window(cur_win_id)
    winmove_mode_activated = true

    local existing_buf_keymaps = get_existing_keymaps(bufnr)
    local saved_buf_keymaps = {}

    local function quit_move_mode()
        -- TODO: Close help if open
        winmove_mode_activated = false
        highlight.unhighlight_window(cur_win_id)

        api.nvim_exec_autocmds("User", {
            pattern = "WinmoveModeEnd",
            group = augroup,
            modeline = false,
        })

        -- Remove winmove keymaps
        for _, map in pairs(mappings) do
            api.nvim_buf_del_keymap(bufnr, "n", map)
        end

        -- Restore old keymaps
        for _, map in pairs(saved_buf_keymaps) do
            if api.nvim_buf_is_valid(bufnr) then
                api.nvim_set_keymap(bufnr, "n", map.lhs, map.rhs, {
                    expr = map.expr,
                    callback = map.callback,
                    noremap = map.noremap,
                    script = map.script,
                    silent = map.silent,
                    nowait = map.nowait
                })
            end
        end
    end

    local function pcall_handler(keys, win_id)
        local ok, error = pcall(move_mode_key_handler, keys, win_id)

        if not ok then
            -- There was an error in the call, restore keymaps and quit move mode
            quit_move_mode()

            api.nvim_err_writeln("winmove got error: " .. error)
        end
    end

    -- Set move mode keymaps and save keymaps that need to be restored when we
    -- exit move mode
    for name, map in pairs(mappings) do
        local desc = keymap_descriptions[name]
        local func = map ~= mappings.quit and pcall_handler or quit_move_mode

        set_move_mode_keymap(cur_win_id, bufnr, map, func, desc)

        local existing_keymap = existing_buf_keymaps[bufnr]

        if existing_keymap then
            table.insert(saved_buf_keymaps, existing_keymap)
        end
    end

    -- TODO: Check augroup?
    api.nvim_exec_autocmds("User", {
        pattern = "WinmoveModeStart",
        group = augroup,
        modeline = false,
    })
end

function winmove.move_mode_activated()
    return winmove_mode_activated
end

function winmove.setup(user_config)
   config.setup(user_config)
   highlight.setup()

   augroup = api.nvim_create_augroup("winmove-augroup", { clear = true })

   api.nvim_create_autocmd("User", {
       pattern = "WinmoveModeStart",
       group = augroup,
       desc = "User autocmd that is triggered when move mode starts"
   })

   api.nvim_create_autocmd("User", {
       pattern = "WinmoveModeEnd",
       group = augroup,
       desc = "User autocmd that is triggered when move mode ends"
   })
end

return winmove
