local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("wrap-around when moving windows", function()
    it("wraps around when enabled in the config", function()
        config.configure({ wrap_around = true })

        given("", function()
            local win_ids = make_layout({
                "row",
                { "main", "leaf" },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf", main_win_id },
                },
            })
        end)
    end)

    it("does not wrap around when disabled in the config", function()
        winmove.configure({ wrap_around = false })

        given("", function()
            local win_ids = make_layout({
                "row",
                { "main", "leaf" },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf" },
                },
            })
        end)
    end)
end)
