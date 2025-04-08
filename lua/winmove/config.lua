local config = {}

local at_edge = require("winmove.at_edge")
local message = require("winmove.message")

local config_loaded = false

---@class winmove.ConfigCommonKeymaps
---@field help        string
---@field help_close  string
---@field quit        string
---@field toggle_mode string

---@class winmove.ConfigMoveModeKeymaps
---@field left        string
---@field down        string
---@field up          string
---@field right       string
---@field far_left    string
---@field far_down    string
---@field far_up      string
---@field far_right   string
---@field split_left  string
---@field split_down  string
---@field split_up    string
---@field split_right string

---@class winmove.ConfigMoveMode
---@field highlight winmove.Highlight
---@field at_edge   winmove.AtEdgeConfig
---@field keymaps   winmove.ConfigMoveModeKeymaps

---@class winmove.ConfigSwapModeKeymaps
---@field left   string
---@field down   string
---@field up     string
---@field right  string

---@class winmove.ConfigSwapMode
---@field highlight winmove.Highlight
---@field at_edge   winmove.AtEdgeConfig
---@field keymaps   winmove.ConfigSwapModeKeymaps

---@class winmove.ConfigResizeModeKeymaps
---@field left           string
---@field down           string
---@field up             string
---@field right          string
---@field left_botright  string
---@field down_botright  string
---@field up_botright    string
---@field right_botright string

---@class winmove.ConfigResizeMode
---@field highlight            winmove.Highlight
---@field default_resize_count integer
---@field default_large_resize_count integer
---@field keymaps              winmove.ConfigResizeModeKeymaps

---@class winmove.ConfigModes
---@field move   winmove.ConfigMoveMode
---@field swap   winmove.ConfigSwapMode
---@field resize winmove.ConfigResizeMode

---@class winmove.AtEdgeConfig
---@field horizontal winmove.AtEdge
---@field vertical   winmove.AtEdge

---@class winmove.Config
---@field keymaps winmove.ConfigCommonKeymaps
---@field modes   winmove.ConfigModes

