local validators = {}

---@param value any
---@return boolean
local function is_valid_direction(value)
    return value == "h" or value == "j" or value == "k" or value == "l"
end

---@param value any
---@return boolean
function validators.is_nonnegative_number(value)
    return type(value) == "number" and value >= 0
end

---@param value any
function validators.win_id_validator(value)
    return { value, validators.is_nonnegative_number, "a non-negative number" }
end

---@param value any
function validators.dir_validator(value)
    return { value, is_valid_direction, "a valid direction" }
end

return validators
