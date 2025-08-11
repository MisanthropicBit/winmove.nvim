describe("State", function()
    local State = require("winmove.state")

    it("updates and resets state, gets properties", function()
        local state = State.new()

        assert.are.same(state:get("mode"), nil)
        assert.are.same(state:get("win_id"), nil)
        assert.are.same(state:get("bufnr"), nil)

        state:update({
            mode = "move",
            win_id = 1000,
            bufnr = 3,
        })

        assert.are.same(state:get("mode"), "move")
        assert.are.same(state:get("win_id"), 1000)
        assert.are.same(state:get("bufnr"), 3)

        state:reset()

        assert.are.same(state:get("mode"), nil)
        assert.are.same(state:get("win_id"), nil)
        assert.are.same(state:get("bufnr"), nil)
    end)
end)
