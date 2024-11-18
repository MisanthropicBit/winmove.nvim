local winutil = {}

local compat = require("winmove.compat")
local message = require("winmove.message")

local events = {
    "WinEnter",
    "WinLeave",
    "WinNew",
    "WinScrolled",
    "WinClosed",
    "BufWinEnter",
    "BufWinLeave",
    "BufEnter",
    "BufLeave",
}

if compat.has("nvim-0.8.2") then
    table.insert(events, "WinResized")
end

function winutil.get_ignored_events()
    return events
end

---@return integer
function winutil.window_count()
    return vim.fn.winnr("$")
end

---@param win_id integer
---@return boolean
function winutil.is_floating_window(win_id)
    local win_config = vim.api.nvim_win_get_config(win_id)

    return win_config and (win_config.relative ~= "" or not win_config.relative)
end

--- Call a window-related function in the current window without triggering any events
---@param func function
---@param ... any
---@return boolean
function winutil.wincall_no_events(func, ...)
    local saved_eventignore = vim.opt_global.eventignore:get()

    vim.opt_global.eventignore = winutil.get_ignored_events()

    -- Do a protected call so that we restore 'eventignore' in case it fails
    local ok, error = pcall(func, ...)

    if not ok then
        message.error(error)
    end

    vim.opt_global.eventignore = saved_eventignore

    return ok
end

---@param win_id integer
---@param func function
---@param ... any
function winutil.wincall(win_id, func, ...)
    -- NOTE: Using vim.api.nvim_win_call seems to trigger 'textlock' or leaves
    -- nvim in a weird state where the process exists with either code 134 or
    -- 139 so we are instead using 'wincall_no_events'. This might also happen
    -- because we would close the window inside the vim.api.nvim_win_call call
    -- when moving the window to another tab
    local cur_win_id = vim.api.nvim_get_current_win()
    local is_same_window_id = cur_win_id == win_id

    if not is_same_window_id then
        winutil.wincall_no_events(vim.api.nvim_set_current_win, win_id)
    end

    winutil.wincall_no_events(func, ...)

    if not is_same_window_id then
        winutil.wincall_no_events(vim.api.nvim_set_current_win, cur_win_id)
    end
end

---@param dir winmove.Direction
function winutil.is_horizontal(dir)
    -- TODO: Move direction functions into a direction.lua file?
    return dir == "h" or dir == "l"
end

---@param dir winmove.Direction
---@return winmove.Direction
function winutil.reverse_direction(dir)
    return ({
        h = "l",
        l = "h",
        j = "k",
        k = "j",
    })[dir]
end

---@return integer
function winutil.editor_width()
    return vim.o.columns
end

---@return integer
function winutil.editor_height()
    local height = vim.o.lines - vim.o.cmdheight

    local showtabline = vim.o.showtabline

    -- Subtract 1 if the tabline is visible
    if showtabline == 2 or (showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) then
        height = height - 1
    end

    local laststatus = vim.o.laststatus

    -- Subtract 1 if the statusline is visible
    if laststatus >= 2 or (laststatus == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1) then
        height = height - 1
    end

    return height
end

return winutil
