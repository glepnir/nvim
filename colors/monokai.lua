--=============================================================================
-- Sublime Text default Monokai
--
--   vim.g.monokai_sublime = {
--     italics         = true,
--     underline_class = true,
--     sublime_def     = true,
--     transparent     = false,
--     dim_inactive    = false,
--   }
--
--=============================================================================

vim.cmd('highlight clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd('syntax reset')
end

vim.o.termguicolors = true
vim.o.background = 'dark'
vim.g.colors_name = 'monokai-sublime'

--=============================================================================
-- 配置
--=============================================================================

local user = vim.g.monokai_sublime or {}
local cfg = {
  italics = user.italics == true,
  underline_class = user.underline_class ~= false,
  sublime_def = user.sublime_def ~= false,
  transparent = user.transparent == true,
  dim_inactive = user.dim_inactive == true,
}

local it = cfg.italics and true or nil
local ul = cfg.underline_class and true or nil

--=============================================================================
-- 调色板
-- 前八个强调色即 Sublime Monokai.sublime-color-scheme 里那组 HSL 变量的十六进制值
--=============================================================================

local p = {
  bg = '#272822', -- background
  bg_dark = '#1E1F1C', -- 侧栏、浮动窗口
  bg_darker = '#191A16', -- 阴影、非活动区
  bg_line = '#3E3D32', -- line_highlight
  bg_sel = '#49483E', -- selection
  bg_subtle = '#343529',

  fg = '#F8F8F2', -- foreground
  fg_bright = '#F9F8F5',
  fg_dim = '#A59F85',
  cursor = '#F8F8F0', -- caret
  comment = '#75715E',
  invisible = '#3B3A32',
  gutter = '#8F908A',
  guide = '#3B3A32',
  guide_active = '#9D550F',
  find_hl = '#FFE792',

  red = '#FF6188',
  -- red = '#F92672', -- keyword / operator / tag
  orange = '#FD971F', -- parameter
  yellow = '#E6DB74', -- string
  yellow_warm = '#F4BF75', -- ANSI yellow
  green = '#A6E22E', -- function / class name
  cyan = '#A1EFE4', -- ANSI cyan
  blue = '#66D9EF', -- storage.type / support
  purple = '#AE81FF', -- number / constant
  brown = '#CC6633',

  diff_add = '#3B4A25',
  diff_change = '#3A3A2A',
  diff_delete = '#4B2733',
  diff_text = '#5C5C34',
}

local bg = cfg.transparent and 'NONE' or p.bg
local bg_float = cfg.transparent and 'NONE' or p.bg_dark

--=============================================================================
-- 语义别名，改口味时只动这一段即可
--=============================================================================

local s = {
  keyword = p.red,
  operator = p.fg,
  storage = p.blue, -- storage.type，Sublime 里是青色斜体
  func = p.green, -- entity.name.function
  class = p.green, -- entity.name.class
  str = p.yellow,
  number = p.purple,
  constant = p.purple,
  param = p.orange, -- variable.parameter，Sublime 里是橙色斜体
  support = p.blue, -- 内置函数、内置类型
  variable = p.fg,
  punct = p.fg,
}

-- def / class / function 这类关键字，Sublime 里归到 storage.type 走青色斜体
local kw_func = cfg.sublime_def and s.storage or s.keyword
local kw_func_it = cfg.sublime_def and it or nil

--=============================================================================
-- 高亮定义
--=============================================================================

local hl = {

  --------------------------------------------------------------------------
  -- 编辑器界面
  --------------------------------------------------------------------------
  Normal = { fg = p.fg, bg = bg },
  NormalNC = cfg.dim_inactive and { fg = p.fg_dim, bg = p.bg_darker } or { link = 'Normal' },
  NormalFloat = { fg = p.fg, bg = bg_float },
  FloatBorder = { fg = p.bg_sel, bg = bg_float },
  FloatTitle = { fg = p.green, bg = bg_float, bold = true },
  Cursor = { fg = p.bg, bg = p.cursor },
  lCursor = { link = 'Cursor' },
  CursorIM = { link = 'Cursor' },
  TermCursor = { link = 'Cursor' },
  CursorLine = { bg = p.bg_line },
  CursorColumn = { bg = p.bg_line },
  ColorColumn = { bg = p.bg_subtle },
  CursorLineNr = { fg = p.fg, bold = true },
  LineNr = { fg = p.gutter },
  LineNrAbove = { link = 'LineNr' },
  LineNrBelow = { link = 'LineNr' },
  SignColumn = { fg = p.gutter, bg = bg },
  FoldColumn = { fg = p.gutter, bg = bg },
  Folded = { fg = p.comment, bg = p.bg_subtle },
  WinSeparator = { fg = p.bg_sel, bg = bg },
  VertSplit = { link = 'WinSeparator' },
  EndOfBuffer = { fg = p.bg },
  NonText = { fg = p.invisible },
  Whitespace = { fg = p.invisible },
  SpecialKey = { fg = p.invisible },
  Conceal = { fg = p.comment },
  Directory = { fg = p.blue },
  Title = { fg = p.green, bold = true },
  MsgArea = { fg = p.fg },
  MsgSeparator = { fg = p.bg_sel, bg = bg },
  ModeMsg = { fg = p.fg, bold = true },
  MoreMsg = { fg = p.green },
  Question = { fg = p.green },
  ErrorMsg = { fg = p.red, bold = true },
  WarningMsg = { fg = p.orange },
  WinBar = { fg = p.fg, bg = bg, bold = true },
  WinBarNC = { fg = p.fg_dim, bg = bg },
  QuickFixLine = { bg = p.bg_sel },
  MatchParen = { fg = p.orange, bold = true, underline = true },
  Substitute = { fg = p.bg, bg = p.orange },

  Visual = { bg = p.bg_sel },
  VisualNOS = { bg = p.bg_sel },
  Search = { fg = p.bg, bg = p.find_hl },
  IncSearch = { fg = p.bg, bg = p.orange },
  CurSearch = { fg = p.bg, bg = p.orange },

  StatusLine = { fg = p.fg, bg = p.bg_sel },
  StatusLineNC = { fg = p.comment, bg = p.bg_subtle },
  TabLine = { fg = p.comment, bg = p.bg_dark },
  TabLineFill = { bg = p.bg_dark },
  TabLineSel = { fg = p.fg, bg = p.bg },

  Pmenu = { fg = p.fg, bg = p.bg_dark },
  PmenuSel = { fg = p.fg_bright, bg = p.bg_sel, bold = true },
  PmenuSbar = { bg = p.bg_subtle },
  PmenuThumb = { bg = p.bg_sel },
  PmenuKind = { fg = p.blue, bg = p.bg_dark },
  PmenuKindSel = { fg = p.blue, bg = p.bg_sel },
  PmenuExtra = { fg = p.comment, bg = p.bg_dark },
  PmenuExtraSel = { fg = p.comment, bg = p.bg_sel },
  PmenuBorder = { bg = 'NONE' },
  WildMenu = { link = 'PmenuSel' },

  --------------------------------------------------------------------------
  -- diff 与 spell
  --------------------------------------------------------------------------
  DiffAdd = { bg = p.diff_add },
  DiffChange = { bg = p.diff_change },
  DiffDelete = { fg = p.red, bg = p.diff_delete },
  DiffText = { bg = p.diff_text },
  diffAdded = { fg = p.green },
  diffRemoved = { fg = p.red },
  diffChanged = { fg = p.orange },
  diffOldFile = { fg = p.yellow },
  diffNewFile = { fg = p.orange },
  diffFile = { fg = p.blue },
  diffLine = { fg = p.comment },
  diffIndexLine = { fg = p.purple },

  SpellBad = { sp = p.red, undercurl = true },
  SpellCap = { sp = p.orange, undercurl = true },
  SpellLocal = { sp = p.blue, undercurl = true },
  SpellRare = { sp = p.purple, undercurl = true },

  --------------------------------------------------------------------------
  -- 传统 syntax 组
  --------------------------------------------------------------------------
  Comment = { fg = p.comment },
  Constant = { fg = s.constant },
  String = { fg = s.str },
  Character = { fg = s.str },
  Number = { fg = s.number },
  Float = { fg = s.number },
  Boolean = { fg = s.constant },

  Identifier = { fg = s.variable },
  Function = { fg = s.func },

  Statement = { fg = s.keyword },
  Conditional = { fg = s.keyword },
  Repeat = { fg = s.keyword },
  Label = { fg = s.keyword },
  Operator = { fg = s.operator },
  Keyword = { fg = s.keyword },
  Exception = { fg = s.keyword },

  PreProc = { fg = s.keyword },
  Include = { fg = s.keyword },
  Define = { fg = s.keyword },
  Macro = { fg = s.keyword },
  PreCondit = { fg = s.keyword },

  Type = { fg = s.storage, italic = it },
  StorageClass = { fg = s.storage, italic = it },
  Structure = { fg = s.storage, italic = it },
  Typedef = { fg = s.storage, italic = it },

  Special = { fg = p.purple },
  SpecialChar = { fg = p.purple },
  Tag = { fg = s.keyword },
  Delimiter = { fg = s.punct },
  SpecialComment = { fg = p.fg_dim },
  Debug = { fg = p.orange },

  Underlined = { underline = true },
  Ignore = { fg = p.comment },
  Error = { fg = p.fg_bright, bg = p.red },
  Todo = { fg = p.bg, bg = p.yellow, bold = true },

  --------------------------------------------------------------------------
  -- Tree-sitter（Neovim 0.10 命名）
  --------------------------------------------------------------------------
  ['@comment'] = { fg = p.comment },
  ['@comment.documentation'] = { fg = p.comment },
  ['@comment.error'] = { fg = p.fg_bright, bg = p.red },
  ['@comment.warning'] = { fg = p.bg, bg = p.orange },
  ['@comment.todo'] = { fg = p.bg, bg = p.yellow, bold = true },
  ['@comment.note'] = { fg = p.bg, bg = p.blue },

  ['@variable'] = { fg = s.variable },
  ['@variable.builtin'] = { fg = p.orange, italic = it },
  ['@variable.parameter'] = { fg = s.param, italic = it },
  ['@variable.parameter.builtin'] = { fg = s.param, italic = it },
  ['@variable.member'] = { fg = s.variable },

  ['@constant'] = { fg = s.constant },
  ['@constant.builtin'] = { fg = s.constant },
  ['@constant.macro'] = { fg = s.constant },

  ['@module'] = { fg = s.variable },
  ['@module.builtin'] = { fg = s.support, italic = it },
  ['@label'] = { fg = s.keyword },

  ['@string'] = { fg = s.str },
  ['@string.documentation'] = { fg = s.str },
  ['@string.regexp'] = { fg = p.orange },
  ['@string.escape'] = { fg = p.purple },
  ['@string.special'] = { fg = p.purple },
  ['@string.special.symbol'] = { fg = s.constant },
  ['@string.special.path'] = { fg = s.str, underline = true },
  ['@string.special.url'] = { fg = p.blue, underline = true },

  ['@character'] = { fg = s.str },
  ['@character.special'] = { fg = p.purple },
  ['@boolean'] = { fg = s.constant },
  ['@number'] = { fg = s.number },
  ['@number.float'] = { fg = s.number },

  ['@type'] = { fg = s.storage, italic = it },
  ['@type.builtin'] = { fg = s.storage, italic = it },
  ['@type.definition'] = { fg = s.class, underline = ul },
  ['@attribute'] = { fg = s.green },
  ['@attribute.builtin'] = { fg = s.support },
  ['@property'] = { fg = s.variable },

  ['@function'] = { fg = s.func },
  ['@function.builtin'] = { fg = s.support },
  ['@function.call'] = { fg = s.func },
  ['@function.macro'] = { fg = s.func },
  ['@function.method'] = { fg = s.func },
  ['@function.method.call'] = { fg = s.func },
  ['@constructor'] = { fg = s.class },

  ['@operator'] = { fg = s.operator },

  ['@keyword'] = { fg = s.keyword },
  ['@keyword.coroutine'] = { fg = s.keyword },
  ['@keyword.function'] = { fg = kw_func, italic = kw_func_it },
  ['@keyword.type'] = { fg = kw_func, italic = kw_func_it },
  ['@keyword.operator'] = { fg = s.keyword },
  ['@keyword.import'] = { fg = s.keyword },
  ['@keyword.modifier'] = { fg = s.storage, italic = it },
  ['@keyword.repeat'] = { fg = s.keyword },
  ['@keyword.return'] = { fg = s.keyword },
  ['@keyword.debug'] = { fg = s.keyword },
  ['@keyword.exception'] = { fg = s.keyword },
  ['@keyword.conditional'] = { fg = s.keyword },
  ['@keyword.conditional.ternary'] = { fg = s.operator },
  ['@keyword.directive'] = { fg = s.keyword },
  ['@keyword.directive.define'] = { fg = s.keyword },

  ['@punctuation.delimiter'] = { fg = s.punct },
  ['@punctuation.bracket'] = { fg = s.punct },
  ['@punctuation.special'] = { fg = p.red },

  ['@tag'] = { fg = p.red },
  ['@tag.builtin'] = { fg = p.red },
  ['@tag.attribute'] = { fg = p.green, italic = it },
  ['@tag.delimiter'] = { fg = s.punct },

  ['@markup.strong'] = { fg = p.orange, bold = true },
  ['@markup.italic'] = { fg = p.yellow, italic = true },
  ['@markup.strikethrough'] = { fg = p.comment, strikethrough = true },
  ['@markup.underline'] = { underline = true },
  ['@markup.heading'] = { fg = p.green, bold = true },
  ['@markup.heading.1'] = { fg = p.red, bold = true },
  ['@markup.heading.2'] = { fg = p.orange, bold = true },
  ['@markup.heading.3'] = { fg = p.yellow, bold = true },
  ['@markup.heading.4'] = { fg = p.green, bold = true },
  ['@markup.heading.5'] = { fg = p.blue, bold = true },
  ['@markup.heading.6'] = { fg = p.purple, bold = true },
  ['@markup.quote'] = { fg = p.comment, italic = true },
  ['@markup.math'] = { fg = p.purple },
  ['@markup.link'] = { fg = p.blue },
  ['@markup.link.label'] = { fg = p.green },
  ['@markup.link.url'] = { fg = p.blue, underline = true },
  ['@markup.raw'] = { fg = p.yellow },
  ['@markup.raw.block'] = { fg = p.yellow },
  ['@markup.list'] = { fg = p.red },
  ['@markup.list.checked'] = { fg = p.green },
  ['@markup.list.unchecked'] = { fg = p.comment },

  ['@diff.plus'] = { fg = p.green },
  ['@diff.minus'] = { fg = p.red },
  ['@diff.delta'] = { fg = p.orange },

  -- 语言特例：JSON 的 key 在 Sublime Monokai 里保持前景白，value 才是字符串黄
  ['@property.json'] = { fg = p.fg },
  ['@property.jsonc'] = { fg = p.fg },
  ['@property.yaml'] = { fg = p.red },
  ['@type.css'] = { fg = p.green },
  ['@property.css'] = { fg = p.blue },
  ['@variable.member.css'] = { fg = p.blue },

  ['@annotation'] = { fg = p.white3 },

  --------------------------------------------------------------------------
  -- LSP 语义记号
  --------------------------------------------------------------------------
  ['@lsp.type.namespace'] = { link = '@module' },
  ['@lsp.type.type'] = { link = '@type' },
  ['@lsp.type.class'] = { fg = s.class, underline = ul },
  ['@lsp.type.enum'] = { fg = s.class, underline = ul },
  ['@lsp.type.interface'] = { fg = s.class, italic = it, underline = ul },
  ['@lsp.type.struct'] = { fg = s.class, underline = ul },
  ['@lsp.type.typeParameter'] = { fg = s.storage, italic = it },
  ['@lsp.type.parameter'] = { link = '@variable.parameter' },
  ['@lsp.type.variable'] = { link = '@variable' },
  ['@lsp.type.property'] = { link = '@property' },
  ['@lsp.type.enumMember'] = { link = '@constant' },
  ['@lsp.type.function'] = { link = '@function' },
  ['@lsp.type.method'] = { link = '@function.method' },
  ['@lsp.type.macro'] = { link = '@function.macro' },
  ['@lsp.type.decorator'] = { link = '@attribute' },
  ['@lsp.type.keyword'] = { link = '@keyword' },
  ['@lsp.type.operator'] = { link = '@operator' },
  ['@lsp.type.string'] = { link = '@string' },
  ['@lsp.type.number'] = { link = '@number' },
  ['@lsp.type.comment'] = { link = '@comment' },
  ['@lsp.mod.readonly'] = { link = '@constant' },
  ['@lsp.mod.deprecated'] = { strikethrough = true },
  ['@lsp.typemod.function.defaultLibrary'] = { link = '@function.builtin' },
  ['@lsp.typemod.variable.defaultLibrary'] = { link = '@variable.builtin' },
  ['@lsp.typemod.variable.readonly'] = { link = '@constant' },

  LspReferenceText = { bg = p.bg_sel },
  LspReferenceRead = { bg = p.bg_sel },
  LspReferenceWrite = { bg = p.bg_sel, underline = true },
  LspSignatureActiveParameter = { fg = p.orange, italic = it, bold = true },
  LspInlayHint = { fg = p.comment, bg = p.bg_subtle, italic = true },
  LspCodeLens = { fg = p.comment, italic = true },
  LspInfoBorder = { link = 'FloatBorder' },

  --------------------------------------------------------------------------
  -- 诊断
  --------------------------------------------------------------------------
  DiagnosticError = { fg = p.red },
  DiagnosticWarn = { fg = p.orange },
  DiagnosticInfo = { fg = p.blue },
  DiagnosticHint = { fg = p.green },
  DiagnosticOk = { fg = p.green },
  DiagnosticVirtualTextError = { fg = p.red, bg = '#3A2229' },
  DiagnosticVirtualTextWarn = { fg = p.orange, bg = '#3A2F1E' },
  DiagnosticVirtualTextInfo = { fg = p.blue, bg = '#233437' },
  DiagnosticVirtualTextHint = { fg = p.green, bg = '#2C3522' },
  DiagnosticUnderlineError = { sp = p.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = p.orange, undercurl = true },
  DiagnosticUnderlineInfo = { sp = p.blue, undercurl = true },
  DiagnosticUnderlineHint = { sp = p.green, undercurl = true },
  DiagnosticUnnecessary = { fg = p.comment },
  DiagnosticDeprecated = { sp = p.comment, strikethrough = true },

  --------------------------------------------------------------------------
  -- 常用插件
  --------------------------------------------------------------------------
  -- gitsigns
  GitSignsAdd = { fg = p.green },
  GitSignsChange = { fg = p.orange },
  GitSignsDelete = { fg = p.red },
  GitSignsCurrentLineBlame = { fg = p.comment, italic = true },
}

for group, spec in pairs(hl) do
  vim.api.nvim_set_hl(0, group, spec)
end

--=============================================================================
-- 内置终端配色（base16-monokai 口径）
--=============================================================================

local term = {
  p.bg,
  p.red,
  p.green,
  p.yellow_warm,
  p.blue,
  p.purple,
  p.cyan,
  p.fg,
  p.comment,
  p.red,
  p.green,
  p.yellow_warm,
  p.blue,
  p.purple,
  p.cyan,
  p.fg_bright,
}
for i, color in ipairs(term) do
  vim.g['terminal_color_' .. (i - 1)] = color
end

vim.api.nvim_create_user_command('ColorOutPut', function()
  for k, v in pairs(p) do
    print(('%s = "%s"'):format(k, v))
  end
end, {})

return p
