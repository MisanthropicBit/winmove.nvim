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
                wrap_around = 2,
            },
            {
                default_resize_count = false,
            },
            {
                default_resize_count = 0,
            },
            {
                default_resize_count = -3,
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
                    resize = "no",
                },
            },
            {
                keymaps = {
                    move = {
                        left = "",
                    },
                },
            },
        }

        stub(message, "error")

        for _, invalid_config in ipairs(invalid_configs) do
            assert.is_false(config.configure(invalid_config))
        end

        message.error:revert()
    end)

    it("throws no errors for a valid config", function()
        local ok = config.configure({
            highlights = {
                move = "Title",
                resize = nil,
            },
            wrap_around = false,
            default_resize_count = 2,
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
                resize = {
                    left = "<Left>",
                    down = "<Down>",
                    up = "<Up>",
                    right = "<Right>",
                },
            },
        })

        assert.is_true(ok)
    end)

    it("throws no errors for empty user config", function()
        assert.is_true(config.configure({}))
    end)

    it("throws no errors for no user config", function()
        assert.is_true(config.configure())
    end)
end)
