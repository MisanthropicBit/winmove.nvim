local at_edge = {}

---@enum winmove.AtEdge
at_edge.AtEdge = {
    None = "none",
    Wrap = "wrap",
    MoveToTab = "move_to_tab",
}

---@param value any
---@return boolean
function at_edge.is_valid_behaviour(value)
    if type(value) ~= "string" then
        return false
    end

    return value == at_edge.AtEdge.None or value == at_edge.AtEdge.Wrap or value == at_edge.AtEdge.MoveToTab
end

return at_edge
