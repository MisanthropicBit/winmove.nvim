local health = require("winmove.health")

describe("healthcheck", function()
    it("runs healthcheck without failing", function()
        assert.has_no_error(health.check)
    end)
end)
