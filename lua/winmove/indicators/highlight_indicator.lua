--- Base class for all indicators
---@class winmove.HighlightIndicator
local HighlightIndicator = {}

local Indicator = require("winmove.indicators.indicator")
local compat = require("winmove.compat")
local config = require("winmove.config")
local str = require("winmove.util.str")

setmetatable(HighlightIndicator, Indicator)

HighlightIndicator.__index = HighlightIndicator

local api = vim.api

---@alias winmove.Highlight string

local global_ns_id = 0

-- Highlight groups to create winmove versions of
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

--- Window higlights per mode
---@type table<winmove.Mode, string?>
local win_highlights = {
    move = nil,
    swap = nil,
    resize = nil,
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

--- Generate group highlights for a mode
---@param mode winmove.Mode
---@param groups string[]
local function generate_highlights(mode, groups)
    local highlights = {}
    local hl_group = config.modes[mode].highlight
    local titlecase_mode = str.titlecase(mode)
    local has_bg, colors = ensure_background_color(hl_group)

    if not has_bg then
        -- Create a new highlight group we can link to
        hl_group = ("Winmove%sInternal%s"):format(titlecase_mode, hl_group)

        -- nvim_get_hl creates the highlight group if it does not exist on <= v0.9.0
        if not compat.has("nvim-0.10.0") or vim.fn.hlexists(hl_group) == 0 then
            vim.api.nvim_set_hl(global_ns_id, hl_group, colors)
        end
    end

    for _, group in ipairs(groups) do
        local winmove_group = "Winmove" .. titlecase_mode .. group

        vim.cmd(("hi default link %s %s"):format(winmove_group, hl_group))
        table.insert(highlights, ("%s:%s"):format(group, winmove_group))
    end

    return table.concat(highlights, ",")
end

function HighlightIndicator.new()
    return setmetatable({
        _saved_winhighlights = nil
    }, HighlightIndicator)
end

function HighlightIndicator:init()
    generate_highlights("move", highlight_groups)
    generate_highlights("swap", highlight_groups)
    generate_highlights("resize", highlight_groups)
end

function HighlightIndicator:supported()
    return vim.fn.has("nvim-0.10.0") == 1
end

---@param win_id integer
---@param mode winmove.Mode
function HighlightIndicator:set(win_id, mode)
    if not api.nvim_win_is_valid(win_id) or mode == nil then
        return
    end

    self._saved_win_highlights = vim.wo[win_id].winhighlight
    vim.wo[win_id].winhighlight = win_highlights[mode]
end

---@param win_id integer
function HighlightIndicator:unset(win_id)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    vim.wo[win_id].winhighlight = self._saved_win_highlights or ""
    self._saved_win_highlights = nil
end

---@param win_id integer
---@param mode winmove.Mode
---@return boolean
function HighlightIndicator:is_set(win_id, mode)
    if not api.nvim_win_is_valid(win_id) then
        return false
    end

    return vim.wo[win_id].winhighlight == win_highlights[mode]
end

return HighlightIndicator
