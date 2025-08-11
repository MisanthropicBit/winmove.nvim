describe("custom highlights", function()
    local winmove = require("winmove")
    local config = require("winmove.config")
    local highlight = require("winmove.highlight")
    local vader = require("winmove.util.vader")
    local test_helpers = require("winmove.util.test_helpers")

    local given = vader.given
    local make_layout = test_helpers.make_layout

    local function get_expected_winhighlight(prefix)
        local template = {
            "CursorLine:%sCursorLine",
            "CursorLineNr:%sCursorLineNr",
            "DiagnosticVirtualTextOk:%sDiagnosticVirtualTextOk",
            "DiagnosticVirtualTextHint:%sDiagnosticVirtualTextHint",
            "DiagnosticVirtualTextInfo:%sDiagnosticVirtualTextInfo",
            "DiagnosticVirtualTextWarn:%sDiagnosticVirtualTextWarn",
            "DiagnosticVirtualTextError:%sDiagnosticVirtualTextError",
            "EndOfBuffer:%sEndOfBuffer",
            "FoldColumn:%sFoldColumn",
            "LineNr:%sLineNr",
            "LineNrAbove:%sLineNrAbove",
            "LineNrBelow:%sLineNrBelow",
            "Normal:%sNormal",
            "SignColumn:%sSignColumn",
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
            modes = {
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
