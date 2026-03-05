local OSD = {
    parts = {} -- 存储生成的 ASS 片段
}

-- 预设颜色常量（RRGGBB 格式）
OSD.colors = {
    green = "98E3A1", -- 薄荷绿
    yellow = "F4D688", -- 琥珀黄
    red = "F48282", -- 珊瑚红
    white = "EEEEEE", -- 象牙白
    sep = "666666", -- 分割线深灰
    hint = "B0B0B0" -- 提示石墨灰
}

-- 预设字号常量（像素）
OSD.size_presets = {
    title = 34, -- 标题字号
    stat = 24, -- 统计信息字号
    hint = 16, -- 提示文字字号
    mini = 12, -- 极小字号（用于留白）
    micro = 10 -- 微字号（用于留白微调）
}
-- 默认字号
OSD.size_presets.default = OSD.size_presets.stat

-- 对齐方式常量（ASS 标准：1=左下，2=中下，3=右下，4=左中，5=居中，6=右中，7=左上，8=中上，9=右上）
OSD.align = {
    bottom_left = 1,
    bottom_center = 2,
    bottom_right = 3,
    middle_left = 4,
    center = 5,
    middle_right = 6,
    top_left = 7,
    top_center = 8,
    top_right = 9
}

-- 默认样式配置（全部使用预设常量）
OSD.defaults = {
    font_name = "DengXian",
    font_size = OSD.size_presets.default, -- 默认字体大小
    color = OSD.colors.white, -- 默认字体颜色
    align = OSD.align.top_left, -- 默认对齐方式
    pos_x = 20, -- 默认 X 坐标
    pos_y = 80 -- 默认 Y 坐标
}

-- 创建新实例
function OSD:new()
    local instance = {
        parts = {}
    }
    setmetatable(instance, self)
    self.__index = self

    instance:align(self.defaults.align)
    instance:pos(self.defaults.pos_x, self.defaults.pos_y)
    instance:font_name(self.defaults.font_name)
    instance:font_size(self.defaults.font_size)

    return instance
end

-- 添加纯文本（不附加任何样式）
function OSD:append(text)
    table.insert(self.parts, tostring(text))
    return self
end

-- 设置位置（像素坐标）
function OSD:pos(x, y)
    return self:append(string.format("{\\pos(%d,%d)}", x, y))
end

-- 设置对齐方式（使用 align 常量）
function OSD:align(mode)
    return self:append(string.format("{\\an%d}", mode))
end

-- 设置字体大小（使用 size_presets 常量）
function OSD:font_size(size)
    return self:append(string.format("{\\fs%d}", size))
end

-- 设置字体名称
function OSD:font_name(name)
    return self:append(string.format("{\\fn%s}", name))
end

-- 设置主要颜色（使用 colors 常量，输入 RRGGBB，自动转换为 ASS 的 BGR 格式）
function OSD:color(hex)
    local r = hex:sub(1, 2)
    local g = hex:sub(3, 4)
    local b = hex:sub(5, 6)
    return self:append(string.format("{\\1c&H%s%s%s&}", b, g, r))
end

-- ========== 语义化颜色函数 ==========
function OSD:green()
    return self:color(OSD.colors.green)
end

function OSD:yellow()
    return self:color(OSD.colors.yellow)
end

function OSD:red()
    return self:color(OSD.colors.red)
end

function OSD:white()
    return self:color(OSD.colors.white)
end

function OSD:sep_color()
    return self:color(OSD.colors.sep)
end

function OSD:hint_color()
    return self:color(OSD.colors.hint)
end

-- ========== 语义化字号函数 ==========
function OSD:title_font()
    return self:font_size(OSD.size_presets.title)
end

function OSD:stat_font()
    return self:font_size(OSD.size_presets.stat)
end

function OSD:hint_font()
    return self:font_size(OSD.size_presets.hint)
end

function OSD:mini_font()
    return self:font_size(OSD.size_presets.mini)
end

function OSD:micro_font()
    return self:font_size(OSD.size_presets.micro)
end

-- ========== 语义化样式组合函数 ==========
-- 标题样式（大字 + 粗体 + 指定颜色）
function OSD:title(text, color_func)
    self:title_font()
    if color_func then
        color_func(self)
    end
    self:bold(text)
    return self
end

-- 统计信息样式（中号字 + 白色）
function OSD:stat(text)
    self:stat_font()
    self:white()
    self:append(text)
    return self
end

-- 提示信息样式（小字 + 提示色）
function OSD:hint_text(text)
    self:hint_font()
    self:hint_color()
    self:append(text)
    return self
end

-- 分割线样式（小字 + 分割线色 + 分割线）
function OSD:separator_line(repeat_count, char)
    self:hint_font()
    self:sep_color()
    self:separator(repeat_count, char)
    return self
end

-- 彩色文本块：用指定颜色包裹文本，之后恢复为默认颜色
function OSD:colored(color_fn, text)
    color_fn(self)
    self:append(text)
    self:color(OSD.defaults.color) -- 恢复默认颜色
    return self
end

-- 指定字号的文本块
function OSD:with_font(size, text)
    self:font_size(size)
    self:append(text)
    self:font_size(OSD.defaults.font_size) -- 恢复默认字号
    return self
end

-- 粗体文本块：用粗体包裹文本，之后关闭粗体
function OSD:bold(text)
    self:append("{\\b700}")
    self:append(text)
    self:append("{\\b0}")
    return self
end

-- 斜体文本块
function OSD:italic(text)
    self:append("{\\i1}")
    self:append(text)
    self:append("{\\i0}")
    return self
end

-- 插入换行符（硬换行）
function OSD:newline()
    return self:append("\\N")
end

-- 插入空格（可指定数量）
function OSD:spaces(count)
    count = count or 1
    return self:append(string.rep("\\h", count))
end

-- 插入Tab（可指定数量）
function OSD:tab(count)
    count = count or 1
    return self:spaces(count * 4)
end

-- 视觉留白（空行）- 使用指定字号实现紧凑留白
-- 参数可以是：
--   - 字符串：使用 size_presets 中预定义的名称（如 "mini", "micro"）
--   - 数字：直接使用该数字作为字号
--   - nil/省略：使用默认字号
function OSD:spacing(size)
    if size == nil then
        -- 没有指定参数，使用默认字号
        self:font_size(OSD.size_presets.default)
    elseif type(size) == "number" then
        -- 参数是数字，直接使用该字号
        self:font_size(size)
    elseif type(size) == "string" then
        -- 参数是字符串，检查是否是预定义的名称
        local preset_size = OSD.size_presets[size]
        if preset_size then
            -- 如果是预定义的名称（如 "mini"），使用对应的字号
            self:font_size(preset_size)
        else
            -- 如果不是预定义的名称，记录警告并使用默认字号
            print("Warning: Unknown size preset '" .. size .. "', using default")
            self:font_size(OSD.size_presets.default)
        end
    else
        -- 其他类型，使用默认字号
        self:font_size(OSD.size_presets.default)
    end

    self:append(" ")
    return self:newline()
end

-- 绘制基于字符串的分割线
-- repeat_count: 重复字符的次数（默认24），char: 用于绘制分割线的字符（默认"—"）
function OSD:separator(repeat_count, char)
    repeat_count = repeat_count or 24
    char = char or "—"
    return self:append(string.rep(char, repeat_count))
end

-- 生成最终的 ASS 字符串
function OSD:build()
    return table.concat(self.parts)
end

return OSD
