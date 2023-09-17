local winutil = {}

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
function winutil.wincall_no_events(func, ...)
    local saved_eventignore = vim.opt_global.eventignore:get()

    vim.opt_global.eventignore = {
        "WinEnter",
        "WinLeave",
        "WinNew",
        "WinScrolled",
        "WinResized",
        "WinClosed",
        "BufWinEnter",
        "BufWinLeave",
        "BufEnter",
        "BufLeave",
    }

    func(...)

    vim.opt_global.eventignore = saved_eventignore
end

---@param dir winmove.Direction
function winutil.is_vertical(dir)
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

    -- Subtract 1 if tabline is visible
    if vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) then
        height = height - 1
    end

    -- Subtract 1 if statusline is visible
    if
        vim.o.laststatus >= 2 or (vim.o.laststatus == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1)
    then
        height = height - 1
    end

    return height
end

function winutil.is_full_width(win_id)
    return vim.api.nvim_win_get_width(win_id) == winutil.editor_width()
end

function winutil.is_full_height(win_id)
    return vim.api.nvim_win_get_height(win_id) == winutil.editor_height()
end

return winutil
