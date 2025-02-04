local winmove = {}

local at_edge = require("winmove.at_edge")
local bufutil = require("winmove.bufutil")
local config = require("winmove.config")
local float = require("winmove.float")
local highlight = require("winmove.highlight")
local layout = require("winmove.layout")
local message = require("winmove.message")
local _mode = require("winmove.mode")
local State = require("winmove.state")
local resize = require("winmove.resize")
local str = require("winmove.util.str")
local swap = require("winmove.swap")
local validators = require("winmove.validators")
local winutil = require("winmove.winutil")

winmove.Mode = _mode.Mode
winmove.AtEdge = at_edge.AtEdge
winmove.ResizeAnchor = resize.anchor

local api = vim.api
local winmove_version = "0.1.2"

local augroup = api.nvim_create_augroup("Winmove", { clear = true })
local autocmds = {}
local state = State.new()

---@type fun(mode: winmove.Mode)
local start_mode

---@type fun(mode: winmove.Mode)
local stop_mode

function winmove.version()
    return winmove_version
end

---@alias winmove.HorizontalDirection "h" | "l"
---@alias winmove.VerticalDirection "k" | "j"
---@alias winmove.Direction winmove.HorizontalDirection | winmove.VerticalDirection

---@param win_id integer
---@param target_win_id integer
---@param dir winmove.Direction
---@param vertical boolean
local function move_window_to_tab(win_id, target_win_id, dir, vertical)
    local source_buffer = api.nvim_win_get_buf(win_id)

    -- https://github.com/neovim/neovim/issues/18283
    highlight.unhighlight_window(win_id)

    if not winutil.wincall_no_events(api.nvim_win_close, win_id, false) then
        return
    end

    if not winutil.wincall_no_events(api.nvim_set_current_win, target_win_id) then
        return
    end

    -- Split buffer and switch to new window
    bufutil.split_buffer(source_buffer, {
        vertical = vertical,
        rightbelow = dir == "j" or dir == "l",
    })

    local new_win_id = api.nvim_get_current_win()
    local mode = winmove.Mode.Move

    if winmove.current_mode() == winmove.Mode.Move then
        highlight.highlight_window(new_win_id, mode)

        -- Update state with the new window
        state:update({ win_id = new_win_id })
    end
end

---@param win_id integer
---@param dir winmove.Direction
---@param behaviour winmove.AtEdge
---@param split_into boolean
---@return boolean
---@return integer?
---@return winmove.Direction
local function handle_edge(win_id, dir, mode, behaviour, split_into)
    if behaviour == winmove.AtEdge.None then
        return false, nil, dir
    elseif behaviour == winmove.AtEdge.Wrap then
        local new_target_win_id = layout.get_wraparound_neighbor(win_id, dir)

        if new_target_win_id == win_id then
            -- If we get the same window it is full width/height because we
            -- wrapped around to the same window
            return false, nil, dir
        end

        local target_win_id = new_target_win_id
        dir = winutil.reverse_direction(dir)

        return true, target_win_id, dir
    elseif behaviour == winmove.AtEdge.MoveToTab then
        if winutil.window_count() == 1 and vim.fn.tabpagenr("$") == 1 then
            -- Only one window and one tab, do not proceed
            return false, nil, dir
        end

        if not winutil.is_horizontal(dir) then
            -- Do not try to move to a tab vertically even if the user selected
            -- that behaviour by mistake
            return false, nil, dir
        end

        ---@cast dir winmove.HorizontalDirection
        local target_win_id, reldir = layout.get_target_window_in_tab(win_id, dir)
        local final_dir = reldir ---@type winmove.Direction
        local vertical = false

        if split_into then
            final_dir = winutil.reverse_direction(dir)
            vertical = true
        end

        if mode == winmove.Mode.Move then
            -- TODO: Refactor so we do not need to call this here
            move_window_to_tab(win_id, target_win_id, final_dir, vertical)
        elseif mode == winmove.Mode.Swap then
            return true, target_win_id, dir
        end

        return false, target_win_id, dir
    else
        error(("Unexpected at edge behaviour '%s'"):format(behaviour))
    end
