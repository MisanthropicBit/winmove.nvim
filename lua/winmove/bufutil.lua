local bufutil = {}

local winutil = require("winmove.winutil")

---@class winmove.SplitBufferOptions
---@field vertical   boolean
---@field rightbelow boolean

---@param buffer integer
---@param options winmove.SplitBufferOptions
function bufutil.split_buffer(buffer, options)
    -- NOTE: We cannot use win_splitmove across tab pages so construct a command to
    -- open a buffer in relation to the target window

    -- Save the old switchbuf option, remove it, and restore it afterwards
    local old_switchbuf = vim.o.switchbuf
    vim.o.switchbuf = ""

    local cmd_prefixes = {}

    if options.vertical then
        table.insert(cmd_prefixes, "vertical")
    end

    local cmd = options.rightbelow and "rightbelow" or "aboveleft"

    table.insert(cmd_prefixes, cmd)
    table.insert(cmd_prefixes, " ")

    local split_command = ("%ssbuffer %d"):format(table.concat(cmd_prefixes, " "), buffer)

    winutil.wincall_no_events(function()
        vim.cmd(split_command)
    end)

    vim.o.switchbuf = old_switchbuf
end

return bufutil
