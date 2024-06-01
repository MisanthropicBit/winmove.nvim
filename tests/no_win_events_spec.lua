local winmove = require("winmove")
local compat = require("winmove.compat")
local vader = require("winmove.util.vader")

local given = vader.given

describe("no window events", function()
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

    local triggers = {}

    it("does not trigger any window events when moving", function()
        given(function()
            vim.cmd.vnew()

            -- Set up autocmds *after* splitting
            for _, event in ipairs(events) do
                vim.api.nvim_create_autocmd(event, {
                    callback = function()
                        triggers[event] = true
                    end,
                })
            end

            winmove.move_window(vim.api.nvim_get_current_win(), "h")

            assert.are.same(triggers, {})
        end)
    end)
end)
