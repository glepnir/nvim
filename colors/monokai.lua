local colors = {
  -- Monokai base colors
  bg = '#272822', -- Main background
  bg_dark = '#1e1f1c', -- Darker background
  bg_light = '#3e3d32', -- Lighter background
  bg_visual = '#49483e', -- Visual selection
  bg_search = '#4e4a3e', -- Search highlight
  fg = '#f8f8f2', -- Main foreground
  fg_dark = '#75715e', -- Comments and secondary text
  fg_light = '#f8f8f0', -- Bright text

  -- Monokai accent colors
  red = '#f92672', -- Keywords
  green = '#a6e22e', -- Strings, functions
  yellow = '#e6db74', -- Strings, numbers
  blue = '#66d9ef', -- Types, constants
  purple = '#ae81ff', -- Numbers, constants
  cyan = '#a1efe4', -- Special chars
  orange = '#fd971f', -- Numbers, constants
  pink = '#f92672', -- Keywords

  -- UI colors
  cursor_line = '#3c3d37',
  line_number = '#90908a',
  selection = '#49483e',
  comment = '#75715e',
  error = '#f92672',
  warning = '#fd971f',
  info = '#66d9ef',
  hint = '#a6e22e',
}

vim.g.colors_name = 'monokai'

local function shl(group, properties)
  vim.api.nvim_set_hl(0, group, properties)
end

