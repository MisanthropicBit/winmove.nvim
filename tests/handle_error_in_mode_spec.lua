describe("error handling in modes", function()
    local float = require("winmove.float")
    local message = require("winmove.message")
    local stub = require("luassert.stub")
    local test_helpers = require("winmove.util.test_helpers")
    local vader = require("winmove.util.vader")
    local winmove = require("winmove")

    local given = vader.given
    local make_layout = test_helpers.make_layout

    it("handles errors in move mode and restores mappings", function()
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

            stub(float, "open", function()
                error("Oh noes", 0)
            end)

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

            stub(vim, "notify")

            winmove.start_mode(winmove.Mode.Move)
            vim.cmd.normal("?")

            assert.is_nil(winmove.current_mode())

            assert
                .stub(vim.notify).was
                .called_with("[winmove.nvim]: Got error in 'move' mode: Oh noes", vim.log.levels.ERROR)

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

            ---@diagnostic disable-next-line: undefined-field
            vim.notify:revert()
            ---@diagnostic disable-next-line: undefined-field
            float.open:revert()
        end)
    end)
end)