end

---@param win_id integer
---@param mode winmove.Mode
---@return boolean
local function can_move_or_swap(win_id, mode)
    local at_edge_horizontal = config.modes[mode].at_edge.horizontal

    if at_edge_horizontal == winmove.AtEdge.MoveToTab then
        if winutil.window_count() == 1 and vim.fn.tabpagenr("$") == 1 then
            ---@cast mode string
            message.error(("Cannot %s window, only one window and tab"):format(mode:lower()))
            return false
        end
    else
        if winutil.window_count() == 1 then
            ---@cast mode string
            message.error(("Cannot %s window, only one window"):format(mode:lower()))
            return false
        end
    end

    if mode == winmove.Mode.Move and winutil.is_floating_window(win_id) then
        message.error("Cannot move floating window")
        return false
    end

    return true
end

---@param win_id integer
---@param dir winmove.Direction
---@param mode winmove.Mode
---@param split_into boolean
---@return boolean
---@return integer?
---@return winmove.Direction
local function find_target_win_id(win_id, dir, mode, split_into)
    local target_win_id = layout.get_neighbor(win_id, dir)

    -- No neighbor, handle configured behaviour at edges
    if target_win_id == nil then
        local edge_type = winutil.is_horizontal(dir) and "horizontal" or "vertical"
        local behaviour = config.modes[mode].at_edge[edge_type]
        local proceed, new_target_win_id, new_dir =
            handle_edge(win_id, dir, mode, behaviour, split_into)

        return proceed, new_target_win_id, new_dir
    end

    return true, target_win_id, dir
end

--- Move a window in a given direction
---@param win_id integer
---@param dir winmove.Direction
local function move_window(win_id, dir)
    if not can_move_or_swap(win_id, winmove.Mode.Move) then
        return
    end

    local proceed, target_win_id, new_dir =
        find_target_win_id(win_id, dir, winmove.Mode.Move, false)

    if not proceed then
        return
    end

    dir = new_dir
    ---@cast target_win_id -nil

    if not layout.are_siblings(win_id, target_win_id) then
        dir = layout.get_sibling_relative_dir(win_id, target_win_id, dir)
    end

    winutil.wincall_no_events(
        vim.fn.win_splitmove,
        win_id,
        target_win_id,
        { vertical = winutil.is_horizontal(dir), rightbelow = dir == "j" or dir == "l" }
    )
end

--- Move a window in a given direction
---@param win_id integer
---@param dir winmove.Direction
function winmove.move_window(win_id, dir)
    vim.validate({
        win_id = validators.win_id_validator(win_id),
        dir = validators.dir_validator(dir),
    })

    winutil.wincall(win_id, move_window, win_id, dir)
end

--- Split a window into another window in a given direction
---@param win_id integer
---@param dir winmove.Direction
local function split_into(win_id, dir)
    if winutil.window_count() == 1 then
        return
    end

    local proceed, target_win_id, new_dir = find_target_win_id(win_id, dir, winmove.Mode.Move, true)

    if not proceed then
        return
    end

    dir = new_dir
    ---@cast target_win_id -nil

    local split_options = {
        vertical = winutil.is_horizontal(dir),
        rightbelow = dir == "h" or dir == "k",
    }

    if layout.are_siblings(win_id, target_win_id) then
        local reldir = layout.get_sibling_relative_dir(win_id, target_win_id, dir)

        split_options.vertical = not split_options.vertical
        split_options.rightbelow = reldir == "l" or reldir == "j"
    end

    winutil.wincall_no_events(vim.fn.win_splitmove, win_id, target_win_id, split_options)
end

