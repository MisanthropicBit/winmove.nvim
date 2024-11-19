local winmove = require("winmove")
local config = require("winmove.config")
local test_helpers = require("winmove.util.test_helpers")
local vader = require("winmove.util.vader")

local given = vader.given

local function compare_keymap(mode, name, keymap)
    assert.is_not_nil(keymap)

    -- Do asserts separately otherwise the callback function will not match
    assert.are.same(keymap.rhs, "")
    assert.are.same(keymap.noremap, 1)
    assert.are.same(keymap.script, 0)
    assert.are.same(keymap.silent, 0)
    assert.are.same(keymap.nowait, 1)
    assert.are.same(keymap.desc, config.get_keymap_description(name, mode))
end

-- TODO: Test that mappings are also restored after moving the window
describe("mode mappings", function()
    it("sets buffer-only mode mappings when entering move mode", function()
        given(function()
            vim.cmd("new") -- Create another buffer to activate move mode

            winmove.start_mode(winmove.Mode.Move)

            local keymaps = test_helpers.get_buf_mapped_keymaps(vim.api.nvim_get_current_buf())

            for name, lhs in pairs(config.modes.move.keymaps) do
                compare_keymap("move", name, keymaps[lhs] or keymaps[lhs:upper()])
            end

            winmove.stop_mode()
        end)
    end)

    it("sets buffer-only mode mappings when entering swap mode", function()
        given(function()
            vim.cmd("new") -- Create another buffer to activate swap mode

            winmove.start_mode(winmove.Mode.Swap)

            local keymaps = test_helpers.get_buf_mapped_keymaps(vim.api.nvim_get_current_buf())

            for name, lhs in pairs(config.modes.swap.keymaps) do
                compare_keymap("swap", name, keymaps[lhs] or keymaps[lhs:upper()])
            end

            winmove.stop_mode()
        end)
    end)

    it("restores mappings after exiting a mode", function()
        given(function()
            vim.cmd("new") -- Create another buffer to activate move mode

            local buffer = vim.api.nvim_get_current_buf()

            local function func()
                vim.cmd("echo 'Hello'")
            end

            vim.keymap.set("n", "sj", func, {
                buffer = buffer,
                silent = true,
                noremap = true,
                nowait = false,
                script = false,
            })

            winmove.start_mode(winmove.Mode.Move)

            local keymaps = test_helpers.get_buf_mapped_keymaps(buffer)
            compare_keymap("move", "split_down", keymaps["sj"])

            winmove.stop_mode()

            keymaps = test_helpers.get_buf_mapped_keymaps(buffer)
            local keymap = keymaps["sj"]

            assert.is_not_nil(keymap)
            assert.are.equal(keymap.callback, func)
            assert.are.same(keymap.rhs, "")
            assert.are.same(keymap.noremap, 1)
            assert.are.same(keymap.script, 0)
            assert.are.same(keymap.silent, 1)
            assert.are.same(keymap.nowait, 0)
        end)
    end)
end)
