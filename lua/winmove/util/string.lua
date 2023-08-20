local string_util = {}

---@param value string
---@return string
function string_util.titlecase(value)
    return value:sub(1, 1):upper() .. value:sub(2):lower()
end

return string_util
