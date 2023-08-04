local health = {}

function health.check()
    vim.health.report_start("winmove")

    local has_bit, _ = pcall(require, "bit")

    if not has_bit then
        vim.health.report_warn(
            "A bit library is not available: Cannot use rgb hex colors (like \"#3d59a1\") for highlighting windows.", {
            "Build neovim with luajit",
            "Use neovim v0.9.0+ which includes a bit library",
        })
    else
        vim.health.report_ok("A bit library is available")
    end

    if not vim.fn.win_splitmove then
        vim.health.report_error("win_splitmove not available")
    else
        vim.health.report_ok("win_splitmove is available")
    end
end

return health
