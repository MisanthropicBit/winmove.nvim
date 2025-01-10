---@param command string
---@param args string[]
---@return string
local function run_command(command, args)
    local result = vim.fn.system(vim.list_extend({ command }, args))

    if vim.v.shell_error ~= 0 then
        error("Failed to run command")
    end

    return result
end

-- Path for the plugin being tested
vim.opt.rtp:append(".")

local lua_path = run_command("luarocks", { "path", "--lr-path" })
local lua_cpath = run_command("luarocks", { "path", "--lr-cpath" })

-- Paths for the project-local luarocks packages
package.path = package.path .. ";" .. lua_path

-- Paths for the project-local shared libraries
package.cpath = package.cpath .. ";" .. lua_cpath

require("busted.runner")({ standalone = false })
