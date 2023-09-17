local health = {}

local config = require("winmove.config")

function health.check()
    vim.health.report_start("winmove")

    if vim.fn.has("nvim-0.5.0") == 1 then
        vim.health.report_ok("Has neovim 0.5.0+")
    else
        vim.health.report_error("winmove.nvim requires at least neovim 0.5.0")
    end

    local ok, error = config.validate(config)

    if not ok then
        vim.health.report_error("config has errors: " .. error)
    else
        vim.health.report_ok("found no errors in config")
    end
end

return health
