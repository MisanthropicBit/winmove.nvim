local test_helpers = {}

---@param buffer integer
---@return table
function test_helpers.get_buf_mapped_keymaps(buffer)
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

return test_helpers
