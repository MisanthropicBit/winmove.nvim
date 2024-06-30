local message = require("winmove.message")
local stub = require("luassert.stub")
local winmove = require("winmove")

describe("init", function()
    it("starts and stops a mode", function()
        -- Split a window so we can start move mode
        vim.cmd.split()

        winmove.start_mode(winmove.Mode.Move)
        assert.are.same(winmove.current_mode(), winmove.Mode.Move)

        winmove.stop_mode()
        assert.is_nil(winmove.current_mode())
    end)

    it("fails to stop mode if no mode is currently active", function()
        stub(message, "error")

        winmove.stop_mode()

        assert.stub(message.error).was.called_with("No mode is currently active")
        message.error:revert()
    end)
end)
