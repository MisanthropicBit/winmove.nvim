local string_util = {}

---@param value string
---@return string
function string_util.titlecase(value)
    return value:sub(1, 1):upper() .. value:sub(2):lower()
end

--- Whether or not a string has a prefix
---@param str string
---@param prefix string
---@return boolean
function string_util.has_prefix(str, prefix)
    return str:sub(1, #prefix) == prefix
end

return string_util