local function load_monokai()
  -- General editor highlights
  shl('Normal', { fg = colors.fg, bg = colors.bg })
  shl('EndOfBuffer', { fg = colors.bg })
  shl('CursorLine', { bg = colors.cursor_line })
  shl('CursorLineNr', { fg = colors.yellow, bg = colors.cursor_line, bold = true })
  shl('LineNr', { fg = colors.line_number })
  shl('Comment', { fg = colors.comment, italic = true })
  shl('String', { fg = colors.yellow })
  shl('Function', { fg = colors.green })
  shl('Keyword', { fg = colors.red, bold = true })
  shl('Constant', { fg = colors.purple })
  shl('Identifier', { fg = colors.fg })
  shl('Statement', { fg = colors.red })
  shl('Number', { fg = colors.purple })
  shl('PreProc', { fg = colors.red })
  shl('Type', { fg = colors.blue })
  shl('Special', { fg = colors.orange })
  shl('Operator', { fg = colors.fg })
  shl('Underlined', { fg = colors.blue, underline = true })
  shl('Todo', { fg = colors.bg, bg = colors.orange, bold = true })
  shl('Error', { fg = colors.error, bg = colors.bg, bold = true })
  shl('WarningMsg', { fg = colors.warning })
  shl('IncSearch', { fg = colors.bg, bg = colors.orange })
  shl('Search', { fg = colors.bg, bg = colors.yellow })
  shl('Visual', { bg = colors.selection })
  shl('Pmenu', { fg = colors.fg, bg = colors.bg_dark })
  shl('PmenuMatch', { fg = colors.green, bg = colors.bg_dark, bold = true })
  shl('PmenuMatchSel', { fg = colors.green, bg = colors.bg_light, bold = true })
  shl('PmenuSel', { fg = colors.fg_light, bg = colors.bg_light })
  shl('PmenuSbar', { bg = colors.bg_light })
  shl('PmenuThumb', { bg = colors.fg_dark })
  shl('MatchParen', { bg = colors.bg_light, bold = true })
  shl('WinBar', { bg = colors.bg_light })
  shl('NormalFloat', { bg = colors.bg_dark })
  shl('FloatBorder', { fg = colors.blue })
  shl('Title', { fg = colors.yellow, bold = true })
  shl('WinSeparator', { fg = colors.fg_dark })
  shl('StatusLine', { bg = colors.bg_light, fg = colors.fg })
  shl('StatusLineNC', { bg = colors.bg_dark, fg = colors.fg_dark })
  shl('ModeMsg', { fg = colors.cyan })
  shl('ColorColumn', { bg = colors.cursor_line })
  shl('WildMenu', { fg = colors.bg, bg = colors.yellow })
  shl('Folded', { bg = colors.bg_light, fg = colors.fg_dark })
  shl('ErrorMsg', { fg = colors.error })
  shl('ComplMatchIns', { fg = colors.comment })
  shl('Directory', { fg = colors.blue })
  shl('QuickFixLine', { bold = true })
  shl('qfFileName', { fg = colors.blue })
  shl('qfSeparator', { fg = colors.comment })
  shl('qfLineNr', { link = 'LineNr' })
  shl('qfText', { link = 'Normal' })

  -- Treesitter highlights
  shl('@function', { fg = colors.green })
  shl('@function.builtin', { fg = colors.blue })
  shl('@function.call', { fg = colors.green })
  shl('@function.macro', { fg = colors.orange })
  shl('@variable', { fg = colors.fg })
  shl('@variable.builtin', { fg = colors.blue })
  shl('@variable.parameter', { fg = colors.orange, italic = true })
  shl('@variable.member', { fg = colors.fg })
  shl('@keyword', { fg = colors.red, bold = true })
  shl('@keyword.function', { fg = colors.red })
  shl('@keyword.operator', { fg = colors.red })
  shl('@keyword.import', { fg = colors.red })
  shl('@keyword.type', { fg = colors.blue })
  shl('@keyword.modifier', { fg = colors.red })
  shl('@keyword.repeat', { fg = colors.red })
  shl('@keyword.return', { fg = colors.red })
  shl('@keyword.debug', { fg = colors.red })
  shl('@keyword.exception', { fg = colors.red })
  shl('@keyword.conditional', { fg = colors.red })
  shl('@keyword.conditional.ternary', { fg = colors.red })
  shl('@keyword.directive', { fg = colors.red })
  shl('@keyword.directive.define', { fg = colors.red })
  shl('@string', { fg = colors.yellow })
  shl('@string.documentation', { fg = colors.yellow })
  shl('@string.regexp', { fg = colors.cyan })
  shl('@string.escape', { fg = colors.orange })
  shl('@string.special', { fg = colors.orange })
  shl('@string.special.symbol', { fg = colors.orange })
  shl('@string.special.url', { fg = colors.cyan, underline = true })
  shl('@comment', { fg = colors.comment, italic = true })
  shl('@comment.documentation', { fg = colors.comment, italic = true })
  shl('@comment.error', { fg = colors.error })
  shl('@comment.warning', { fg = colors.warning })
  shl('@comment.note', { fg = colors.info })
  shl('@comment.todo', { fg = colors.bg, bg = colors.orange, bold = true })
  shl('@type', { fg = colors.blue })
  shl('@constant', { fg = colors.purple })
  shl('@constant.builtin', { fg = colors.purple })
  shl('@constant.macro', { fg = colors.purple })
  shl('@constructor', { fg = colors.green })
  shl('@parameter', { fg = colors.orange, italic = true })
  shl('@class', { fg = colors.blue })
  shl('@method', { fg = colors.green })
  shl('@method.call', { fg = colors.green })
  shl('@property', { fg = colors.fg })
  shl('@field', { fg = colors.fg })
  shl('@interface', { fg = colors.blue })
  shl('@namespace', { fg = colors.blue })
  shl('@module', { fg = colors.blue })
  shl('@punctuation', { fg = colors.fg })
  shl('@punctuation.bracket', { fg = colors.fg })
  shl('@punctuation.delimiter', { fg = colors.fg })
  shl('@punctuation.special', { fg = colors.orange })
  shl('@operator', { link = 'Operator' })
  shl('@attribute', { fg = colors.orange })
  shl('@boolean', { fg = colors.purple })
  shl('@number', { fg = colors.purple })
  shl('@number.float', { fg = colors.purple })
  shl('@tag', { fg = colors.red })
  shl('@tag.attribute', { fg = colors.green })
  shl('@tag.delimiter', { fg = colors.fg })
  shl('@markup', { fg = colors.fg })
  shl('@markup.strong', { fg = colors.fg, bold = true })
  shl('@markup.italic', { fg = colors.fg, italic = true })
  shl('@markup.strikethrough', { fg = colors.fg, strikethrough = true })
  shl('@markup.underline', { fg = colors.fg, underline = true })
  shl('@markup.heading', { fg = colors.yellow, bold = true })
  shl('@markup.quote', { fg = colors.comment, italic = true })
  shl('@markup.math', { fg = colors.cyan })
  shl('@markup.environment', { fg = colors.orange })
  shl('@markup.link', { fg = colors.cyan })
  shl('@markup.link.label', { fg = colors.cyan })
  shl('@markup.link.url', { fg = colors.cyan, underline = true })
  shl('@markup.raw', { fg = colors.yellow })
  shl('@markup.raw.block', { fg = colors.yellow })
  shl('@markup.list', { fg = colors.red })
  shl('@markup.list.checked', { fg = colors.green })
  shl('@markup.list.unchecked', { fg = colors.comment })
  shl('@character', { fg = colors.yellow })

  -- Diagnostics
  shl('DiagnosticError', { fg = colors.error })
  shl('DiagnosticWarn', { fg = colors.warning })
  shl('DiagnosticInfo', { fg = colors.info })
  shl('DiagnosticHint', { fg = colors.hint })
  shl('DiagnosticOk', { fg = colors.green })
  shl('DiagnosticUnderlineError', { undercurl = true, sp = colors.error })
  shl('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.warning })
  shl('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.info })
  shl('DiagnosticUnderlineHint', { undercurl = true, sp = colors.hint })
  shl('DiagnosticUnderlineOk', { undercurl = true, sp = colors.green })

  -- LSP
  shl('LspReferenceText', { bg = colors.bg_light })
  shl('LspReferenceRead', { bg = colors.bg_light })
  shl('LspReferenceWrite', { bg = colors.bg_light })
  shl('LspSignatureActiveParameter', { fg = colors.orange, bold = true })
  shl('LspCodeLens', { fg = colors.comment, italic = true })
  shl('LspCodeLensSeparator', { fg = colors.comment })

  -- Semantic tokens
  shl('@lsp.type.class', { fg = colors.blue })
  shl('@lsp.type.decorator', { fg = colors.orange })
  shl('@lsp.type.enum', { fg = colors.blue })
  shl('@lsp.type.enumMember', { fg = colors.purple })
  shl('@lsp.type.function', { fg = colors.green })
  shl('@lsp.type.interface', { fg = colors.blue })
  shl('@lsp.type.macro', { fg = colors.orange })
  shl('@lsp.type.method', { fg = colors.green })
  shl('@lsp.type.namespace', { fg = colors.blue })
  shl('@lsp.type.parameter', { fg = colors.orange, italic = true })
  shl('@lsp.type.property', { fg = colors.fg })
  shl('@lsp.type.struct', { fg = colors.blue })
  shl('@lsp.type.type', { fg = colors.blue })
  shl('@lsp.type.typeParameter', { fg = colors.blue, italic = true })
  shl('@lsp.type.variable', { fg = colors.fg })

  shl('IndentLine', { fg = colors.bg_light })
  shl('IndentLineCurrent', { fg = colors.fg_dark })

  -- GitSigns
  shl('GitSignsAdd', { fg = colors.green, bg = colors.bg })
  shl('GitSignsChange', { fg = colors.yellow, bg = colors.bg })
  shl('GitSignsDelete', { fg = colors.red, bg = colors.bg })
  shl('GitSignsAddNr', { fg = colors.green })
  shl('GitSignsChangeNr', { fg = colors.yellow })
  shl('GitSignsDeleteNr', { fg = colors.red })
  shl('GitSignsAddLn', { bg = '#2a3f2a' })
  shl('GitSignsChangeLn', { bg = '#3f3a2a' })
  shl('GitSignsDeleteLn', { bg = '#3f2a2a' })

  -- Mode line
  shl('ModeLineMode', { fg = colors.bg, bg = colors.red, bold = true })
  shl('ModeLineFileinfo', { fg = colors.fg, bold = true })
  shl('ModeLineGit', { fg = colors.green })
  shl('ModeLineDiagnostic', { fg = colors.warning })
end

load_monokai()
