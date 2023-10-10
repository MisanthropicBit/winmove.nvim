-- Testing tools inspired by the awesome vader.vim and based on
-- the fine ideas from:
-- https://github.com/Julian/lean.nvim/blob/main/lua/tests/helpers.lua

local vader = {}

local has_luassert, luassert = pcall(require, "luassert")

if not has_luassert then
    error("Luassert library not found")
end

local say = require("say")

---@diagnostic disable-next-line:unused-local
local function expect_buffer(description, state, arguments)
    luassert.are.same(state, arguments)
end

say:set("assertion.expect_buffer.positive", "Expected %s to %s in buffer \n but got %s")
say:set("assertion.expect_buffer.negative", "Expected %s to %s in buffer \nto didn't get %s")

luassert:register(
    "assertion",
    "expect_buffer",
    expect_buffer,
    "assertion.expect_buffer.positive",
    "assertion.expect_buffer.negative"
)

-- A concrete window layout is the one returned by vim.fn.winlayout
---@alias ConcreteLeaf { [1]: "leaf", [2]: integer } # "lol"
---@alias ConcreteRow { [1]: "row", [2]: ConcreteWinLayout[] }
---@alias ConcreteCol { [1]: "col", [2]: ConcreteWinLayout[] }
---@alias ConcreteWinLayout ConcreteLeaf | ConcreteRow | ConcreteCol

-- An abstract window layout is used in comparison with a concrete one where
-- we do not want to specify window IDs for every window in the abstract layout
---@alias AbstractLeaf { [1]: "leaf", [2]: integer? }
---@alias AbstractRow { [1]: "row", [2]: AbstractWinLayout[] }
---@alias AbstractCol { [1]: "col", [2]: AbstractWinLayout[] }
---@alias AbstractWinLayout AbstractLeaf | AbstractRow | AbstractCol

--- Compare two trees (window layouts)
---@param tree1 ConcreteWinLayout
---@param tree2 AbstractWinLayout
---@return boolean
local function compare_tree(tree1, tree2)
    local type1, data1 = tree1[1], tree1[2]
    local type2, data2 = tree2[1], tree2[2]

    if type1 ~= type2 then
        return false
    end

    if type1 == "leaf" then
        if data1 ~= nil and data1 ~= data2 then
            return false
        end
    else
        if #data1 ~= #data2 then
            return false
        end

        ---@cast data1 -integer
        for idx, child in ipairs(data1) do
            ---@cast data2 -?, -integer
            if not compare_tree(child, data2[idx]) then
                return false
            end
        end
    end

    return true
end

local function matches_winlayout(_, arguments)
    if #arguments ~= 2 then
        error("matches_winlayout expected two table arguments")
    end

    local actual_layout = arguments[1]
    local expected_layout = arguments[2]

    if not type(actual_layout) == "table" and not type(expected_layout) == "table" then
        error("matches_winlayout expected two table arguments")
    end

    return compare_tree(expected_layout, actual_layout)
end

say:set("assertion.matches_winlayout.positive", "Expected %s \nto match window layout: %s")
assert:register(
    "assertion",
    "matches_winlayout",
    matches_winlayout,
    "assertion.matches_winlayout.positive"
)

--- Create a new buffer with the given contents and run the callback
--- in that buffer
---@param ... any
function vader.given(...)
    local description, contents, callback
    local numargs = select("#", ...)

    if numargs < 2 then
        error("vader.given takes at least 2 arguments")
    elseif numargs == 2 then
        contents, callback = ...
    elseif numargs == 3 then
        description, contents, callback = ...
    end

    local bufnr = vim.api.nvim_create_buf(false, false)

    if bufnr == 0 then
        error("Failed to create stratch buffer for testing")
    end

    vim.api.nvim_set_current_buf(bufnr)
    vim.opt_local.bufhidden = "hide"
    vim.opt_local.swapfile = false

    if #contents > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, contents)
    end

    -- TODO: Add custom formatter here?
    vim.api.nvim_buf_call(bufnr, function()
        callback({ bufnr = bufnr, win_id = vim.api.nvim_get_current_win() })
    end)

    -- Clean up all open buffers to ensure test isolation
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        pcall(vim.api.nvim_buf_delete, buffer, { force = true })
    end
end

--- Run normal mode commands without mappings
---@param input string
---@param use_mappings? boolean
function vader.normal(input, use_mappings)
    local bang = use_mappings and "!" or ""
    vim.cmd(vim.api.nvim_replace_termcodes("normal" .. bang .. " " .. input, true, false, true))
end

function vader.expect(contents, bufnr)
    local actual_contents = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, true)

    expect_buffer("", actual_contents, contents)

    -- luassert.are.same(actual_contents, contents)
end

-- A skeleton window layout that only contains the shape of the desired
-- window layout without any window IDs
---@alias SkeletonLeaf string
---@alias SkeletonRow { [1]: "row", [2]: SkeletonWinLayout[] }
---@alias SkeletonCol { [1]: "col", [2]: SkeletonWinLayout[] }
---@alias SkeletonWinLayout string | SkeletonRow | SkeletonCol

---@param layout SkeletonWinLayout
function vader.make_layout(layout)
    local win_ids = {}

    local function _make_layout(sublayout)
        local type = type(sublayout) == "string" and sublayout or sublayout[1]

        if type == "row" or type == "col" then
            local subtrees = sublayout[2]
            local new_win_type = type == "row" and "vnew" or "new"
            local new_win_ids = { vim.api.nvim_get_current_win() }

            -- Start by creating the subtrees for this node
            for _ = 1, #subtrees - 1 do
                vim.cmd("belowright " .. new_win_type)
                table.insert(new_win_ids, vim.api.nvim_get_current_win())
            end

            for idx, subtree in ipairs(subtrees) do
                vim.api.nvim_set_current_win(new_win_ids[idx])
                _make_layout(subtree)
            end
        else
            -- Save leaves not labelled as "leaf" for testing
            if type ~= "leaf" then
                win_ids[type] = vim.api.nvim_get_current_win()
            end
        end
    end

    _make_layout(layout)

    return win_ids
end

return vader
