local mode = {}

---@enum winmove.Mode
mode.Mode = {
    Move = "move",
    Swap = "swap",
}

---@param value any
---@return boolean
function mode.is_valid_mode(value)
    return value == mode.Mode.Move or value == mode.Mode.Swap
end

return mode
