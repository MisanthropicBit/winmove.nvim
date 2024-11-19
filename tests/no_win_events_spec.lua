local winmove = require("winmove")
local winutil = require("winmove.winutil")
local vader = require("winmove.util.vader")

local given = vader.given

describe("no window events", function()
    local events = winutil.get_ignored_events()
    local triggers = {}
    local autocmd_ids = {}

    before_each(function()
        triggers = {}
        autocmd_ids = {}
    end)

    after_each(function()
        for _, autocmd_id in ipairs(autocmd_ids) do
            pcall(vim.api.nvim_del_autocmd, autocmd_id)
        end
    end)

    it("does not trigger any window events when moving", function()
        given(function()
            vim.cmd.vnew()

            -- Set up autocmds *after* splitting
            for _, event in ipairs(events) do
                local autocmd_id = vim.api.nvim_create_autocmd(event, {
                    callback = function()
                        triggers[event] = true
                    end,
                })

                table.insert(autocmd_ids, autocmd_id)
            end

            winmove.move_window(vim.api.nvim_get_current_win(), "h")

            assert.are.same(triggers, {})
        end)
    end)

    it("does not trigger any window events when swapping", function()
        given(function()
            vim.cmd.vnew()

            -- Set up autocmds *after* splitting
            for _, event in ipairs(events) do
                local autocmd_id = vim.api.nvim_create_autocmd(event, {
                    callback = function()
                        triggers[event] = true
                    end,
                })

                table.insert(autocmd_ids, autocmd_id)
            end

            winmove.swap_window_in_direction(vim.api.nvim_get_current_win(), "h")

            assert.are.same(triggers, {})
        end)
    end)
end)
