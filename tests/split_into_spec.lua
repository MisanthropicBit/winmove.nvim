local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")

local given = vader.given

describe("split_into", function()
    -- Ensure default keymaps
    config.setup({
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
            local win_id = vader.make_layout({
                "row",
                {
                    {
                        "col",
                        { "main", "leaf" },
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
                            { "leaf", win_id },
                            { "leaf", -1 },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.start_move_mode()
            vim.cmd.normal("sh")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", -1 },
                    { "leaf", win_id },
                    { "leaf", -1 },
                },
            })
        end)
    end)

    it("splits down", function()
        given("", function()
            local win_id = vader.make_layout({
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
                                    { "leaf", -1 },
                                    { "leaf", win_id },
                                },
                            },
                            { "leaf", -1 },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)
            winmove.start_move_mode()
            vim.cmd.normal("sj")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf", -1 },
                            { "leaf", win_id },
                            { "leaf", -1 },
                        },
                    },
                    { "leaf", -1 },
                },
            })
        end)
    end)

    it("splits up", function()
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
                            { "leaf", -1 },
                            {
                                "row",
                                {
                                    { "leaf", -1 },
                                    { "leaf", win_id },
                                },
                            },
                        },
                    },
                    { "leaf", -1 },
                },
            })

            vim.api.nvim_set_current_win(win_id)

            winmove.start_move_mode()
            vim.cmd.normal("sk")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf", -1 },
                            { "leaf", win_id },
                            { "leaf", -1 },
                        },
                        { "leaf", -1 },
                    },
                    { "leaf", -1 },
                },
            })
        end)
    end)

    -- it("splits right", function()
    --     given("", function()
    --         local win_id = vader.make_layout({
    --             "row",
    --             { "main", "leaf" },
    --         })["main"]

    --         assert.matches_winlayout(vim.fn.winlayout(), {
    --             "row",
    --             {
    --                 { "leaf", win_id },
    --                 { "leaf", -1 },
    --             },
    --         })

    --         vim.api.nvim_set_current_win(win_id)
    --         winmove.start_move_mode()
    --         vim.cmd.normal("l")

    --         assert.matches_winlayout(vim.fn.winlayout(), {
    --             "row",
    --             {
    --                 { "leaf", -1 },
    --                 { "leaf", win_id },
    --             },
    --         })
    --     end)
    -- end)
end)