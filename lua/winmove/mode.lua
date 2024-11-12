local mode = {}

---@enum winmove.Mode
mode.Mode = {
    Move = "move",
}

---@param value any
---@return boolean
function mode.is_valid_mode(value)
    return value == mode.Mode.Move
end

return mode
