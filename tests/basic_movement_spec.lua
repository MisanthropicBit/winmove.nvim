local winmove = require("winmove")
local vader = require("winmove.util.vader")
local stub = require("luassert.stub")

local given = vader.given

describe("basic movements", function()
    describe("direct function invocation", function()
        it("moves window to the left", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "h")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })
            end)
        end)

        it("moves window down", function()
            given("", function()
                local win_id = vader.make_layout({
                    "col",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "j")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves window up", function()
            given("", function()
                local win_id = vader.make_layout({
                    "col",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "k")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })
            end)
        end)

        it("moves window to the right", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.move_window(win_id, "l")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves nothing if only one window", function()
            stub(vim.api, "nvim_echo")

            given("", function(context)
                winmove.move_window(context.win_id, "l")

                assert.stub(vim.api.nvim_echo).was.called_with({
                    { "[winmove.nvim]:", "ErrorMsg" },
                    { " Only one window" },
                }, true, {})
            end)

            vim.api.nvim_echo:revert()
        end)

        it("does not move floating windows", function()
            stub(vim.api, "nvim_echo")

            given("", function(context)
                local float_win_id = vim.api.nvim_open_win(context.bufnr, true, {
                    relative = "win",
                    row = 1,
                    col = 1,
                    width = 10,
                    height = 10,
                })

                winmove.move_window(float_win_id, "l")

                assert.stub(vim.api.nvim_echo).was.called_with({
                    { "[winmove.nvim]:", "ErrorMsg" },
                    { " Cannot move floating window" },
                }, true, {})
            end)

            vim.api.nvim_echo:revert()
        end)
    end)

    describe("move mode", function()
        it("moves window to the left", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_move_mode()
                vim.cmd.normal("h")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })
            end)
        end)

        it("moves window down", function()
            given("", function()
                local win_id = vader.make_layout({
                    "col",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_move_mode()
                vim.cmd.normal("j")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })
            end)
        end)

        it("moves window up", function()
            given("", function()
                local win_id = vader.make_layout({
                    "col",
                    { "leaf", "main" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_move_mode()
                vim.cmd.normal("k")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "col",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })
            end)
        end)

        it("moves window to the right", function()
            given("", function()
                local win_id = vader.make_layout({
                    "row",
                    { "main", "leaf" },
                })["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", win_id },
                        { "leaf", -1 },
                    },
                })

                vim.api.nvim_set_current_win(win_id)
                winmove.start_move_mode()
                vim.cmd.normal("l")

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf", -1 },
                        { "leaf", win_id },
                    },
                })
            end)
        end)
    end)
end)
