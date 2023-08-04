local winmove = require("winmove")

local function complete()
    return {
        "left",
        "down",
        "up",
        "right",
        "far_left",
        "far_down",
        "far_up",
        "far_right",
        "start",
        "quit",
        "version",
    }
end

---@param arg string
---@return winmove.Direction
local function arg_to_dir(arg)
   return ({
       left = "h",
       down = "j",
       up = "k",
       right = "l",
   })[arg]
end

local function winmove_command(options)
    local arg = options.fargs[1]

    if arg == "version" then
        vim.print(winmove.version())
    elseif arg == "start" then
        if winmove.move_mode_activated() then
            vim.api.nvim_err_writeln("Window move mode is already activated")
            return
        end

        winmove.start_move_mode()
    elseif arg == "quit" then
        if not winmove.move_mode_activated() then
            vim.api.nvim_err_writeln("Window move mode is not activated")
            return
        end

        winmove.stop_move_mode()
    else
        local dir = arg_to_dir(arg)

        if arg then
            local cur_win_id = vim.api.nvim_get_current_win()
            winmove.move_window(cur_win_id, dir)
        end
    end
end

vim.api.nvim_create_user_command("Winmove", winmove_command, {
    nargs = "?",
    complete = complete
})
