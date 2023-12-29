local winmove = require("winmove")
local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")
local message = require("winmove.message")
local stub = require("luassert.stub")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("moving between tabs", function()
    -- Ensure default configuration
    config.configure({
        at_edge = {
            horizontal = at_edge.MoveToTab,
        },
    })

    assert:set_parameter("TableFormatLevel", 10)

    it("moves window to the tab to the right and ignores switchbuf option", function()
        given("", function()
            vim.opt_local.switchbuf = "newtab"

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

            local win_ids = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "top",
                            "bottom",
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
                            { "leaf", win_ids["top"] },
                            -- We don't match the window id as moving between
                            -- tabs closes the old window and opens a new
                            -- window with the same buffer
                            { "leaf" },
                            { "leaf", win_ids["bottom"] },
                        },
                    },
                    { "leaf" },
                },
            })
        end)
    end)

    it("wraps around on the first tabpage", function()
        given("", function()
            local source_win_ids = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "old_top",
                            "main",
                            "old_bottom",
                        },
                    },
                    "leaf",
                },
            })

            vim.cmd.tabnew()

            local target_win_ids = make_layout({
                "row",
                {
                    "leaf",
                    {
                        "col",
                        {
                            "top",
                            "bottom",
                        },
                    },
                },
            })

            local win_id = source_win_ids["main"]
            vim.api.nvim_set_current_win(win_id)
            local before_buffer = vim.api.nvim_get_current_buf()
            winmove.move_window(win_id, "h")
            local after_buffer = vim.api.nvim_get_current_buf()

            -- Window ids are not the same but the buffer is
            assert.are.same(before_buffer, after_buffer)

            -- Check window layout of tab 1
            assert.matches_winlayout(vim.fn.winlayout(1), {
                "row",
                {
                    {
                        "col",
                        {
                            { "leaf", source_win_ids["old_top"] },
                            { "leaf", source_win_ids["old_bottom"] },
                        },
                    },
                    { "leaf" },
                },
            })

            -- Check window layout of tab 2
            assert.matches_winlayout(vim.fn.winlayout(2), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf", target_win_ids["top"] },
                            -- We don't match the window id as moving between
                            -- tabs closes the old window and opens a new
                            -- window with the same buffer
                            { "leaf" },
                            { "leaf", target_win_ids["bottom"] },
                        },
                    },
                },
            })
        end)
    end)

    it("wraps around on the last tabpage", function()
        given("", function()
            local target_win_ids = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "middle",
                            "bottom",
                        },
                    },
                    "leaf",
                },
            })

            vim.cmd.tabnew()

            local source_win_ids = make_layout({
                "row",
                {
                    "leaf",
                    {
                        "col",
                        {
                            "main",
                            "old_middle",
                            "old_bottom",
                        },
                    },
                },
            })

            local win_id = source_win_ids["main"]
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
                    {
                        "col",
                        {
                            -- We don't match the window id as moving between
                            -- tabs closes the old window and opens a new
                            -- window with the same buffer
                            { "leaf" },
                            { "leaf", target_win_ids["middle"] },
                            { "leaf", target_win_ids["bottom"] },
                        },
                    },
                    { "leaf" },
                },
            })

            -- Check window layout of tab 2
            assert.matches_winlayout(vim.fn.winlayout(2), {
                "row",
                {
                    { "leaf" },
                    {
                        "col",
                        {
                            { "leaf", source_win_ids["old_middle"] },
                            { "leaf", source_win_ids["old_bottom"] },
                        },
                    },
                },
            })
        end)
    end)

    it("splits left into another tab", function()
        given("", function()
            local target_win_ids = make_layout({
                "row",
                {
                    "leaf",
                    {
                        "col",
                        {
                            "top",
                            "middle",
                            "bottom",
                        },
                    },
                },
            })

            vim.cmd.tabnew()

            local source_win_ids = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "main",
                            "old_bottom",
                        },
                    },
                    "leaf",
                },
            })

            local win_id = source_win_ids["main"]
            vim.api.nvim_set_current_win(win_id)
            local before_buffer = vim.api.nvim_get_current_buf()
            local line_end = math.floor(0.85 * vim.api.nvim_win_get_height(win_id))

            -- Fill the main window's buffer with lines so it splits into the middle
            -- window in the other tab
            vim.api.nvim_buf_set_lines(
                before_buffer,
                0,
                1,
                true,
                vim.fn.split((",_"):rep(line_end), ",")
            )

            -- Move down to the last line
            vim.cmd.normal("G")

            winmove.split_into(win_id, "h")
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
                            { "leaf", target_win_ids["top"] },
                            {
                                "row",
                                {
                                    { "leaf", target_win_ids["middle"] },
                                    { "leaf" },
                                },
                            },
                            { "leaf", target_win_ids["bottom"] },
                        },
                    },
                },
            })

            -- Check window layout of tab 2
            assert.matches_winlayout(vim.fn.winlayout(2), {
                "row",
                {

                    { "leaf", source_win_ids["old_bottom"] },
                    { "leaf" },
                },
            })
        end)
    end)

    it("splits right into another tab", function()
        given("", function()
            local source_win_ids = make_layout({
                "row",
                {
                    "leaf",
                    {
                        "col",
                        {
                            "main",
                            "old_bottom",
                        },
                    },
                },
            })

            vim.cmd.tabnew()

            local target_win_ids = make_layout({
                "row",
                {
                    {
                        "col",
                        {
                            "top",
                            "bottom",
                        },
                    },
                    "leaf",
                },
            })

            local win_id = source_win_ids["main"]
            vim.api.nvim_set_current_win(win_id)
            local before_buffer = vim.api.nvim_get_current_buf()

            winmove.split_into(win_id, "l")
            local after_buffer = vim.api.nvim_get_current_buf()

            -- Window ids are not the same but the buffer is
            assert.are.same(before_buffer, after_buffer)

            -- Check window layout of tab 1
            assert.matches_winlayout(vim.fn.winlayout(1), {
                "row",
                {
                    { "leaf" },
                    { "leaf", source_win_ids["old_bottom"] },
                },
            })

            -- Check window layout of tab 2
            assert.matches_winlayout(vim.fn.winlayout(2), {
                "row",
                {
                    {
                        "col",
                        {
                            {
                                "row",
                                {
                                    { "leaf" },
                                    { "leaf", target_win_ids["top"] },
                                },
                            },
                            { "leaf", target_win_ids["bottom"] },
                        },
                    },
                    { "leaf" },
                },
            })
        end)
    end)

    it("does not move window if there is only one window and one tab", function()
        given("", function()
            stub(message, "error")

            local win_id = vim.api.nvim_get_current_win()

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", win_id })

            winmove.move_window(win_id, "l")

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", win_id })

            assert.stub(message.error).was.called_with("Only one window and tab")
            message.error:revert()
        end)
    end)

    it("does not start move mode if there is only one window and one tab", function()
        given("", function()
            stub(message, "error")

            winmove.start_mode(winmove.mode.Move)
            assert.stub(message.error).was.called_with("Only one window and tab")

            message.error:revert()
        end)
    end)
end)
