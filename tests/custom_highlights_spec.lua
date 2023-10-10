local winmove = require("winmove")
local compat = require("winmove.compat")
local config = require("winmove.config")
local highlight = require("winmove.highlight")
local vader = require("winmove.util.vader")

local given = vader.given

---@param group_name string
---@return string
local function get_linked_highlight_group(group_name)
    if compat.has("nvim-0.9.0") then
        local hi = vim.api.nvim_get_hl(0, { name = group_name })

        return hi.link
    else
        return vim.fn.synIDattr(
            vim.fn.synIDtrans(vim.api.nvim_get_hl_id_by_name(group_name)),
            "name"
        )
    end
end

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

            assert.are.same(
                vim.wo[win_id].winhighlight,
                "Normal:WinmoveMoveNormal,CursorLine:WinmoveMoveCursorLine,CursorLineNr:WinmoveMoveCursorLineNr,EndOfBuffer:WinmoveMoveEndOfBuffer,SignColumn:WinmoveMoveSignColumn,FoldColumn:WinmoveMoveFoldColumn,LineNr:WinmoveMoveLineNr,LineNrAbove:WinmoveMoveLineNrAbove,LineNrBelow:WinmoveMoveLineNrBelow"
            )

            for _, group in ipairs(highlight.groups()) do
                local linked_group = get_linked_highlight_group("WinmoveMove" .. group)

                assert.are.same(linked_group, "CustomWinmoveMoveMode")
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

            assert.are.same(
                vim.wo[win_id].winhighlight,
                "Normal:WinmoveResizeNormal,CursorLine:WinmoveResizeCursorLine,CursorLineNr:WinmoveResizeCursorLineNr,EndOfBuffer:WinmoveResizeEndOfBuffer,SignColumn:WinmoveResizeSignColumn,FoldColumn:WinmoveResizeFoldColumn,LineNr:WinmoveResizeLineNr,LineNrAbove:WinmoveResizeLineNrAbove,LineNrBelow:WinmoveResizeLineNrBelow"
            )

            for _, group in ipairs(highlight.groups()) do
                local linked_group = get_linked_highlight_group("WinmoveResize" .. group)

                assert.are.same(linked_group, "CustomWinmoveResizeMode")
            end

            winmove.stop_resize_mode()
        end)
    end)
end)
