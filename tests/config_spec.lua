local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local message = require("winmove.message")
local stub = require("luassert.stub")

describe("config", function()
    it("handles invalid configs", function()
        local invalid_configs = {
            {
                highlights = {
                    move = true,
                },
            },
            {
                at_edge = 2,
            },
            {
                at_edge = {
                    horizontal = at_edge.MoveToTab,
                    vertical = at_edge.MoveToTab,
                },
            },
            {
                at_edge = {
                    vertical = true,
                },
            },
            {
                keymaps = {
                    help = function() end,
                },
            },
            {
                keymaps = {
                    move = {
                        left = 12.5,
                    },
                },
            },
            {
                keymaps = {
                    move = {
                        left = "",
                    },
                },
            },
            {
                keymaps = {
                    swap = {
                        left = 12.5,
                    },
                },
            },
            {
                keymaps = {
                    swap = {
                        left = "",
                    },
                },
            },
        }

        stub(message, "error")

        for _, invalid_config in ipairs(invalid_configs) do
            local ok = config.configure(invalid_config)

            if ok then
                vim.print(invalid_config)
            end

            assert.is_false(ok)
        end

        ---@diagnostic disable-next-line: undefined-field
        message.error:revert()
    end)

    it("throws no errors for a valid config", function()
        local ok = config.configure({
            highlights = {
                move = "Title",
            },
            at_edge = {
                horizontal = at_edge.Wrap,
                vertical = false,
            },
            keymaps = {
                help = "_",
                help_close = "z",
                quit = "i",
                toggle_mode = "<c-t>",
                move = {
                    left = "<left>",
                    down = "<down>",
                    up = "<up>",
                    right = "<right>",
                    far_left = "U",
                    far_down = "I",
                    far_up = "O",
                    far_right = "P",
                    split_left = "ef",
                    split_down = "nv",
                    split_up = "qp",
                    split_right = "vn",
                },
                swap = {
                    left = "<left>",
                    down = "<down>",
                    up = "<up>",
                    right = "<right>",
                    select = "-",
                },
            },
        })

        assert.is_true(ok)
    end)

    it("throws no errors for empty user config", function()
        ---@diagnostic disable-next-line: missing-fields
        assert.is_true(config.configure({}))
    end)

    it("throws no errors for no user config", function()
        assert.is_true(config.configure())
    end)
end)
