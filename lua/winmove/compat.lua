-- Neovim compatibility module
local compat = {}

---@param value string
---@return boolean
function compat.has(value)
    return vim.fn.has(value) == 1
end

---@param ns_id integer
---@param opts vim.api.keyset.get_highlight
---@return vim.api.keyset.hl_info
function compat.get_hl(ns_id, opts)
    if opts.create ~= nil and not compat.has("nvim-0.10.0") then
        opts.create = nil
    end

    return vim.api.nvim_get_hl(ns_id, opts)
end

---@param tbl table
---@return boolean
function compat.tbl_islist(tbl)
  if vim.fn.has("nvim-0.10.0") == 1 then
    return vim.islist(tbl)
  end

  ---@diagnostic disable-next-line: deprecated
  return vim.tbl_islist(tbl)
end

return compat