--- Split a window into another window in a given direction
---@param win_id integer
---@param dir winmove.Direction
function winmove.split_into(win_id, dir)
    vim.validate({
        win_id = validators.win_id_validator(win_id),
        dir = validators.dir_validator(dir),
    })

    winutil.wincall(win_id, split_into, win_id, dir)
end

---@diagnostic disable-next-line:unused-local
--- Move a window as far as possible in a direction
---@param win_id integer
---@param dir winmove.Direction
function winmove.move_window_far(win_id, dir)
    vim.validate({
        win_id = validators.win_id_validator(win_id),
        dir = validators.dir_validator(dir),
    })

    winutil.wincall(win_id, function()
        vim.cmd("wincmd " .. dir:upper())
    end)
end

---@param win_id integer
---@param dir winmove.Direction
local function swap_window_in_direction(win_id, dir)
    local mode = winmove.Mode.Swap

    if not can_move_or_swap(win_id, mode) then
        return
    end

    local proceed, target_win_id, _ = find_target_win_id(win_id, dir, mode, false)

    if not proceed then
        return
    end

    ---@cast target_win_id -nil
    swap.swap_window_in_direction(win_id, target_win_id)

    if winmove.current_mode() == winmove.Mode.Swap then
        -- Seems the winhighlight bug can also leak into other windows when
        -- switching: https://github.com/neovim/neovim/issues/18283
        highlight.unhighlight_window(target_win_id)
        highlight.unhighlight_window(win_id)
        highlight.highlight_window(target_win_id, mode)

        -- Update state with the new window
        state:update({ win_id = target_win_id })
    end
end

---@param win_id integer
---@param dir winmove.Direction
function winmove.swap_window_in_direction(win_id, dir)
    vim.validate({
        win_id = validators.win_id_validator(win_id),
        dir = validators.dir_validator(dir),
    })

    winutil.wincall_no_events(function()
        swap_window_in_direction(win_id, dir)
    end)
end

---@param win_id integer
function winmove.swap_window(win_id)
    vim.validate({ win_id = validators.win_id_validator(win_id) })

    winutil.wincall_no_events(function()
        swap.swap_window(win_id)
    end)
end

local next_mode = {
    [winmove.Mode.Move] = winmove.Mode.Swap,
    [winmove.Mode.Swap] = winmove.Mode.Resize,
    [winmove.Mode.Resize] = winmove.Mode.Move,
}

local function toggle_mode()
    local mode = winmove.current_mode()
    local new_mode = next_mode[mode]

    stop_mode(mode)
    start_mode(new_mode)
end

---@param keys string
local function move_mode_key_handler(keys)
    local keymaps = config.modes.move.keymaps

    ---@type integer
    local win_id = state:get("win_id")

    if keys == keymaps.left then
        move_window(win_id, "h")
    elseif keys == keymaps.down then
        move_window(win_id, "j")
    elseif keys == keymaps.up then
        move_window(win_id, "k")
    elseif keys == keymaps.right then
        move_window(win_id, "l")
    elseif keys == keymaps.split_left then
        split_into(win_id, "h")
    elseif keys == keymaps.split_down then
        split_into(win_id, "j")
    elseif keys == keymaps.split_up then
        split_into(win_id, "k")
    elseif keys == keymaps.split_right then
        split_into(win_id, "l")
    elseif keys == keymaps.far_left then
        winmove.move_window_far(win_id, "h")
    elseif keys == keymaps.far_down then
        winmove.move_window_far(win_id, "j")
    elseif keys == keymaps.far_up then
        winmove.move_window_far(win_id, "k")
    elseif keys == keymaps.far_right then
        winmove.move_window_far(win_id, "l")
    end
end

