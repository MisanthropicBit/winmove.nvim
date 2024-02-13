local float = {}

local at_edge = require("winmove.at_edge")
local config = require("winmove.config")
local message = require("winmove.message")
local winutil = require("winmove.winutil")

local api = vim.api
local has_title = vim.fn.has("nvim-0.9.0") == 1

local float_win_id = nil ---@type integer?

---@class FloatOptions
---@field padding integer?
---@field width integer
---@field title_alignment string?

---@type table<string, boolean | string>
local window_options = {
    wrap = false,
    signcolumn = "no",
    foldenable = false,
}

--- Pad an array of lines and prepare each line for insertion into a buffer
---@param lines string[][]
---@param padding integer
---@return string[]
local function pad_lines(lines, padding)
    local padded_lines = {}

    if padding > 0 then
        table.insert(padded_lines, "")
    end

    local pad = (" "):rep(padding)

    for _, columns in ipairs(lines) do
        table.insert(padded_lines, pad .. table.concat(columns) .. pad)
    end

    if padding > 0 then
        table.insert(padded_lines, "")
    end

    return padded_lines
end

---@param title string | string[]
---@param lines any[]
---@param options FloatOptions?
---@return integer?
---@return integer?
local function open_centered_float(title, lines, options)
    local _options = options or {}

    -- If float exists, focus it
    if float_win_id ~= nil then
        pcall(vim.api.nvim_set_current_win, float_win_id)
        return nil, nil
    end

    local buffer = api.nvim_create_buf(false, true)
    local padding = _options.padding or 0
    local editor_width = winutil.editor_width()
    local editor_height = winutil.editor_height()
    local _lines = pad_lines(lines, padding)
    local width = _options.width + padding * 2
    local height = #lines + padding * 2

    local win_options = {
        width = math.max(width, #title + 2),
        height = height,
        row = math.floor(editor_height / 2 - height / 2),
        col = math.floor(editor_width / 2 - width / 2),
        relative = "editor",
        style = "minimal",
        border = "rounded",
    }

    if has_title then
        win_options.title = title
        win_options.title_pos = _options.title_alignment or "center"
    end

    local ok, win_id = pcall(api.nvim_open_win, buffer, false, win_options)

    if not ok then
        message.error("Failed to open help: " .. win_id)
        return
    end

    vim.bo[buffer].filetype = "winmove_help"
    api.nvim_buf_set_lines(buffer, 0, -1, true, _lines)

    -- The winhighlight option can leak into other windows although it is
    -- supposed to be local to the window:
    -- https://github.com/neovim/neovim/issues/18283
    vim.wo[win_id].winhighlight = ""

    for option, value in pairs(window_options) do
        api.nvim_win_set_option(win_id, option, value)
    end

    return win_id, buffer
end

--- Open a float that displays help for the current mode
---@param mode winmove.Mode
function float.open_help(mode)
    local lines = {}
    local keymaps = config.keymaps[mode]
    local max_widths = {}
    local spacing = (" "):rep(4)

    for action, target in pairs(keymaps) do
        local desc_mode = action ~= "help_close" and mode or nil
        local desc = config.get_keymap_description(action, desc_mode)
        local line = { target, spacing, desc }

        table.insert(lines, line)

        for idx, col in ipairs(line) do
            max_widths[idx] = math.max(max_widths[idx] or 0, #col)
        end
    end

    -- Sort lines by the lhs mapping
    table.sort(lines, function(a, b)
        return a[1] < b[1]
    end)

    vim.list_extend(lines, {
        {},
        {
            config.keymaps["help_close"],
            spacing,
            config.get_keymap_description("help_close"),
        },
    })

    -- Adjust padding for each line to align each column
    for idx, chunk in ipairs(lines) do
        for col, line in ipairs(chunk) do
            local adjusted_line = line .. (" "):rep(max_widths[col] - #line)
            lines[idx][col] = adjusted_line
        end
    end

    local title = "Help for " .. mode .. " mode"

    local win_id, buffer = open_centered_float(title, lines, {
        padding = 1,
        width = max_widths[1] + max_widths[2] + max_widths[3],
    })

    if win_id == nil or buffer == nil then
        return
    end

    -- Set the float_win_id *before* entering the help window so the WinEnter
    -- autocmd set when starting a mode can use it
    float_win_id = win_id
    api.nvim_set_current_win(win_id)

    ---@diagnostic disable-next-line: param-type-mismatch
    api.nvim_buf_set_keymap(buffer, "n", config.keymaps["help_close"], "", {
        desc = config.get_keymap_description("help_close"),
        callback = float.close,
    })
end

function float.close()
    -- TODO: Should we explicitly set the window to the parent window here?
    pcall(vim.api.nvim_win_close, float_win_id, true)
    float_win_id = nil
end

--- Dettach a floating window by changing its 'relative' property to 'editor' so it
--- can be moved around freely
---@param win_id integer
function float.dettach(win_id, win_config)
    if not float.is_floating_window(win_id) then
        error(("Not a floating window: %d"):format(win_id))
    end

    if win_config.relative == "editor" then
        return win_config.row[vim.val_idx], win_config.col[vim.val_idx]
    elseif win_config.relative == "win" then
        win_config.relative = "editor"
        local win_row, win_col = unpack(vim.fn.win_screenpos(win_id))

        -- Calculate global screen positions
        local row = win_row + win_config.bufpos[1] + win_config.row[vim.val_idx] + 1
        local col = win_col + win_config.bufpos[2] + win_config.col[vim.val_idx]

        return row, col
    elseif win_config.relative == "cursor" then
    elseif win_config.relative == "mouse" then
    end
end

function float.get_wraparound_position(dir, row, col, win_config)
    if winutil.is_horizontal(dir) then
        if dir == "h" then
            vim.print({ row, winutil.editor_width() - win_config.width })
            return row - 1, winutil.editor_width() - win_config.width
        else
            return row - 1, 0
        end
    else
        if dir == "j" then
            return 0, col - 1
        else
            -- TODO: Use zero or do we need to account for the tabline?
            return winutil.editor_bottom() - win_config.height - 1, col - 1
        end
    end
end

function float.is_at_edge(dir, row, col, win_config)
    if dir == "h" then
        return col <= 1
    elseif dir == "j" then
        return row + win_config.height >= winutil.editor_bottom() - 1
    elseif dir == "k" then
        return row <= 1
    elseif dir == "l" then
        return col + win_config.width >= winutil.editor_width() - 1
    end
end

function float.move_window(win_id, dir, count)
    local row, col = unpack(vim.fn.win_screenpos(win_id))
    local win_config = vim.api.nvim_win_get_config(win_id)

    if float.is_at_edge(dir, row, col, win_config) then
        local edge_type = winutil.is_horizontal(dir) and "horizontal" or "vertical"
        local behaviour = config.at_edge[edge_type]

        if not behaviour then
            return
        end

        row, col = float.get_wraparound_position(dir, row, col, win_config)
    else
        local dy, dx = 0, 0

        if winutil.is_horizontal(dir) then
            dx = dir == "l" and 1 or -1
        else
            dy = dir == "j" and 1 or -1
        end

        row, col = row + dy * count - 1, col + dx * count - 1
    end

    -- See lua-special-tbl for the row/col values
    local new_win_config = {
        row = row,
        col = col,
        relative = "editor",
    }

    vim.api.nvim_win_set_config(win_id, new_win_config)
end

function float.move_window_far(win_id, dir)

end

---@param win_id integer
---@return boolean
function float.is_floating_window(win_id)
    vim.print(win_id)
    local win_config = vim.api.nvim_win_get_config(win_id)

    return win_config and (win_config.relative ~= "" or not win_config.relative)
end

---@param win_id integer
---@return boolean
function float.is_help_window(win_id)
    return float_win_id == win_id
end

return float
