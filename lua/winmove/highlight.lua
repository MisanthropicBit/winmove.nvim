-- Convert to use nvim_win_set_hl_ns when we have nvim_win_get_hl_ns:
-- https://github.com/neovim/neovim/issues/24309

local highlight = {}

local config = require("winmove.config")
local string_util = require("winmove.util.string")

local api = vim.api

-- Window higlights per mode
local win_highlights = {
    move = {},
    resize = {},
}

local saved_win_highlights = nil

-- Highlight groups to create winmove versions of
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

--- Process a color definition, getting either the rgb true color or terminal
--- color, whichever is available
---@param color { guifg?: integer, guibg?: integer, ctermfg?: string, ctermbg?: string }
---@param type "fg" | "bg"
---@return string
local function process_color(color, type)
    local truecolor = color[type] ---@cast truecolor integer

    if truecolor then
        return rgb_as_hex(colors_number_to_rgb(truecolor))
    end

    ---@diagnostic disable-next-line:return-type-mismatch
    return color["cterm" .. type]
end

--- Get a highlight's colors
---@param name string
---@return table
local function get_highlight(name)
    local id = vim.fn.synIDtrans(api.nvim_get_hl_id_by_name(name))

    vim.print("before", colors)
    colors.fg = process_color(colors, "fg")
    colors.bg = process_color(colors, "bg")
    vim.print("after", colors)

    return colors
end

--- Set highlight for a group
---@param group string
---@param colors { fg: string, bg: string }
local function set_highlight(group, colors)
    local gui = vim.o.termguicolors and "gui" or ""
    vim.print(group, colors)

    vim.cmd(
        ("hi default %s %s %s"):format(
            group,
            colors.fg and (gui .. "fg=" .. colors.fg) or "",
            colors.bg and (gui .. "bg=" .. colors.bg) or ""
        )
    )
end

---@param win_id integer
---@param mode winmove.Mode
function highlight.highlight_window(win_id, mode)
    if not api.nvim_win_is_valid(win_id) or mode == "none" then
        return
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

--- Generate group highlights for a mode
---@param mode winmove.Mode
---@param groups string[]
local function generate_highlights(mode, groups)
    local highlights = {}
    local color = config.highlights[mode] -- get_highlight(config.highlights[mode])

    -- TODO: Support custom highlights if config.highlights[mode] is a table
    for _, group in ipairs(groups) do
        local titlecase_mode = string_util.titlecase(mode)
        local winmove_group = "Winmove" .. titlecase_mode .. group

        vim.cmd(("hi default link %s %s"):format(winmove_group, color))

        -- set_highlight(winmove_group, color)
        table.insert(highlights, ("%s:%s"):format(group, winmove_group))
    end

    return table.concat(highlights, ",")
end

function highlight.setup()
    win_highlights.move = generate_highlights("move", highlight_groups)
    win_highlights.resize = generate_highlights("resize", highlight_groups)

    -- -- TODO: Handle changing colorscheme during active modes
    -- api.nvim_create_autocmd("Colorscheme", {
    --     pattern = "*",
    --     desc = "Update Winmove highlights when colorscheme is changed",
    --     callback = highlight.setup,
    -- })
end

highlight.setup()

return highlight
