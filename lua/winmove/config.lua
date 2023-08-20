local config = {}

---@class winmove.ConfigMappings
---@field left         string
---@field down         string
---@field up           string
---@field right        string
---@field far_left     string
---@field far_down     string
---@field far_up       string
---@field far_right    string
---@field column_left  string
---@field column_down  string
---@field column_up    string
---@field column_right string
---@field help         string
---@field quit         string

---@class winmove.Highlights
---@field move string
---@field resize string

---@class winmove.Config
---@field highlights  winmove.Highlights
---@field wrap_around boolean
---@field mappings    winmove.ConfigMappings

---@type winmove.Config
local default_config = {
    -- TODO: Move into move_mode key if we get top-level options
    highlights = {
        move = "Search",
        resize = "Title",
    },
    wrap_around = true,
    mappings = {
        help = "?",
        quit = "q",
        quitall = "Q",
        move = {
            left = "h",
            down = "j",
            up = "k",
            right = "l",
            far_left = "H",
            far_down = "J",
            far_up = "K",
            far_right = "L",
            split_left = "sh",
            split_down = "sj",
            split_up = "sk",
            split_right = "sl",
            help = "?",
            quit = "q",
            column_left = "<c-h>",
            column_down = "<c-j>",
            column_up = "<c-k>",
            column_right = "<c-l>",
        },
        resize = {
            left = "h",
            down = "j",
            up = "k",
            right = "l",
            help = "?",
            quit = "q",
        }
    }
}

--- Validate a config
---@param _config winmove.Config
local function validate_config(_config)
    vim.validate({
        mappings = { _config.mappings, "table", true },
        ["mappings.left"] = { _config.mappings.left, "string", true },
        ["mappings.down"] = { _config.mappings.down, "string", true },
        ["mappings.up"] = { _config.mappings.up, "string", true },
        ["mappings.right"] = { _config.mappings.right, "string", true },
    })
end

---@type winmove.Config
local _user_config = default_config

---Use in testing
---@private
function config._default_config()
    return default_config
end

---@param user_config? winmove.Config
function config.setup(user_config)
    _user_config = vim.tbl_deep_extend("keep", user_config or {}, default_config)

    validate_config(_user_config)
end

setmetatable(config, {
    __index = function(_, key)
        return _user_config[key]
    end,
})

return config
