-- Sublime Text 4 default mariana theme
--
--   vim.g.mariana_italic         = false
--   vim.g.mariana_transparent    = true
--   vim.g.mariana_dim_cursorline = true
--   vim.g.mariana_dim_inactive   = true

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end

vim.o.background = 'dark'
vim.g.colors_name = 'mariana'

local function opt(name, default)
  local v = vim.g[name]
  if v == nil then
    return default
  end
  return not (v == false or v == 0)
end

local cfg = {
  italic = opt('mariana_italic', false),
  transparent = opt('mariana_transparent', false),
  dim_cursorline = opt('mariana_dim_cursorline', false),
  dim_inactive = opt('mariana_dim_inactive', false),
}

local function hsl(h, s, l)
  h = h % 360
  s, l = s / 100, l / 100
  local c = (1 - math.abs(2 * l - 1)) * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = l - c / 2
  local r, g, b
  if h < 60 then
    r, g, b = c, x, 0
  elseif h < 120 then
    r, g, b = x, c, 0
  elseif h < 180 then
    r, g, b = 0, c, x
  elseif h < 240 then
    r, g, b = 0, x, c
  elseif h < 300 then
    r, g, b = x, 0, c
  else
    r, g, b = c, 0, x
  end
  return { (r + m) * 255, (g + m) * 255, (b + m) * 255 }
end

-- 把 fg 以 alpha a 合成到 bg 上 (Sublime 的 color() alpha 是 sRGB 直接混合)
local function over(fg, bg, a)
  return {
    fg[1] * a + bg[1] * (1 - a),
    fg[2] * a + bg[2] * (1 - a),
    fg[3] * a + bg[3] * (1 - a),
  }
end

local function hex(rgb)
  local function ch(vv)
    vv = math.max(0, math.min(255, math.floor(vv + 0.5)))
    return string.format('%02x', vv)
  end
  return '#' .. ch(rgb[1]) .. ch(rgb[2]) .. ch(rgb[3])
end

local V = {
  black = hsl(0, 0, 0),
  blue = hsl(210, 50, 60),
  blue_vib = hsl(210, 60, 60), -- blue-vibrant / accent
  blue3 = hsl(210, 15, 22), -- background
  blue4 = hsl(210, 13, 45), -- selection_border
  blue5 = hsl(180, 36, 54), -- cyan / active_guide
  blue6 = hsl(221, 12, 69), -- comment / separator
  green = hsl(114, 31, 68),
  grey = hsl(0, 0, 20), -- find_highlight_foreground
  orange = hsl(32, 93, 66), -- caret / number / parameter
  orange2 = hsl(32, 85, 55), -- invalid.deprecated
  orange3 = hsl(40, 94, 68), -- find_highlight
  pink = hsl(300, 30, 68),
  red = hsl(357, 79, 65),
  red2 = hsl(13, 93, 66), -- keyword.operator
  white = hsl(0, 0, 100), -- punctuation.section
  white2 = hsl(0, 0, 97), -- invalid 前景
  white3 = hsl(219, 28, 88), -- foreground
}

-- blue2 是半透明选区/当前行色 hsla(210,13%,40%,0.7), 合成到背景
local blue2_base = hsl(210, 13, 40)
V.blue2 = over(blue2_base, V.blue3, 0.7)

