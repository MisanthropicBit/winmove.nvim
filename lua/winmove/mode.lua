local mode = {}

---@enum winmove.Mode
mode.Mode = {
    Move = "move",
    Resize = "resize",
}

---@param value any
---@return boolean
function mode.is_valid_mode(value)
    return value == mode.Mode.Move or value == mode.Mode.Resize
end

return mode
