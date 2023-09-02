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
        "WinScrolled",
        "WinResized",
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

return winutil
