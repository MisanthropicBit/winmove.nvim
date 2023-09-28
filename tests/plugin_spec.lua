local winmove = require("winmove")
local vader = require("winmove.util.vader")
local stub = require("luassert.stub")

local given = vader.given

describe("plugin", function()
    before_each(function()
        stub(vim.api, "nvim_echo")
    end)

    after_each(function()
        vim.api.nvim_echo:revert()
    end)

    describe("commands", function()
        it("prints version", function()
            local version = vim.fn.execute("Winmove version", "")
            local match = version:gsub("%s+", ""):match([[^%d+%.%d+%.%d+$]])

            assert.are.same(match == winmove.version(), true)
        end)

        it("starts move mode", function()
            given("", function()
                vim.cmd("new") -- Create another buffer to activate move mode
                vim.cmd("Winmove move")

                assert.are.same(winmove.current_mode(), "move")

                vim.cmd("Winmove quit")
            end)
        end)

        it("starts resize mode", function()
            given("", function()
                vim.cmd("new") -- Create another buffer to activate resize mode
                vim.cmd("Winmove resize")

                assert.are.same(winmove.current_mode(), "resize")

                vim.cmd("Winmove quit")
            end)
        end)

        it("handles invalid arguments", function()
            vim.cmd("Winmove nope")

            assert.stub(vim.api.nvim_echo).was.called_with({
                { "[winmove.nvim]:", "ErrorMsg" },
                { " Invalid argument 'nope'" },
            }, true, {})
        end)
    end)
end)
