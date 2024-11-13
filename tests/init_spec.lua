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

    it("validates arguments of start_mode", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.start_mode("hello")
        end, "mode: expected a valid mode (move, swap), got hello")
    end)

    it("fails to stop mode if no mode is currently active", function()
        stub(message, "error")

        winmove.stop_mode()

        assert.stub(message.error).was.called_with("No mode is currently active")

        ---@diagnostic disable-next-line: undefined-field
        message.error:revert()
    end)

    it("validates arguments of move_window", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.move_window(true, "j")
        end, "win_id: expected a non-negative number, got true")

        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.move_window(1000, 1)
        end, "dir: expected a valid direction, got 1")
    end)

    it("validates arguments of split_into", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.split_into(true, "j")
        end, "win_id: expected a non-negative number, got true")

        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.split_into(1000, 1)
        end, "dir: expected a valid direction, got 1")
    end)

    it("validates arguments of move_window_far", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.move_window_far(true, "j")
        end, "win_id: expected a non-negative number, got true")

        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.move_window_far(1000, 1)
        end, "dir: expected a valid direction, got 1")
    end)

    it("validates arguments of swap_window_in_direction", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.swap_window_in_direction(true, "j")
        end, "win_id: expected a non-negative number, got true")

        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.swap_window_in_direction(1000, 1)
        end, "dir: expected a valid direction, got 1")
    end)

    it("validates arguments of swap_window", function()
        assert.has_error(function()
            ---@diagnostic disable-next-line: param-type-mismatch
            winmove.swap_window(true)
        end, "win_id: expected a non-negative number, got true")
    end)
end)
