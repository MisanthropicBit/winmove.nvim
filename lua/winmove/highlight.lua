-- TODO: Convert to use nvim_win_set_hl_ns when we have nvim_win_get_hl_ns:
-- https://github.com/neovim/neovim/issues/24309

local highlight = {}

local config = require("winmove.config")
local str = require("winmove.util.str")

local api = vim.api

-- Window higlights per mode
local win_highlights = {
    move = nil,
    resize = nil,
}

---@type string?
local saved_win_highlights = nil

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
    local highlights = {}
    local color = config.highlights[mode]

    for _, group in ipairs(groups) do
        local titlecase_mode = str.titlecase(mode)
        local winmove_group = "Winmove" .. titlecase_mode .. group

        vim.cmd(("hi default link %s %s"):format(winmove_group, color))
        table.insert(highlights, ("%s:%s"):format(group, winmove_group))
    end

    return table.concat(highlights, ",")
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

    if not win_highlights[mode] then
        win_highlights[mode] = generate_highlights(mode, highlight_groups)
    end

    saved_win_highlights = vim.wo[win_id].winhighlight
    vim.wo[win_id].winhighlight = win_highlights[mode]
end

---@param win_id integer
function highlight.unhighlight_window(win_id)
    if not api.nvim_win_is_valid(win_id) then
        return
    end

    vim.wo[win_id].winhighlight = saved_win_highlights
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
