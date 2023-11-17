local winmove = require("winmove")
local compat = require("winmove.compat")
local config = require("winmove.config")
local highlight = require("winmove.highlight")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("custom highlights", function()
    if not compat.has("nvim-0.9.0") then
        pending("Skipped for versions below 0.9.0")
        return
    end

    it("uses a custom highlight for move mode", function()
        vim.cmd(("hi link %s %s"):format("CustomWinmoveMoveMode", "Title"))

        config.configure({
            highlights = {
                move = "CustomWinmoveMoveMode",
            },
        })

        given("", function()
            make_layout({
                "row",
                { "leaf", "leaf" },
            })

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf" },
                },
            })

            winmove.start_move_mode()

            local win_id = vim.api.nvim_get_current_win()

            assert.are.same(
                vim.wo[win_id].winhighlight,
                "Normal:WinmoveMoveNormal,CursorLine:WinmoveMoveCursorLine,CursorLineNr:WinmoveMoveCursorLineNr,EndOfBuffer:WinmoveMoveEndOfBuffer,SignColumn:WinmoveMoveSignColumn,FoldColumn:WinmoveMoveFoldColumn,LineNr:WinmoveMoveLineNr,LineNrAbove:WinmoveMoveLineNrAbove,LineNrBelow:WinmoveMoveLineNrBelow"
            )

            for _, group in ipairs(highlight.groups()) do
                local linked_group = vim.api.nvim_get_hl(0, { name = "WinmoveMove" .. group }).link

                assert.are.same(linked_group, "CustomWinmoveMoveMode")
            end

            winmove.stop_move_mode()
        end)
    end)

    it("uses a custom highlight for resize mode", function()
        vim.cmd(("hi link %s %s"):format("CustomWinmoveResizeMode", "Repeat"))

        config.configure({
            highlights = {
                resize = "CustomWinmoveResizeMode",
            },
        })

        given("", function()
            make_layout({
                "row",
                { "leaf", "leaf" },
            })

            assert.matches_winlayout(vim.fn.winlayout(), {
                "row",
                {
                    { "leaf" },
                    { "leaf" },
                },
            })

            winmove.start_resize_mode()

            local win_id = vim.api.nvim_get_current_win()

            assert.are.same(
                vim.wo[win_id].winhighlight,
                "Normal:WinmoveResizeNormal,CursorLine:WinmoveResizeCursorLine,CursorLineNr:WinmoveResizeCursorLineNr,EndOfBuffer:WinmoveResizeEndOfBuffer,SignColumn:WinmoveResizeSignColumn,FoldColumn:WinmoveResizeFoldColumn,LineNr:WinmoveResizeLineNr,LineNrAbove:WinmoveResizeLineNrAbove,LineNrBelow:WinmoveResizeLineNrBelow"
            )

            for _, group in ipairs(highlight.groups()) do
                local linked_group =
                    vim.api.nvim_get_hl(0, { name = "WinmoveResize" .. group }).link

                assert.are.same(linked_group, "CustomWinmoveResizeMode")
            end

            winmove.stop_resize_mode()
        end)
    end)
end)
