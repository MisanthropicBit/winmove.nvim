local winmove = require("winmove")
local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("wrap-around when moving windows", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("wraps around when enabled in the config", function()
        config.configure({
            at_edge = {
                horizontal = at_edge.Wrap,
                vertical = at_edge.Wrap,
            },
            keymaps = {
                move = {
                    split_left = "sh",
                    split_down = "sj",
                    split_up = "sk",
                    split_right = "sl",
                },
            },
        })

        given(function()
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
        config.configure({
            at_edge = {
                horizontal = false,
                vertical = false,
            },
            keymaps = {
                move = {
                    split_left = "sh",
                    split_down = "sj",
                    split_up = "sk",
                    split_right = "sl",
                },
            },
        })

        given(function()
            local main_win_id = make_layout({
                "row",
                { "main", "leaf" },
            })["main"]

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

    it("does not wrap full width window", function()
        config.configure({
            at_edge = {
                horizontal = at_edge.Wrap,
                vertical = at_edge.Wrap,
            },
            keymaps = {
                move = {
                    split_left = "sh",
                    split_down = "sj",
                    split_up = "sk",
                    split_right = "sl",
                },
            },
        })

        given(function()
            local main_win_id = make_layout({
                "col",
                {
                    "main",
                    {
                        "row",
                        { "leaf", "leaf" },
                    },
                },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", main_win_id },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "h")
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", main_win_id },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })
        end)
    end)

    it("does not wrap full height window", function()
        config.configure({
            at_edge = {
                horizontal = at_edge.Wrap,
                vertical = at_edge.Wrap,
            },
            keymaps = {
                move = {
                    split_left = "sh",
                    split_down = "sj",
                    split_up = "sk",
                    split_right = "sl",
                },
            },
        })

        given(function()
            local main_win_id = make_layout({
                "row",
                {
                    "main",
                    {
                        "col",
                        { "leaf", "leaf" },
                    },
                },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "k")
            winmove.move_window(main_win_id, "j")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })
        end)
    end)
end)