---@type winmove.Config
local default_config = {
    keymaps = {
        help = "?",
        help_close = "q",
        quit = "q",
        toggle_mode = "<tab>",
    },
    modes = {
        move = {
            highlight = "Visual",
            at_edge = {
                horizontal = at_edge.AtEdge.None,
                vertical = at_edge.AtEdge.None,
            },
            keymaps = {
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
        },
        swap = {
            highlight = "Substitute",
            at_edge = {
                horizontal = at_edge.AtEdge.None,
                vertical = at_edge.AtEdge.None,
            },
            keymaps = {
                left = "h",
                down = "j",
                up = "k",
                right = "l",
            },
        },
        resize = {
            highlight = "Todo",
            default_resize_count = 3,
            default_large_resize_count = 10,
            keymaps = {
                left = "h",
                down = "j",
                up = "k",
                right = "l",
                large_left = "H",
                large_down = "J",
                large_up = "K",
                large_right = "L",
                left_botright = "<c-h>",
                down_botright = "<c-j>",
                up_botright = "<c-k>",
                right_botright = "<c-l>",
                large_left_botright = "<c-s-h>",
                large_down_botright = "<c-s-j>",
                large_up_botright = "<c-s-k>",
                large_right_botright = "<c-s-l>",
            },
        },
    },
}

local mapping_descriptions = {
    keymaps = {
        help = "Show help",
        help_close = "Close help",
        quit = "Quit current mode",
        toggle_mode = "Toggle between modes",
    },
    modes = {
        move = {
            keymaps = {
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
        },
        swap = {
            keymaps = {
                left = "Swap window left",
                down = "Swap window down",
                up = "Swap window up",
                right = "Swap window right",
            },
        },
        resize = {
            keymaps = {
                left = "Resize window left",
                down = "Resize window down",
                up = "Resize window up",
                right = "Resize window right",
                large_left = "Resize window a large amount left",
                large_down = "Resize window a large amount down",
                large_up = "Resize window a large amount up",
                large_right = "Resize window a large amount right",
                left_botright = "Resize window left with bottom-right anchor",
                down_botright = "Resize window down with bottom-right anchor",
                up_botright = "Resize window up with bottom-right anchor",
                right_botright = "Resize window right with bottom-right anchor",
                large_left_botright = "Resize window a large amount left with bottom-right anchor",
                large_down_botright = "Resize window a large amount down with bottom-right anchor",
                large_up_botright = "Resize window a large amount up with bottom-right anchor",
                large_right_botright = "Resize window a large amount right with bottom-right anchor",
            },
        },
    },
}

--- Get the description of a keymap
---@param name string
---@param mode winmove.Mode?
---@return string
function config.get_keymap_description(name, mode)
    if mode == nil then
        ---@diagnostic disable-next-line:return-type-mismatch
        return mapping_descriptions.keymaps[name]
    else
        return mapping_descriptions.modes[mode].keymaps[name]
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

---@param object table<string, unknown>
---@param schema table<string, unknown>
---@return table
local function validate_schema(object, schema)
    local errors = {}

    for key, value in pairs(schema) do
        if type(value) == "string" then
            local ok, err = pcall(vim.validate, { [key] = { object[key], value } })

            if not ok then
                table.insert(errors, err)
            end
        elseif type(value) == "table" then
            if type(object) ~= "table" then
                table.insert(errors, "Expected a table at key " .. key)
            else
                if vim.is_callable(value[1]) then
                    local ok, err = pcall(vim.validate, {
                        [key] = { object[key], value[1], value[2] },
                    })

                    if not ok then
                        table.insert(errors, err)
                    end
                else
                    vim.list_extend(errors, validate_schema(object[key], value))
                end
            end
        end
    end

    return errors
end

local expected_non_empty_string = "Expected a non-empty string"

local horizontal_validator = {
    at_edge.is_valid_behaviour,
    "valid behaviour at horizontal edge",
}

local vertical_validator = {
    function(value)
        return value == at_edge.AtEdge.None or value == at_edge.AtEdge.Wrap
    end,
    "valid behaviour at vertical edge",
}

local non_empty_string_validator = { is_non_empty_string, expected_non_empty_string }

local is_positive_non_zero_number_validator =
    { is_positive_non_zero_number, "a positive, non-zero number" }

--- Validate a config
---@param _config winmove.Config
---@return boolean
---@return any?
function config.validate(_config)
    -- TODO: Validate superfluous keys

    -- stylua: ignore start
    local config_schema = {
        keymaps = {
            help        = "string",
            help_close  = "string",
            quit        = "string",
            toggle_mode = "string",
        },
        modes = {
            move = {
                highlight = "string",
                at_edge = {
                    horizontal = horizontal_validator,
                    vertical   = vertical_validator,
                },
                keymaps = {
                    left        = non_empty_string_validator,
                    down        = non_empty_string_validator,
                    up          = non_empty_string_validator,
                    right       = non_empty_string_validator,
                    far_left    = non_empty_string_validator,
                    far_down    = non_empty_string_validator,
                    far_up      = non_empty_string_validator,
                    far_right   = non_empty_string_validator,
                    split_left  = non_empty_string_validator,
                    split_down  = non_empty_string_validator,
                    split_up    = non_empty_string_validator,
                    split_right = non_empty_string_validator,
                },
            },
            swap = {
                highlight = "string",
                at_edge = {
                    horizontal = horizontal_validator,
                    vertical   = vertical_validator,
                },
                keymaps = {
                    left  = non_empty_string_validator,
                    down  = non_empty_string_validator,
                    up    = non_empty_string_validator,
                    right = non_empty_string_validator,
                },
            },
            resize = {
                highlight = "string",
                default_resize_count = is_positive_non_zero_number_validator,
                keymaps = {
                    left                 = non_empty_string_validator,
                    down                 = non_empty_string_validator,
                    up                   = non_empty_string_validator,
                    right                = non_empty_string_validator,
                    large_left           = non_empty_string_validator,
                    large_down           = non_empty_string_validator,
                    large_up             = non_empty_string_validator,
                    large_right          = non_empty_string_validator,
                    left_botright        = non_empty_string_validator,
                    down_botright        = non_empty_string_validator,
                    up_botright          = non_empty_string_validator,
                    right_botright       = non_empty_string_validator,
                    large_left_botright  = non_empty_string_validator,
                    large_down_botright  = non_empty_string_validator,
                    large_up_botright    = non_empty_string_validator,
                    large_right_botright = non_empty_string_validator,
                },
            },
        },
    }
    -- stylua: ignore end

    local errors = validate_schema(_config, config_schema)

    return #errors == 0, errors
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
        message.error("Errors found in config: " .. table.concat(error, "\n"))
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
