local winmove = require("winmove")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("resize", function()
    local count = 3
    assert:set_parameter("TableFormatLevel", 10)

    ---@param win_id integer
    ---@return integer
    ---@return integer
    ---@return integer
    ---@return integer
    local function get_win_pos_and_dimensions(win_id)
        local pos = vim.api.nvim_win_get_position(win_id)
        local width = vim.api.nvim_win_get_width(win_id)
        local height = vim.api.nvim_win_get_height(win_id)

        return pos[1], pos[2], width, height
    end

    ---@param row_or_col "row" | "col"
    ---@return integer
    local function make_three_column_or_row_layout(row_or_col)
        local win_id = make_layout({
            row_or_col,
            { "leaf", "main", "leaf" },
        })["main"]

        assert.matches_winlayout(vim.fn.winlayout(), {
            row_or_col,
            { { "leaf" }, { "leaf" }, { "leaf" } },
        })

        return win_id
    end

    describe("bottom-right anchor", function()
        describe("not at edge", function()
            it("resizes window to the left", function()
                given(function()
                    local win_id = make_three_column_or_row_layout("row")

                    vim.api.nvim_set_current_win(win_id)
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "h", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before - count, col_after)
                    assert.are.same(width_before + count, width_after)
                end)
            end)

            it("resizes window down", function()
                given(function()
                    local win_id = make_three_column_or_row_layout("col")

                    vim.api.nvim_set_current_win(win_id)
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "j", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before + count, row_after)
                    assert.are.same(height_before - count, height_after)
                end)
            end)

            it("resizes window up", function()
                given(function()
                    local win_id = make_three_column_or_row_layout("col")

                    vim.api.nvim_set_current_win(win_id)
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "k", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before - count, row_after)
                    assert.are.same(height_before + count, height_after)
                end)
            end)

            it("resizes window to the right", function()
                given(function()
                    local win_id = make_three_column_or_row_layout("row")

                    vim.api.nvim_set_current_win(win_id)
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "l", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before + count, col_after)
                    assert.are.same(width_before - count, width_after)
                end)
            end)
        end)

        describe("at right edge", function()
            it("resizes window to the left at right edge", function()
                given(function()
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
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "h", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before - count, col_after)
                    assert.are.same(width_before + count, width_after)
                end)
            end)

            it("resizes window to the right at right edge", function()
                given(function()
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
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "l", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before + count, col_after)
                    assert.are.same(width_before - count, width_after)
                end)
            end)
        end)

        describe("at bottom edge", function()
            it("resizes window down at bottom edge", function()
                given(function()
                    local win_id = make_layout({
                        "row",
                        {
                            "leaf",
                            {
                                "col",
                                { "leaf", "main" },
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
                                    { "leaf" },
                                    { "leaf", win_id },
                                },
                            },
                        },
                    })

                    vim.api.nvim_set_current_win(win_id)
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "j", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before + count, row_after)
                    assert.are.same(height_before - count, height_after)
                end)
            end)

            it("resizes window up at bottom edge", function()
                given(function()
                    local win_id = make_layout({
                        "row",
                        {
                            "leaf",
                            {
                                "col",
                                { "leaf", "main" },
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
                                    { "leaf" },
                                    { "leaf", win_id },
                                },
                            },
                        },
                    })

                    vim.api.nvim_set_current_win(win_id)
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "k", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before - count, row_after)
                    assert.are.same(height_before + count, height_after)
                end)
            end)
        end)

        describe("at top edge", function()
            it("resizes window down at top edge", function()
                given(function()
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
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "j", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before, row_after)
                    assert.are.same(height_before + count, height_after)
                end)
            end)

            it("resizes window up at top edge", function()
                given(function()
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
                    local row_before, _, _, height_before = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "k", count, winmove.ResizeAnchor.BottomRight)

                    local row_after, _, _, height_after = get_win_pos_and_dimensions(win_id)

                    assert.are.same(row_before, row_after)
                    assert.are.same(height_before - count, height_after)
                end)
            end)
        end)

        describe("at left edge", function()
            it("resizes window to the left at left edge", function()
                given(function()
                    local win_id = make_layout({
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
                                    { "leaf" },
                                },
                            },
                            { "leaf" },
                        },
                    })

                    vim.api.nvim_set_current_win(win_id)
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "h", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before, col_after)
                    assert.are.same(width_before - count, width_after)
                end)
            end)

            it("resizes window to the right at left edge", function()
                given(function()
                    local win_id = make_layout({
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
                                    { "leaf" },
                                },
                            },
                            { "leaf" },
                        },
                    })

                    vim.api.nvim_set_current_win(win_id)
                    local _, col_before, width_before, _ = get_win_pos_and_dimensions(win_id)

                    winmove.resize_window(win_id, "l", count, winmove.ResizeAnchor.BottomRight)

                    local _, col_after, width_after, _ = get_win_pos_and_dimensions(win_id)

                    assert.are.same(col_before, col_after)
                    assert.are.same(width_before + count, width_after)
                end)
            end)
        end)
    end)
end)
