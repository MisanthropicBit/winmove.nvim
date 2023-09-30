local winmove = require("winmove")
local config = require("winmove.config")
local vader = require("winmove.util.vader")

local given = vader.given

local function get_buf_mapped_keymaps(buffer)
    local all_keymaps = vim.api.nvim_buf_get_keymap(buffer, "n")
    local keymaps = {}

    for _, map in ipairs(all_keymaps) do
        keymaps[map.lhs] = {
            rhs = map.rhs or "",
            expr = map.expr,
            callback = map.callback,
            noremap = map.noremap,
            script = map.script,
            silent = map.silent,
            nowait = map.nowait,
            desc = map.desc,
        }
    end

    return keymaps
end

local function compare_keymap(mode, name, keymap)
    -- Do asserts separately otherwise the callback function will not match
    assert.are.same(keymap.rhs, "")
    assert.are.same(keymap.noremap, 1)
    assert.are.same(keymap.script, 0)
    assert.are.same(keymap.silent, 0)
    assert.are.same(keymap.nowait, 1)
    assert.are.same(keymap.desc, config.get_keymap_description(name, mode))
end

describe("mode mappings", function()
    it("sets buffer-only mode mappings when entering move mode", function()
        given("", function()
            vim.cmd("new") -- Create another buffer to activate move mode

            winmove.start_move_mode()

            local keymaps = get_buf_mapped_keymaps(vim.api.nvim_get_current_buf())

            for name, lhs in pairs(config.keymaps.move) do
                compare_keymap("move", name, keymaps[lhs])
            end
        end)
    end)

    it("sets buffer-only mode mappings when entering resize mode", function()
        given("", function()
            vim.cmd("new") -- Create another buffer to activate move mode

            winmove.start_resize_mode()

            local keymaps = get_buf_mapped_keymaps(vim.api.nvim_get_current_buf())

            for name, lhs in pairs(config.keymaps.resize) do
                compare_keymap("resize", name, keymaps[lhs])
            end
        end)
    end)

    it("restores mappings after exiting a mode", function()
        given("", function()
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

            winmove.start_move_mode()

            local keymaps = get_buf_mapped_keymaps(buffer)
            compare_keymap("move", "split_down", keymaps["sj"])

            winmove.stop_move_mode()

            keymaps = get_buf_mapped_keymaps(buffer)
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
