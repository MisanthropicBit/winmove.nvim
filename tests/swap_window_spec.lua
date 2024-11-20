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
                        { "leaf", "main" },
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

    it("swaps a window with another across tabs", function()
        given(function()
            local main_win_id = make_layout({
                "col",
                {
                    "leaf",
                    {
                        "row",
                        { "leaf", "main" },
                    },
                },
            })["main"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf" },
                    {
                        "row",
                        {
                            { "leaf" },
                            { "leaf", main_win_id },
                        },
                    },
                },
            })

            vim.cmd.tabnew()

            local target_win_id = make_layout({
                "row",
                {
                    "target",
                    {
                        "col",
                        { "leaf", "leaf" },
                    },
                },
            })["target"]

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf", target_win_id },
                    {
                        "col",
                        {
                            { "leaf" },
                            { "leaf" },
                        },
                    },
                },
            })

            local bufnr1 = vim.api.nvim_win_get_buf(main_win_id)
            local bufnr2 = vim.api.nvim_win_get_buf(target_win_id)

            winmove.swap_window(main_win_id)
            winmove.swap_window(target_win_id)

            assert.are.same(vim.api.nvim_win_get_buf(main_win_id), bufnr2)
            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)
        end)
    end)

    it("fails if previously selected window is not valid anymore", function()
        given(function()
            stub(vim, "notify")

            local windows = make_layout({
                "col",
                {
                    "target",
                    {
                        "row",
                        { "leaf", "main" },
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

            assert.stub(vim.notify).was.called_with(
                "[winmove.nvim]: Previously selected window is not valid anymore",
                vim.log.levels.ERROR
            )

            assert.matches_winlayout(vim.fn.winlayout(), {
                "col",
                {
                    { "leaf", target_win_id },
                    { "leaf" },
                },
            })

            assert.are.same(vim.api.nvim_win_get_buf(target_win_id), bufnr1)

            ---@diagnostic disable-next-line: undefined-field
            vim.notify:revert()
        end)
    end)

    it("fails if swapping selected window with itself", function()
        given(function()
            stub(vim, "notify")

            local main_win_id = make_layout("main")["main"]

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", main_win_id })

            winmove.swap_window(main_win_id)
            winmove.swap_window(main_win_id)

            assert
                .stub(vim.notify).was
                .called_with("[winmove.nvim]: Cannot swap selected window with itself", vim.log.levels.ERROR)

            assert.matches_winlayout(vim.fn.winlayout(), { "leaf", main_win_id })
            assert.are.same(vim.wo[main_win_id].winhighlight, "")

            ---@diagnostic disable-next-line: undefined-field
            vim.notify:revert()
        end)
    end)
end)
