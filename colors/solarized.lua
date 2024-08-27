local colors = {
  base03 = '#002b36',
  base02 = '#073642',
  base01 = '#586e75',
  base00 = '#657b83',
  base0 = '#839496',
  base1 = '#93a1a1',
  base2 = '#eee8d5',
  base3 = '#fdf6e3',
  yellow = '#b58900',
  orange = '#cc7d2d',
  red = '#d75f5f',
  violet = '#9884c4',
  blue = '#268bd2',
  cyan = '#2aa198',
  green = '#859900',
  -- Custom modifications
  bg = '#001f27', -- Darker background
  fg = '#bfbfbf', -- Brighter foreground
}

local function shl(group, properties)
  vim.api.nvim_set_hl(0, group, properties)
end

local function load_solarized()
  -- General editor highlights
  shl('Normal', { fg = colors.fg, bg = colors.bg })
  shl('EndOfBuffer', { fg = colors.bg })
  shl('CursorLine', { bg = colors.base02 })
  shl('CursorLineNr', { fg = colors.base1, bg = colors.base02 })
  shl('LineNr', { fg = colors.base01, bg = colors.bg })
  shl('Comment', { fg = colors.base01, italic = true })
  shl('String', { fg = colors.cyan })
  shl('Function', { fg = colors.blue })
  shl('Keyword', { fg = colors.green, bold = true })
  shl('Constant', { fg = colors.violet })
  shl('Identifier', { fg = colors.blue })
  shl('Statement', { fg = colors.green })
  shl('Number', { fg = colors.fg })
  shl('PreProc', { fg = colors.orange })
  shl('Type', { fg = colors.yellow })
  shl('Special', { fg = colors.orange })
  shl('Underlined', { fg = colors.violet, underline = true })
  shl('Todo', { fg = colors.violet, bold = true })
  shl('Error', { fg = colors.red, bg = colors.base03, bold = true })
  shl('WarningMsg', { fg = colors.orange })
  shl('IncSearch', { fg = colors.base03, bg = colors.yellow })
  shl('Search', { fg = colors.base03, bg = colors.yellow })
  shl('Visual', { bg = colors.base02 })
  shl('Pmenu', { fg = colors.base0, bg = colors.base02 })
  shl('PmenuSel', { fg = colors.base03, bg = colors.cyan })
  shl('PmenuSbar', { bg = colors.base01 })
  shl('PmenuThumb', { bg = colors.base0 })
  shl('MatchParen', { bg = colors.base02 })
  shl('WinBar', { bg = colors.base02 })
  shl('NormalFloat', { bg = colors.base03 })
  shl('FloatBorder', { fg = colors.blue })
  shl('Title', { fg = colors.yellow })
  shl('WinSeparator', { fg = colors.base1 })
  shl('StatusLine', { bg = colors.base1, fg = colors.base02 })
  shl('StatusLineNC', { bg = colors.base00, fg = colors.base02 })

  -- Treesitter highlights
  shl('@function', { fg = colors.blue })
  shl('@function.builtin', { fg = colors.blue })
  shl('@variable', { fg = colors.fg })
  shl('@keyword', { fg = colors.green, bold = true })
  shl('@string', { fg = colors.cyan })
  shl('@comment', { fg = colors.base01, italic = true })
  shl('@type', { fg = colors.yellow })
  shl('@type.builtin', { link = '@type' })
  shl('@constant', { fg = colors.violet })
  shl('@constructor', { fg = colors.orange })
  shl('@parameter', { fg = colors.base0 })
  shl('@class', { fg = colors.yellow })
  shl('@method', { fg = colors.blue })
  shl('@property', { link = '@variable' })
  shl('@field', { fg = colors.base0 })
  shl('@interface', { fg = colors.yellow })
  shl('@namespace', { fg = colors.base0 })
  shl('@punctuation', { fg = colors.base0 })
  shl('@operator', { fg = colors.base0 })
  shl('@attribute', { fg = colors.yellow })
  shl('@boolean', { link = 'Constant' })
  shl('@number', { link = 'Number' })
  shl('@tag', { fg = colors.green })
  shl('@tag.attribute', { fg = colors.base0 })
  shl('@tag.delimiter', { fg = colors.base0 })

  -- Diagnostics
  shl('DiagnosticError', { fg = colors.red })
  shl('DiagnosticWarn', { fg = colors.yellow })
  shl('DiagnosticInfo', { fg = colors.blue })
  shl('DiagnosticHint', { fg = colors.cyan })
  shl('DiagnosticUnderlineError', { undercurl = true, sp = colors.red })
  shl('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.yellow })
  shl('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.blue })
  shl('DiagnosticUnderlineHint', { undercurl = true, sp = colors.cyan })

  -- LSP
  shl('LspReferenceText', { bg = colors.base02 })
  shl('LspReferenceRead', { bg = colors.base02 })
  shl('LspReferenceWrite', { bg = colors.base02 })

  -- Git
  shl('diffAdded', { fg = colors.green })
  shl('diffRemoved', { fg = colors.red })
  shl('diffChanged', { fg = colors.yellow })
  shl('diffOldFile', { fg = colors.orange })
  shl('diffNewFile', { fg = colors.cyan })
  shl('diffFile', { fg = colors.base0 })
  shl('diffLine', { fg = colors.base00 })
  shl('diffIndexLine', { fg = colors.violet })

  -- Indentmini
  shl('IndentLine', { link = 'Comment' })
  shl('IndentLineCurrent', { link = 'Comment' })

  -- GitSigns
  shl('GitSignsAdd', { fg = colors.green, bg = colors.bg })
  shl('GitSignsChange', { fg = colors.yellow, bg = colors.bg })
  shl('GitSignsDelete', { fg = colors.red, bg = colors.bg })
  shl('DashboardHeader', { fg = colors.green })
end

load_solarized()