local config = {}

local config_loaded = false

---@class winmove.ConfigMoveModeMappings
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

---@class winmove.ConfigResizeModeMappings
---@field left         string
---@field down         string
---@field up           string
---@field right        string

---@class winmove.ConfigModeMappings
---@field help        string
---@field quit        string
---@field toggle_mode string
---@field move        winmove.ConfigMoveModeMappings
---@field resize      winmove.ConfigResizeModeMappings

---@class winmove.Highlights
---@field move string
---@field resize string

---@class winmove.Config
---@field highlights  winmove.Highlights
---@field wrap_around boolean
---@field mappings    winmove.ConfigModeMappings

---@type winmove.Config
local default_config = {
    -- TODO: Move everything into top-level "move" and "resize" tables?
    -- TODO: Move into move_mode key if we get top-level options
    highlights = {
        move = "Search",
        resize = "Substitute",
    },
    wrap_around = true,
    default_resize_count = 3,
    mappings = {
        help = "?",
        quit = "q",
        toggle_mode = "<tab>",
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
            resize_mode = "r",
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
            move_mode = "m",
        }
    }
}

--- Validate a config
---@param _config winmove.Config
local function validate_config(_config)
    -- FIX: Validation
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

    local global_options = vim.g.winmove

    if global_options and type(global_options) == "table" then
        _user_config = vim.tbl_deep_extend("keep", global_options, _user_config)
    end

    validate_config(_user_config)
    config_loaded = true
end

setmetatable(config, {
    __index = function(_, key)
        -- Lazily load configuration so there is no need to call seutp explicitly
        if not config_loaded then
            config.setup()
        end

        return _user_config[key]
    end,
})

return config