local p = {
  black = hex(V.black),
  blue = hex(V.blue),
  blue_vib = hex(V.blue_vib),
  blue2 = hex(V.blue2),
  blue3 = hex(V.blue3),
  blue4 = hex(V.blue4),
  blue5 = hex(V.blue5),
  blue6 = hex(V.blue6),
  green = hex(V.green),
  grey = hex(V.grey),
  orange = hex(V.orange),
  orange2 = hex(V.orange2),
  orange3 = hex(V.orange3),
  pink = hex(V.pink),
  red = hex(V.red),
  red2 = hex(V.red2),
  white = hex(V.white),
  white2 = hex(V.white2),
  white3 = hex(V.white3),

  -- === 派生值: 严格按源文件里的 alpha 合成到背景 (blue3) 上 ===
  stack_guide = hex(over(V.blue5, V.blue3, 0.5)), -- stack_guide: color(blue5 a(.5))
  raw_bg = hex(over(blue2_base, V.blue3, 0.38)), -- markup.raw:        color(blue2 a(.38))
  raw_bg_inline = hex(over(blue2_base, V.blue3, 0.5)), -- markup.raw.inline: color(blue2 a(.5))
  diff_del = hex(over(hsl(357, 45, 60), V.blue3, 0.15)), -- diff.deleted
  diff_del_char = hex(over(hsl(357, 60, 60), V.blue3, 0.30)), -- diff.deleted.char
  diff_ins = hex(over(hsl(180, 45, 60), V.blue3, 0.15)), -- diff.inserted
  diff_ins_char = hex(over(hsl(180, 60, 60), V.blue3, 0.30)), -- diff.inserted.char

  -- 移植自定义 (Sublime 无对应): dim_cursorline 开关用, blue2 底色压到 35%
  cursorline_dim = hex(over(blue2_base, V.blue3, 0.35)),

  -- === 以下是 Sublime 配色里没有的 UI chrome, 用 hsl 从背景色系推, 与 hsl port 无关 ===
  ui_bar = hex(hsl(210, 15, 19)), -- statusline / 侧栏 (约等于背景, 略暗)
  ui_deep = hex(hsl(210, 15, 15)), -- tabline 底 / 分割线
  ui_light = hex(hsl(210, 14, 28)), -- ColorColumn / 折叠
  ui_dim = hex(hsl(210, 15, 18)), -- 非当前窗口
  guide = hex(hsl(210, 13, 30)), -- 普通缩进线 (非 active)
}

local it = cfg.italic
local bg = cfg.transparent and 'NONE' or p.blue3
local bg_float = cfg.transparent and 'NONE' or p.ui_bar
local cursorline = cfg.dim_cursorline and p.cursorline_dim or p.blue2

