local key_handler = {}

local config = require("winmove.config")
local float = require("winmove.float")
local winmove = require("winmove")

local key_handler_namespace = vim.api.nvim_create_namespace("winmove.key-handler")

--- Listen to key events and stop the current mode if the pressed keys are not
--- supported in that mode
---@param stop_mode fun(mode: winmove.Mode)
function key_handler.start(stop_mode)
    local key_buffer = ""

    ---@diagnostic disable-next-line: unused-local
    vim.on_key(function(key, typed)
        if not (typed and #typed > 0) then
            return
        end

        -- Ignore keypresses when in the floating help window
        if float.is_help_window(vim.api.nvim_get_current_win()) then
            return
        end

        local mode = winmove.current_mode()
        local handled = false
        key_buffer = key_buffer .. vim.fn.keytrans(typed):lower()

        if key_buffer == config.keymaps.quit:lower() then
            handled = true
        elseif key_buffer == config.keymaps.help:lower() then
            handled = true
        elseif key_buffer == config.keymaps.toggle_mode:lower() then
            handled = true
        elseif config.key_is_prefix(key_buffer, mode) then
            handled = true
        end

        if handled then
            key_buffer = ""
        else
            stop_mode(mode)
        end
    end, key_handler_namespace)
end

function key_handler.stop()
    vim.on_key(nil, key_handler_namespace)
end

return key_handler
