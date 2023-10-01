local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")

local given = vader.given

describe("toggle mode", function()
    it("toggles modes", function()
        given("", function()
            config.setup({ keymaps = { toggle_mode = "t" } })

            local win_id = vader.make_layout({
                "row",
                { "main", "leaf" },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", win_id },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.start_move_mode()

            assert.are.same(winmove.current_mode(), "move")

            vim.cmd([[execute "normal t"]])
            assert.are.same(winmove.current_mode(), "resize")

            vim.cmd([[execute "normal t"]])
            assert.are.same(winmove.current_mode(), "move")

            winmove.stop_move_mode()
        end)
    end)
end)
