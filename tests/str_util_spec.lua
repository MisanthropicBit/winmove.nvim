local str = require("winmove.util.str")

describe("string utilities", function()
    describe("str.titlecase", function()
        it("converts to titlecase", function()
            assert.are.same(str.titlecase("title"), "Title")
            assert.are.same(str.titlecase("TiTlE"), "Title")
        end)
    end)

    -- TODO: Add test case for str.has_prefix only if we do not remove the :Winmove command
end)
