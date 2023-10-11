local winmove = require("winmove")
local config = require("winmove.config")
local float = require("winmove.float")
local vader = require("winmove.util.vader")

local given = vader.given

describe("shows floating window help", function()
    -- Ensure default keymaps
    config.setup({
        keymaps = {
            help = "?",
            help_close = "q",
        },
    })

    it("shows help in resize mode", function()
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

            local win_id1 = vim.api.nvim_get_current_win()
            winmove.start_resize_mode()

            assert.is_false(float.is_help_window(win_id1))

            vim.cmd.normal(config.keymaps.help)

            local win_id2 = vim.api.nvim_get_current_win()
            assert.are_not.same(win_id1, win_id2)
            assert.is_true(float.is_help_window(win_id2))

            vim.cmd.normal(config.keymaps.help_close)

            local win_id3 = vim.api.nvim_get_current_win()
            assert.are.same(win_id1, win_id3)
            assert.is_false(float.is_help_window(win_id3))
        end)
    end)
end)