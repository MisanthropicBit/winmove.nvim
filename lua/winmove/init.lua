local winmove = {}

local config = require("winmove.config")
local core = require("winmove.core")
local highlight = require("winmove.highlight")
local util = require("winmove.util")

local api = vim.api
local winmove_version = "0.1.0"
local augroup = nil

---@class winmove.State
---@field win_id integer?
---@field bufnr integer?
---@field mappings table?
---@field saved_mappings table?
local state = {
    win_id = nil,
    bufnr = nil,
    mappings = nil,
    saved_mappings = nil,
}

---@alias winmove.ModeState { mode: winmove.Mode, state: winmove.State }

---@type winmove.ModeState[]
local mode_states = {}

local function push_state(win_id, bufnr, mappings, saved_mappings)
    state = {
        win_id = win_id,
        bufnr = bufnr,
        mappings = mappings,
        saved_mappings = saved_mappings,
    }
end

local function clear_state()
    -- TODO: Might not be valid
    state = {
        win_id = nil,
        bufnr = nil,
        mappings = nil,
        saved_mappings = nil,
    }
end

---@enum winmove.Mode
winmove.mode = {
    None = "none",
    Move = "move",
    Resize = "reize",
}

local function push_mode(new_mode, win_id, bufnr, mappings, saved_mappings)
    local new_state = {
        win_id = win_id,
        bufnr = bufnr,
        mappings = mappings,
        saved_mappings = saved_mappings,
    }

    for idx, mode in ipairs(mode_states) do
        -- Remove the mode from its current position and insert it at the end
        if mode == new_mode then
            table.remove(mode_states, idx)
            table.insert(mode_states, { mode = new_mode, state = new_state })
            return
        end
    end

    table.insert(mode_states, { mode = new_mode, state = new_state })
end

