---@class winmove.State
---@field mode winmove.Mode?
---@field win_id integer?
---@field bufnr integer?
local State = {}

State.__index = State

---@return winmove.State
function State.new()
    return setmetatable({
        mode = nil,
        win_id = nil,
        bufnr = nil,
    }, State)
end

---@param key string
---@return unknown
function State:get(key)
    return self[key]
end

---@param changes winmove.State
function State:update(changes)
    self.mode = changes.mode or self.mode
    self.win_id = changes.win_id or self.win_id
    self.bufnr = changes.bufnr or self.bufnr
end

function State:reset()
    self.mode = nil
    self.win_id = nil
    self.bufnr = nil
end

---@return string
function State:__tostring()
    return ("State(%s)"):format(vim.inspect({
        mode = self.mode,
        win_id = self.win_id,
        bufnr = self.bufnr,
    }))
end

return State
