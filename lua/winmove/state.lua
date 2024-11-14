---@class winmove.State
---@field mode winmove.Mode?
---@field win_id integer?
---@field bufnr integer?
---@field saved_keymaps table?
local State = {}

State.__index = State

---@return winmove.State
function State.new()
    return setmetatable({
        mode = nil,
        win_id = nil,
        bufnr = nil,
        saved_keymaps = nil,
    }, State)
end

function State:get(key)
    return self[key]
end

---@param changes winmove.State
function State:update(changes)
    self.mode = changes.mode or self.mode
    self.win_id = changes.win_id or self.win_id
    self.bufnr = changes.bufnr or self.bufnr
    self.saved_keymaps = changes.saved_keymaps or self.saved_keymaps
end

function State:reset()
    self.mode = nil
    self.win_id = nil
    self.bufnr = nil
    self.saved_keymaps = nil
end

function State:__tostring()
    return ("State(%s)"):format(vim.inspect({
        mode = self.mode,
        win_id = self.win_id,
        bufnr = self.bufnr,
        saved_keymaps = self.saved_keymaps,
    }))
end

return State
