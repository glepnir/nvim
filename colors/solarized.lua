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
  orange = '#cb4b16',
  red = '#dc322f',
  magenta = '#d33682',
  violet = '#6c71c4',
  blue = '#268bd2',
  cyan = '#2aa198',
  green = '#859900',
  -- Custom modifications
  bg = '#001f27', -- Darker background
  fg = '#bfbfbf', -- Brighter foreground
}

local function set_hl(group, properties)
  vim.api.nvim_set_hl(0, group, properties)
end

local function load_solarized()
  -- General editor highlights
  set_hl('Normal', { fg = colors.fg, bg = colors.bg })
  set_hl('EndOfBuffer', { fg = colors.bg })
  set_hl('CursorLine', { bg = colors.base02 })
  set_hl('CursorLineNr', { fg = colors.base1, bg = colors.base02 })
  set_hl('LineNr', { fg = colors.base01, bg = colors.bg })
  set_hl('Comment', { fg = colors.base01, italic = true })
  set_hl('String', { fg = colors.cyan })
  set_hl('Function', { fg = colors.blue })
  set_hl('Keyword', { fg = colors.green, bold = true })
  set_hl('Constant', { fg = colors.violet })
  set_hl('Identifier', { fg = colors.blue })
  set_hl('Statement', { fg = colors.green })
  set_hl('PreProc', { fg = colors.orange })
  set_hl('Type', { fg = colors.yellow })
  set_hl('Special', { fg = colors.magenta })
  set_hl('Underlined', { fg = colors.violet, underline = true })
  set_hl('Todo', { fg = colors.magenta, bold = true })
  set_hl('Error', { fg = colors.red, bg = colors.base03, bold = true })
  set_hl('WarningMsg', { fg = colors.orange })
  set_hl('IncSearch', { fg = colors.base03, bg = colors.yellow })
  set_hl('Search', { fg = colors.base03, bg = colors.yellow })
  set_hl('Visual', { bg = colors.base02 })
  set_hl('Pmenu', { fg = colors.base0, bg = colors.base02 })
  set_hl('PmenuSel', { fg = colors.base03, bg = colors.cyan })
  set_hl('PmenuSbar', { bg = colors.base01 })
  set_hl('PmenuThumb', { bg = colors.base0 })
  set_hl('MatchParen', { bg = colors.base02 })
  set_hl('WinBar', { bg = colors.base02 })
  set_hl('NormalFloat', { bg = colors.cyan })
  set_hl('FloatBorder', { fg = colors.blue })

  -- Status Line
  -- set_highlight('StatusLine', { fg = colors.base1, bg = colors.base02 })
  -- set_highlight('StatusLineNC', { fg = colors.base00, bg = colors.base02 })

  -- Treesitter highlights
  set_hl('@function', { fg = colors.blue })
  set_hl('@function.builtin', { fg = colors.blue })
  set_hl('@variable', { fg = colors.fg })
  set_hl('@keyword', { fg = colors.green, bold = true })
  set_hl('@string', { fg = colors.cyan })
  set_hl('@comment', { fg = colors.base01, italic = true })
  set_hl('@type', { fg = colors.yellow })
  set_hl('@constant', { fg = colors.violet })
  set_hl('@constructor', { fg = colors.orange })
  set_hl('@parameter', { fg = colors.base0 })
  set_hl('@class', { fg = colors.yellow })
  set_hl('@method', { fg = colors.blue })
  set_hl('@property', { link = '@variable' })
  set_hl('@field', { fg = colors.base0 })
  set_hl('@interface', { fg = colors.yellow })
  set_hl('@namespace', { fg = colors.base0 })
  set_hl('@punctuation', { fg = colors.base0 })
  set_hl('@operator', { fg = colors.base0 })
  set_hl('@attribute', { fg = colors.yellow })
  set_hl('@boolean', { fg = colors.orange })
  set_hl('@number', { fg = colors.orange })
  set_hl('@tag', { fg = colors.green })
  set_hl('@tag.attribute', { fg = colors.base0 })
  set_hl('@tag.delimiter', { fg = colors.base0 })

  -- Diagnostics
  set_hl('DiagnosticError', { fg = colors.red })
  set_hl('DiagnosticWarn', { fg = colors.yellow })
  set_hl('DiagnosticInfo', { fg = colors.blue })
  set_hl('DiagnosticHint', { fg = colors.cyan })
  set_hl('DiagnosticUnderlineError', { undercurl = true, sp = colors.red })
  set_hl('DiagnosticUnderlineWarn', { undercurl = true, sp = colors.yellow })
  set_hl('DiagnosticUnderlineInfo', { undercurl = true, sp = colors.blue })
  set_hl('DiagnosticUnderlineHint', { undercurl = true, sp = colors.cyan })

  -- LSP
  set_hl('LspReferenceText', { bg = colors.base02 })
  set_hl('LspReferenceRead', { bg = colors.base02 })
  set_hl('LspReferenceWrite', { bg = colors.base02 })

  -- Git
  set_hl('diffAdded', { fg = colors.green })
  set_hl('diffRemoved', { fg = colors.red })
  set_hl('diffChanged', { fg = colors.yellow })
  set_hl('diffOldFile', { fg = colors.orange })
  set_hl('diffNewFile', { fg = colors.cyan })
  set_hl('diffFile', { fg = colors.base0 })
  set_hl('diffLine', { fg = colors.base00 })
  set_hl('diffIndexLine', { fg = colors.violet })

  -- Indentmini
  set_hl('IndentLine', { link = 'Comment' })

  -- GitSigns
  set_hl('GitSignsAdd', { fg = colors.green, bg = colors.bg })
  set_hl('GitSignsChange', { fg = colors.yellow, bg = colors.bg })
  set_hl('GitSignsDelete', { fg = colors.red, bg = colors.bg })
end

load_solarized()
