local swap = {}

local highlight = require("winmove.highlight")
local message = require("winmove.message")
local mode = require("winmove.mode")

---@type integer?
local selected_window

---@param win_id1 integer
---@param win_id2 integer
local function swap_windows(win_id1, win_id2)
    local buf1 = vim.api.nvim_win_get_buf(win_id1)
    local buf2 = vim.api.nvim_win_get_buf(win_id2)

    -- Save views before switching buffers
    vim.api.nvim_set_current_win(win_id1)
    local view1 = vim.fn.winsaveview()

    vim.api.nvim_set_current_win(win_id2)
    local view2 = vim.fn.winsaveview()

    -- Set buffers and restore views
    vim.api.nvim_win_set_buf(win_id2, buf1)
    vim.fn.winrestview(view1)

    vim.api.nvim_set_current_win(win_id1)
    vim.api.nvim_win_set_buf(win_id1, buf2)
    vim.fn.winrestview(view2)
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
        selected_window = nil
        message.error("Previously selected window is not valid anymore")
        return
    elseif win_id == selected_window then
        selected_window = nil
        message.error("Cannot swap selected window with itself")
        return
    end

    highlight.unhighlight_window(selected_window)
    swap_windows(win_id, selected_window)
    selected_window = nil
end

---@param win_id integer
---@param target_win_id integer
function swap.swap_window_in_direction(win_id, target_win_id)
    swap_windows(win_id, target_win_id)
    vim.api.nvim_set_current_win(target_win_id)
end

return swap
