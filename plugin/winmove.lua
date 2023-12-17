-- TODO: Remove command? It servers no purpose, users might as well require
local winmove = require("winmove")
local compat = require("winmove.compat")
local resize = require("winmove.resize")
local str = require("winmove.util.str")

local message = require("winmove.message")

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
    "resize_left",
    "resize_down",
    "resize_up",
    "resize_right",
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
       split_left = "h",
       split_down = "j",
       split_up = "k",
       split_right = "l",
       far_left = "h",
       far_down = "j",
       far_up = "k",
       far_right = "l",
       resize_left = "h",
       resize_down = "j",
       resize_up = "k",
       resize_right = "l",
   })[arg]
end

---@param arg string
---@return string?
local function get_command(arg)
    for _, command_arg in ipairs(command_args) do
        if arg == command_arg then
            return arg
        end
    end

    return nil
end

local function winmove_command(options)
    local arg = options.fargs[1]

    if arg == "version" then
        compat.print(winmove.version())
    elseif arg == "move" then
        winmove.start_mode(winmove.mode.Move)
    elseif arg == "resize" then
        winmove.start_mode(winmove.mode.Resize)
    elseif arg == "quit" then
        winmove.stop_mode()
    else
        local command = get_command(arg)

        if command == nil then
            message.error(("Invalid argument '%s'"):format(arg))
            return
        end

        local win_id = vim.api.nvim_get_current_win()
        local dir = arg_to_dir(arg)

        if str.has_prefix(command, "resize") then
            resize.resize_window(win_id, dir, 3)
        elseif str.has_prefix(command, "split") then
            winmove.split_into(win_id, dir)
        elseif str.has_prefix(command, "far") then
            winmove.move_window_far(win_id, dir)
        else
            winmove.move_window(win_id, dir)
        end
    end
end

vim.api.nvim_create_user_command("Winmove", winmove_command, {
    nargs = "?",
    complete = complete
})
