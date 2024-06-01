local config = {}

local at_edge = require("winmove.at_edge")
local message = require("winmove.message")

local config_loaded = false

---@class winmove.ConfigMoveModeKeymaps
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

---@class winmove.ConfigResizeModeKeymaps
---@field left           string
---@field down           string
---@field up             string
---@field right          string
---@field left_botright  string
---@field down_botright  string
---@field up_botright    string
---@field right_botright string

---@class winmove.ConfigModeKeymaps
---@field help        string
---@field help_close  string
---@field quit        string
---@field toggle_mode string
---@field move        winmove.ConfigMoveModeKeymaps
---@field resize      winmove.ConfigResizeModeKeymaps

---@class winmove.Highlights
---@field move   string?
---@field resize string?

---@class winmove.AtEdgeConfig
---@field horizontal false | winmove.AtEdge
---@field vertical   false | winmove.AtEdge

---@class winmove.Config
---@field highlights           winmove.Highlights
---@field at_edge              winmove.AtEdgeConfig
---@field default_resize_count integer
---@field keymaps              winmove.ConfigModeKeymaps

---@type winmove.Config
local default_config = {
    highlights = {
        move = "Visual",
        resize = "Substitute",
    },
    at_edge = {
        horizontal = at_edge.MoveToTab,
        vertical = at_edge.Wrap,
    },
    default_resize_count = 3,
    keymaps = {
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
        },
        resize = {
            left = "h",
            down = "j",
            up = "k",
            right = "l",
            left_botright = "<c-h>",
            down_botright = "<c-j>",
            up_botright = "<c-k>",
            right_botright = "<c-l>",
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
    },
    resize = {
        left = "Resize window left",
        down = "Resize window down",
        up = "Resize window up",
        right = "Resize window right",
        left_botright = "Resize window left with bottom-right anchor",
        down_botright = "Resize window down with bottom-right anchor",
        up_botright = "Resize window up with bottom-right anchor",
        right_botright = "Resize window right with bottom-right anchor",
    },
}

--- Get the description of a keymap
---@param name string
---@param mode winmove.Mode?
---@return string
function config.get_keymap_description(name, mode)
    if mode == nil then
        ---@diagnostic disable-next-line:return-type-mismatch
        return mapping_descriptions[name]
    else
        return mapping_descriptions[mode][name]
    end
end

--- Check if a value is a valid string option
---@param value any
---@return boolean
function config.valid_string_option(value)
    return value ~= nil and type(value) == "string" and #value > 0
end

local function is_positive_non_zero_number(value)
    return type(value) == "number" and value > 0
end

local function is_non_empty_string(value)
    return type(value) == "string" and #value > 0
end

--- Validate keys in a table
---@param specs table<any>
---@return fun(tbl: table): boolean, any?
local function validate_keys(specs)
    return function(tbl)
        if not tbl then
            return true
        end

        for _, spec in ipairs(specs) do
            local key = spec[1]
            local expected = spec[2]

            local validated, error = pcall(vim.validate, {
                [key] = { tbl[key], expected, spec[3] },
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
    local expected_non_empty_string = "Expected a non-empty string"

    -- stylua: ignore start
    return pcall(vim.validate, {
        highlights = {
            _config.highlights,
            validate_keys({
                { "move",   "string" },
                { "resize", "string" },
            }),
        },
        at_edge = {
            _config.at_edge,
            validate_keys({
                {
                    "horizontal",
                    function(value)
                        return value == false or value == at_edge.Wrap or value == at_edge.MoveToTab
                    end,
                    "valid behaviour at horizontal edge",
                },
                {
                    "vertical",
                    function(value)
                        return value == false or value == at_edge.Wrap
                    end,
                    "valid behaviour at vertical edge",
                },
            }),
        },
        default_resize_count = {
            _config.default_resize_count,
            is_positive_non_zero_number,
        },
        keymaps = {
            _config.keymaps,
            validate_keys({
                { "help",        "string" },
                { "help_close",  "string" },
                { "quit",        "string" },
                { "toggle_mode", "string" },
            }),
        },
        ["keymaps.move"] = {
            _config.keymaps.move,
            validate_keys({
                { "left",        is_non_empty_string, expected_non_empty_string },
                { "down",        is_non_empty_string, expected_non_empty_string },
                { "up",          is_non_empty_string, expected_non_empty_string },
                { "right",       is_non_empty_string, expected_non_empty_string },
                { "far_left",    is_non_empty_string, expected_non_empty_string },
                { "far_down",    is_non_empty_string, expected_non_empty_string },
                { "far_up",      is_non_empty_string, expected_non_empty_string },
                { "far_right",   is_non_empty_string, expected_non_empty_string },
                { "split_left",  is_non_empty_string, expected_non_empty_string },
                { "split_down",  is_non_empty_string, expected_non_empty_string },
                { "split_up",    is_non_empty_string, expected_non_empty_string },
                { "split_right", is_non_empty_string, expected_non_empty_string },
            }),
        },
        ["keymaps.resize"] = {
            _config.keymaps.resize,
            validate_keys({
                { "left",  is_non_empty_string, expected_non_empty_string },
                { "down",  is_non_empty_string, expected_non_empty_string },
                { "up",    is_non_empty_string, expected_non_empty_string },
                { "right", is_non_empty_string, expected_non_empty_string },
                { "left_botright", is_non_empty_string, expected_non_empty_string },
                { "down_botright", is_non_empty_string, expected_non_empty_string },
                { "up_botright", is_non_empty_string, expected_non_empty_string },
                { "right_botright", is_non_empty_string, expected_non_empty_string },
            }),
        },
    })
    -- stylua: ignore end
end

---@type winmove.Config
local _user_config = default_config

---Use in testing
---@private
function config._default_config()
    return default_config
end

---@param user_config? winmove.Config
function config.configure(user_config)
    _user_config = vim.tbl_deep_extend("keep", user_config or {}, default_config)

    local ok, error = config.validate(_user_config)

    if not ok then
        message.error("Errors found in config: " .. error)
    else
        config_loaded = true
    end

    return ok
end

setmetatable(config, {
    __index = function(_, key)
        -- Lazily load configuration so there is no need to call configure explicitly
        if not config_loaded then
            config.configure()
        end

        return _user_config[key]
    end,
})

return config
