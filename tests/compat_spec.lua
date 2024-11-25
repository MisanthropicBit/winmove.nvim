local compat = require("winmove.compat")

describe("compat", function()
    it("converts pre-0.9.0 highlight info to newer format", function()
        vim.cmd.colorscheme("vim")

        ---@diagnostic disable-next-line: invisible
        local result = compat.convert_old_hl_info_to_new("TabLine")

        assert.are.same(result, {
            bg = 11119017,
            cterm = {
                underline = true
            },
            ctermbg = 242,
            ctermfg = 15,
            underline = true
        })
    end)
end)
