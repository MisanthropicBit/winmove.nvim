local window = {}

--- Call a window-related function in the current window without triggering any events
---@param func function
---@param ... any
function window.wincall_no_events(func, ...)
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
function window.is_vertical(dir)
    return dir == "h" or dir == "l"
end

---@param dir winmove.Direction
---@return winmove.Direction
function window.reverse_direction(dir)
    return ({
        h = "l",
        l = "h",
        j = "k",
        k = "j",
    })[dir]
end

return window
