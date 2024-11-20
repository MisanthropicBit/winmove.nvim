local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local message = require("winmove.message")
local stub = require("luassert.stub")

describe("config", function()
    it("handles invalid configs", function()
        local invalid_configs = {
            {
                modes = {
                    move = {
                        highlight = true,
                    },
                },
            },
            {
                modes = {
                    swap = {
                        at_edge = 2,
                    },
                },
            },
            {
                modes = {
                    move = {
                        at_edge = {
                            vertical = at_edge.AtEdge.MoveToTab,
                        },
                    },
                },
            },
            {
                modes = {
                    swap = {
                        at_edge = {
                            vertical = at_edge.AtEdge.MoveToTab,
                        },
                    },
                },
            },
            {
                modes = {
                    move = {
                        at_edge = {
                            vertical = true,
                        },
                    },
                },
            },
            {
                modes = {
                    resize = {
                        default_resize_count = false,
                    },
                },
            },
            {
                modes = {
                    resize = {
                        default_resize_count = 0,
                    },
                },
            },
            {
                modes = {
                    resize = {
                        default_resize_count = -3,
                    },
                },
            },
            {
                keymaps = {
                    help = function() end,
                },
            },
            {
                modes = {
                    swap = {
                        keymaps = {
                            left = 12.5,
                        },
                    },
                },
            },
            {
                modes = {
                    move = {
                        keymaps = {
                            left = "",
                        },
                    },
                },
            },
            {
                modes = {
                    resize = {
                        keymaps = {
                            left_botright = true,
                        },
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
            keymaps = {
                help = "_",
                help_close = "z",
                quit = "i",
                toggle_mode = "<c-t>",
            },
            modes = {
                move = {
                    highlight = "Title",
                    at_edge = {
                        horizontal = at_edge.AtEdge.Wrap,
                        vertical = at_edge.AtEdge.None,
                    },
                    keymaps = {
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
                },
                swap = {
                    highlight = "Question",
                    at_edge = {
                        horizontal = at_edge.AtEdge.MoveToTab,
                        vertical = at_edge.AtEdge.None,
                    },
                    keymaps = {
                        left = "<left>",
                        down = "<down>",
                        up = "<up>",
                        right = "<right>",
                    },
                },
                resize = {
                    highlight = "Todo",
                    default_resize_count = 3,
                    keymaps = {
                        left = "<Left>",
                        down = "<Down>",
                        up = "<Up>",
                        right = "<Right>",
                        left_botright = "<s-h>",
                        down_botright = "<s-j>",
                        up_botright = "<s-k>",
                        right_botright = "<s-l>",
                    },
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
