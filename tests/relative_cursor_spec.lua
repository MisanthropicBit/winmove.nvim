local winmove = require("winmove")
local vader = require("winmove.util.vader")

local given = vader.given

describe("relative cursor", function()
    before_each(function()
        assert:set_parameter("TableFormatLevel", 10)
    end)

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
                            { "leaf", -1 },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    {
                        "col",
                        {
                            { "leaf", main_win_id },
                            { "leaf", -1 },
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
                            { "leaf", -1 },
                            { "leaf", main_win_id },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(main_win_id)
            winmove.move_window(main_win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    {
                        "col",
                        {
                            { "leaf", -1 },
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
                            { "leaf", -1 },
                            { "leaf", main_win_id },
                            { "leaf", -1 },
                        },
                    },
                    {
                        "col",
                        {
                            { "leaf", -1 },
                            { "leaf", -1 },
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
                            { "leaf", -1 },
                            { "leaf", -1 },
                        },
                    },
                    {
                        "col",
                        {
                            { "leaf", -1 },
                            { "leaf", main_win_id },
                            { "leaf", -1 },
                        },
                    },
                },
            })
        end)
    end)
end)
