local State = require("winmove.state")

describe("State", function()
    it("updates and resets state, gets properties", function()
        local state = State.new()

        assert.are.same(state:get("mode"), nil)
        assert.are.same(state:get("win_id"), nil)
        assert.are.same(state:get("bufnr"), nil)
        assert.are.same(state:get("saved_keymaps"), nil)

        state:update({
            mode = "move",
            win_id = 1000,
            bufnr = 3,
            saved_keymaps = {},
        })

        assert.are.same(state:get("mode"), "move")
        assert.are.same(state:get("win_id"), 1000)
        assert.are.same(state:get("bufnr"), 3)
        assert.are.same(state:get("saved_keymaps"), {})

        state:reset()

        assert.are.same(state:get("mode"), nil)
        assert.are.same(state:get("win_id"), nil)
        assert.are.same(state:get("bufnr"), nil)
        assert.are.same(state:get("saved_keymaps"), nil)
    end)
end)