---@param keys string
local function swap_mode_key_handler(keys)
    ---@type integer
    local win_id = state:get("win_id")
    local keymaps = config.modes.swap.keymaps

    if keys == keymaps.left then
        winmove.swap_window_in_direction(win_id, "h")
    elseif keys == keymaps.down then
        winmove.swap_window_in_direction(win_id, "j")
    elseif keys == keymaps.up then
        winmove.swap_window_in_direction(win_id, "k")
    elseif keys == keymaps.right then
        winmove.swap_window_in_direction(win_id, "l")
    end
end

---@param keys string
local function resize_mode_key_handler(keys)
    local count = vim.v.count

    -- If no count is provided use the default count
    if count == 0 then
        count = config.modes.resize.default_resize_count
    end

    ---@type integer
    local win_id = state.win_id
    local keymaps = config.modes.resize.keymaps

    if keys == keymaps.left then
        resize.resize_window(win_id, "h", count, resize.anchor.TopLeft)
    elseif keys == keymaps.down then
        resize.resize_window(win_id, "j", count, resize.anchor.TopLeft)
    elseif keys == keymaps.up then
        resize.resize_window(win_id, "k", count, resize.anchor.TopLeft)
    elseif keys == keymaps.right then
        resize.resize_window(win_id, "l", count, resize.anchor.TopLeft)
    elseif keys == keymaps.left_botright then
        resize.resize_window(win_id, "h", count, resize.anchor.BottomRight)
    elseif keys == keymaps.down_botright then
        resize.resize_window(win_id, "j", count, resize.anchor.BottomRight)
    elseif keys == keymaps.up_botright then
        resize.resize_window(win_id, "k", count, resize.anchor.BottomRight)
    elseif keys == keymaps.right_botright then
        resize.resize_window(win_id, "l", count, resize.anchor.BottomRight)
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

    for _, keymap in ipairs(existing_buf_keymaps) do
        if keymap.lhs then
            keymaps[keymap.lhs] = {
                lhs = keymap.lhs,
                rhs = keymap.rhs or "",
                expr = keymap.expr == 1,
                callback = keymap.callback,
                noremap = keymap.noremap > 0, -- Apparently noremap is 2 when script is given
                script = keymap.script == 1,
                silent = keymap.silent == 1,
                nowait = keymap.nowait == 1,
            }
        end
    end

    return keymaps
end

---@param mode winmove.Mode?
---@param err unknown?
local function handle_error_in_mode(mode, err)
    -- There was an error during a mode, restore keymaps and quit current mode
    local cur_mode = mode or winmove.current_mode()

    winmove.stop_mode()
    message.error((("Got error in '%s' mode: %s"):format(cur_mode, err)))
end

---@param func function
---@param ... unknown
---@return function
local function safe_call_autorestore_mode(func, ...)
    local args = { ... }

    return function()
        local ok, err = pcall(func, unpack(args))

        if not ok then
            handle_error_in_mode(nil, err)
        end
    end
end

local mode_key_handlers = {
    [winmove.Mode.Move] = move_mode_key_handler,
    [winmove.Mode.Swap] = swap_mode_key_handler,
    [winmove.Mode.Resize] = resize_mode_key_handler,
}

---@param mode winmove.Mode
---@return fun(keys: string)
local function create_mode_key_handler(mode)
    local handler = mode_key_handlers[mode]

    return function(keys)
        local ok, err = pcall(handler, keys)

        if not ok then
            handle_error_in_mode(mode, err)
        end
    end
end

