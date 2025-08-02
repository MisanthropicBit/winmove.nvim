local winmove = require("winmove")
local config = require("winmove.config")
local highlight = require("winmove.highlight")
local vader = require("winmove.util.vader")
local test_helpers = require("winmove.util.test_helpers")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("custom highlights", function()
    local function get_expected_winhighlight(prefix)
        local template = {
            "CursorLine:%sCursorLine",
            "CursorLineNr:%sCursorLineNr",
            "DiagnosticVirtualTextError:%sDiagnosticVirtualTextError",
            "DiagnosticVirtualTextHint:%sDiagnosticVirtualTextHint",
            "DiagnosticVirtualTextInfo:%sDiagnosticVirtualTextInfo",
            "DiagnosticVirtualTextOk:%sDiagnosticVirtualTextOk",
            "DiagnosticVirtualTextWarn:%sDiagnosticVirtualTextWarn",
            "EndOfBuffer:%sEndOfBuffer",
            "FoldColumn:%sFoldColumn",
            "IblIndent:%sIblIndent",
            "IblScope:%sIblScope",
            "IblWhitespace:%sIblWhitespace",
            "LineNr:%sLineNr",
            "LineNrAbove:%sLineNrAbove",
            "LineNrBelow:%sLineNrBelow",
            "Normal:%sNormal",
            "SignColumn:%sSignColumn",
            "@ibl.indent.char.1:%s@ibl.indent.char.1",
            "@ibl.whitespace.char.1:%s@ibl.whitespace.char.1",
            "@ibl.indent.char.2:%s@ibl.indent.char.2",
            "@ibl.whitespace.char.2:%s@ibl.whitespace.char.2",
            "@ibl.indent.char.3:%s@ibl.indent.char.3",
            "@ibl.whitespace.char.3:%s@ibl.whitespace.char.3",
            "@ibl.indent.char.4:%s@ibl.indent.char.4",
            "@ibl.whitespace.char.4:%s@ibl.whitespace.char.4",
            "@ibl.indent.char.5:%s@ibl.indent.char.5",
            "@ibl.whitespace.char.5:%s@ibl.whitespace.char.5",
            "@ibl.indent.char.6:%s@ibl.indent.char.6",
            "@ibl.whitespace.char.6:%s@ibl.whitespace.char.6",
            "@ibl.indent.char.7:%s@ibl.indent.char.7",
            "@ibl.whitespace.char.7:%s@ibl.whitespace.char.7",
            "@ibl.indent.char.8:%s@ibl.indent.char.8",
            "@ibl.whitespace.char.8:%s@ibl.whitespace.char.8",
            "@ibl.indent.char.9:%s@ibl.indent.char.9",
            "@ibl.whitespace.char.9:%s@ibl.whitespace.char.9",
            "@ibl.indent.char.10:%s@ibl.indent.char.10",
            "@ibl.whitespace.char.10:%s@ibl.whitespace.char.10",
        }

        local prefixed = vim.tbl_map(function(item)
            return item:format(prefix)
        end, template)

        return table.concat(prefixed, ",")
    end

    it("uses a custom highlight for move mode", function()
        vim.cmd.colorscheme("desert")
        vim.cmd(("hi link %s %s"):format("CustomWinmoveMoveMode", "Todo"))

        ---@diagnostic disable-next-line: missing-fields
        config.configure({
            ---@diagnostic disable-next-line: missing-fields
            modes = {
                ---@diagnostic disable-next-line: missing-fields
                move = {
                    highlight = "CustomWinmoveMoveMode",
                },
            },
        })

        given(function()
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

            winmove.start_mode(winmove.Mode.Move)

            local win_id = vim.api.nvim_get_current_win()

            assert.are.same(vim.wo[win_id].winhighlight, get_expected_winhighlight("WinmoveMove"))

            for _, group in ipairs(highlight.groups()) do
                local linked_group = vim.api.nvim_get_hl(0, { name = "WinmoveMove" .. group }).link

                assert.are.same(linked_group, "CustomWinmoveMoveMode")
            end

            winmove.stop_mode()
        end)
    end)

    it("uses a custom highlight for swap mode", function()
        vim.cmd.colorscheme("desert")
        vim.cmd(("hi link %s %s"):format("CustomWinmoveSwapMode", "Todo"))

        ---@diagnostic disable-next-line: missing-fields
        config.configure({
            modes = {
                swap = {
                    highlight = "CustomWinmoveSwapMode",
                },
            },
        })

        given(function()
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

            winmove.start_mode(winmove.Mode.Swap)

            local win_id = vim.api.nvim_get_current_win()

            assert.are.same(vim.wo[win_id].winhighlight, get_expected_winhighlight("WinmoveSwap"))

            for _, group in ipairs(highlight.groups()) do
                local linked_group = vim.api.nvim_get_hl(0, { name = "WinmoveSwap" .. group }).link

                assert.are.same(linked_group, "CustomWinmoveSwapMode")
            end

            winmove.stop_mode()
        end)
    end)

    it("uses a custom highlight for resize mode", function()
        vim.cmd.colorscheme("desert")
        vim.cmd(("hi link %s %s"):format("CustomWinmoveResizeMode", "Todo"))

        config.configure({
            modes = {
                resize = {
                    highlight = "CustomWinmoveResizeMode",
                },
            },
        })

        given(function()
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

            winmove.start_mode(winmove.Mode.Resize)

            local win_id = vim.api.nvim_get_current_win()

            assert.are.same(vim.wo[win_id].winhighlight, get_expected_winhighlight("WinmoveResize"))

            for _, group in ipairs(highlight.groups()) do
                local linked_group =
                    vim.api.nvim_get_hl(0, { name = "WinmoveResize" .. group }).link

                assert.are.same(linked_group, "CustomWinmoveResizeMode")
            end

            winmove.stop_mode()
        end)
    end)
end)
