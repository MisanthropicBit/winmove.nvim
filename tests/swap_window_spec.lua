local winmove = require("winmove")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")
local stub = require("luassert.stub")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("swap window", function()
    assert:set_parameter("TableFormatLevel", 10)

    it("swaps a window with another", function()
        given(function()
            local windows = make_layout({
                "col",
                {
                    "target",
                    {
                        "row",
                        { "leaf", "main" }
                    },
                },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            winmove.swap_window(main_win_id)
            winmove.swap_window(target_win_id)

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("fails if previously selected window is not valid anymore", function()
        given(function()
            stub(vim.api, "nvim_echo")

            local windows = make_layout({
                "col",
                {
                    "target",
                    {
                        "row",
                        { "leaf", "main" }
                    },
                },
            })
            local main_win_id = windows["main"]
            local target_win_id = windows["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(target_win_id)

            winmove.swap_window(main_win_id)
            vim.api.nvim_win_close(main_win_id, true)
            winmove.swap_window(target_win_id)

            assert.stub(vim.api.nvim_echo).was.called_with({
                { "[winmove.nvim]:", "ErrorMsg" },
                { " Previously selected window is not valid anymore" },
            }, true, {})

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    { "leaf" },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)

            ---@diagnostic disable-next-line: undefined-field
            vim.api.nvim_echo:revert()
        end)
    end)

    it("fails if swapping selected window with itself", function()
        given(function()
            stub(vim.api, "nvim_echo")

            local main_win_id = make_layout("main")["main"]

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", main_win_id })

            winmove.swap_window(main_win_id)
            winmove.swap_window(main_win_id)

            assert.stub(vim.api.nvim_echo).was.called_with({
                { "[winmove.nvim]:", "ErrorMsg" },
                { " Cannot swap selected window with itself" },
            }, true, {})

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", main_win_id })

            ---@diagnostic disable-next-line: undefined-field
            vim.api.nvim_echo:revert()
        end)
    end)
end)