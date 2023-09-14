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
---@field split_left  string
---@field split_down  string
---@field split_up    string
---@field split_right string
---@field resize_mode string

---@class winmove.ConfigResizeModeMappings
---@field left         string
---@field down         string
---@field up           string
---@field right        string
---@field move_mode    string

---@class winmove.ConfigModeMappings
---@field help        string
---@field help_close  string
---@field quit        string
---@field toggle_mode string
---@field move        winmove.ConfigMoveModeMappings
---@field resize      winmove.ConfigResizeModeMappings

---@class winmove.Highlights
---@field move   string
---@field resize string

---@class winmove.Config
---@field highlights           winmove.Highlights
---@field wrap_around          boolean
---@field default_resize_count integer
---@field mappings             winmove.ConfigModeMappings

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
        help_close = "q",
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
        },
        resize = {
            left = "h",
            down = "j",
            up = "k",
            right = "l",
            move_mode = "m",
        },
    },
}

local mapping_descriptions = {
    help = "Show help",
    help_close = "Close help",
    quit = "Quit current mode",
    toggle_mode = "Toggle between modes",
    move = {
        left = "Move a window left",
        down = "Move a window down",
        up = "Move a window up",
        right = "Move a window right",
        far_left = "Move a window far left and maximize it",
        far_down = "Move a window far down and maximize it",
        far_up = "Move a window far up and maximize it",
        far_right = "Move a window far right and maximize it",
        split_left = "Split a window left into another window",
        split_down = "Split a window down into another window",
        split_up = "Split a window up into another window",
        split_right = "Split a window right into another window",
        resize_mode = "Switch to resize mode",
    },
    resize = {
        left = "Resize window left",
        down = "Resize window down",
        up = "Resize window up",
        right = "Resize window right",
        move_mode = "Switch to move mode",
    },
}

--- Get the description of a keymap
---@param name string
---@param mode winmove.Mode?
---@return string
function config.get_keymap_description(name, mode)
    if mode == "none" or mode == nil then
        ---@diagnostic disable-next-line:return-type-mismatch
        return mapping_descriptions[name]
    else
        return mapping_descriptions[mode][name]
    end
end

--- Validate keys in a table
---@param specs table<any>
---@return fun(tbl: table): boolean, any?
local function validate_keys(specs)
    return function(tbl)
        for _, spec in ipairs(specs) do
            local key = spec[1]

            local validated, error = pcall(vim.validate, {
                [key] = { tbl[key], spec[2], spec[3] and true },
            })

            if not validated then
                return validated, error
            end
        end

        return true
    end
end

--- Validate a config
---@param _config winmove.Config
---@return boolean
---@return any?
function config.validate(_config)
    return pcall(vim.validate, {
        highlights = {
            _config.highlights,
            validate_keys({
                { "move", "string" },
                { "resize", "string" },
            }),
        },
        wrap_around = { _config.wrap_around, "boolean" },
        default_resize_count = { _config.default_resize_count, "number" },
        mappings = {
            _config.mappings,
            validate_keys({
                { "help", "string" },
                { "help_close", "string" },
                { "quit", "string" },
                { "toggle_mode", "string" },
            }),
        },
        ["mappings.move"] = {
            _config.mappings.move,
            validate_keys({
                { "left", "string" },
                { "down", "string" },
                { "up", "string" },
                { "right", "string" },
                { "far_left", "string" },
                { "far_down", "string" },
                { "far_up", "string" },
                { "far_right", "string" },
                { "split_left", "string" },
                { "split_down", "string" },
                { "split_up", "string" },
                { "split_right", "string" },
                { "resize_mode", "string" },
            }),
        },
        ["mappings.resize"] = {
            _config.mappings.resize,
            validate_keys({
                { "left", "string" },
                { "down", "string" },
                { "up", "string" },
                { "right", "string" },
                { "move_mode", "string" },
            }),
        },
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

    if global_options then
        if type(global_options) == "table" then
            _user_config = vim.tbl_deep_extend("keep", global_options, _user_config)
        else
            error("vim.g.winmove is not a table")
        end
    end

    local ok, error = config.validate(_user_config)

    if not ok then
        vim.api.nvim_echo({
            { "[winmove.nvim]:", "ErrorMsg" },
            { " Errors found in config: " .. error },
        }, true, {})
        return
    end

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
