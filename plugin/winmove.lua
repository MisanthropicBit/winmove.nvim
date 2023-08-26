local winmove = require("winmove")

local command_args = {
    "left",
    "down",
    "up",
    "right",
    "split_left",
    "split_down",
    "split_up",
    "split_right",
    "far_left",
    "far_down",
    "far_up",
    "far_right",
    "column_left",
    "column_down",
    "column_up",
    "column_right",
    "move",
    "resize",
    "quit",
    "version",
}

local function complete()
    return command_args
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
    elseif arg == "move" then
        winmove.start_move_mode()
    elseif arg == "resize" then
        winmove.start_resize_mode()
    elseif arg == "quit" then
        winmove.stop_move_mode()
    else
        if command_args[arg] == nil then
            vim.api.nvim_err_writeln(("Invalid argument '%s'"):format(arg))
            return
        end

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