--- Set move mode keymaps and save keymaps that need to be restored when we
--- exit move mode
---@param win_id integer
---@param bufnr integer
---@param mode winmove.Mode
local function set_keymaps(win_id, bufnr, mode)
    local existing_buf_keymaps = get_existing_buffer_keymaps(bufnr)
    local saved_buf_keymaps = {}
    local handler = create_mode_key_handler(mode)

    for name, map in pairs(config.modes[mode].keymaps) do
        local description = config.get_keymap_description(name, mode)
        set_mode_keymap(win_id, bufnr, map, handler, description)

        local existing_keymap = existing_buf_keymaps[map]

        -- Save any existing user-defined keymap that we override so we can
        -- restore it later
        if existing_keymap then
            table.insert(saved_buf_keymaps, existing_keymap)
        end
    end

    set_mode_keymap(
        win_id,
        bufnr,
        config.keymaps.help,
        safe_call_autorestore_mode(float.open, mode),
        config.get_keymap_description("help")
    )

    -- We cannot use safe_call_autorestore_mode here as it would call stop_mode
    -- indefintely on error
    set_mode_keymap(
        win_id,
        bufnr,
        config.keymaps.quit,
        winmove.stop_mode,
        config.get_keymap_description("quit")
    )

    set_mode_keymap(
        win_id,
        bufnr,
        config.keymaps.toggle_mode,
        safe_call_autorestore_mode(toggle_mode),
        config.get_keymap_description("toggle_mode")
    )

    return saved_buf_keymaps
end

--- Delete mode keymaps and restore previous buffer keymaps
---@param mode winmove.Mode
local function restore_keymaps(mode)
    local bufnr = state:get("bufnr")

    if not api.nvim_buf_is_valid(bufnr) then
        return
    end

    -- Remove winmove keymaps in protected calls since the buffer might have
    -- been deleted but the buffer can still be marked as valid
    for _, map in pairs(config.modes[mode].keymaps) do
        pcall(api.nvim_buf_del_keymap, bufnr, "n", map)
    end

    for _, map in pairs(config.keymaps) do
        pcall(api.nvim_buf_del_keymap, bufnr, "n", map)
    end

    -- Restore old keymaps
    for _, keymap in ipairs(state:get("saved_keymaps")) do
        vim.keymap.set("n", keymap.lhs, keymap.rhs, {
            buffer = bufnr,
            expr = keymap.expr,
            callback = keymap.callback,
            noremap = keymap.noremap,
            script = keymap.script,
            silent = keymap.silent,
            nowait = keymap.nowait,
        })
    end
end

---@param mode winmove.Mode
---@param win_id integer
local function create_mode_autocmds(mode, win_id)
    -- Clear any existing autocommands
    for _, autocmd in ipairs(autocmds) do
        pcall(api.nvim_del_autocmd, autocmd)
    end

    autocmds = {}

    -- TODO: Do these actually trigger when we ignore them?

    if mode ~= winmove.Mode.Swap then
        table.insert(
            autocmds,
            api.nvim_create_autocmd("WinEnter", {
                callback = function()
                    local cur_win_id = api.nvim_get_current_win()

                    -- Do not stop the current mode if we are entering the window
                    -- we are moving or if we are entering the help window
                    if cur_win_id ~= win_id and not float.is_help_window(cur_win_id) then
                        stop_mode(mode)
                        return true
                    end
                end,
                group = augroup,
                desc = "Quits " .. mode .. " mode when leaving the window",
            })
        )
    end

    -- If we enter a new window, unhighlight the window since there is a bug
    -- where the winhighlight option can leak into other windows:
    -- https://github.com/neovim/neovim/issues/18283
    table.insert(
        autocmds,
        api.nvim_create_autocmd("WinNew", {
            callback = function()
                local cur_win_id = api.nvim_get_current_win()

                -- Clear the winhighlight option if the winmove highlighting
                -- has leaked into the new window
                if highlight.has_highlight(cur_win_id, mode) then
                    highlight.unhighlight_window(cur_win_id)
                end

                return true
            end,
            group = augroup,
            desc = "Remove highlighting from any new window because the winhighlight option can leak into other windows",
        })
    )

    table.insert(
        autocmds,
        api.nvim_create_autocmd("InsertEnter", {
            callback = function()
                stop_mode(mode)
                return true
            end,
            group = augroup,
            desc = "Quits " .. mode .. " mode when entering insert mode",
        })
    )
end