local function get_mode()
    return mode_states[#mode_states] and mode_states[#mode_states].mode or winmove.mode.None
end

---@type fun(mode: winmove.Mode)
local start_mode

local function drop_mode()
    table.remove(mode_states)
    local mode_state = mode_states[#mode_states]
    local mode = mode_state.mode

    if mode ~= nil and mode ~= winmove.mode.None then
        -- Start the new current mode
        start_mode(mode)
    end
end

function winmove.version()
    return winmove_version
end

---@alias winmove.Direction "h" | "j" | "k" | "l"

---@class winmove.BoundingBox
---@field top integer
---@field left integer
---@field bottom integer
---@field right integer

-- local function move_siblings(source_win, target_win, dir)
--     local vertical = util.win.is_vertical(reldir)
--     local rightbelow = reldir == "j" or reldir == "l"

--     if dir == "j" then
--     end

--     vim.fn.win_splitmove(
--         vim.api.nvim_win_get_number(source_win),
--         vim.api.nvim_win_get_number(target_win),
--         { vertical = vertical, rightbelow = rightbelow }
--     )
-- end

local function move_window(source_win_id, target_win_id, dir)
    util.win.wincall_no_events(vim.fn.win_splitmove, source_win_id, target_win_id, {
        vertical = util.win.is_vertical(dir),
        rightbelow = dir == "h" or dir == "k",
    })
end

--- Move a window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.move_window(source_win_id, dir)
    -- Only one window
    if core.move.window_count() == 1 then
        return
    end

    local target_win_id = core.move.get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            target_win_id = core.move.get_wraparound_neighbor(dir)
            dir = util.win.reverse_direction(dir)
        else
            return
        end
    end

    ---@diagnostic disable-next-line:param-type-mismatch
    if not core.move.are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        dir = core.move.get_sibling_relative_dir(source_win_id, target_win_id, dir)
    end

    util.win.wincall_no_events(
        vim.fn.win_splitmove,
        source_win_id,
        target_win_id,
        { vertical = util.win.is_vertical(dir), rightbelow = dir == "j" or dir == "l" }
    )
end

--- Split a window into another window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.split_into(source_win_id, dir)
    -- Only one window
    if core.move.window_count() == 1 then
        return
    end

    local target_win_id = core.move.get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            target_win_id = core.move.get_wraparound_neighbor(dir)
        else
            return
        end
    end

    local split_options = {
        vertical = util.win.is_vertical(dir),
        rightbelow = dir == "h" or dir == "k",
    }

    ---@diagnostic disable-next-line:param-type-mismatch
    if core.move.are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        local reldir = core.move.get_sibling_relative_dir(source_win_id, target_win_id, dir)

        split_options.vertical = not split_options.vertical
        split_options.rightbelow = reldir == "l" or reldir == "j"
    end

    util.win.wincall_no_events(vim.fn.win_splitmove, source_win_id, target_win_id, split_options)
end

---@diagnostic disable-next-line:unused-local
function winmove.move_far(source_win_id, dir)
    -- TODO: Is this necessary?
    util.win.wincall_no_events(function()
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
    local parent_node = core.move.get_leaf_parent(win_id)

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

    if core.move.are_siblings(win_id, first_child) then
        -- Nodes are siblings, move window out into a row or column
        first_child = parent_node[2][1][2]
    else
        -- Source window and target are not siblings so split on the other
        -- side of the target to move beyond it
        dir = util.win.reverse_direction(dir)
        local target_node_parent = core.move.get_leaf_parent(win_id)
        first_child = target_node_parent[2][1][2]
    end

    -- Split with the first child node in the parent
    util.win.wincall_no_events(
        vim.fn.win_splitmove,
        win_id,
        first_child,
        { vertical = util.win.is_vertical(dir), rightbelow = dir == "l" or dir == "j" }
    )

    for _, node in ipairs(parent_node[2]) do
        local node_win_id = node[2]

        -- Don't split the current window again
        if node_win_id ~= win_id and node_win_id ~= first_child then
            vim.print(node[2])
            util.win.wincall_no_events(vim.fn.win_splitmove, node_win_id, first_child, {
                vertical = not util.win.is_vertical(dir),
                rightbelow = dir == "l" or dir == "j",
            })
        end
    end
end

function winmove.show_help() end

-- local keymap_funcs = {
--     left = { winmove.move_window, "h" },
--     down = { winmove.move_window, "j" },
--     up = { winmove.move_window, "k" },
--     right = { winmove.move_window, "l" },
--     split_left = { winmove.move_window, "h" },
--     split_down = { winmove.move_window, "j" },
--     split_up = { winmove.move_window, "k" },
--     split_right = { winmove.move_window, "l" },
--     far_left = { winmove.move_window, "h" },
--     far_down = { winmove.move_window, "j" },
--     far_up = { winmove.move_window, "k" },
--     far_right = { winmove.move_window, "l" },
--     column_left = { winmove.move_window, "h" },
--     column_down = { winmove.move_window, "j" },
--     column_up = { winmove.move_window, "k" },
--     column_right = { winmove.move_window, "l" },
-- }

---@param keys string
---@param win_id integer
local function move_mode_key_handler(keys, win_id)
    local mappings = config.mappings.move

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
    elseif keys == config.mappings.help then
        winmove.show_help()
    end
end

---@param keys string
---@param win_id integer
local function resize_mode_key_handler(keys, win_id)
    local count = vim.v.count1
    local mappings = config.mappings.resize

    if keys == mappings.left then
        winmove.resize_window(win_id, "h", count)
    elseif keys == mappings.down then
        winmove.resize_window(win_id, "j", count)
    elseif keys == mappings.up then
        winmove.resize_window(win_id, "k", count)
    elseif keys == mappings.right then
        winmove.resize_window(win_id, "l", count)
    elseif keys == config.mappings.help then
        winmove.show_help()
    end
end

--- Set a move mode keymap for a buffer
---@param win_id integer
---@param bufnr integer
---@param lhs string
---@param rhs fun(keys: string, win_id: integer)
---@param desc string
local function set_mode_keymap(win_id, bufnr, lhs, rhs, desc)
    local function rhs_handler()
        rhs(lhs, win_id)
    end

    -- TODO: Escape lhs(?)
    api.nvim_buf_set_keymap(bufnr, "n", lhs, "", {
        noremap = true,
        desc = desc,
        nowait = true,
        callback = rhs_handler,
    })
end

--- Get all existing normal mode buffer keymaps as a table indexed by lhs
---@param bufnr integer
---@return table
local function get_existing_buffer_keymaps(bufnr)
    local existing_buf_keymaps = api.nvim_buf_get_keymap(bufnr, "n")
    local keymaps = {}

    for _, map in ipairs(existing_buf_keymaps) do
        if map.lhs then
            keymaps[map.lhs] = {
                rhs = map.rhs or "",
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

for name, _ in pairs(config.mappings.move) do
    keymap_descriptions[name] = generate_keymap_description(name)
end

local function create_pcall_mode_key_handler(mode)
    local handler = mode == winmove.mode.Move and move_mode_key_handler or resize_mode_key_handler

    return function(keys, win_id)
        local ok, error = pcall(handler, keys, win_id)

        if not ok then
            -- There was an error in the call, restore keymaps and quit move mode
            winmove["stop_" .. mode .. "_mode"]()

            api.nvim_err_writeln(("winmove got error in mode '%s': %s"):format(mode, error))
        end
    end
end

--- Set move mode keymaps and save keymaps that need to be restored when we
--- exit move mode
---@param win_id integer
---@param bufnr integer
---@param mode winmove.Mode
---@param mappings table
local function set_mappings(win_id, bufnr, mode, mappings)
    local existing_buf_keymaps = get_existing_buffer_keymaps(bufnr)
    local saved_buf_keymaps = {}
    local handler = create_pcall_mode_key_handler(mode)

    for name, map in pairs(mappings) do
        local desc = keymap_descriptions[name]
        vim.print("stop_" .. mode .. "_mode")
        local func = map ~= mappings.quit and handler or winmove["stop_" .. mode .. "_mode"]

        set_mode_keymap(win_id, bufnr, map, func, desc)

        local existing_keymap = existing_buf_keymaps[bufnr]

        if existing_keymap then
            table.insert(saved_buf_keymaps, existing_keymap)
        end
    end

    return saved_buf_keymaps
end

local function restore_mappings()
    -- Remove winmove keymaps
    for _, map in pairs(state.mappings) do
        api.nvim_buf_del_keymap(state.bufnr, "n", map)
    end

    -- Restore old keymaps
    for _, map in pairs(state.saved_mappings) do
        if api.nvim_buf_is_valid(state.bufnr) then
            api.nvim_set_keymap(state.bufnr, "n", map.lhs, map.rhs, {
                expr = map.expr,
                callback = map.callback,
                noremap = map.noremap,
                script = map.script,
                silent = map.silent,
                nowait = map.nowait,
            })
        end
    end

    clear_state()
end

---@param mode winmove.Mode
start_mode = function(mode)
    if core.move.window_count() == 1 then
        vim.api.nvim_err_writeln("Only one window")
        return
    end

    if winmove.current_mode() == mode then
        vim.api.nvim_err_writeln("Move mode already activated")
        return
    end

    local cur_win_id = api.nvim_get_current_win()
    local bufnr = api.nvim_get_current_buf()
    local mappings = config.mappings[mode]

    highlight.highlight_window(cur_win_id, mode)
    local saved_buf_keymaps = set_mappings(cur_win_id, bufnr, mode, mappings)
    push_mode(mode, cur_win_id, bufnr, mappings, saved_buf_keymaps)

    -- TODO: Check augroup?
    api.nvim_exec_autocmds("User", {
        pattern = "Winmove" .. mode .. "ModeStart",
        group = augroup,
        modeline = false,
    })
end

---@param mode winmove.Mode
local function stop_mode(mode)
    if winmove.current_mode() ~= mode then
        vim.api.nvim_err_writeln("Window " .. mode .. " mode is not activated")
        return
    end

    highlight.unhighlight_window(state.win_id)
    restore_mappings()

    api.nvim_exec_autocmds("User", {
        pattern = "Winmove" .. mode .. "ModeEnd",
        group = augroup,
        modeline = false,
    })

    drop_mode()
end

function winmove.start_move_mode()
    start_mode(winmove.mode.Move)
end

function winmove.stop_move_mode()
    stop_mode(winmove.mode.Move)
end

function winmove.start_resize_mode()
    start_mode(winmove.mode.Resize)
end

function winmove.stop_resize_mode()
    stop_mode(winmove.mode.Resize)
end

function winmove.current_mode()
    return get_mode()
end

function winmove.setup(user_config)
    config.setup(user_config)
    highlight.setup()

    augroup = api.nvim_create_augroup("winmove-augroup", { clear = true })

    for _, mode in ipairs(winmove.mode) do
        if mode ~= winmove.mode.None then
            api.nvim_create_autocmd("User", {
                pattern = "Winmove" .. mode .. "ModeStart",
                group = augroup,
                desc = "User autocmd that is triggered when " .. mode .. " mode starts",
            })

            api.nvim_create_autocmd("User", {
                pattern = "Winmove" .. mode .. "ModeEnd",
                group = augroup,
                desc = "User autocmd that is triggered when " .. mode .. " mode ends",
            })
        end
    end
end

return winmove
