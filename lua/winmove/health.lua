local health = {}

local config = require("winmove.config")

local min_neovim_version = "0.9.0"

function health.check()
    vim.health.report_start("winmove")

    if vim.fn.has("nvim-" .. min_neovim_version) == 1 then
        vim.health.report_ok(("has neovim %s+"):format(min_neovim_version))
    else
        vim.health.report_error("winmove.nvim requires at least neovim " .. min_neovim_version)
    end

    local ok, error = config.validate(config)

    if ok then
        vim.health.report_ok("found no errors in config")
    else
        vim.health.report_error("config has errors: " .. error)
    end
end

return health
