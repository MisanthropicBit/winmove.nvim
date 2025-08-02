local winmove = require("winmove")
local compat = require("winmove.compat")
local config = require("winmove.config")

describe("highlight", function()
    it("generates internal highlight groups for foreground-only highlights", function()
        vim.cmd.colorscheme("desert")

        ---@diagnostic disable-next-line: missing-fields
        config.configure({
            ---@diagnostic disable-next-line: missing-fields
            modes = {
                ---@diagnostic disable-next-line: missing-fields
                move = {
                    highlight = "Type",
                },
            },
        })

        vim.cmd.vnew()

        local hl_group = "WinmoveMoveInternalType"
        local opts = { name = hl_group }

        if compat.has("nvim-0.10.0") then
            opts.create = false
        end

        assert.are.same(#vim.api.nvim_get_hl(0, opts), 0)

        winmove.start_mode(winmove.Mode.Move)
        winmove.stop_mode()

        assert.are.same(vim.api.nvim_get_hl(0, opts), {
            bold = true,
            cterm = {
                bold = true,
            },
            bg = 12433259,
            ctermbg = 143,
        })
    end)
end)
