local winmove = require("winmove")
local vader = require("winmove.util.vader")

local given = vader.given

describe("basic movements", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("moves window far to the left", function()
        given("", function()
            local win_ids = vader.make_layout({
                "row",
                {
                    { "leaf" },
                    { "col", { "main", "leaf" } },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    {
                        "col",
                        {
                            { "leaf", win_id },
                            { "leaf", -1 },
                        },
                    },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", win_id },
                    { "leaf", -1 },
                    { "leaf", -1 },
                },
            })
        end)
    end)

    it("moves window far down", function()
        given("", function()
            local win_ids = vader.make_layout({
                "col",
                {
                    { "row", { "main", "leaf" } },
                    { "leaf" },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    {
                        "row",
                        {
                            { "leaf", win_id },
                            { "leaf", -1 },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "j")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", -1 },
                    { "leaf", -1 },
                    { "leaf", win_id },
                },
            })
        end)
    end)

    it("moves window far up", function()
        given("", function()
            local win_ids = vader.make_layout({
                "col",
                {
                    { "leaf" },
                    { "row", { "leaf", "main" } },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", -1 },
                    {
                        "row",
                        {
                            { "leaf", -1 },
                            { "leaf", win_id },
                        },
                    },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "k")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", win_id },
                    { "leaf", -1 },
                    { "leaf", -1 },
                },
            })
        end)
    end)

    it("moves window far to the right", function()
        given("", function()
            -- TODO: Move to util.test_helpers along with compare_tree etc.
            local win_ids = vader.make_layout({
                "row",
                {
                    { "col", { "leaf", "main" } },
                    { "leaf" },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf", -1 },
                            { "leaf", win_id },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    { "leaf", -1 },
                    { "leaf", win_id },
                },
            })
        end)
    end)
end)
