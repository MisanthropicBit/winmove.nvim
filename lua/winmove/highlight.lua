--- TODO: Convert to use nvim_win_set_hl_ns when we have nvim_win_get_hl_ns:
--- https://github.com/neovim/neovim/issues/24309
local highlight = {}

local config = require("winmove.config")

local api = vim.api
local highlight_ns = api.nvim_create_namespace("winmove-highlight")

-- Window higlights per mode
local win_highlights = {
    move = nil,
    resize = nil,
}

-- Highlight groups to create winmove versions of
---@type string[]
local highlight_groups = {
    "Normal",
    "CursorLine",
    "CursorLineNr",
    "EndOfBuffer",
    "SignColumn",
    "FoldColumn",
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
}

--- Generate group highlights for a mode
---@param mode winmove.Mode
---@param groups string[]
local function generate_highlights(mode, groups)
    local color = config.highlights[mode]

    for _, group in ipairs(groups) do
        api.nvim_set_hl(highlight_ns, group, { link = color })
    end
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

    local hi = config.highlights[mode]

    -- Do not bother highlighting if highlights are turned off
    if not config.valid_string_option(hi) then
        return
    end

    if not win_highlights[mode] then
        generate_highlights(mode, highlight_groups)
    end

    api.nvim_win_set_hl_ns(win_id, highlight_ns)
end

---@param win_id integer
function highlight.unhighlight_window(win_id)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    api.nvim_win_set_hl_ns(win_id, 0)
end

---@param win_id integer
---@param mode winmove.Mode
function highlight.has_winmove_highlight(win_id, mode)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    return vim.wo[win_id].winhighlight == win_highlights[mode]
end

return highlight
