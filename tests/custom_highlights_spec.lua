local winmove = require("winmove")
local config = require("winmove.config")
local highlight = require("winmove.highlight")
local vader = require("winmove.util.vader")

local given = vader.given

describe("custom highlights", function()
    it("uses a custom highlight for move mode", function()
        vim.cmd(("hi link %s %s"):format("CustomWinmoveMoveMode", "Title"))

        config.setup({
            highlights = {
                move = "CustomWinmoveMoveMode",
            },
        })

        given("", function()
            vader.make_layout({
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

            assert.are.same(vim.wo[win_id].winhighlight, "Normal:WinmoveMoveNormal,CursorLine:WinmoveMoveCursorLine,CursorLineNr:WinmoveMoveCursorLineNr,EndOfBuffer:WinmoveMoveEndOfBuffer,SignColumn:WinmoveMoveSignColumn,FoldColumn:WinmoveMoveFoldColumn,LineNr:WinmoveMoveLineNr,LineNrAbove:WinmoveMoveLineNrAbove,LineNrBelow:WinmoveMoveLineNrBelow")

            for _, group in ipairs(highlight.groups()) do
                local hi = vim.api.nvim_get_hl(0, { name = "WinmoveMove" .. group })

                assert.are.same(hi.link, "CustomWinmoveMoveMode")
            end

            winmove.stop_move_mode()
        end)
    end)

    it("uses a custom highlight for resize mode", function()
        vim.cmd(("hi link %s %s"):format("CustomWinmoveResizeMode", "Repeat"))

        config.setup({
            highlights = {
                resize = "CustomWinmoveResizeMode",
            },
        })

        given("", function()
            vader.make_layout({
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

            assert.are.same(vim.wo[win_id].winhighlight, "Normal:WinmoveResizeNormal,CursorLine:WinmoveResizeCursorLine,CursorLineNr:WinmoveResizeCursorLineNr,EndOfBuffer:WinmoveResizeEndOfBuffer,SignColumn:WinmoveResizeSignColumn,FoldColumn:WinmoveResizeFoldColumn,LineNr:WinmoveResizeLineNr,LineNrAbove:WinmoveResizeLineNrAbove,LineNrBelow:WinmoveResizeLineNrBelow")

            for _, group in ipairs(highlight.groups()) do
                local hi = vim.api.nvim_get_hl(0, { name = "WinmoveResize" .. group })

                assert.are.same(hi.link, "CustomWinmoveResizeMode")
            end

            winmove.stop_resize_mode()
        end)
    end)
end)
