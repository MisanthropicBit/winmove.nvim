local winmove = require("winmove")
local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

-- TODO: Add tests for wrap-around on first/last tabs
-- TODO: Add tests for split into

describe("moving between tabs", function()
    -- Ensure default configuration
    config.setup({
        at_edge = {
            horizontal = at_edge.MoveTab,
        },
    })

    assert:set_parameter("TableFormatLevel", 10)

    it("moves window to the right tab", function()
        given("", function()
            local win_id = make_layout({
                "row",
                {
                    "leaf",
                    {
                        "col",
                        {
                            "leaf",
                            "main",
                            "leaf",
                        },
                    },
                },
            })["main"]

            vim.cmd.tabnew()

            make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "leaf",
                            "leaf",
                        },
                    },
                    "leaf",
                },
            })

            vim.api.nvim_set_current_win(win_id)
            local before_buffer = vim.api.nvim_get_current_buf()
            winmove.move_window(win_id, "l")
            local after_buffer = vim.api.nvim_get_current_buf()

            -- Window ids are not the same but the buffer is
            assert.are.same(before_buffer, after_buffer)

            -- Check window layout of tab 1
            assert.matches_winlayout(vim.fn.winlayout(1), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })

            -- Check window layout of tab 2
            assert.matches_winlayout(vim.fn.winlayout(2), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf" },
                            -- We don't match the window id as moving between
                            -- tabs closes the old window and opens a new
                            -- window with the same buffer
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                    { "leaf" },
                },
            })
        end)
    end)
end)
