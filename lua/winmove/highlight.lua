-- Convert to use nvim_win_set_hl_ns when we have nvim_win_get_hl_ns:
-- https://github.com/neovim/neovim/issues/24309

local highlight = {}

local has_bit, bit = pcall(require, "bit")
local config = require("winmove.config")

local api = vim.api

local win_highlights = {
    move = {},
    resize = {},
}
local saved_win_highlights = nil

local groups = {
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

local function bit_warn()
    api.nvim_echo({{
        "Cannot use highlight group without bit library",
        "Warning",
    }}, false, {})
end

local function colors_number_to_rgb(color)
    local r = bit.band(bit.rshift(color, 16), 0xff)
    local g = bit.band(bit.rshift(color, 8), 0xff)
    local b = bit.band(bit.rshift(color, 0), 0xff)

    return r, g, b
end

local function rgb_as_hex(r, g, b)
    return ("#%02x%02x%02x"):format(r, g, b)
end

local function process_true_color(truecolor, termcolor)
    if truecolor then
        if not has_bit and not termcolor then
            bit_warn()

            return termcolor
        end

        return rgb_as_hex(colors_number_to_rgb(truecolor))
    end

    return termcolor
end

--- Get a highlight's colors
---@param name string
---@return table | nil
local function get_highlight(name)
    local colors = api.nvim_get_hl(0, { name = name, link = false })

    colors.fg = process_true_color(colors.fg, colors.ctermfg)
    colors.bg = process_true_color(colors.bg, colors.ctermbg)

    return colors
end

local function set_highlight(group, colors)
    local gui = vim.o.termguicolors and "gui" or ""

    vim.cmd(("hi default %s %s %s"):format(
        group,
        colors.fg and (gui .. "fg=" .. colors.fg) or "",
        colors.bg and (gui .. "bg=" .. colors.bg) or ""
    ))
end

---@param win_id integer
---@param mode winmove.Mode
function highlight.highlight_window(win_id, mode)
    if not api.nvim_win_is_valid(win_id) or mode == 0 then
        return
    end

    saved_win_highlights = vim.wo[win_id].winhighlight
    vim.wo[win_id].winhighlight = win_highlights[mode]
end

---@param win_id integer
function highlight.unhighlight_window(win_id)
    vim.wo[win_id].winhighlight = saved_win_highlights
end

function highlight.setup()
    for _, mode in pairs({ "move", "resize" }) do
        local color = get_highlight(config.highlights[mode])

        for _, group in ipairs(groups) do
            local _mode = mode == "move" and "Move" or "Resize"
            local winmove_group  = "Winmove" .. _mode .. group
            set_highlight(winmove_group, color)
            table.insert(win_highlights[mode], ("%s:%s"):format(group, winmove_group))
        end
    end

    ---@diagnostic disable-next-line:param-type-mismatch
    win_highlights.move = table.concat(win_highlights.move, ",")

    ---@diagnostic disable-next-line:param-type-mismatch
    win_highlights.resize = table.concat(win_highlights.resize, ",")

    -- TODO: Handle changing colorscheme during active modes
    api.nvim_create_autocmd("Colorscheme", {
        pattern = "*",
        desc = "Update Winmove highlights when colorscheme is changed",
        callback = highlight.setup,
    })
end

highlight.setup()

return highlight
