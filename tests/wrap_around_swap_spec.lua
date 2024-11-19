local winmove = require("winmove")
local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("wrap-around when swapping windows", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("wraps around when enabled in the config", function()
        config.configure({
            modes = {
                swap = {
                    at_edge = {
                        horizontal = at_edge.AtEdge.Wrap,
                        vertical = at_edge.AtEdge.Wrap,
                    },
                },
            },
        })

        given(function()
            local win_ids = make_layout({
                "row",
                { "main", "target" },
            })

            local main_win_id = win_ids["main"]
            local target_win_id = win_ids["target"]
            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            winmove.swap_window_in_direction(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("does not wrap around when disabled in the config", function()
        config.configure({
            modes = {
                swap = {
                    at_edge = {
                        horizontal = at_edge.AtEdge.None,
                        vertical = at_edge.AtEdge.None,
                    },
                },
            },
        })

        given(function()
            local win_ids = make_layout({
                "row",
                { "main", "target" },
            })

            local main_win_id = win_ids["main"]
            local target_win_id = win_ids["target"]
            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            winmove.swap_window_in_direction(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr1)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr2)
        end)
    end)

    it("does not wrap full width window", function()
        config.configure({
            modes = {
                swap = {
                    at_edge = {
                        horizontal = at_edge.AtEdge.Wrap,
                        vertical = at_edge.AtEdge.Wrap,
                    },
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

            local bufnr = vim.api.nvim_win_get_buf(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "h")
            winmove.swap_window_in_direction(main_win_id, "l")

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

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr)
        end)
    end)

    it("does not wrap full height window", function()
        config.configure({
            modes = {
                swap = {
                    at_edge = {
                        horizontal = at_edge.AtEdge.Wrap,
                        vertical = at_edge.AtEdge.Wrap,
                    },
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

            local bufnr = vim.api.nvim_win_get_buf(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "k")
            winmove.swap_window_in_direction(main_win_id, "j")

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

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr)
        end)
    end)
end)
