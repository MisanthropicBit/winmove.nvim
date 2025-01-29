local indicators = {}

---@param name string
function indicators.get_indicator_by_name(name)
    local ok, indicator = pcall(require, "winmove.indicators." .. name)

    if not ok then
        error(("No indicator called '%s'"):format(name))
    end

    return indicator
end

return indicators
