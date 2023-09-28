local winmove = require("winmove")
local vader = require("winmove.util.vader")

local given = vader.given

describe("no window events", function()
    local events = {
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
    local triggers = {}

    it("does not trigger any window events when moving", function()
        given("", function()
            vim.cmd("belowright vnew")

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
