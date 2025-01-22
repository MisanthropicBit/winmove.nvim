local highlight = {}

local compat = require("winmove.compat")
local config = require("winmove.config")

local api = vim.api

---@alias winmove.Highlight string

local global_ns_id = 0

-- Window higlights per mode
local win_hl_ns_per_mode = {
    move = nil,
    swap = nil,
    resize = nil,
}

-- Highlight groups to override in mode highlight namespaces
---@type string[]
local highlight_groups = {
    "CursorLine",
    "CursorLineNr",
    "DiagnosticVirtualTextOk",
    "DiagnosticVirtualTextHint",
    "DiagnosticVirtualTextInfo",
    "DiagnosticVirtualTextWarn",
    "DiagnosticVirtualTextError",
    "EndOfBuffer",
    "FoldColumn",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "Normal",
    "SignColumn",
}

--- If the highlight group only contains a foreground color, return it as
--- the color to use for the background, otherwise use the background color
---@param group string
---@return boolean
---@return table<string, unknown>
local function ensure_background_color(group)
    local colors = compat.get_hl(global_ns_id, { name = group, link = false, create = false })

    if colors.bg or colors.ctermbg then
        return true, colors
    end

    colors.bg = colors.fg
    colors.fg = nil

    ---@diagnostic disable-next-line: inject-field
    colors.ctermbg = colors.ctermfg
    ---@diagnostic disable-next-line: inject-field
    colors.ctermfg = nil

    return false, colors
end

--- Generate a highlight namespace for a mode
---@param mode winmove.Mode
---@param groups string[]
local function generate_hl_ns(mode, groups)
    local hl_group = config.modes[mode].highlight
    local _, colors = ensure_background_color(hl_group)
    local ns_id = api.nvim_create_namespace(("winmove-%s-mode-hl"):format(mode))

    for _, group in ipairs(groups) do
        api.nvim_set_hl(ns_id, group, colors)
    end

    return ns_id
end

---@return string[]
function highlight.groups()
    return highlight_groups
end

---@param win_id integer
---@param mode winmove.Mode
function highlight.highlight_window(win_id, mode)
    if not api.nvim_win_is_valid(win_id) or mode == nil then
        return
    end

    if not win_hl_ns_per_mode[mode] then
        win_hl_ns_per_mode[mode] = generate_hl_ns(mode, highlight_groups)
    end

    api.nvim_win_set_hl_ns(win_id, win_hl_ns_per_mode[mode])
end

---@param win_id integer
function highlight.unhighlight_window(win_id)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    api.nvim_win_set_hl_ns(win_id, global_ns_id)
end

---@param win_id integer
---@param mode winmove.Mode
function highlight.has_highlight(win_id, mode)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    return api.nvim_get_hl_ns({ winid = win_id }) == win_hl_ns_per_mode[mode]
end

return highlight
