local str = {}

---@param value string
---@return string
function str.titlecase(value)
    return value:sub(1, 1):upper() .. value:sub(2):lower()
end

return str
