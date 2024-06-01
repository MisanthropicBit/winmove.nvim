local test_helpers = {}

local say = require("say")

local has_luassert, luassert = pcall(require, "luassert")

if not has_luassert then
    error("Luassert library not found")
end

---@param buffer integer
---@return table
function test_helpers.get_buf_mapped_keymaps(buffer)
    local all_keymaps = vim.api.nvim_buf_get_keymap(buffer, "n")
    local keymaps = {}

    for _, map in ipairs(all_keymaps) do
        keymaps[map.lhs] = {
            rhs = map.rhs or "",
            expr = map.expr,
            callback = map.callback,
            noremap = map.noremap,
            script = map.script,
            silent = map.silent,
            nowait = map.nowait,
            desc = map.desc,
        }
    end

    return keymaps
end

-- A skeleton window layout that only contains the shape of the desired
-- window layout without any window IDs
---@alias SkeletonLeaf string
---@alias SkeletonRow { [1]: "row", [2]: SkeletonWinLayout[] }
---@alias SkeletonCol { [1]: "col", [2]: SkeletonWinLayout[] }
---@alias SkeletonWinLayout string | SkeletonRow | SkeletonCol

---@param layout SkeletonWinLayout
---@return table<string, integer>
function test_helpers.make_layout(layout)
    local win_ids = {}

    local function _make_layout(sublayout, level)
        local type = type(sublayout) == "string" and sublayout or sublayout[1]

        if type == "row" or type == "col" then
            local subtrees = sublayout[2]

            if #subtrees < 2 then
                error(("Tree of type %s at level %d only has one child"):format(type, level))
            end

            local new_win_type = type == "row" and "vnew" or "new"
            local new_win_ids = { vim.api.nvim_get_current_win() }

            -- Start by creating the subtrees for this node
            for _ = 1, #subtrees - 1 do
                vim.cmd("belowright " .. new_win_type)
                table.insert(new_win_ids, vim.api.nvim_get_current_win())
            end

            for idx, subtree in ipairs(subtrees) do
                vim.api.nvim_set_current_win(new_win_ids[idx])
                _make_layout(subtree, level + 1)
            end
        else
            -- Save leaves not labelled as "leaf" for testing
            if type ~= "leaf" then
                win_ids[type] = vim.api.nvim_get_current_win()
            end
        end
    end

    _make_layout(layout, 0)

    return win_ids
end

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
    ---@param _tree1 ConcreteWinLayout
    ---@param _tree2 AbstractWinLayout
    local function _compare_tree(_tree1, _tree2, level)
        local type1, data1 = _tree1[1], _tree1[2]
        local type2, data2 = _tree2[1], _tree2[2]

        if type1 ~= type2 then
            return false
        end

        if type1 == "leaf" then
            if data2 ~= nil and data1 ~= data2 then
                return false
            end
        else
            if #data2 < 2 then
                error(
                    ("Abstract tree of type %s at level %d only has one child"):format(type1, level)
                )
            end

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
    end

    return _compare_tree(tree1, tree2, 0) == nil and true or false
end

---@param _ any
---@param arguments { [1]: ConcreteWinLayout, [2]: AbstractWinLayout }
local function matches_winlayout(_, arguments)
    if #arguments ~= 2 then
        error("matches_winlayout expected two table arguments")
    end

    local actual_layout = arguments[1]
    local expected_layout = arguments[2]

    if not type(actual_layout) == "table" and not type(expected_layout) == "table" then
        error("matches_winlayout expected two table arguments")
    end

    return compare_tree(actual_layout, expected_layout)
end

say:set("assertion.matches_winlayout.positive", "Expected %s \nto match window layout: %s")

luassert:register(
    "assertion",
    "matches_winlayout",
    matches_winlayout,
    "assertion.matches_winlayout.positive"
)

return test_helpers
