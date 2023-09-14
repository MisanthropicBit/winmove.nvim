local winmove = {}

local config = require("winmove.config")
local resize = require("winmove.resize")
local highlight = require("winmove.highlight")
local layout = require("winmove.layout")
local resize = require("winmove.resize")
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

--- Set the current mode
---@param mode winmove.Mode
---@param win_id integer
---@param bufnr integer
---@param saved_mappings table
local function set_mode(mode, win_id, bufnr, saved_mappings)
    state.mode = mode
    state.win_id = win_id
    state.bufnr = bufnr
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

---@param keys string
---@param win_id integer
local function move_mode_key_handler(keys, win_id)
    local mappings = config.mappings.move

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
local function set_mappings(win_id, bufnr, mode)
    local existing_buf_keymaps = get_existing_buffer_keymaps(bufnr)
    local saved_buf_keymaps = {}
    local handler = create_pcall_mode_key_handler(mode)

    for name, map in pairs(config.mappings[mode]) do
        local description = config.get_keymap_description(name, mode)
        set_mode_keymap(win_id, bufnr, map, handler, description)

        local existing_keymap = existing_buf_keymaps[map]

        -- Save any existing user-defined keymap that we override so we can
        -- restore it later
        if existing_keymap then
            table.insert(saved_buf_keymaps, existing_keymap)
        end
    end

    set_mode_keymap(win_id, bufnr, config.mappings.help, function()
        float.open(mode)
    end, config.get_keymap_description("help"))

    set_mode_keymap(
        win_id,
        bufnr,
        config.mappings.quit,
        winmove["stop_" .. mode .. "_mode"],
        config.get_keymap_description("quit")
    )

    set_mode_keymap(
        win_id,
        bufnr,
        config.mappings.toggle_mode,
        winmove.toggle_mode,
        config.get_keymap_description("toggle_mode")
    )

    return saved_buf_keymaps
end

--- Delete mode keymaps and restore previous buffer keymaps
---@param mode winmove.Mode
local function restore_mappings(mode)
    if not api.nvim_buf_is_valid(state.bufnr) then
        return
    end

    -- Remove winmove keymaps
    for _, map in pairs(config.mappings[mode]) do
        api.nvim_buf_del_keymap(state.bufnr, "n", map)
    end

    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.help)
    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.quit)
    api.nvim_buf_del_keymap(state.bufnr, "n", config.mappings.toggle_mode)

    -- Restore old keymaps
    for _, map in pairs(state.saved_mappings) do
        api.nvim_buf_set_keymap(state.bufnr, "n", map.lhs, map.rhs, {
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
    local saved_buf_keymaps = set_mappings(cur_win_id, bufnr, mode)

    highlight.highlight_window(cur_win_id, mode)
    set_mode(mode, cur_win_id, bufnr, saved_buf_keymaps)

    -- TODO: Check augroup?
    api.nvim_exec_autocmds("User", {
        pattern = "Winmove" .. titlecase_mode .. "ModeStart",
        group = augroup,
        modeline = false,
    })

    winleave_autocmd = api.nvim_create_autocmd("WinEnter", {
        callback = function()
            local win_id = api.nvim_get_current_win()

            -- Do not stop the current mode if we are entering the window we are
            -- moving/resizing or if we are entering the help window
            if win_id ~= cur_win_id and not float.is_help_window(win_id) then
                stop_mode(mode)
                return true
            end
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
    restore_mappings(mode)
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
