local lualine_require = require("lualine_require")

local M = lualine_require.require("lualine.component"):extend()

---@class winmove.LuaLineComponentModeOptions
---@field move   { icon: string? }
---@field swap   { icon: string? }
---@field resize { icon: string? }

---@class winmove.LuaLineComponentFormatterContext
---@field mode winmove.Mode?
---@field icon string?

---@class winmove.LuaLineComponentOptions
---@field modes winmove.LuaLineComponentModeOptions
---@field formatter fun(context: winmove.LuaLineComponentFormatterContext): string?

local default_options = {
    modes = {
        move = {
            icon = "󰆾",
        },
        swap = {
            icon = "󰓡",
        },
        resize = {
            icon = "󰩨",
        },
    },
    ---@param context winmove.LuaLineComponentFormatterContext
    formatter = function(context)
        if not context.mode then
            -- Do not show anything if no mode is currently active
            return nil
        else
            return ("%s%s mode active"):format(
                context.icon and context.icon .. " " or "",
                context.mode
            )
        end
    end,
}

function M:init(options)
    M.super.init(self, options)

    self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)
    self.mode = nil

    local autocmd_group = vim.api.nvim_create_augroup("winmove.lualine.component", {})

    vim.api.nvim_create_autocmd("User", {
        pattern = { "WinmoveModeStart", "WinmoveModeEnd" },
        desc = "Update the lualine winmove component when a mode starts or ends",
        group = autocmd_group,
        ---@param event { match: string, data: { mode: winmove.Mode } }
        callback = function(event)
            if event.match == "WinmoveModeStart" then
                self.mode = event.data.mode
            else
                self.mode = nil
            end
        end,
    })
end

function M:update_status()
    local context =
        vim.tbl_extend("force", self.options.modes[self.mode] or {}, { mode = self.mode })

    return self.options.formatter(context)
end

return M
