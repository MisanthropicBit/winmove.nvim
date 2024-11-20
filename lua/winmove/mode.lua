local mode = {}

---@enum winmove.Mode
mode.Mode = {
    Move = "move",
    Swap = "swap",
    Resize = "resize",
}

---@param value any
---@return boolean
function mode.is_valid_mode(value)
    if type(value) ~= "string" then
        return false
    end

    return value == mode.Mode.Move or value == mode.Mode.Swap or value == mode.Mode.Resize
end

return mode
