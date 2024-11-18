local message = {}

---@param msg string
---@param level integer
local function _message(msg, level)
    vim.notify("[winmove.nvim]: " .. msg, level)
end

---@param msg string
function message.error(msg)
    _message(msg, vim.log.levels.ERROR)
end

---@param msg string
function message.warn(msg)
    _message(msg, vim.log.levels.WARN)
end

return message
