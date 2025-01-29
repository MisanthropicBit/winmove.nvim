--- Base class for all indicators
---@class winmove.Indicator
local Indicator = {}

Indicator.__index = Indicator

---@return winmove.Indicator
function Indicator.new()
    return setmetatable({}, Indicator)
end

function Indicator:init()
end

function Indicator:supported()
    return false
end

---@param win_id integer
---@param mode winmove.Mode
---@diagnostic disable-next-line: unused-local
function Indicator:set(win_id, mode)
    error("Not implemented")
end

---@param win_id integer
---@diagnostic disable-next-line: unused-local
function Indicator:unset(win_id)
    error("Not implemented")
end

---@param win_id integer
---@param mode winmove.Mode
---@return boolean
---@diagnostic disable-next-line: unused-local
function Indicator:is_set(win_id, mode)
    error("Not implemented")
end

return Indicator
