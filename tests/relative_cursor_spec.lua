local winmove = require("winmove")
local vader = require("winmove.util.vader")

local given = vader.given

describe("relative cursor", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("moves window above target", function()
        given("", function()
            local win_ids = vader.make_layout({
                "row",
                {
                    { "col", { "main", "leaf" } },
                    { "leaf" },
                },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf", main_win_id },
                            { "leaf" },
                        },
                    },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf", main_win_id },
                            { "leaf" },
                        },
                    },
                },
            })
        end)
    end)

    it("moves window below target", function()
        given("", function()
            local win_ids = vader.make_layout({
                "row",
                {
                    { "col", { "leaf", "main" } },
                    { "leaf" },
                },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                },
            })
        end)
    end)

    it("moves window between targets", function()
        given("", function()
            local win_ids = vader.make_layout({
                "row",
                {
                    { "col", { "leaf", "main", "leaf" } },
                    { "col", { "leaf", "leaf" } },
                },
            })

            local main_win_id = win_ids["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                            { "leaf" },
                        },
                    },
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
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                            { "leaf" },
                        },
                    },
                },
            })
        end)
    end)

    it("moves window to the right of window above it with long line", function()
        given("", function()
            local win_id = vader.make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "leaf",
                            {
                                "row",
                                {
                                    "leaf",
                                    "main",
                                },
                            },
                        },
                    },
                    "leaf",
                },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
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
                    },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(win_id)

            local buffer = vim.api.nvim_win_get_buf(win_id)
            local width = vim.api.nvim_win_get_width(win_id)
            local long_line = ("x"):rep(width * 0.75)

            vim.api.nvim_buf_set_lines(buffer, 0, 1, true, { long_line })
            winmove.move_window(win_id, "k")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            {
                                "row",
                                {
                                    { "leaf" },
                                    { "leaf", win_id },
                                },
                            },
                            { "leaf" },
                        },
                    },
                    { "leaf" },
                },
            })
        end)
    end)
end)
