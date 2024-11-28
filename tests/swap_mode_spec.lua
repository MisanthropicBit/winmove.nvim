local config = require("winmove.config")
local message = require("winmove.message")
local stub = require("luassert.stub")
local winmove = require("winmove")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("swap mode", function()
    it("swaps window to the left", function()
        given(function()
            local windows = make_layout({
                "row",
                { "target", "main" },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", target_win_id },
                    { "leaf", main_win_id },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            vim.api.nvim_set_current_win(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "h")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", target_win_id },
                    { "leaf", main_win_id },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("swaps window down", function()
        given(function()
            local windows = make_layout({
                "col",
                { "main", "target" },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            vim.api.nvim_set_current_win(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "j")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("swaps window up", function()
        given(function()
            local windows = make_layout({
                "col",
                { "target", "main" },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    { "leaf", main_win_id },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            vim.api.nvim_set_current_win(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "k")

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    { "leaf", main_win_id },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("swaps window to the right", function()
        given(function()
            local windows = make_layout({
                "row",
                { "main", "target" },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", main_win_id },
                    { "leaf", target_win_id },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            vim.api.nvim_set_current_win(main_win_id)
            winmove.swap_window_in_direction(main_win_id, "l")

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

    it("does not start swap mode if only one window", function()
        config.configure({
            modes = {
                swap = {
                    at_edge = {
                        horizontal = "none",
                    },
                },
            },
        })

        stub(message, "error")

        winmove.start_mode(winmove.Mode.Swap)
        assert.are.same(winmove.current_mode(), nil)

        assert.stub(message.error).was.called_with("Cannot swap window, only one window")

        ---@diagnostic disable-next-line: undefined-field
        message.error:revert()
    end)

    it(
        "does not start swap mode if only one window and tab and at-edge behaviour is MoveToTab",
        function()
            config.configure({
                modes = {
                    swap = {
                        at_edge = {
                            horizontal = "move_to_tab",
                        },
                    },
                },
            })

            stub(message, "error")

            winmove.start_mode(winmove.Mode.Swap)
            assert.are.same(winmove.current_mode(), nil)

            assert
                .stub(message.error).was
                .called_with("Cannot swap window, only one window and tab")

            ---@diagnostic disable-next-line: undefined-field
            message.error:revert()
        end
    )
end)
