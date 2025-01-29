local Indicator = require("winmove.indicators.indicator")

---@class winmove.FloatIndicator
---@diagnostic disable-next-line: assign-type-mismatch
local FloatIndicator = setmetatable({}, Indicator)

---@class winmove.FloatIndicatorOptions
---@field width  number | integer | "auto"
---@field height number | integer | "auto"

FloatIndicator.__index = FloatIndicator

---@param win_id integer
---@param options winmove.FloatIndicatorOptions
---@return table
local function compute_float_pos_and_sizes(win_id, options)
    -- TODO: Use user config options to compute values

    local win_width = vim.api.nvim_win_get_width(win_id)
    local win_height = vim.api.nvim_win_get_height(win_id)
    local float_width = math.floor(win_width * 0.15)
    local float_height = math.floor(win_height * 0.25)
    local col = win_width / 2 - win_width / 2
    local row = win_height / 2 - win_height / 2

    return {
        width = float_width,
        height = float_height,
        row = row,
        col = col,
    }
end

---@param options winmove.FloatIndicatorOptions
---@return winmove.FloatIndicator
function FloatIndicator.new(options)
    return setmetatable({ options = options }, FloatIndicator)
end

function FloatIndicator:init()
    self.buffer = vim.api.nvim_create_buf(false, true)

    self.win_options = {
        relative = "win",
        style = "minimal",
        border = nil,
        focusable = false,
        zindex = 300,
        noautocmd = true,
    }
end

function FloatIndicator:supported()
    return true
end

---@param win_id integer
---@param mode winmove.Mode
function FloatIndicator:set(win_id, mode)
    if not vim.api.nvim_win_is_valid(win_id) or mode == nil then
        return
    end

    local pos_and_sizes = compute_float_pos_and_sizes(win_id, self.options)

    self.float_id = vim.api.nvim_open_win(
        self.buffer,
        false,
        vim.tbl_extend("force", self.win_options, pos_and_sizes)
    )

    local empty_lines = vim.split((" "):rep(pos_and_sizes.height - 1), " ")
    vim.api.nvim_buf_set_lines(self.buffer, 0, -1, true, empty_lines)

    vim.wo[self.float_id].winhighlight = "NormalFloat:DiffText"
    vim.w[win_id].__winmove_float_indicator_id = self.float_id
end

---@param win_id integer
function FloatIndicator:unset(win_id)
    if not vim.api.nvim_win_is_valid(win_id) then
        return
    end

    local float_id = vim.w[win_id].__winmove_float_indicator_id

    if not float_id then
        return
    end

    vim.wo[float_id].winhighlight = ""
    vim.api.nvim_win_close(float_id, true)
    vim.w[win_id].__winmove_float_indicator_id = nil
end

---@param win_id integer
---@param mode winmove.Mode
---@return boolean
function FloatIndicator:is_set(win_id, mode)
    if not vim.api.nvim_win_is_valid(win_id) then
        return false
    end

    local float_id = vim.w[win_id].__winmove_float_indicator_id

    if not float_id then
        return false
    end

    -- TODO:
    if vim.wo[float_id].winhighlight ~= "TODO" then
        return false
    end

    return true
end

return FloatIndicator
