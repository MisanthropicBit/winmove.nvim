local winmove = {}

local config = require("winmove.config")
local resize = require("winmove.resize")
local highlight = require("winmove.highlight")
local layout = require("winmove.layout")
local str = require("winmove.str")
local winutil = require("winmove.winutil")

local api = vim.api
local winmove_version = "0.1.0"

local augroup = nil
local winleave_autocmd = nil

---@enum winmove.Mode
winmove.mode = {
    None = "none",
    Move = "move",
    Resize = "resize",
}

---@class winmove.State
---@field mode winmove.Mode
---@field win_id integer?
---@field bufnr integer?
---@field mappings table?
---@field saved_mappings table?

---@type winmove.State
local state = {
    mode = winmove.mode.None,
    win_id = nil,
    bufnr = nil,
    mappings = nil,
    saved_mappings = nil,
}

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

--- Set the current mode
---@param mode winmove.Mode
---@param win_id integer
---@param bufnr integer
---@param mappings table
---@param saved_mappings table
local function set_mode(mode, win_id, bufnr, mappings, saved_mappings)
    state.mode = mode
    state.win_id = win_id
    state.bufnr = bufnr
    state.mappings = mappings
    state.saved_mappings = saved_mappings
end

---@type fun(mode: winmove.Mode)
local start_mode

---@type fun(mode: winmove.Mode)
local stop_mode

--- Quit the current mode
local function quit_mode()
    state.mode = winmove.mode.None
    state.win_id = nil
    state.bufnr = nil
    state.mappings = nil
    state.saved_mappings = nil
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
--     local vertical = winutil.is_vertical(reldir)
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
    winutil.wincall_no_events(vim.fn.win_splitmove, source_win_id, target_win_id, {
        vertical = winutil.is_vertical(dir),
        rightbelow = dir == "h" or dir == "k",
    })
end

--- Move a window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.move_window(source_win_id, dir)
    -- Only one window
    if winutil.window_count() == 1 then
        return
    end

    local target_win_id = layout.get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            local new_target_win_id = layout.get_wraparound_neighbor(dir)

            if new_target_win_id == source_win_id then
                -- The window is full width/height
                return
            end

            target_win_id = new_target_win_id
            dir = winutil.reverse_direction(dir)
        else
            return
        end
    end

    ---@diagnostic disable-next-line:param-type-mismatch
    if not layout.are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        dir = layout.get_sibling_relative_dir(source_win_id, target_win_id, dir)
    end

    winutil.wincall_no_events(
        vim.fn.win_splitmove,
        source_win_id,
        target_win_id,
        { vertical = winutil.is_vertical(dir), rightbelow = dir == "j" or dir == "l" }
    )
end

--- Split a window into another window in a given direction
---@param source_win_id integer
---@param dir winmove.Direction
function winmove.split_into(source_win_id, dir)
    -- Only one window
    if winutil.window_count() == 1 then
        return
    end

    local target_win_id = layout.get_neighbor(dir)

    if target_win_id == nil then
        if config.wrap_around then
            target_win_id = layout.get_wraparound_neighbor(dir)
        else
            return
        end
    end

    local split_options = {
        vertical = winutil.is_vertical(dir),
        rightbelow = dir == "h" or dir == "k",
    }

    ---@diagnostic disable-next-line:param-type-mismatch
    if layout.are_siblings(source_win_id, target_win_id) then
        ---@diagnostic disable-next-line:param-type-mismatch
        local reldir = layout.get_sibling_relative_dir(source_win_id, target_win_id, dir)

        split_options.vertical = not split_options.vertical
        split_options.rightbelow = reldir == "l" or reldir == "j"
    end

    winutil.wincall_no_events(vim.fn.win_splitmove, source_win_id, target_win_id, split_options)
end