--------------------------------------------------------------------------------
local groups = {
  ------------------------------------------------------------------ 编辑器界面
  Normal = { fg = p.white3, bg = bg },
  NormalNC = { fg = p.white3, bg = cfg.dim_inactive and p.ui_dim or bg },
  NormalFloat = { fg = p.white3, bg = bg_float },
  FloatBorder = { fg = p.blue4, bg = bg_float },
  FloatTitle = { fg = p.blue_vib, bg = bg_float, bold = true },
  Cursor = { fg = p.blue3, bg = p.orange }, -- caret: var(orange)
  lCursor = { link = 'Cursor' },
  CursorIM = { link = 'Cursor' },
  TermCursor = { link = 'Cursor' },
  CursorLine = { bg = cursorline }, -- line_highlight: var(blue2)
  CursorColumn = { bg = cursorline },
  ColorColumn = { bg = p.ui_light },
  CursorLineNr = { fg = p.white3, bold = true },
  LineNr = { fg = p.blue4 },
  LineNrAbove = { fg = p.blue4 },
  LineNrBelow = { fg = p.blue4 },
  SignColumn = { fg = p.blue4, bg = bg },
  FoldColumn = { fg = p.blue4, bg = bg },
  Folded = { fg = p.blue6, bg = p.ui_light },
  WinSeparator = { fg = p.ui_deep, bg = bg },
  VertSplit = { link = 'WinSeparator' },
  NonText = { fg = '#4a545f' },
  Whitespace = { fg = '#4a545f' },
  SpecialKey = { fg = '#4a545f' },
  Conceal = { fg = p.blue4 },
  EndOfBuffer = { fg = cfg.transparent and p.blue3 or bg },
  -- brackets_options: underline / brackets_foreground: var(orange)
  MatchParen = { fg = p.orange, underline = true },
  Visual = { bg = p.blue2 }, -- selection: var(blue2)
  VisualNOS = { bg = p.blue2 },
  -- find_highlight: var(orange3) / find_highlight_foreground: var(grey)
  Search = { fg = p.grey, bg = p.orange3 },
  IncSearch = { fg = p.grey, bg = p.orange3, bold = true },
  CurSearch = { link = 'IncSearch' },
  Substitute = { fg = p.grey, bg = p.red2 },
  QuickFixLine = { bg = p.blue2 },
  Directory = { fg = p.blue },
  Title = { fg = p.blue_vib, bold = true },
  ErrorMsg = { fg = p.red, bold = true },
  WarningMsg = { fg = p.orange },
  MoreMsg = { fg = p.green },
  Question = { fg = p.blue5 },
  ModeMsg = { fg = p.white3, bold = true },
  MsgArea = { fg = p.white3 },
  MsgSeparator = { fg = p.ui_deep, bg = bg },
  Underlined = { underline = true },
  Ignore = { fg = p.blue4 },
  Error = { fg = p.white2, bg = p.red }, -- invalid
  Todo = { fg = p.grey, bg = p.orange3, bold = true },
  SpellBad = { sp = p.red, undercurl = true }, -- misspelling: var(red)
  SpellCap = { sp = p.orange, undercurl = true },
  SpellLocal = { sp = p.blue5, undercurl = true },
  SpellRare = { sp = p.pink, undercurl = true },

  ------------------------------------------------------------------ 状态栏/标签
  StatusLine = { fg = p.blue6, bg = p.ui_bar },
  StatusLineNC = { fg = p.blue4, bg = p.ui_deep },
  TabLine = { fg = p.blue4, bg = p.ui_deep },
  TabLineFill = { bg = p.ui_deep },
  TabLineSel = { fg = p.white3, bg = p.blue3, bold = true },
  WinBar = { fg = p.blue6, bg = bg },
  WinBarNC = { fg = p.blue4, bg = bg },

  ------------------------------------------------------------------ 补全菜单
  Pmenu = { fg = p.white3, bg = bg },
  PmenuSel = { fg = p.white3, bg = p.blue2, bold = true },
  -- PmenuKind = { fg = p.blue5 },
  -- PmenuKindSel = { fg = p.blue5 },
  PmenuExtra = { fg = p.blue4, bg = p.ui_bar },
  PmenuExtraSel = { fg = p.blue6, bg = p.blue2 },
  PmenuSbar = { bg = p.ui_deep },
  PmenuThumb = { bg = p.blue4 },
  WildMenu = { link = 'PmenuSel' },

  ------------------------------------------------------------------ diff
  DiffAdd = { bg = p.diff_ins },
  DiffChange = { bg = p.diff_ins },
  DiffDelete = { fg = p.red, bg = p.diff_del },
  DiffText = { bg = p.diff_ins_char },
  diffAdded = { fg = p.green }, -- markup.inserted
  diffRemoved = { fg = p.red }, -- markup.deleted
  diffChanged = { fg = p.orange }, -- markup.changed
  diffFile = { fg = p.pink }, -- meta.diff.header
  diffLine = { fg = p.pink },
  diffIndexLine = { fg = p.pink },

  ------------------------------------------------------------------ 传统语法组
  Comment = { fg = p.blue6 }, -- comment → var(blue6)
  Constant = { fg = p.white3 }, -- constant.other → var(pink)
  String = { fg = p.green },
  Character = { fg = p.green },
  Number = { fg = p.orange },
  Boolean = { fg = p.red, italic = it }, -- constant.language, italic
  Float = { fg = p.orange },
  Identifier = { fg = p.white3 },
  Function = { fg = p.blue5 }, -- entity.name.function
  Statement = { fg = p.pink },
  Conditional = { fg = p.pink },
  Repeat = { fg = p.pink },
  Label = { fg = p.pink },
  Operator = { fg = p.red2 }, -- keyword.operator → var(red2)
  Keyword = { fg = p.pink },
  Exception = { fg = p.pink },
  PreProc = { fg = p.pink },
  Include = { fg = p.pink },
  Define = { fg = p.pink },
  Macro = { fg = p.blue, italic = it }, -- support.macro
  PreCondit = { fg = p.pink },
  Type = { fg = p.orange }, -- entity.name.* → var(orange)
  StorageClass = { fg = p.red }, -- storage → var(red)
  Structure = { fg = p.pink, italic = it }, -- storage.type, italic
  Typedef = { fg = p.pink, italic = it },
  Special = { fg = p.blue5 },
  SpecialChar = { fg = p.pink }, -- constant.character
  Tag = { fg = p.red },
  Delimiter = { fg = p.blue6 }, -- punctuation.separator
  SpecialComment = { fg = p.blue6, bold = true },
  Debug = { fg = p.red },

  ------------------------------------------------------------------ Treesitter
  ['@variable'] = { fg = p.white3 },
  ['@variable.builtin'] = { fg = p.red, italic = it }, -- variable.language
  ['@variable.parameter'] = { fg = p.fg }, -- variable.parameter
  ['@variable.parameter.builtin'] = { fg = p.orange },
  -- 注意: C/C++ 的成员 a->b 在 Sublime 里是 variable.other.member.c,
  -- 匹配不到 "variable.member" 那条红色规则, 走默认前景 → 白色
  ['@variable.member'] = { fg = p.white3 },

  ['@constant'] = { fg = p.white3 }, -- constant.other
  ['@constant.builtin'] = { fg = p.red, italic = it }, -- constant.language
  ['@constant.macro'] = { fg = p.pink },

  ['@module'] = { fg = p.orange },
  ['@module.builtin'] = { fg = p.blue, italic = it },
  ['@label'] = { fg = p.white3 }, -- entity.name.label 被排除在橙色规则外

  ['@string'] = { fg = p.green },
  ['@string.documentation'] = { fg = p.green },
  ['@string.regexp'] = { fg = p.green },
  ['@string.escape'] = { fg = p.pink }, -- constant.character.escape
  ['@string.special'] = { fg = p.pink },
  ['@string.special.path'] = { fg = p.green },
  ['@string.special.symbol'] = { fg = p.pink },
  ['@string.special.url'] = { fg = p.blue }, -- string.other.link
  ['@character'] = { fg = p.green },
  ['@character.special'] = { fg = p.pink },
  ['@boolean'] = { fg = p.red, italic = it },
  ['@number'] = { fg = p.orange },
  ['@number.float'] = { fg = p.orange },

  ['@type'] = { fg = p.orange }, -- entity.name.class/struct/enum
  ['@type.builtin'] = { fg = p.pink, italic = it }, -- storage.type, italic
  ['@type.definition'] = { fg = p.orange },
  ['@attribute'] = { fg = p.blue }, -- variable.annotation
  ['@attribute.builtin'] = { fg = p.blue, italic = it },
  ['@property'] = { fg = p.white3 }, -- 同上, 走默认前景

  ['@function'] = { fg = p.blue5 }, -- entity.name.function → 青
  ['@function.call'] = { fg = p.blue }, -- variable.function → 蓝
  ['@function.method'] = { fg = p.blue5 },
  ['@function.method.call'] = { fg = p.blue },
  ['@function.builtin'] = { fg = p.blue, italic = it }, -- support.function, italic
  ['@function.macro'] = { fg = p.blue, italic = it }, -- support.macro, italic
  ['@constructor'] = { fg = p.orange },
  ['@operator'] = { fg = p.red2 }, -- keyword.operator

  ['@keyword'] = { fg = p.pink },
  ['@keyword.coroutine'] = { fg = p.pink },
  ['@keyword.function'] = { fg = p.pink, italic = it }, -- storage.type.function
  ['@keyword.operator'] = { fg = p.pink }, -- keyword.operator.word
  ['@keyword.import'] = { fg = p.pink },
  ['@keyword.type'] = { fg = p.pink, italic = it }, -- storage.type.class/struct
  ['@keyword.modifier'] = { fg = p.red }, -- storage.modifier → storage
  ['@keyword.repeat'] = { fg = p.pink },
  ['@keyword.return'] = { fg = p.pink },
  ['@keyword.debug'] = { fg = p.pink },
  ['@keyword.exception'] = { fg = p.pink },
  ['@keyword.conditional'] = { fg = p.pink },
  ['@keyword.conditional.ternary'] = { fg = p.red2 },
  ['@keyword.directive'] = { fg = p.pink },
  ['@keyword.directive.define'] = { fg = p.pink },

  ['@punctuation.delimiter'] = { fg = p.blue6 }, -- punctuation.separator/terminator/accessor
  ['@punctuation.bracket'] = { fg = p.white }, -- punctuation.section → 纯白
  ['@punctuation.special'] = { fg = p.blue5 }, -- punctuation.definition

  ['@comment'] = { fg = p.blue6 }, -- 原版注释不用斜体
  ['@comment.documentation'] = { fg = p.blue6 },
  ['@comment.error'] = { fg = p.white2, bg = p.red, bold = true },
  ['@comment.warning'] = { fg = p.grey, bg = p.orange2, bold = true },
  ['@comment.todo'] = { fg = p.grey, bg = p.orange3, bold = true },
  ['@comment.note'] = { fg = p.grey, bg = p.blue5, bold = true },

  -- markup: 原版标题只加粗不改色, 只有标记符号上色
  ['@markup.strong'] = { bold = true },
  ['@markup.italic'] = { italic = true },
  ['@markup.strikethrough'] = { strikethrough = true },
  ['@markup.underline'] = { underline = true },
  ['@markup.heading'] = { fg = p.white3, bold = true },
  ['@markup.heading.1.marker'] = { fg = p.red },
  ['@markup.heading.2.marker'] = { fg = p.red2 },
  ['@markup.heading.3.marker'] = { fg = p.red2 },
  ['@markup.heading.4.marker'] = { fg = p.red2 },
  ['@markup.heading.5.marker'] = { fg = p.red2 },
  ['@markup.heading.6.marker'] = { fg = p.red2 },
  ['@markup.quote'] = { fg = p.orange },
  ['@markup.math'] = { fg = p.blue5 },
  ['@markup.link'] = { fg = p.blue },
  ['@markup.link.label'] = { fg = p.blue },
  ['@markup.link.url'] = { fg = p.blue, underline = true },
  ['@markup.list'] = { fg = p.orange },
  ['@markup.list.checked'] = { fg = p.green },
  ['@markup.list.unchecked'] = { fg = p.blue6 },

  ['@diff.plus'] = { fg = p.green },
  ['@diff.minus'] = { fg = p.red },
  ['@diff.delta'] = { fg = p.orange },

  ['@tag'] = { fg = p.red }, -- entity.name.tag
  ['@tag.builtin'] = { fg = p.red },
  ['@tag.attribute'] = { fg = p.pink }, -- entity.other.attribute-name
  ['@tag.delimiter'] = { fg = p.blue5 }, -- punctuation.definition.tag

  -- 语言特例 (原 scheme 里显式写了规则的)
  ['@property.yaml'] = { fg = p.blue5 }, -- entity.name.tag.yaml
  ['@field.yaml'] = { fg = p.blue5 },
  ['@string.yaml'] = { fg = p.white3 }, -- source.yaml string.unquoted
  ['@property.json'] = { fg = p.green }, -- JSON 键就是普通字符串
  ['@property.jsonc'] = { fg = p.green },
  ['@property.css'] = { fg = p.white3 }, -- support.type.property-name
  ['@property.scss'] = { fg = p.white3 },
  ['@type.css'] = { fg = p.red }, -- 选择器标签名
  ['@variable.parameter.bash'] = { fg = p.white3 },
  ['@variable.parameter.vim'] = { fg = p.white3 },

  ['@annotation'] = { fg = p.white3 },

  ------------------------------------------------------------------ LSP
  ['@lsp.type.class'] = { fg = p.orange },
  ['@lsp.type.comment'] = {},
  ['@lsp.type.decorator'] = { fg = p.blue },
  ['@lsp.type.enum'] = { fg = p.orange },
  ['@lsp.type.enumMember'] = { fg = p.pink },
  ['@lsp.type.event'] = { fg = p.orange },
  ['@lsp.type.function'] = { fg = p.blue5 },
  ['@lsp.type.interface'] = { fg = p.orange },
  ['@lsp.type.keyword'] = { fg = p.pink },
  ['@lsp.type.macro'] = { fg = p.blue, italic = it },
  ['@lsp.type.method'] = { fg = p.blue5 },
  ['@lsp.type.modifier'] = { fg = p.red },
  ['@lsp.type.namespace'] = { fg = p.orange },
  ['@lsp.type.number'] = { fg = p.orange },
  ['@lsp.type.operator'] = { fg = p.red2 },
  ['@lsp.type.parameter'] = { fg = p.orange },
  ['@lsp.type.property'] = { fg = p.white3 }, -- 成员 → 白色 (否则 clangd 语义高亮又把它染红)
  ['@lsp.type.regexp'] = { fg = p.green },
  ['@lsp.type.string'] = { fg = p.green },
  ['@lsp.type.struct'] = { fg = p.orange },
  ['@lsp.type.type'] = { fg = p.orange },
  ['@lsp.type.typeParameter'] = { fg = p.orange },
  ['@lsp.type.variable'] = {},
  ['@lsp.mod.deprecated'] = { strikethrough = true },
  ['@lsp.typemod.function.defaultLibrary'] = { fg = p.blue, italic = it },
  ['@lsp.typemod.method.defaultLibrary'] = { fg = p.blue, italic = it },
  ['@lsp.typemod.variable.defaultLibrary'] = { fg = p.red, italic = it },
  ['@lsp.typemod.class.defaultLibrary'] = { fg = p.blue, italic = it },
  ['@lsp.typemod.variable.readonly'] = { fg = p.pink },
  ['@lsp.typemod.variable.global'] = { fg = p.pink },
  ['@lsp.type.snippet'] = { fg = p.red },
  ['@lsp.type.constant'] = { fg = p.yellow },
  ['@lsp.type.reference'] = { fg = p.blue },
  ['lsp.type.text'] = { link = 'String' },
  ['lsp.type.constructor'] = { link = 'Type' },
  ['lsp.type.field'] = { link = 'Property' },
  ['lsp.type.module'] = { link = 'Namespace' },
  ['lsp.type.unit'] = { link = 'Type' },
  ['lsp.type.value'] = { link = 'Number' },
  ['lsp.type.snippet'] = { link = 'Macro' },
  ['lsp.type.color'] = { link = 'Number' },
  ['lsp.type.file'] = { link = 'String' },
  ['lsp.type.folder'] = { link = 'Directory' },

  LspReferenceText = { bg = p.ui_light },
  LspReferenceRead = { bg = p.ui_light },
  LspReferenceWrite = { bg = p.ui_light, underline = true },
  LspInlayHint = { fg = p.blue4, bg = p.cursorline_dim },
  LspSignatureActiveParameter = { fg = p.orange, bold = true },
  LspCodeLens = { fg = p.blue4 },
  LspInfoBorder = { fg = p.blue4, bg = bg_float },

  ------------------------------------------------------------------ 诊断
  DiagnosticError = { fg = p.red },
  DiagnosticWarn = { fg = p.orange },
  DiagnosticInfo = { fg = p.blue },
  DiagnosticHint = { fg = p.blue5 },
  DiagnosticOk = { fg = p.green },
  DiagnosticVirtualTextError = { fg = p.red, bg = p.diff_del },
  DiagnosticVirtualTextWarn = { fg = p.orange, bg = '#3d3a3a' },
  DiagnosticVirtualTextInfo = { fg = p.blue, bg = '#333c48' },
  DiagnosticVirtualTextHint = { fg = p.blue5, bg = p.diff_ins },
  DiagnosticVirtualTextOk = { fg = p.green, bg = '#354037' },
  DiagnosticUnderlineError = { sp = p.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = p.orange, undercurl = true },
  DiagnosticUnderlineInfo = { sp = p.blue, undercurl = true },
  DiagnosticUnderlineHint = { sp = p.blue5, undercurl = true },
  DiagnosticUnderlineOk = { sp = p.green, undercurl = true },
  DiagnosticUnnecessary = { fg = p.blue4 },
  DiagnosticDeprecated = { sp = p.blue4, strikethrough = true },
  DiagnosticFloatingError = { fg = p.red, bg = bg_float },
  DiagnosticFloatingWarn = { fg = p.orange, bg = bg_float },
  DiagnosticFloatingInfo = { fg = p.blue, bg = bg_float },
  DiagnosticFloatingHint = { fg = p.blue5, bg = bg_float },
  DiagnosticSignError = { fg = p.red, bg = bg },
  DiagnosticSignWarn = { fg = p.orange, bg = bg },
  DiagnosticSignInfo = { fg = p.blue, bg = bg },
  DiagnosticSignHint = { fg = p.blue5, bg = bg },

  ------------------------------------------------------------------ gitsigns
  GitSignsAdd = { fg = p.green, bg = bg },
  GitSignsChange = { fg = p.orange, bg = bg },
  GitSignsDelete = { fg = p.red, bg = bg },
  GitSignsAddInline = { bg = p.diff_ins_char },
  GitSignsChangeInline = { bg = p.diff_ins_char },
  GitSignsDeleteInline = { bg = p.diff_del_char },
  GitSignsCurrentLineBlame = { fg = p.blue4 },

  ------------------------------------------------------------------ 缩进线
  IblIndent = { fg = p.guide },
  IblScope = { fg = p.blue5 }, -- active_guide: var(blue5)
  IblWhitespace = { fg = p.guide },
  IndentBlanklineChar = { fg = p.guide },
  IndentBlanklineContextChar = { fg = p.blue5 },
  MiniIndentscopeSymbol = { fg = p.blue5 },

  ------------------------------------------------------------------ telescope
  TelescopeNormal = { fg = p.white3, bg = p.ui_bar },
  TelescopeBorder = { fg = p.ui_deep, bg = p.ui_bar },
  TelescopeTitle = { fg = p.blue3, bg = p.blue_vib, bold = true },
  TelescopePromptNormal = { fg = p.white3, bg = p.ui_light },
  TelescopePromptBorder = { fg = p.ui_light, bg = p.ui_light },
  TelescopePromptTitle = { fg = p.grey, bg = p.orange, bold = true },
  TelescopePromptPrefix = { fg = p.orange },
  TelescopePromptCounter = { fg = p.blue4 },
  TelescopePreviewTitle = { fg = p.blue3, bg = p.blue5, bold = true },
  TelescopeResultsTitle = { fg = p.ui_bar, bg = p.ui_bar },
  TelescopeSelection = { fg = p.white3, bg = p.blue2 },
  TelescopeSelectionCaret = { fg = p.orange, bg = p.blue2 },
  TelescopeMultiSelection = { fg = p.pink },
  TelescopeMatching = { fg = p.grey, bg = p.orange3 },

  ------------------------------------------------------------------ nvim-cmp / blink
  CmpItemAbbr = { fg = p.white3 },
  CmpItemAbbrDeprecated = { fg = p.blue4, strikethrough = true },
  CmpItemAbbrMatch = { fg = p.orange3, bold = true },
  CmpItemAbbrMatchFuzzy = { fg = p.orange3 },
  CmpItemMenu = { fg = p.blue4 },
  CmpItemKindText = { fg = p.white3 },
  CmpItemKindMethod = { fg = p.blue5 },
  CmpItemKindFunction = { fg = p.blue5 },
  CmpItemKindConstructor = { fg = p.orange },
  CmpItemKindField = { fg = p.red },
  CmpItemKindVariable = { fg = p.white3 },
  CmpItemKindClass = { fg = p.orange },
  CmpItemKindInterface = { fg = p.orange },
  CmpItemKindModule = { fg = p.orange },
  CmpItemKindProperty = { fg = p.red },
  CmpItemKindUnit = { fg = p.orange },
  CmpItemKindValue = { fg = p.orange },
  CmpItemKindEnum = { fg = p.orange },
  CmpItemKindKeyword = { fg = p.pink },
  CmpItemKindSnippet = { fg = p.green },
  CmpItemKindColor = { fg = p.red2 },
  CmpItemKindFile = { fg = p.blue5 },
  CmpItemKindReference = { fg = p.red },
  CmpItemKindFolder = { fg = p.blue5 },
  CmpItemKindEnumMember = { fg = p.pink },
  CmpItemKindConstant = { fg = p.pink },
  CmpItemKindStruct = { fg = p.orange },
  CmpItemKindEvent = { fg = p.orange },
  CmpItemKindOperator = { fg = p.red2 },
  CmpItemKindTypeParameter = { fg = p.orange },
  BlinkCmpMenu = { link = 'Pmenu' },
  BlinkCmpMenuBorder = { link = 'FloatBorder' },
  BlinkCmpMenuSelection = { link = 'PmenuSel' },
  BlinkCmpLabelMatch = { fg = p.orange3, bold = true },
  BlinkCmpLabelDeprecated = { fg = p.blue4, strikethrough = true },
  BlinkCmpKind = { fg = p.blue5 },

  ------------------------------------------------------------------ 文件树
  NvimTreeNormal = { fg = p.blue6, bg = p.ui_bar },
  NvimTreeNormalNC = { fg = p.blue6, bg = p.ui_bar },
  NvimTreeWinSeparator = { fg = p.ui_deep, bg = p.ui_bar },
  NvimTreeRootFolder = { fg = p.pink, bold = true },
  NvimTreeFolderName = { fg = p.blue6 },
  NvimTreeOpenedFolderName = { fg = p.white3, bold = true },
  NvimTreeEmptyFolderName = { fg = p.blue4 },
  NvimTreeFolderIcon = { fg = p.blue6 },
  NvimTreeIndentMarker = { fg = p.guide },
  NvimTreeSpecialFile = { fg = p.orange },
  NvimTreeExecFile = { fg = p.green },
  NvimTreeImageFile = { fg = p.pink },
  NvimTreeSymlink = { fg = p.blue5 },
  NvimTreeGitDirty = { fg = p.orange },
  NvimTreeGitNew = { fg = p.green },
  NvimTreeGitDeleted = { fg = p.red },
  NvimTreeCursorLine = { bg = p.blue2 },
  NeoTreeNormal = { fg = p.blue6, bg = p.ui_bar },
  NeoTreeNormalNC = { fg = p.blue6, bg = p.ui_bar },
  NeoTreeDirectoryName = { fg = p.blue6 },
  NeoTreeDirectoryIcon = { fg = p.blue6 },
  NeoTreeRootName = { fg = p.pink, bold = true },
  NeoTreeIndentMarker = { fg = p.guide },
  NeoTreeGitAdded = { fg = p.green },
  NeoTreeGitModified = { fg = p.orange },
  NeoTreeGitDeleted = { fg = p.red },
  NeoTreeCursorLine = { bg = p.blue2 },

  ------------------------------------------------------------------ 其他插件
  WhichKey = { fg = p.pink },
  WhichKeyGroup = { fg = p.blue },
  WhichKeyDesc = { fg = p.white3 },
  WhichKeySeparator = { fg = p.blue4 },
  WhichKeyFloat = { bg = p.ui_bar },
  WhichKeyBorder = { fg = p.blue4, bg = p.ui_bar },

  NotifyERRORBorder = { fg = p.red },
  NotifyWARNBorder = { fg = p.orange },
  NotifyINFOBorder = { fg = p.blue },
  NotifyDEBUGBorder = { fg = p.blue4 },
  NotifyTRACEBorder = { fg = p.pink },
  NotifyERRORIcon = { fg = p.red },
  NotifyWARNIcon = { fg = p.orange },
  NotifyINFOIcon = { fg = p.blue },
  NotifyDEBUGIcon = { fg = p.blue4 },
  NotifyTRACEIcon = { fg = p.pink },
  NotifyERRORTitle = { fg = p.red, bold = true },
  NotifyWARNTitle = { fg = p.orange, bold = true },
  NotifyINFOTitle = { fg = p.blue, bold = true },
  NotifyDEBUGTitle = { fg = p.blue4, bold = true },
  NotifyTRACETitle = { fg = p.pink, bold = true },

  BufferLineFill = { bg = p.ui_deep },
  BufferLineBackground = { fg = p.blue4, bg = p.ui_deep },
  BufferLineBufferSelected = { fg = p.white3, bg = p.blue3, bold = true },
  BufferLineIndicatorSelected = { fg = p.blue_vib, bg = p.blue3 },
  BufferLineModified = { fg = p.orange, bg = p.ui_deep },
  BufferLineModifiedSelected = { fg = p.orange, bg = p.blue3 },

  FlashLabel = { fg = p.grey, bg = p.orange3, bold = true },
  LeapLabelPrimary = { fg = p.grey, bg = p.orange3, bold = true },
  LeapMatch = { fg = p.orange, bold = true },

  MiniStatuslineModeNormal = { fg = p.blue3, bg = p.blue_vib, bold = true },
  MiniStatuslineModeInsert = { fg = p.blue3, bg = p.green, bold = true },
  MiniStatuslineModeVisual = { fg = p.blue3, bg = p.pink, bold = true },
  MiniStatuslineModeReplace = { fg = p.blue3, bg = p.red, bold = true },
  MiniStatuslineModeCommand = { fg = p.grey, bg = p.orange, bold = true },
  MiniStatuslineDevinfo = { fg = p.blue6, bg = p.ui_light },
  MiniStatuslineFilename = { fg = p.blue6, bg = p.ui_bar },

  ------------------------------------------------------------------ 内建 ft
  htmlTag = { fg = p.blue5 },
  htmlEndTag = { fg = p.blue5 },
  htmlTagName = { fg = p.red },
  htmlArg = { fg = p.pink },
  htmlH1 = { bold = true },
  cssTagName = { fg = p.red },
  cssClassName = { fg = p.orange },
  cssIdentifier = { fg = p.orange },
  cssProp = { fg = p.white3 },
  cssBraces = { fg = p.white },
  markdownHeadingDelimiter = { fg = p.red2 },
  markdownH1 = { bold = true },
  markdownCode = { bg = p.raw_bg_inline }, -- 行内代码 → markup.raw.inline
  markdownCodeBlock = { bg = p.raw_bg }, -- 代码块 → markup.raw
  markdownLinkText = { fg = p.blue },
  markdownUrl = { fg = p.blue },
  markdownListMarker = { fg = p.orange },
  markdownRule = { fg = p.orange },
  helpHyperTextEntry = { fg = p.blue },
  helpHyperTextJump = { fg = p.blue, underline = true },
  helpExample = { fg = p.green },
  qfFileName = { fg = p.blue },
  qfLineNr = { fg = p.blue4 },
}

for group, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, group, spec)
end

--------------------------------------------------------------------------------
-- 终端调色板
--------------------------------------------------------------------------------
local term = {
  p.ui_bar,
  p.red,
  p.green,
  p.orange3,
  p.blue,
  p.pink,
  p.blue5,
  p.white3,
  p.blue4,
  p.red2,
  p.green,
  p.orange,
  p.blue_vib,
  p.pink,
  p.blue5,
  p.white,
}
for i, color in ipairs(term) do
  vim.g['terminal_color_' .. (i - 1)] = color
end

vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(vim.tbl_extend('force', p, { bg = bg })) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})
