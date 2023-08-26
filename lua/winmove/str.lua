local str = {}

---@param value string
---@return string
function str.titlecase(value)
    return value:sub(1, 1):upper() .. value:sub(2):lower()
end

--- Whether or not a string has a prefix
---@param value string
---@param prefix string
---@return boolean
function str.has_prefix(value, prefix)
    return value:sub(1, #prefix) == prefix
end

return str
