local key_handler = {}

local compat = require("winmove.compat")
local config = require("winmove.config")
local float = require("winmove.float")
local message = require("winmove.message")

local interval_ms = 50
local timer
local debug = false

---@param mode winmove.Mode
---@param handler fun(keys: string): boolean
---@param toggle_mode fun()
---@param start_mode fun(mode: winmove.Mode, use_key_handler: boolean?)
---@param stop_mode fun(mode: winmove.Mode, use_key_handler: boolean?)
function key_handler.start(mode, handler, toggle_mode, start_mode, stop_mode)
    local key_buffer = ""
    local running = true

    timer = compat.uv.new_timer()
    timer:start(interval_ms, interval_ms, vim.schedule_wrap(vim.cmd.redraw))

    local ok, err  = pcall(function()
        while running do
            local ok, key_or_err = pcall(vim.fn.getcharstr)

            if not ok then
                stop_mode(mode, true)
                break
            end

            key_buffer = (key_buffer .. vim.fn.keytrans(key_or_err)):lower()
            local handled = handler(key_buffer)

            if debug then
                vim.print(vim.inspect({ "handled", handled }))
                vim.print(vim.inspect({ "key_buffer", key_buffer }))
                vim.print(vim.inspect({ "prefix", config.key_is_prefix(key_buffer, mode) }))
            end

            if key_buffer == config.keymaps.quit:lower() then
                stop_mode(mode, true)
                break
            elseif key_buffer == config.keymaps.help:lower() then
                stop_mode(mode, true)

                float.open(mode, { on_quit = function()
                    start_mode(mode, true)
                end})

                vim.api.nvim_create_autocmd("WinEnter", {
                    callback = function()
                        float.close()
                        return true
                    end,
                })

                break
            elseif key_buffer == config.keymaps.toggle_mode:lower() then
                key_buffer = ""
                mode, handler = toggle_mode()

                if debug then
                    vim.print(("Switched to new mode '%s'"):format(mode))
                end
            elseif handled then
                key_buffer = ""
            elseif not config.key_is_prefix(key_buffer, mode) then
                -- If a key is not a prefix and was not handled then stop
                stop_mode(mode, true)
                break
            end
        end
    end)

    timer:stop()

    if not ok then
        stop_mode(mode, true)
        message.error((("Got error in '%s' mode: %s"):format(mode, err)))
    end
end

function key_handler.stop()
    if timer then
        timer:stop()
    end
end

return key_handler
