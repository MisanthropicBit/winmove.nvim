local message = {}

local function color_level(level)
    return ({
        [vim.log.levels.ERROR] = "ErrorMsg",
        [vim.log.levels.WARN] = "WarningMsg",
    })[level]
end

---@param msg string | string[][]
---@param level integer
---@param history boolean
local function _message(msg, level, history)
    local chunks = {}

    if type(msg) == "string" then
        table.insert(chunks, { " " .. msg })
    elseif type(msg) == "table" then
        table.insert(chunks, { " " })
        vim.list_extend(chunks, msg)
    end

    table.insert(chunks, 1, { "[winmove.nvim]:", color_level(level) })

    vim.api.nvim_echo(chunks, history or false, {})
end

---@param chunks string | string[][]
---@param history boolean?
function message.error(chunks, history)
    _message(chunks, vim.log.levels.ERROR, history or true)
end

---@param chunks string | string[][]
---@param history boolean?
function message.warn(chunks, history)
    _message(chunks, vim.log.levels.WARN, history or true)
end

return message
