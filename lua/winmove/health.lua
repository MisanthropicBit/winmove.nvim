local health = {}

local compat = require("winmove.compat")
local config = require("winmove.config")

local min_neovim_version = "0.8.0"

local report_start, report_ok, report_error

if compat.has("nvim-0.10") then
    report_start = vim.health.start
    report_ok = vim.health.ok
    report_error = vim.health.error
else
    ---@diagnostic disable-next-line: deprecated
    report_start = vim.health.report_start
    ---@diagnostic disable-next-line: deprecated
    report_ok = vim.health.report_ok
    ---@diagnostic disable-next-line: deprecated
    report_error = vim.health.report_error
    ---@diagnostic disable-next-line: deprecated
end

function health.check()
    report_start("winmove")

    if compat.has("nvim-" .. min_neovim_version) then
        report_ok(("has neovim %s+"):format(min_neovim_version))
    else
        report_error("winmove.nvim requires at least neovim " .. min_neovim_version)
    end

    local ok, error = config.validate(config)

    if ok then
        report_ok("found no errors in config")
    else
        report_error("config has errors: " .. error)
    end
end

return health
