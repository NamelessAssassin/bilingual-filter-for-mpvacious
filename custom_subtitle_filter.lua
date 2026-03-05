local utils = require('custom_filter.utils')
local state = require('custom_filter.state')
local extractor = require('custom_filter.subtitle_extractor')
local menu = require('custom_filter.menu.filter_menu')
local language_rules = require('custom_filter.language_rules')

local M = {}

-- 在 init 中初始化
local get_current_profile_mode = function()
    return nil
end

local function check_profile_activity(profile_mode)
    return profile_mode ~= nil and profile_mode:lower() ~= "none"
end

local function get_display_info()
    local profile_mode = get_current_profile_mode()
    return {
        is_profile_active = check_profile_activity(profile_mode),
        title_prefix = language_rules.get_title_prefix(profile_mode)
    }
end

-- 主过滤入口
M.preprocess = function(text)
    -- 基础状态检查
    if not state.enabled or text == "" then
        return text
    end

    local profile_mode = get_current_profile_mode()

    local is_profile_active = check_profile_activity(profile_mode)
    if not is_profile_active then
        return text
    end

    if state.current_mode == "MONO" then
        return text
    end

    local check_lang = language_rules.get_rule(profile_mode)

    -- 注入探测逻辑，并执行过滤
    extractor.set_rule(check_lang)
    return extractor.process(text, state, menu)
end

-- 初始化
M.init = function(config)
    if type(config.get_mode) == "function" then
        get_current_profile_mode = config.get_mode
    end

    -- 初始化菜单
    menu:init({
        state = state,
        get_display_info = get_display_info
    })

    -------------------------------------------------------------------------------
    -- mpv 事件和按键绑定
    -------------------------------------------------------------------------------

    -- 监听字幕轨道切换
    mp.observe_property("sid", "string", function(_, value)
        local subtitle_track = utils.get_subtitle_fingerprint(value)
        if subtitle_track ~= state.last_subtitle_track then
            state:switch_to(subtitle_track)
            menu:maybe_refresh()
        end
    end)

    -- 监听视频加载
    mp.register_event("start-file", function()
        state:reset_all()
    end)

    -- 快捷键绑定
    mp.add_key_binding("alt+m", "bilingual_filter_toggle_filter_menu", function()
        menu:toggle()
    end)
end

return M
