local winmove = require("winmove")
local config = require("winmove.config")

describe("highlight", function()
    it("generates internal highlight groups for foreground-only highlights", function()
        vim.cmd.colorscheme("desert")

        ---@diagnostic disable-next-line: missing-fields
        config.configure({
            modes = {
                move = {
                    highlight = "Type",
                },
            },
        })

        vim.cmd.vnew()

        local hl_group = "WinmoveMoveInternalType"
        assert.are.same(#vim.api.nvim_get_hl(0, { name = hl_group, create = false }), 0)

        winmove.start_mode(winmove.Mode.Move)
        winmove.stop_mode()

        assert.are.same(vim.api.nvim_get_hl(0, { name = hl_group, create = false }), {
            bold = true,
            cterm = {
                bold = true,
            },
            bg = 12433259,
        })
    end)
end)
