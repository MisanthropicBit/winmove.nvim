local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")

local given = vader.given

describe("wrap-around when moving windows", function()
    it("wraps around when enabled in the config", function()
        config.setup({ wrap_around = true })

        given("", function()
            local win_ids = vader.make_layout({
                "row",
                { "main", "leaf" },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    { "leaf", main_win_id },
                },
            })
        end)
    end)

    it("does not wrap around when disabled in the config", function()
        winmove.setup({ wrap_around = false })

        given("", function()
            local win_ids = vader.make_layout({
                "row",
                { "main", "leaf" },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", -1 },
                },
            })
        end)
    end)
end)
