local winmove = require("winmove")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("basic movements", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("moves window far to the left", function()
        given(function()
            local win_ids = make_layout({
                "row",
                {
                    "leaf",
                    { "col", { "main", "leaf" } },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf", win_id },
                            { "leaf" },
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
                    { "leaf" },
                    { "leaf" },
                },
            })
        end)
    end)

    it("moves window far down", function()
        given(function()
            local win_ids = make_layout({
                "col",
                {
                    { "row", { "main", "leaf" } },
                    "leaf",
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
                            { "leaf" },
                        },
                    },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "j")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf" },
                    { "leaf" },
                    { "leaf", win_id },
                },
            })
        end)
    end)

    it("moves window far up", function()
        given(function()
            local win_ids = make_layout({
                "col",
                {
                    "leaf",
                    { "row", { "leaf", "main" } },
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf" },
                    {
                        "row",
                        {
                            { "leaf" },
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
                    { "leaf" },
                    { "leaf" },
                },
            })
        end)
    end)

    it("moves window far to the right", function()
        given(function()
            local win_ids = make_layout({
                "row",
                {
                    { "col", { "leaf", "main" } },
                    "leaf",
                },
            })

            local win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", win_id },
                        },
                    },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.move_window_far(win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf" },
                    { "leaf", win_id },
                },
            })
        end)
    end)
end)
