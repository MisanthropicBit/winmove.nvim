local winmove = require("winmove")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout
local get_win_pos_and_dimensions = test_helpers.get_win_pos_and_dimensions

describe("resize", function()
    local winwidth = nil

    before_each(function()
        winwidth = vim.go.winwidth
    end)

    after_each(function()
        if winwidth ~= nil then
            vim.go.winwidth = winwidth
        end
    end)

    describe("adjusts neighbors", function()
        local count = 3
        assert:set_parameter("TableFormatLevel", 10)

        it("resizes towards non-sibling window", function()
            given(function()
                local layout = make_layout({
                    "row",
                    {
                        "neighbor3",
                        {
                            "col",
                            {
                                {
                                    "row",
                                    { "neighbor2", "neighbor1", "main" },
                                },
                                "bottom neighbor",
                            },
                        },
                        "neighbor4",
                    },
                })

                local win_id = layout["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf" },
                        {
                            "col",
                            {
                                {
                                    "row",
                                    {
                                        { "leaf" },
                                        { "leaf" },
                                        { "leaf" },
                                    },
                                },
                                { "leaf" },
                            },
                        },
                        { "leaf" },
                    },
                })

                vim.go.winwidth = 10
                vim.api.nvim_set_current_win(win_id)

                local _, main_col_before, main_width_before, _ = get_win_pos_and_dimensions(win_id)
                local _, col_before1, width_before1, _ =
                    get_win_pos_and_dimensions(layout["neighbor1"])
                local _, col_before2, width_before2, _ =
                    get_win_pos_and_dimensions(layout["neighbor2"])
                local _, col_before3, width_before3, _ =
                    get_win_pos_and_dimensions(layout["neighbor3"])
                local _, bottom_col_before, bottom_width_before, _ =
                    get_win_pos_and_dimensions(layout["bottom neighbor"])
                local _, col_before4, width_before4, _ =
                    get_win_pos_and_dimensions(layout["neighbor4"])

                winmove.resize_window(win_id, "l", count, winmove.ResizeAnchor.TopLeft)

                local _, main_col_after, main_width_after, _ = get_win_pos_and_dimensions(win_id)
                local _, col_after1, width_after1, _ =
                    get_win_pos_and_dimensions(layout["neighbor1"])
                local _, col_after2, width_after2, _ =
                    get_win_pos_and_dimensions(layout["neighbor2"])
                local _, col_after3, width_after3, _ =
                    get_win_pos_and_dimensions(layout["neighbor3"])
                local _, bottom_col_after, bottom_width_after, _ =
                    get_win_pos_and_dimensions(layout["bottom neighbor"])
                local _, col_after4, width_after4, _ =
                    get_win_pos_and_dimensions(layout["neighbor4"])

                assert.are.same(main_col_before, main_col_after)
                assert.are.same(main_width_before + count, main_width_after)

                assert.are.same(col_before1, col_after1)
                assert.are.same(width_before1, width_after1)

                assert.are.same(col_before2, col_after2)
                assert.are.same(width_before2, width_after2)

                assert.are.same(col_before3, col_after3)
                assert.are.same(width_before3, width_after3)

                assert.are.same(bottom_col_before, bottom_col_after)
                assert.are.same(bottom_width_before + count, bottom_width_after)

                assert.are.same(col_before4 + count, col_after4)
                assert.are.same(width_before4 - count, width_after4)
            end)
        end)

        it("resizes towards multiple sibling windows", function()
            given(function()
                local layout = make_layout({
                    "row",
                    {
                        "neighbor1",
                        {
                            "col",
                            {
                                {
                                    "row",
                                    { "neighbor2", "neighbor3", "main" },
                                },
                                "bottom neighbor",
                            },
                        },
                        "neighbor4",
                    },
                })

                local win_id = layout["main"]

                assert.matches_winlayout(vim.fn.winlayout(), {
                    "row",
                    {
                        { "leaf" },
                        {
                            "col",
                            {
                                {
                                    "row",
                                    {
                                        { "leaf" },
                                        { "leaf" },
                                        { "leaf" },
                                    },
                                },
                                { "leaf" },
                            },
                        },
                        { "leaf" },
                    },
                })

                vim.go.winwidth = 10
                vim.api.nvim_set_current_win(win_id)

                local _, main_col_before, main_width_before, _ = get_win_pos_and_dimensions(win_id)
                local _, col_before1, width_before1, _ =
                    get_win_pos_and_dimensions(layout["neighbor1"])
                local _, col_before2, width_before2, _ =
                    get_win_pos_and_dimensions(layout["neighbor2"])
                local _, col_before3, width_before3, _ =
                    get_win_pos_and_dimensions(layout["neighbor3"])
                local _, bottom_col_before, bottom_width_before, _ =
                    get_win_pos_and_dimensions(layout["bottom neighbor"])
                local _, col_before4, width_before4, _ =
                    get_win_pos_and_dimensions(layout["neighbor4"])

                vim.cmd("wincmd =")
                winmove.resize_window(win_id, "h", count, winmove.ResizeAnchor.BottomRight)

                local _, main_col_after, main_width_after, _ = get_win_pos_and_dimensions(win_id)
                local _, col_after1, width_after1, _ =
                    get_win_pos_and_dimensions(layout["neighbor1"])
                local _, col_after2, width_after2, _ =
                    get_win_pos_and_dimensions(layout["neighbor2"])
                local _, col_after3, width_after3, _ =
                    get_win_pos_and_dimensions(layout["neighbor3"])
                local _, bottom_col_after, bottom_width_after, _ =
                    get_win_pos_and_dimensions(layout["bottom neighbor"])
                local _, col_after4, width_after4, _ =
                    get_win_pos_and_dimensions(layout["neighbor4"])

                vim.print(vim.inspect({ main_col_before, count, main_col_after }))
                vim.print(vim.inspect({ main_width_before, count, main_width_after }))
                assert.are.same(main_col_before - count, main_col_after)
                assert.are.same(main_width_before + count, main_width_after)

                assert.are.same(col_before1, col_after1)
                assert.are.same(width_before1, width_after1)

                assert.are.same(col_before2, col_after2)
                assert.are.same(width_before2, width_after2)

                assert.are.same(col_before3, col_after3)
                assert.are.same(width_before3 - count, width_after3)

                assert.are.same(bottom_col_before, bottom_col_after)
                assert.are.same(bottom_width_before, bottom_width_after)

                assert.are.same(col_before4, col_after4)
                assert.are.same(width_before4, width_after4)
            end)
        end)

        it(
            "resizes towards multiple sibling windows and respects window dimension settings",
            function()
                given(function()
                    local layout = make_layout({
                        "row",
                        {
                            "neighbor1",
                            {
                                "col",
                                {
                                    {
                                        "row",
                                        { "neighbor2", "neighbor3", "main" },
                                    },
                                    "bottom neighbor",
                                },
                            },
                            "neighbor4",
                        },
                    })

                    local win_id = layout["main"]

                    assert.matches_winlayout(vim.fn.winlayout(), {
                        "row",
                        {
                            { "leaf" },
                            {
                                "col",
                                {
                                    {
                                        "row",
                                        {
                                            { "leaf" },
                                            { "leaf" },
                                            { "leaf" },
                                        },
                                    },
                                    { "leaf" },
                                },
                            },
                            { "leaf" },
                        },
                    })

                    vim.go.winwidth = vim.o.columns / 5 / 2

                    for _, _win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                        vim.wo[_win_id].signcolumn = "no"
                    end

                    vim.api.nvim_set_current_win(win_id)

                    local _, _, main_width_before, _ = get_win_pos_and_dimensions(win_id)
                    local _, col_before1, n1_width_before, _ =
                        get_win_pos_and_dimensions(layout["neighbor1"])
                    local _, _, n2_width_before, _ = get_win_pos_and_dimensions(layout["neighbor2"])
                    local _, _, n3_width_before, _ = get_win_pos_and_dimensions(layout["neighbor3"])
                    local _, _, _, _ = get_win_pos_and_dimensions(layout["bottom neighbor"])
                    local _, col_before4, width_before4, _ =
                        get_win_pos_and_dimensions(layout["neighbor4"])

                    local resize_count = n1_width_before
                        + n2_width_before
                        + n3_width_before
                        - (vim.go.winwidth * 3)
                        + 1

                    for _ = 1, resize_count do
                        winmove.resize_window(win_id, "h", count, winmove.ResizeAnchor.BottomRight)
                    end

                    local _, main_col_after, main_width_after, _ =
                        get_win_pos_and_dimensions(win_id)
                    local _, col_after1, width_after1, _ =
                        get_win_pos_and_dimensions(layout["neighbor1"])
                    local _, col_after2, width_after2, _ =
                        get_win_pos_and_dimensions(layout["neighbor2"])
                    local _, col_after3, width_after3, _ =
                        get_win_pos_and_dimensions(layout["neighbor3"])
                    local _, bottom_col_after, bottom_width_after, _ =
                        get_win_pos_and_dimensions(layout["bottom neighbor"])
                    local _, col_after4, width_after4, _ =
                        get_win_pos_and_dimensions(layout["neighbor4"])

                    assert.are.same(
                        vim.api.nvim_win_get_width(layout["neighbor1"]),
                        vim.go.winwidth
                    )
                    assert.are.same(
                        vim.api.nvim_win_get_width(layout["neighbor2"]),
                        vim.go.winwidth
                    )
                    assert.are.same(
                        vim.api.nvim_win_get_width(layout["neighbor3"]),
                        vim.go.winwidth
                    )

                    -- + 3 for the window separators
                    local left_total_width = vim.api.nvim_win_get_width(layout["neighbor1"])
                        + vim.api.nvim_win_get_width(layout["neighbor2"])
                        + vim.api.nvim_win_get_width(layout["neighbor3"])
                        + 3

                    assert.are.same(main_col_after, left_total_width)
                    assert.is._true(main_width_after > main_width_before)

                    assert.are.same(col_before1, col_after1)
                    assert.are.same(width_after1, vim.go.winwidth)

                    assert.are.same(col_after2, vim.go.winwidth + 1)
                    assert.are.same(width_after2, vim.go.winwidth)

                    assert.are.same(col_after3, vim.go.winwidth * 2 + 2)
                    assert.are.same(width_after3, vim.go.winwidth)

                    -- + 2 for the window separators
                    local top_column_width = vim.api.nvim_win_get_width(layout["neighbor2"])
                        + vim.api.nvim_win_get_width(layout["neighbor3"])
                        + vim.api.nvim_win_get_width(layout["main"])
                        + 2

                    assert.are.same(
                        bottom_col_after,
                        vim.api.nvim_win_get_width(layout["neighbor1"]) + 1
                    )
                    assert.are.same(bottom_width_after, top_column_width)

                    assert.are.same(col_before4, col_after4)
                    assert.are.same(width_before4, width_after4)
                end)
            end
        )
    end)
end)
