-- Neovim compatibility module
local compat = {}

local attributes = {
    "fg",
    "bg",
    "sp",
    "fg#",
    "bg#",
    "sp#",
    "bold",
    "italic",
    "reverse",
    "inverse",
    "standout",
    "underline",
    "undercurl",
    "underdouble",
    "underdotted",
    "underdashed",
    "strikethrough",
    "altfont",
    "nocombine",
}

local attribute_remap = {
    fg = "ctermfg",
    bg = "ctermbg",
    ["fg#"] = "fg",
    ["bg#"] = "bg",
}

local function toboolean(value)
    return value == '1' and true or false
end

local attribute_transformers = {
    bold = toboolean,
    italic = toboolean,
    reverse = toboolean,
    inverse = toboolean,
    standout = toboolean,
    underline = toboolean,
    undercurl = toboolean,
    underdouble = toboolean,
    underdotted = toboolean,
    underdashed = toboolean,
    strikethrough = toboolean,
    -- "altfont",
    -- "nocombine",
}

---@param value string
---@return boolean
function compat.has(value)
    return vim.fn.has(value) == 1
end

---@param name string
---@param attr string
---@param mode string
---@return string
local function get_hl_attribute(name, attr, mode)
    return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(name)), attr, mode)
end

--- Convert pre-0.9.0 highlight info to the newer format
---@package
---@param name string
---@return table<string, unknown>
function compat.convert_old_hl_info_to_new(name)
    local result = {}

    -- Get gui components
    for _, attr in ipairs(attributes) do
        local value = get_hl_attribute(name, attr, "gui")

        if attr == "bg#" then
            vim.print(vim.inspect({ attr, value }))
        end

        if value ~= "" then
            local _attr = attribute_remap[attr] or attr
            local transformer = attribute_transformers[attr]
            result[_attr] = transformer and transformer(value) or value
        end
    end

    vim.print(vim.inspect(result))

    -- Get cterm components
    for _, attr in ipairs(attributes) do
        if not vim.endswith(attr, "#") then
            local value = get_hl_attribute(name, attr, "cterm")
            vim.print(vim.inspect({ attr, value }))

            if value ~= "" then
                if attr ~= "fg" and attr ~= "bg" and attr ~= "sp" then
                    if not result.cterm then
                        result.cterm = {}
                    end

                    local _attr = attribute_remap[attr] or attr
                    local transformer = attribute_transformers[attr]
                    result.cterm[_attr] = transformer and transformer(value) or value
                else
                    local _attr = attribute_remap[attr] or attr
                    result[_attr] = tonumber(value)
                end
            end
        end
    end

    -- Convert rgb values to base 10 numbers
    for _, color in ipairs({ "fg", "bg" }) do
        vim.print(result[color])
        if result[color] then
            result[color] = tonumber(result[color]:sub(2), 16)
        end
    end

    return result
end

---@param ns_id integer
---@param opts vim.api.keyset.get_highlight
---@return unknown
function compat.get_hl(ns_id, opts)
    if not compat.has("nvim-0.9.0") then
        return compat.convert_old_hl_info_to_new(opts.name)
    else
        return vim.api.nvim_get_hl(ns_id, opts)
    end
end

function compat.set_hl(ns_id, name, opts)
    if opts.create ~= nil and not compat.has("nvim-0.10.0") then
        opts.create = nil
    end

    vim.api.nvim_set_hl(ns_id, name, opts)
end

return compat
