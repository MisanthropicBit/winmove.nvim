local state = {}

---@class winmove.State
---@field mode winmove.Mode?
---@field win_id integer?
---@field bufnr integer?
---@field saved_keymaps table?

---@return winmove.State
function state.new()
    return {
        mode = nil,
        win_id = nil,
        bufnr = nil,
        saved_keymaps = nil,
    }
end

--- Set current state
---@param cur_state winmove.State
---@param mode winmove.Mode
---@param win_id integer
---@param bufnr integer
---@param saved_keymaps table
function state.set(cur_state, mode, win_id, bufnr, saved_keymaps)
    cur_state.mode = mode
    cur_state.win_id = win_id
    cur_state.bufnr = bufnr
    cur_state.saved_keymaps = saved_keymaps
end

---@param cur_state winmove.State
---@param changes winmove.State
---@return winmove.State
function state.update(cur_state, changes)
    return vim.tbl_extend("force", cur_state, changes)
end

---@param cur_state winmove.State
function state.reset(cur_state)
    cur_state.mode = nil
    cur_state.win_id = nil
    cur_state.bufnr = nil
    cur_state.saved_keymaps = nil
end

return state
