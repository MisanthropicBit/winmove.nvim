local winmove = require("winmove")
local test_helpers = require("winmove.util.test_helpers")
local vader = require("winmove.util.vader")
local stub = require("luassert.stub")

local given = vader.given
local make_layout = test_helpers.make_layout

describe("error handling in modes", function()
    it("handles errors in move mode and restores mappings", function()
        given("", function()
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

            local function func()
                vim.cmd("echo 'Hello'")
            end

            local buffer = vim.api.nvim_get_current_buf()

            vim.keymap.set("n", "sj", func, {
                buffer = buffer,
                silent = true,
                noremap = true,
                nowait = false,
                script = false,
            })

            -- Create stubs
            stub(vim.api, "nvim_echo")
            stub(winmove, "move_window", function()
                error("Oh noes", 0)
            end)

            winmove.start_mode(winmove.mode.Move)
            vim.cmd.normal("l")

            assert.is_nil(winmove.current_mode())

            assert.stub(vim.api.nvim_echo).was.called_with({
                { "[winmove.nvim]:", "ErrorMsg" },
                { " Got error in 'move' mode: Oh noes" },
            }, true, {})

            local keymaps = test_helpers.get_buf_mapped_keymaps(buffer)
            local keymap = keymaps["sj"]

            -- Check that user keymap has been restored
            assert.is_not_nil(keymap)
            assert.are.equal(keymap.callback, func)
            assert.are.same(keymap.rhs, "")
            assert.are.same(keymap.noremap, 1)
            assert.are.same(keymap.script, 0)
            assert.are.same(keymap.silent, 1)
            assert.are.same(keymap.nowait, 0)

            -- Revert stubs
            vim.api.nvim_echo:revert()
            winmove.move_window:revert()
        end)
    end)
end)
