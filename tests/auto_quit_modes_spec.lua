describe("auto-quit mode", function()
    local winmove = require("winmove")
    local vader = require("winmove.util.vader")

    local given = vader.given

    it("quits current mode when entering a new window", function()
        given(function()
            vim.cmd.vnew()
            winmove.start_mode(winmove.Mode.Move)
            assert.are.same(winmove.current_mode(), winmove.Mode.Move)

            vim.cmd.new()
            assert.are.same(winmove.current_mode(), nil)
        end)
    end)

    it("quits current mode when entering insert mode", function()
        given(function()
            vim.cmd.vnew()
            winmove.start_mode(winmove.Mode.Move)
            assert.are.same(winmove.current_mode(), winmove.Mode.Move)

            vim.cmd.norm([[i]])
            assert.are.same(winmove.current_mode(), nil)
        end)
    end)
end)
