local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("split_into", function()
    -- Ensure default configuration
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

    assert:set_parameter("TableFormatLevel", 10)

    it("splits left", function()
        given("", function()
            local win_id = make_layout({
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
            winmove.start_mode(winmove.mode.Move)
            vim.cmd.normal("sh")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf", win_id },
                    { "leaf" },
                },
            })
        end)
    end)

    it("splits down", function()
        given("", function()
            local win_id = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            {
                                "row",
                                { "leaf", "main" },
                            },
                            "leaf",
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

            vim.api.nvim_set_current_win(win_id)
            winmove.start_mode(winmove.mode.Move)
            vim.cmd.normal("sj")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", win_id },
                            { "leaf" },
                        },
                    },
                    { "leaf" },
                },
            })
        end)
    end)

    it("splits up", function()
        given("", function()
            local win_id = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "leaf",
                            {
                                "row",
                                { "leaf", "main" },
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

            winmove.start_mode(winmove.mode.Move)
            vim.cmd.normal("sk")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf", win_id },
                            { "leaf" },
                        },
                        { "leaf" },
                    },
                    { "leaf" },
                },
            })
        end)
    end)

    it("splits right", function()
        given("", function()
            local win_id = make_layout({
                "row",
                { "main", "leaf" },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", win_id },
                    { "leaf" },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.start_mode(winmove.mode.Move)
            vim.cmd.normal("l")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf", win_id },
                },
            })
        end)
    end)
end)