---@param mode winmove.Mode
start_mode = function(mode)
    local cur_win_id = api.nvim_get_current_win()

    if mode == winmove.Mode.Resize then
        if winutil.window_count() == 1 then
            message.error("Cannot resize window, only one window")
            return
        end
    else
        if not can_move_or_swap(cur_win_id, mode) then
            return
        end
    end

    if winmove.current_mode() == mode then
        message.error(str.titlecase(mode) .. " mode already activated")
        return
    end

    local bufnr = api.nvim_get_current_buf()
    local saved_buf_keymaps = set_keymaps(cur_win_id, bufnr, mode)

    highlight.highlight_window(cur_win_id, mode)
    state:update({
        mode = mode,
        win_id = cur_win_id,
        bufnr = bufnr,
        saved_keymaps = saved_buf_keymaps,
    })

    api.nvim_exec_autocmds("User", {
        pattern = "WinmoveModeStart",
        modeline = false,
        data = { mode = mode },
    })

    create_mode_autocmds(mode, cur_win_id)
end

---@param mode winmove.Mode
stop_mode = function(mode)
    if winmove.current_mode() == nil then
        message.error("No mode is currently active")
        return
    end

    if winmove.current_mode() ~= mode then
        message.error("Window " .. mode .. " mode is not activated")
        return
    end

    local unhighlight_ok = pcall(highlight.unhighlight_window, state:get("win_id"))

    if not unhighlight_ok then
        message.error("Failed to unhighlight window when stopping mode")
    end

    local restore_ok = pcall(restore_keymaps, mode)

    if not restore_ok then
        message.error("Failed to restore keymaps when stopping mode")
    end

    state:reset()

    for _, autocmd in ipairs(autocmds) do
        pcall(api.nvim_del_autocmd, autocmd)
    end

    autocmds = {}

    api.nvim_exec_autocmds("User", {
        pattern = "WinmoveModeEnd",
        modeline = false,
        data = { mode = mode },
    })
end

local sorted_modes = vim.tbl_values(winmove.Mode)
table.sort(sorted_modes)

local check_mode_error_message = ("a valid mode (%s)"):format(table.concat(sorted_modes, ", "))

---@param mode winmove.Mode
function winmove.start_mode(mode)
    vim.validate({ mode = { mode, _mode.is_valid_mode, check_mode_error_message } })

    start_mode(mode)
end

function winmove.stop_mode()
    stop_mode(winmove.current_mode())
end

---@param win_id integer
---@param dir winmove.Direction
---@param count integer
---@param anchor winmove.ResizeAnchor?
function winmove.resize_window(win_id, dir, count, anchor)
    vim.validate({
        win_id = validators.win_id_validator(win_id),
        dir = validators.dir_validator(dir),
        count = { count, validators.is_nonnegative_number, "a non-negative number" },
        anchor = { anchor, resize.is_valid_anchor, "a valid anchor" },
    })

    if winutil.window_count() == 1 then
        return
    end

    winutil.wincall(win_id, function()
        resize.resize_window(win_id, dir, count, anchor)
    end)
end

function winmove.current_mode()
    return state:get("mode")
end

function winmove.configure(user_config)
    config.configure(user_config)
end

local function fix_lingering_winhighlight()
    -- See https://github.com/neovim/neovim/discussions/32163 for details
    api.nvim_create_autocmd("BufWinEnter", {
        callback = function()
            local win_id = api.nvim_get_current_win()
            local has_winmove_hl = highlight.has_highlight(win_id, winmove.Mode.Move)
                or highlight.has_highlight(win_id, winmove.Mode.Swap)
                or highlight.has_highlight(win_id, winmove.Mode.Resize)

            if has_winmove_hl then
                vim.wo[win_id].winhighlight = ""
            end
        end,
        group = augroup,
        desc = "Fixes lingering winhighlight for winmove modes",
    })
end

fix_lingering_winhighlight()

return winmove