---@diagnostic disable-next-line:unused-local
function winmove.move_far(source_win_id, dir)
    -- TODO: Is this necessary?
    winutil.wincall_no_events(function()
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
    local parent_node = move.get_leaf_parent(win_id)

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

    if layout.are_siblings(win_id, first_child) then
        -- Nodes are siblings, move window out into a row or column
        first_child = parent_node[2][1][2]
    else
        -- Source window and target are not siblings so split on the other
        -- side of the target to move beyond it
        dir = winutil.reverse_direction(dir)
        local target_node_parent = layout.get_leaf_parent(win_id)
        first_child = target_node_parent[2][1][2]
    end

    -- Split with the first child node in the parent
    winutil.wincall_no_events(
        vim.fn.win_splitmove,
        win_id,
        first_child,
        { vertical = winutil.is_vertical(dir), rightbelow = dir == "l" or dir == "j" }
    )

    for _, node in ipairs(parent_node[2]) do
        local node_win_id = node[2]

        -- Don't split the current window again
        if node_win_id ~= win_id and node_win_id ~= first_child then
            vim.print(node[2])
            winutil.wincall_no_events(vim.fn.win_splitmove, node_win_id, first_child, {
                vertical = not winutil.is_vertical(dir),
                rightbelow = dir == "l" or dir == "j",
            })
        end
    end
end

---@param mode winmove.Mode
function winmove.show_help(mode) end

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
    elseif keys == mappings.resize_mode then
        winmove.toggle_mode()
    end
end

---@param keys string
---@param win_id integer
local function resize_mode_key_handler(keys, win_id)
    local count = vim.v.count

    -- If no count is provided use the default count otherwise use the provided count
    if count == 0 then
        count = config.default_resize_count
    end

    local mappings = config.mappings.resize

    if keys == mappings.left then
        resize.resize_window(win_id, "h", count, "top_left")
    elseif keys == mappings.down then
        resize.resize_window(win_id, "j", count, "top_left")
    elseif keys == mappings.up then
        resize.resize_window(win_id, "k", count, "top_left")
    elseif keys == mappings.right then
        resize.resize_window(win_id, "l", count, "top_left")
    elseif keys == mappings.move_mode then
        winmove.toggle_mode()
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

--- Generate keymap descriptions for all move mode mappings
---@param name string
---@return string
local function generate_keymap_description(name)
    -- TODO: Handle typos and superfluous elements
    -- TODO: Handle column mappings
    if name == "help" then
        return "Show help"
    elseif str.has_prefix(name, "split") then
        return ("Split a window %s into another window"):format(name)
    elseif str.has_prefix(name, "far") then
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

for name, _ in pairs(config.mappings.resize) do
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
        set_mode_keymap(win_id, bufnr, map, handler, keymap_descriptions[name])

        local existing_keymap = existing_buf_keymaps[map]

        if existing_keymap then
            table.insert(saved_buf_keymaps, existing_keymap)
        end
    end

    set_mode_keymap(
        win_id,
        bufnr,
        config.mappings.quit,
        winmove["stop_" .. mode .. "_mode"],
        "Quit " .. mode .. " mode"
    )

    set_mode_keymap(win_id, bufnr, config.mappings.help, function()
        winmove.show_help(mode)
    end, "Show help")

    set_mode_keymap(
        win_id,
        bufnr,
        config.mappings.toggle_mode,
        winmove.toggle_mode,
        "Toggle between modes"
    )

    return saved_buf_keymaps
end

--- Delete mode keymaps and restore previous buffer keymaps
local function restore_mappings()
    if not api.nvim_buf_is_valid(state.bufnr) then
        return
    end

    -- Remove winmove keymaps
    for _, map in pairs(state.mappings) do
        api.nvim_buf_del_keymap(state.bufnr, "n", map)
    end

    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.quit)
    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.help)
    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.toggle_mode)

    -- Restore old keymaps
    for _, map in pairs(state.saved_mappings) do
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

---@param mode winmove.Mode
start_mode = function(mode)
    if winutil.window_count() == 1 then
        vim.api.nvim_err_writeln("Only one window")
        return
    end

    local cur_win_id = api.nvim_get_current_win()

    if mode == winmove.mode.Move and winutil.is_floating_window(cur_win_id) then
        vim.api.nvim_err_writeln("Cannot " .. mode .. " floating window")
        return
    end

    local titlecase_mode = str.titlecase(mode)

    if winmove.current_mode() == mode then
        vim.api.nvim_err_writeln(titlecase_mode .. " mode already activated")
        return
    end

    local bufnr = api.nvim_get_current_buf()
    local mappings = config.mappings[mode]

    highlight.highlight_window(cur_win_id, mode)
    local saved_buf_keymaps = set_mappings(cur_win_id, bufnr, mode, mappings)
    set_mode(mode, cur_win_id, bufnr, mappings, saved_buf_keymaps)

    -- TODO: Check augroup?
    api.nvim_exec_autocmds("User", {
        pattern = "Winmove" .. titlecase_mode .. "ModeStart",
        group = augroup,
        modeline = false,
    })

    winleave_autocmd = api.nvim_create_autocmd("WinLeave", {
        callback = function()
            stop_mode(mode)
            return true
        end,
        group = augroup,
        desc = "Quits " .. mode .. " when leaving the window",
    })
end

---@param mode winmove.Mode
stop_mode = function(mode)
    local titlecase_mode = str.titlecase(mode)

    if winmove.current_mode() ~= mode then
        vim.api.nvim_err_writeln("Window " .. titlecase_mode .. " mode is not activated")
        return
    end

    highlight.unhighlight_window(state.win_id)
    restore_mappings()
    quit_mode()

    if winleave_autocmd then
        pcall(api.nvim_del_autocmd, winleave_autocmd)
        winleave_autocmd = nil
    end

    -- TODO: Check augroup?
    api.nvim_exec_autocmds("User", {
        pattern = "Winmove" .. titlecase_mode .. "ModeEnd",
        group = augroup,
        modeline = false,
    })
end

function winmove.toggle_mode()
    local mode = winmove.current_mode()
    local new_mode = mode == winmove.mode.Move and winmove.mode.Resize or winmove.mode.Move

    stop_mode(mode)
    start_mode(new_mode)
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
    return state.mode
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