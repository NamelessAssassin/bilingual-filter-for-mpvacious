local utils = require('custom_filter.utils')

local M = {}

-- 动态注入的语言判定函数
local check_lang = function(line)
    return false
end

M.set_rule = function(fn)
    check_lang = fn
end

local function update_scores(lines, state, menu)
    if not state.enabled or state.current_mode ~= "AUTO" then
        return
    end

    if not lines or #lines < 1 or #lines > 2 then
        return
    end

    -- 判定位置：顶部、底部或单语
    local key
    if #lines == 1 then
        key = "MONO"
    else
        local h1 = check_lang(lines[1])
        local h2 = check_lang(lines[2])
        if h1 and not h2 then
            key = "TARGET_TOP"
        elseif not h1 and h2 then
            key = "TARGET_BOTTOM"
        else
            key = "MONO"
        end
    end

    state.scores[key] = state.scores[key] + 1
    if state.scores[key] >= state.threshold then
        state.current_mode = key
        utils.notify("锁定位置：" .. state.MODES[key])
    end
    menu:maybe_refresh()
end

-- 核心提取逻辑
function M.process(text, state, menu)
    local lines = utils.split_lines(text)

    update_scores(lines, state, menu)

    if #lines <= 1 then
        return text
    end

    -- MONO 模式直接返回原文
    if state.current_mode == "MONO" then
        return text
    end

    -- 基于语言特征和位置提取
    local target_lines = {}
    for i, line in ipairs(lines) do
        if check_lang(line) -- 包含假名的行（目标语言行）必选
        -- 目标在顶部则提取奇数行，目标在底部则提取偶数行
        or (state.current_mode == "TARGET_TOP" and i % 2 == 1) or (state.current_mode == "TARGET_BOTTOM" and i % 2 == 0) then
            table.insert(target_lines, line)
        end
    end

    if #target_lines > 0 then
        return table.concat(target_lines, "\n")
    else
        return text
    end
end

return M
