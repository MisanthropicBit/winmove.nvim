local winmove = require("winmove")
local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local message = require("winmove.message")
local vader = require("winmove.util.vader")
local stub = require("luassert.stub")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("basic movements", function()
    config.configure({
        at_edge = {
            horizontal = at_edge.Wrap,
            vertical = at_edge.Wrap,
        },
    })

    describe("direct function invocation", function()
        it("moves window to the left", function()
            given(function()
                local win_id = make_layout({
                    "row",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "h")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })
            end)
        end)

        it("moves window down", function()
            given(function()
                local win_id = make_layout({
                    "col",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "j")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves window up", function()
            given(function()
                local win_id = make_layout({
                    "col",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "k")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })
            end)
        end)

        it("moves window to the right", function()
            given(function()
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
                winmove.move_window(win_id, "l")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves nothing if only one window", function()
            stub(vim, "notify")

            given(function(context)
                winmove.move_window(context.win_id, "l")

                assert
                    .stub(vim.notify).was
                    .called_with("[winmove.nvim]: Only one window", vim.log.levels.ERROR)
            end)

            ---@diagnostic disable-next-line: undefined-field
            vim.notify:revert()
        end)

        it("does not move floating windows", function()
            stub(vim, "notify")

            given(function(context)
                local float_win_id = vim.api.nvim_open_win(context.bufnr, true, {
                    relative = "win",
                    row = 1,
                    col = 1,
                    width = 10,
                    height = 10,
                })

                winmove.move_window(float_win_id, "l")

                assert
                    .stub(vim.notify).was
                    .called_with("[winmove.nvim]: Cannot move floating window", vim.log.levels.ERROR)
            end)

            ---@diagnostic disable-next-line: undefined-field
            vim.notify:revert()
        end)
    end)

    describe("move mode", function()
        it("moves window to the left", function()
            given(function()
                local win_id = make_layout({
                    "row",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_mode(winmove.Mode.Move)
                vim.cmd.normal("h")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })
            end)
        end)

        it("moves window down", function()
            given(function()
                local win_id = make_layout({
                    "col",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_mode(winmove.Mode.Move)
                vim.cmd.normal("j")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves window up", function()
            given(function()
                local win_id = make_layout({
                    "col",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf" },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_mode(winmove.Mode.Move)
                vim.cmd.normal("k")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf" },
                    },
                })
            end)
        end)

        it("moves window to the right", function()
            given(function()
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
                winmove.start_mode(winmove.Mode.Move)
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
end)
