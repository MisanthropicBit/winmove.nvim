local winmove = require("winmove")
local vader = require("winmove.util.vader")

local given = vader.given

-- TODO: Also test that windows are *not* resized when they should not be
describe("resize", function()
    local count = 3
    assert:set_parameter("TableFormatLevel", 10)

    describe("windows", function()
        it("resizes window to the left", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    {
                        "leaf",
                        {
                            "col",
                            { "leaf", "main" },
                        },
                    },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        {
                            "col",
                            {
                                { "leaf", -1 },
                                { "leaf", win_id },
                            },
                        },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local width = vim.api.nvim_win_get_width(win_id)

                winmove.resize_window(win_id, "h", count)

                assert.are.same(vim.api.nvim_win_get_width(win_id), width + count)
            end)
        end)

        it("resizes window down", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    {
                        "leaf",
                        {
                            "col",
                            { "main", "leaf" },
                        },
                    },
                })["main"]

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
                local height = vim.api.nvim_win_get_height(win_id)

                winmove.resize_window(win_id, "j", count)

                assert.are.same(vim.api.nvim_win_get_height(win_id), height + count)
            end)
        end)

        it("resizes window up", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    {
                        "leaf",
                        {
                            "col",
                            { "leaf", "main" },
                        },
                    },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        {
                            "col",
                            {
                                { "leaf", -1 },
                                { "leaf", win_id },
                            },
                        },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local height = vim.api.nvim_win_get_height(win_id)

                winmove.resize_window(win_id, "k", count)

                assert.are.same(vim.api.nvim_win_get_height(win_id), height + count)
            end)
        end)

        it("resizes window to the right", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    {
                        {
                            "col",
                            { "leaf", "main" },
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
                                { "leaf", -1 },
                                { "leaf", win_id },
                            },
                        },
                        { "leaf", -1 },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local width = vim.api.nvim_win_get_width(win_id)

                winmove.resize_window(win_id, "l", count)

                assert.are.same(vim.api.nvim_win_get_width(win_id), width + count)
            end)
        end)
    end)

    describe("full width/height windows", function()
        it("resizes window to the left", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    {
                        {
                            "col",
                            { "leaf", "leaf" },
                        },
                        "main",
                    },
                })["main"]

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
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local width = vim.api.nvim_win_get_width(win_id)

                winmove.resize_window(win_id, "h", count)

                assert.are.same(vim.api.nvim_win_get_width(win_id), width + count)
            end)
        end)

        it("resizes window down", function()
            given("", function()
                local win_id = vader.make_layout({
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
                        { "leaf", win_id },
                        {
                            "row",
                            {
                                { "leaf", -1 },
                                { "leaf", -1 },
                            },
                        },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local height = vim.api.nvim_win_get_height(win_id)

                winmove.resize_window(win_id, "j", count)

                assert.are.same(vim.api.nvim_win_get_height(win_id), height + count)
            end)
        end)

        it("resizes window up", function()
            given("", function()
                local win_id = vader.make_layout({
                    "col",
                    {
                        {
                            "row",
                            { "leaf", "leaf" },
                        },
                        "main",
                    },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        {
                            "row",
                            {
                                { "leaf", -1 },
                                { "leaf", -1 },
                            },
                        },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local height = vim.api.nvim_win_get_height(win_id)

                winmove.resize_window(win_id, "k", count)

                assert.are.same(vim.api.nvim_win_get_height(win_id), height + count)
            end)
        end)

        it("resizes window to the right", function()
            given("", function()
                local win_id = vader.make_layout({
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
                        { "leaf", win_id },
                        {
                            "col",
                            {
                                { "leaf", -1 },
                                { "leaf", -1 },
                            },
                        },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                local width = vim.api.nvim_win_get_width(win_id)

                winmove.resize_window(win_id, "l", count)

                assert.are.same(vim.api.nvim_win_get_width(win_id), width + count)
            end)
        end)
    end)
end)
