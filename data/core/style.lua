local common = require "core.common"
local style = {}

style.padding = { x = common.round(14 * SCALE), y = common.round(7 * SCALE) }
style.divider_size = common.round(1 * SCALE)
style.scrollbar_size = common.round(4 * SCALE)
style.expanded_scrollbar_size = common.round(12 * SCALE)
style.caret_width = common.round(2 * SCALE)
style.tab_width = common.round(170 * SCALE)

-- The function renderer.font.load can accept an option table as a second optional argument.
-- It shoud be like the following:
--
-- {antialiasing= "grayscale", hinting = "full"}
--
-- The possible values for each option are:
-- - for antialiasing: grayscale, subpixel
-- - for hinting: none, slight, full
--
-- The defaults values are antialiasing subpixel and hinting slight for optimal visualization
-- on ordinary LCD monitor with RGB patterns.
--
-- On High DPI monitor or non RGB monitor you may consider using antialiasing grayscale instead.
-- The antialiasing grayscale with full hinting is interesting for crisp font rendering.
-- 中文字体回退：内置字体不含中文字形，这里查找系统中文字体作为后备字体，
-- 否则中文会显示为方块。也可以把任意中文字体放到 DATADIR/fonts/cjk.ttf 使用。
local function find_font(paths)
  for _, path in ipairs(paths) do
    local info = system.get_file_info(path)
    if info and info.type == "file" then
      return path
    end
  end
end

local cjk_font_path = find_font({
  DATADIR .. "/fonts/cjk.ttf",
  DATADIR .. "/fonts/cjk.otf",
  "C:/Windows/Fonts/msyh.ttc",
  "C:/Windows/Fonts/msyh.ttf",
  "C:/Windows/Fonts/simhei.ttf",
  "C:/Windows/Fonts/simsun.ttc",
  "/System/Library/Fonts/PingFang.ttc",
  "/System/Library/Fonts/Hiragino Sans GB.ttc",
  "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
  "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
  "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
  "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
  "/usr/share/fonts/truetype/arphic/uming.ttc",
})

local function load_font(path, size, opts)
  local font = renderer.font.load(path, size, opts)
  if not cjk_font_path then return font end
  local ok, fallback = pcall(renderer.font.load, cjk_font_path, size,
    { antialiasing = "grayscale", hinting = "full" })
  if not ok or not fallback then return font end
  return renderer.font.group({ font, fallback })
end

style.font = load_font(DATADIR .. "/fonts/FiraSans-Regular.ttf", 15 * SCALE)
style.big_font = style.font:copy(46 * SCALE)
style.icon_font = renderer.font.load(DATADIR .. "/fonts/icons.ttf", 16 * SCALE, {antialiasing="grayscale", hinting="full"})
style.icon_big_font = style.icon_font:copy(23 * SCALE)
style.code_font = load_font(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 15 * SCALE)

style.syntax = {}

-- This can be used to override fonts per syntax group.
-- The syntax highlighter will take existing values from this table and
-- override style.code_font on a per-token basis, so you can choose to eg.
-- render comments in an italic font if you want to.
style.syntax_fonts = {}
-- style.syntax_fonts["comment"] = renderer.font.load(path_to_font, size_of_font, rendering_options)

style.log = {}

return style
