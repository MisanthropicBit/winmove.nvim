local swap = {}

local highlight = require("winmove.highlight")
local message = require("winmove.message")
local mode = require("winmove.mode")
local layout = require("winmove.layout")

---@type integer?
local selected_window

---@param win_id1 integer
---@param win_id2 integer
local function swap_windows(win_id1, win_id2)
    local buf1 = vim.api.nvim_win_get_buf(win_id1)
    local buf2 = vim.api.nvim_win_get_buf(win_id2)

    vim.api.nvim_win_set_buf(win_id1, buf2)
    vim.api.nvim_win_set_buf(win_id2, buf1)
end

--- Selects a window for swapping. If no window has been selected already, selects
--- it, otherwise swaps the window with the previously selected window
---@param win_id integer
function swap.swap_window(win_id)
    -- Normalize window id
    win_id = win_id == 0 and vim.api.nvim_get_current_win() or win_id

    if not selected_window then
        selected_window = win_id
        highlight.highlight_window(win_id, mode.Mode.Swap)
        return
    end

    if not vim.api.nvim_win_is_valid(selected_window) then
        message.error("Previously selected window is not valid anymore")
        return
    end

    highlight.unhighlight_window(selected_window)
    swap_windows(win_id, selected_window)
    selected_window = nil
end

---@param win_id integer
---@param dir winmove.Direction
---@return integer?
function swap.swap_window_in_direction(win_id, dir)
    local neighbor_win_id = layout.get_neighbor(dir)

    if not neighbor_win_id or win_id == neighbor_win_id then
        return nil
    end

    swap_windows(win_id, neighbor_win_id)
    vim.api.nvim_set_current_win(neighbor_win_id)

    return neighbor_win_id
end

return swap
