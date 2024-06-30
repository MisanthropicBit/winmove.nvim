local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("toggle mode", function()
    it("toggles modes", function()
        given(function()
            config.configure({ keymaps = { toggle_mode = "t" } })

            local win_id = make_layout({
                "row",
                { "main", "leaf" },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", win_id },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.start_mode(winmove.Mode.Move)

            assert.are.same(winmove.current_mode(), "move")

            vim.cmd([[execute "normal t"]])
            assert.are.same(winmove.current_mode(), "resize")

            vim.cmd([[execute "normal t"]])
            assert.are.same(winmove.current_mode(), "move")

            winmove.stop_mode()
        end)
    end)
end)
